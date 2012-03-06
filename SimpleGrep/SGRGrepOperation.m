//
//  SGRGrepOperation.m
//  SimpleGrep
//
//  Created by Rick Fillion on 12-03-05.
//  Copyright (c) 2012 Centrix.ca. All rights reserved.
//

#import "SGRGrepOperation.h"

@interface SGRGrepOperation (Private)

- (void)_start;
- (void)_handleData:(NSData *)data;
- (void)_processLine:(NSString *)line;
- (void)_reportResultToDelegate:(NSArray *)components;
- (void)_reportCompletedToDelegate;

@end

@implementation SGRGrepOperation

- (SGRGrepOperation *)initWithPath:(NSString *)path searchString:(NSString *)searchString recursive:(BOOL)recursive
{
    if (self = [super init])
    {
        _path = [path retain];
        _searchString = [searchString retain];
        _recursive = recursive;
        _lineBuffer = [[NSMutableData dataWithCapacity:100] retain];
        _lineSplitValues = [[NSArray arrayWithObjects:
                            //[NSNumber numberWithChar:0x0],
                            [NSNumber numberWithChar:0xA],
                            //[NSNumber numberWithChar:0xD],
                            nil] retain];
    }
    return self;
}

- (void)dealloc
{
    [_searchString release];
    [_path release];
    [_grepTask release];
    [_lineSplitValues release];
    [_lineBuffer release];

    [super dealloc];
}

- (NSString *)searchString
{
    return _searchString;
}

- (NSString *)path
{
    return _path;
}
- (BOOL)isRecursive
{
    return _recursive;
}

- (id)delegate
{
    return _delegate;
}

- (void)setDelegate:(id)delegate
{
    _delegate = delegate;
}

- (void)start
{
    if (_started == YES)
        return;
    _started = YES;
    
    [NSThread detachNewThreadSelector:@selector(_start) toTarget:self withObject:nil];
}

- (void)_start;
{    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Create pipes and put them in the right mode
    NSPipe *outputPipe = [[NSPipe pipe] retain];
    
    // Just... do it.
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/grep"];
    [task setCurrentDirectoryPath:[self path]];
    NSArray *arguments = nil;
    if ([self isRecursive])
        arguments = [NSArray arrayWithObjects:@"-n", @"-R",[self searchString], [self path], nil];
    else
        arguments = [NSArray arrayWithObjects:@"-n", [self searchString], [self path], nil];
    [task setArguments: arguments];
    [task setStandardOutput: outputPipe];
    [task setStandardError: outputPipe];
    NSMutableDictionary* environment = [NSMutableDictionary dictionaryWithDictionary: [[NSProcessInfo processInfo] environment]];
	// set up for unbuffered I/O
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
	[task setEnvironment:environment];
    
    [task launch];
    
    [[outputPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
    
    NSUInteger length = 1;
    NSFileHandle *readHandle = [outputPipe fileHandleForReading];
    NSData *data = [readHandle readDataOfLength:length];
    while ([data length]>0)
    {
        [self _handleData:data];
        data = [readHandle readDataOfLength:length];
    }
    
    [task waitUntilExit];
    
    int status = [task terminationStatus];
    NSLog(@"end status = %i", status);
    
    // Clean up
    [task release];
    [outputPipe release];
    
    [self performSelector:@selector(_reportCompletedToDelegate) onThread:[NSThread mainThread] withObject:nil waitUntilDone:YES];
    
    [pool drain];
}

- (BOOL)isCanceled
{
    return _canceled;
}

- (void)cancel
{
    _canceled = YES;
}

// Private

- (void)_handleData:(NSData *)data
{
    BOOL foundSplit = NO;
    char byte;
    [data getBytes:&byte length:1];
    for (int i = 0; i < [_lineSplitValues count]; i++)
    {
        NSNumber *lineSplitValue = [_lineSplitValues objectAtIndex:i];
        if ([lineSplitValue charValue] == byte)
            foundSplit = YES;
    }
    
    if (foundSplit)
    {
        // create a string with the current data
        NSString *lineBufferString = [[[NSString alloc] initWithBytes:[_lineBuffer bytes] length:[_lineBuffer length] encoding:NSASCIIStringEncoding] autorelease];
        [self _processLine:lineBufferString];
        [_lineBuffer setData:[NSData data]];
    }
    else {
        // add the data to the line buffer
        [_lineBuffer appendData:data];
    }
}
- (void)_processLine:(NSString *)line
{
    NSString *divider = @":";
    NSArray *components = [line componentsSeparatedByString:divider];
    if ([components count] < 2) {
        components = [NSArray arrayWithObjects:[components objectAtIndex:0], @"", @"", nil];
    }

    [self performSelector:@selector(_reportResultToDelegate:) onThread:[NSThread mainThread] withObject:components waitUntilDone:YES];
}

- (void)_reportResultToDelegate:(NSArray *)components
{
    if ([[NSThread currentThread] isMainThread] == NO)
    {
        NSLog(@"-[SGRGrepOperation _reportResultToDelegate:] must be called on the main thread");
        return;
    }
    
    if ([self isCanceled])
        return;
    
    NSString *path = [components objectAtIndex:0];
    if ([path length] > [[self path] length])
    {
        path = [path substringFromIndex:[[self path] length]];
    }
    NSNumber *lineNumber = [NSNumber numberWithInt:[[components objectAtIndex:1] intValue]];
    NSString *lineString = [components objectAtIndex:2];
    if (_delegate != nil && [_delegate respondsToSelector:@selector(grepOperation:foundResultWithPath:lineNumber:lineStringValue:)])
    {
        [_delegate grepOperation:self foundResultWithPath:path lineNumber:lineNumber lineStringValue:lineString];
    }
}

- (void)_reportCompletedToDelegate
{
    if ([[NSThread currentThread] isMainThread] == NO)
    {
        NSLog(@"-[SGRGrepOperation _reportCompletedToDelegate:] must be called on the main thread");
        return;
    }
    
    if ([self isCanceled])
        return;
    
    if (_delegate != nil && [_delegate respondsToSelector:@selector(grepOperationCompleted:)])
    {
        [_delegate grepOperationCompleted:self];
    }
}

@end

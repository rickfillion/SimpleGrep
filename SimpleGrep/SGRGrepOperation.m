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
- (void)_grepSubPath:(NSString *)subpath;
- (void)_handleData:(NSData *)data forSubPath:(NSString *)subpath;
- (void)_processLine:(NSString *)line forSubPath:(NSString *)subpath;
- (void)_reportResultToControllerWithPath:(NSString *)path lineNumber:(NSNumber *)lineNumber lineStringValue:(NSString *)lineString;
- (void)_reportCompletedToController;

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

- (void)start
{
    if (_started == YES)
        return;
    _started = YES;
    
    [NSThread detachNewThreadSelector:@selector(_start) toTarget:self withObject:nil];
}

- (void)_grepSubPath:(NSString *)subpath;
{
    int length = 1;
    int status;

    NSArray *arguments = nil;
    NSMutableDictionary *environment = nil;
    NSFileHandle *readHandle = nil;
    NSData *data = nil;
    NSString *finalPath = nil;
    NSTask *task = nil;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Create pipes and put them in the right mode
    NSPipe *outputPipe = [[NSPipe pipe] retain];

    NSString *appleGrepPath = @"/usr/bin/grep";
    NSString *nextGrepPath = @"/bin/grep";

    BOOL isApple = [[NSFileManager defaultManager] fileExistsAtPath:appleGrepPath];

    finalPath = [NSString stringWithFormat:@"%@/%@", [self path], subpath];
    //NSLog(@"grep path: %@", finalPath);
    // Just... do it.
    task = [[NSTask alloc] init];
    [task setLaunchPath:isApple ? appleGrepPath : nextGrepPath];
    [task setCurrentDirectoryPath:@"/"];
    arguments = [NSArray arrayWithObjects:@"-n", [self searchString], finalPath, nil];
    [task setArguments: arguments];
    [task setStandardOutput: outputPipe];
    [task setStandardError: outputPipe];
    environment = [NSMutableDictionary dictionaryWithDictionary: [[NSProcessInfo processInfo] environment]];
    // set up for unbuffered I/O
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [task setEnvironment:environment];

    [task launch];

    readHandle = [outputPipe fileHandleForReading];
    data = [readHandle readDataOfLength:length];
    while ([data length]>0)
    {
        [self _handleData:data forSubPath:subpath];
        data = [readHandle readDataOfLength:length];
    }

    [task waitUntilExit];

    status = [task terminationStatus];
    //NSLog(@"task termination status = %i", status);

    // Clean up
    [task release];
    [outputPipe release];

    [pool release];
}

- (void)_start;
{
    int subpathIndex = 0;
    NSArray *subpaths = nil;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if ([self isRecursive])
        subpaths = [[NSFileManager defaultManager] subpathsAtPath:[self path]];
    else 
        subpaths = [[NSFileManager defaultManager] directoryContentsAtPath:[self path]];

    for (subpathIndex = 0; subpathIndex < [subpaths count]; subpathIndex++)
    {
        [self _grepSubPath:[subpaths objectAtIndex:subpathIndex]];
    }
    
    [self _reportCompletedToController];
    
    [pool release];
}

- (BOOL)isCanceled
{
    return _canceled;
}

- (void)cancel
{
    NSLog(@"canceling grep operation");
    _canceled = YES;
}

- (int)identifier {
    return _identifier;
}

- (void)setIdentifier:(int)uniqueIdentifier {
    _identifier = uniqueIdentifier;
}

// Private

- (void)_handleData:(NSData *)data forSubPath:(NSString *)subpath
{
    BOOL foundSplit = NO;
    char byte;
    int i;
    [data getBytes:&byte length:1];
    for (i = 0; i < [_lineSplitValues count]; i++)
    {
        NSNumber *lineSplitValue = [_lineSplitValues objectAtIndex:i];
        if ([lineSplitValue charValue] == byte)
            foundSplit = YES;
    }
    
    if (foundSplit)
    {
        // create a string with the current data
        NSString *lineBufferString = [[[NSString alloc] initWithCString:[_lineBuffer bytes] length:[_lineBuffer length]] autorelease];
        [self _processLine:lineBufferString forSubPath:subpath];
        [_lineBuffer setData:[NSData data]];
    }
    else {
        // add the data to the line buffer
        [_lineBuffer appendData:data];
    }
}
- (void)_processLine:(NSString *)line forSubPath:(NSString *)subpath
{
    NSString *divider = @":";
    NSArray *components = [line componentsSeparatedByString:divider];
    NSNumber *lineNumber = nil;
    NSString *lineString = nil;

    if ([components count] != 2) {
        return;
    }

    lineNumber = [NSNumber numberWithInt:[[components objectAtIndex:0] intValue]];
    lineString = [components objectAtIndex:1];
    [self _reportResultToControllerWithPath:subpath lineNumber:lineNumber lineStringValue:lineString];
}

- (void)_reportResultToControllerWithPath:(NSString *)path lineNumber:(NSNumber *)lineNumber lineStringValue:(NSString *)lineString
{
    NSString *finalPath = nil;
    id searchControllerProxy = nil;
    
    if ([self isCanceled]) {
        NSLog(@"grep operation canceled, returning.");
        return;
    }

    //NSLog(@"processing result for path %@",  path);

    // Check to see if final path actually exists
    finalPath = [NSString stringWithFormat:@"%@/%@", [self path], path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:finalPath] == NO) {
        NSLog(@"file doesn't exist at path : %@", finalPath);
        return;
    }
    
    searchControllerProxy = [NSConnection rootProxyForConnectionWithRegisteredName:@"searchController" host:@"*"];
    [searchControllerProxy setProtocolForProxy:@protocol(SGRGrepOperationController)];
    [searchControllerProxy grepOperation:self foundResultWithPath:path lineNumber:lineNumber lineStringValue:lineString];
}

- (void)_reportCompletedToController
{
    id searchControllerProxy = nil;

    if ([self isCanceled])
        return; 
    
    searchControllerProxy = [NSConnection rootProxyForConnectionWithRegisteredName:@"searchController" host:@"*"];
    [searchControllerProxy setProtocolForProxy:@protocol(SGRGrepOperationController)];
    [searchControllerProxy grepOperationCompleted: self];
}

@end

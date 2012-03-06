//
//  SGRSearchResult.m
//  SimpleGrep
//
//  Created by Rick Fillion on 12-03-05.
//  Copyright (c) 2012 Centrix.ca. All rights reserved.
//

#import "SGRSearchResult.h"

@implementation SGRSearchResult

- (id)initWithPath:(NSString *)path lineNumber:(NSNumber *)lineNumber lineStringValue:(NSString *)lineStringValue
{
    if (self = [super init])
    {
        [self setPath:path];
        [self setLineNumber:lineNumber];
        [self setLineStringValue:lineStringValue];
    }
    return self;
}

- (void)dealloc 
{
    [_path release];
    [_lineNumber release];
    [_lineStringValue release];
    [super dealloc];
}
- (NSString *)path 
{
    return _path;
}
- (void)setPath:(NSString *)path 
{
    [path retain];
    [_path release];
    _path = path;
}

- (NSNumber *)lineNumber
{
    return _lineNumber;
}

- (void)setLineNumber:(NSNumber *)lineNumber
{
    [lineNumber retain];
    [_lineNumber release];
    _lineNumber = lineNumber;
}

- (NSString *)lineStringValue
{
    return _lineStringValue;
}

- (void)setLineStringValue:(NSString *)lineStringValue
{
    [lineStringValue retain];
    [_lineStringValue release];
    _lineStringValue = lineStringValue;
}

@end

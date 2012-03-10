//
//  SGRSearchResult.h
//  SimpleGrep
//
//  Created by Rick Fillion on 12-03-05.
//  Copyright (c) 2012 Centrix.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGRSearchResult : NSObject
{
    NSString *_path;
    NSNumber *_lineNumber;
    NSString *_lineStringValue;
}
- (id)initWithPath:(NSString *)path lineNumber:(NSNumber *)lineNumber lineStringValue:(NSString *)lineStringValue;

- (NSString *)path;
- (void)setPath:(NSString *)path;
- (NSNumber *)lineNumber;
- (void)setLineNumber:(NSNumber *)lineNumber;
- (NSString *)lineStringValue;
- (void)setLineStringValue:(NSString *)lineStringValue;

@end

//
//  SGRGrepOperation.h
//  SimpleGrep
//
//  Created by Rick Fillion on 12-03-05.
//  Copyright (c) 2012 Centrix.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGRGrepOperation;

@protocol SGRGrepOperationDelegate <NSObject>

- (void)grepOperationCompleted:(SGRGrepOperation *)operation;
- (void)grepOperation:(SGRGrepOperation *)operation foundResultWithPath:(NSString *)path lineNumber:(NSNumber *)lineNumber lineStringValue:(NSString *)lineStringValue;

@end

@interface SGRGrepOperation : NSObject
{
@private;
    NSString *_searchString;
    NSString *_path;
    BOOL _canceled;
    BOOL _recursive;
    BOOL _started;
    id<SGRGrepOperationDelegate> _delegate;
    
    // NSTask related
    NSTask *_grepTask;
    NSArray *_lineSplitValues;
    NSMutableData *_lineBuffer;
}

- (SGRGrepOperation *)initWithPath:(NSString *)path searchString:(NSString *)searchString recursive:(BOOL)recursive;
- (NSString *)searchString;
- (NSString *)path;
- (BOOL)isRecursive;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (void)start;
- (BOOL)isCanceled;
- (void)cancel;

@end

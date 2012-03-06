//
//  SGRSearchController.m
//  SimpleGrep
//
//  Created by Rick Fillion on 12-03-05.
//  Copyright (c) 2012 Centrix.ca. All rights reserved.
//

#import "SGRSearchController.h"
#import "SGRSearchResult.h"
#import "SGRGrepOperation.h"

@interface SGRSearchController (Private)

- (void)_changeStatus:(SGRSearchControllerStatus)newStatus;
- (void)_clearSearchResults;
- (void)_addSearchResult:(SGRSearchResult *)result;

@end

@implementation SGRSearchController

- (id)init
{
    if (self = [super init])
    {
        _currentSearchResults = [[NSMutableArray alloc] initWithCapacity:100];
    }
    return self;
}

- (void)dealloc
{
    [_currentGrepOperation release];
    [_currentSearchResults release];
    [super dealloc];
}

- (SGRSearchControllerStatus)status
{
    return _status;
}

- (NSString *)statusString
{
    if (_status == SGRSearchControllerStatusIdle)
        return @"Ready";
    else if (_status == SGRSearchControllerStatusSearching)
        return @"Searching...";
    return @"";
}

- (NSArray *)currentSearchResults
{
    return [[_currentSearchResults copy] autorelease];
}

- (void)searchFor:(NSString *)searchString inFolder:(NSString *)path recursively:(BOOL)recursively
{
    if (_status != SGRSearchControllerStatusIdle)
    {
        // Cancel whatever we're currently doing
        
        [_currentGrepOperation cancel];
        [_currentGrepOperation release];
        _currentGrepOperation = nil;
        [self _clearSearchResults];
        [self _changeStatus:SGRSearchControllerStatusIdle];
    }
    
    [self _changeStatus:SGRSearchControllerStatusSearching];
    
    
    SGRGrepOperation *operation = [[SGRGrepOperation alloc] initWithPath:path searchString:searchString recursive:recursively];
    [operation setDelegate:self];
    _currentGrepOperation = operation;
    [_currentGrepOperation start];
}

// Grep Operation Delelegate
// Guaranteed to be called on main thread
- (void)grepOperation:(SGRGrepOperation *)operation foundResultWithPath:(NSString *)path lineNumber:(NSNumber *)lineNumber lineStringValue:(NSString *)lineStringValue
{
    if (operation != _currentGrepOperation)
        return;
    
    SGRSearchResult *result = [[[SGRSearchResult alloc] initWithPath:path lineNumber:lineNumber lineStringValue:lineStringValue] autorelease];
    [self _addSearchResult:result];
}

- (void)grepOperationCompleted:(SGRGrepOperation *)operation
{
    [self _changeStatus:SGRSearchControllerStatusIdle];
    [_currentGrepOperation release];
    _currentGrepOperation = nil;
}

// Private

- (void)_changeStatus:(SGRSearchControllerStatus)newStatus
{
    _status = newStatus;
    [[NSNotificationCenter defaultCenter] postNotificationName:SGRSearchControllerChangedStatusNotification object:self];
}


- (void)_clearSearchResults
{
    if ([[NSThread currentThread] isMainThread] == NO) 
    {
        NSLog(@"-[SGRSearchController _clearSearchResults] cannot be called from the non-main thread");
        return;
    }
    
    [_currentSearchResults removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:SGRSearchControllerUpdatedResultsNotification object:self];
}

- (void)_addSearchResult:(SGRSearchResult *)result
{
    if ([[NSThread currentThread] isMainThread] == NO) 
    {
        NSLog(@"-[SGRSearchController _addSearchResult:] cannot be called from the non-main thread");
        return;
    }
    
    [_currentSearchResults addObject:result];
    [[NSNotificationCenter defaultCenter] postNotificationName:SGRSearchControllerUpdatedResultsNotification object:self];
}

@end

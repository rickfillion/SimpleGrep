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
        NSConnection *distributedConnection = [NSConnection defaultConnection];
        [distributedConnection setRootObject:self];
        [distributedConnection registerName:@"searchController"];
        _currentSearchResults = [[NSMutableArray alloc] initWithCapacity:100];
        _grepOperations = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

- (void)dealloc
{
    [_grepOperations release];
    [_currentSearchResults release];
    [_lastResultsChangedNotificationPostedDate release];
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
    SGRGrepOperation *operation = nil;
    NSString *operationKey = nil;
    
    _currentOperationIdentifier++;
    [self _clearSearchResults];

    [self _changeStatus:SGRSearchControllerStatusSearching];
    
    operation = [[SGRGrepOperation alloc] initWithPath:path searchString:searchString recursive:recursively];
    [operation setIdentifier: _currentOperationIdentifier];
    operationKey = [NSString stringWithFormat:@"%i", [operation identifier]];
    [_grepOperations setObject:operation forKey:operationKey]; 
    [operation start];
}

// Grep Operation Delelegate
// Called via Distributed Objects
- (void)grepOperation:(SGRGrepOperation *)operation foundResultWithPath:(NSString *)path lineNumber:(NSNumber *)lineNumber lineStringValue:(NSString *)lineStringValue
{
    SGRSearchResult *result = nil;

    if ([operation identifier] != _currentOperationIdentifier) {
        [operation cancel];
        return;
    }
    
    result = [[[SGRSearchResult alloc] initWithPath:path lineNumber:lineNumber lineStringValue:lineStringValue] autorelease];
    [self _addSearchResult:result];
}

- (void)grepOperationCompleted:(SGRGrepOperation *)operation
{
    NSString *operationKey = nil;
    NSString *operationToRelease = nil;

    if ([operation identifier] == _currentOperationIdentifier)
    	[self _changeStatus:SGRSearchControllerStatusIdle];

    operationKey = [NSString stringWithFormat:@"%i", [operation identifier]];
    operationToRelease = [_grepOperations objectForKey:operationKey];
    [_grepOperations removeObjectForKey:operationKey];
    [operationToRelease autorelease];
}

// Private

- (void)_changeStatus:(SGRSearchControllerStatus)newStatus
{
    _status = newStatus;
    [[NSNotificationCenter defaultCenter] postNotificationName:SGRSearchControllerChangedStatusNotification object:self];
}


- (void)_clearSearchResults
{   
    [_currentSearchResults removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:SGRSearchControllerUpdatedResultsNotification object:self];
}

- (void)_addSearchResult:(SGRSearchResult *)result
{
    NSTimeInterval secondsBetweenNotifications = 0.5;
    BOOL shouldPostNotification = NO;
        
    [_currentSearchResults addObject:result];
    
    if (_lastResultsChangedNotificationPostedDate == nil)
        shouldPostNotification = YES;
    else if ([_lastResultsChangedNotificationPostedDate timeIntervalSinceNow] < -secondsBetweenNotifications)
        shouldPostNotification = YES;

    if (shouldPostNotification) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SGRSearchControllerUpdatedResultsNotification object:self];
        [_lastResultsChangedNotificationPostedDate release];
        _lastResultsChangedNotificationPostedDate = [[NSDate date] retain];
    }
    
}

@end

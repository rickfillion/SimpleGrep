//
//  SGRSearchController.h
//  SimpleGrep
//
//  Created by Rick Fillion on 12-03-05.
//  Copyright (c) 2012 Centrix.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SGRSearchControllerUpdatedResultsNotification @"SGRSearchControllerUpdatedResultsNotification"
#define SGRSearchControllerChangedStatusNotification @"SGRSearchControllerUpdatedResultsNotification"

enum _SGRSearchControllerStatus {
    SGRSearchControllerStatusIdle = 0,
    SGRSearchControllerStatusSearching = 1,
};
typedef int SGRSearchControllerStatus;

@class SGRGrepOperation;

@interface SGRSearchController : NSObject
{
    int _status;
    NSMutableArray *_currentSearchResults;
    SGRGrepOperation *_currentGrepOperation;
    NSDate *_lastResultsChangedNotificationPostedDate;
}

- (SGRSearchControllerStatus)status;
- (NSString *)statusString;
- (NSArray *)currentSearchResults;
- (void)searchFor:(NSString *)searchString inFolder:(NSString *)path recursively:(BOOL)recursively;

@end

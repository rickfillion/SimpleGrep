//
//  SGRAppController.h
//  SimpleGrep
//
//  Created by Rick Fillion on 12-03-05.
//  Copyright (c) 2012 Centrix.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGRSearchController;

@interface SGRAppController : NSObject <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSTextField *searchTextField;
    IBOutlet NSTextField *folderPathTextField;
    IBOutlet NSButton *recursiveCheckboxButton;
    IBOutlet NSTextField *statusTextField;
    IBOutlet NSTextField *resultsTextField;
    IBOutlet NSTableView *resultsTableView;
    
    NSString *_path;
    NSArray *_results;
    SGRSearchController *_searchController;
}

- (IBAction)search:(id)sender;
- (IBAction)chooseFolder:(id)sender;
- (IBAction)toggleRecursive:(id)sender;

@end

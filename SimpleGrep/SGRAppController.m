//
//  SGRAppController.m
//  SimpleGrep
//
//  Created by Rick Fillion on 12-03-05.
//  Copyright (c) 2012 Centrix.ca. All rights reserved.
//

#import "SGRAppController.h"
#import "SGRSearchController.h"
#import "SGRSearchResult.h"

#define SGRResultsTableColumnIcon @"SGRResultsTableColumnIcon"
#define SGRResultsTableColumnPath @"SGRResultsTableColumnPath"
#define SGRResultsTableColumnLineNumber @"SGRResultsTableColumnLineNumber"
#define SGRResultsTableColumnLineStringValue @"SGRResultsTableColumnLineStringValue"

@interface SGRAppController (Private)

- (void)_updateSearchResultTextField;
- (void)_updateSearchStatusTextField;
- (void)_updateFolderPathTextField;
- (void)_setupTableViewColumns;
- (void)_tableViewDoubleClick;

@end

@implementation SGRAppController

- (id)init
{
    if (self = [super init])
    {
        _path = NSHomeDirectory();
        [_path retain];
        _searchController = [[SGRSearchController alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(searchResultsUpdatedNotification:) 
                                                     name:SGRSearchControllerUpdatedResultsNotification 
                                                   object:_searchController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(searchControllerStatusChangedNotification:)
                                                     name:SGRSearchControllerChangedStatusNotification
                                                   object:_searchController];
        
    }
    return self;
}

- (void)dealloc
{
    [_path release];
    [_results release];
    [_searchController release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [self _setupTableViewColumns];
    [resultsTableView setDataSource:self];
    [resultsTableView setDelegate:self];
    [resultsTableView setTarget:self];
    [resultsTableView setDoubleAction:@selector(_tableViewDoubleClick:)];
    [resultsTableView reloadData];
    [self _updateSearchResultTextField];
    [self _updateSearchStatusTextField];
    [self _updateFolderPathTextField];
}

// Actions

- (IBAction)search:(id)sender
{
    NSString *searchString = [searchTextField stringValue];
    if ([[searchTextField  stringValue]length] == 0)
    {
        return;
    }
    [_searchController searchFor:searchString inFolder:_path recursively:[recursiveCheckboxButton state]];
}
- (IBAction)chooseFolder:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    long result = [openPanel runModalForDirectory:_path file:nil];
    if (result == NSCancelButton)
        return;
    
    [_path release];
    _path = [[[openPanel filenames] objectAtIndex:0] retain];
    [self _updateFolderPathTextField];
}
- (IBAction)toggleRecursive:(id)sender
{
    
}

// Notifications

- (void)searchControllerStatusChangedNotification:(NSNotification *)notification
{
    [self _updateSearchStatusTextField];
    [resultsTableView reloadData];
}

- (void)searchResultsUpdatedNotification:(NSNotification *)notification
{
    [_results release];
    _results = [[_searchController currentSearchResults] retain];
    [self _updateSearchResultTextField];
    [resultsTableView reloadData];
}

// Private

- (void)_updateSearchResultTextField
{
    NSString *resultsFound = @"";
    if (_results == nil)
        resultsFound = @"";
    else if ([_results count] == 0)
        resultsFound = @"No results found.";
    else if ([_results count] == 1)
        resultsFound = @"1 result found.";
    else
        resultsFound = [NSString stringWithFormat:@"%i results found.", [_results count]];
    
    [resultsTextField setStringValue:resultsFound];
}

- (void)_updateSearchStatusTextField
{
    [statusTextField setStringValue:[_searchController statusString]];
}

- (void)_updateFolderPathTextField
{
    [folderPathTextField setStringValue:_path];
}

- (void)_setupTableViewColumns
{
    // Get rid of whatever was in there.
    while ([[resultsTableView tableColumns] count] > 0) {
        [resultsTableView removeTableColumn:[[resultsTableView tableColumns] objectAtIndex:0]];
    }

    NSTableColumn *iconColumn = [[[NSTableColumn alloc] initWithIdentifier:SGRResultsTableColumnIcon] autorelease];
    NSTableColumn *pathColumn = [[[NSTableColumn alloc] initWithIdentifier:SGRResultsTableColumnPath] autorelease];
    NSTableColumn *lineNumberTableColumn = [[[NSTableColumn alloc] initWithIdentifier:SGRResultsTableColumnLineNumber] autorelease];
    NSTableColumn *lineStringValueTableColumn = [[[NSTableColumn alloc] initWithIdentifier:SGRResultsTableColumnLineStringValue] autorelease];
    
    [iconColumn setWidth:18.0];
    [pathColumn setWidth:200.0];
    [lineNumberTableColumn setWidth:40.0];
    [lineStringValueTableColumn setWidth:230.0];
    
    [[iconColumn headerCell] setStringValue:@""];
    [[pathColumn headerCell] setStringValue:@"Path"];
    [[lineNumberTableColumn headerCell] setStringValue:@"Line"];
    [[lineStringValueTableColumn headerCell] setStringValue:@"Sample"];
    
    NSCell *imageCell = [[[NSCell alloc] initImageCell:[NSImage imageNamed:@"NSApplication"]] autorelease];
    [iconColumn setDataCell:imageCell];
    
    [resultsTableView addTableColumn:iconColumn];
    [resultsTableView addTableColumn:pathColumn];
    [resultsTableView addTableColumn:lineNumberTableColumn];
    [resultsTableView addTableColumn:lineStringValueTableColumn];    
}

- (void)_tableViewDoubleClick:(id)sender
{
    long clickedRow = [resultsTableView clickedRow];
    if (clickedRow > [_results count])
        return;
    
    SGRSearchResult *result = [_results objectAtIndex:clickedRow];
    NSString *path = [NSString stringWithFormat:@"%@/%@", _path, [result path]];
    [[NSWorkspace sharedWorkspace] openFile:path];
}

// NSTableViewDelegate

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:SGRResultsTableColumnIcon]) {
        NSString *path = [aCell objectValue];
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        [icon setSize:NSMakeSize(16, 16)];
        [aCell setImage:icon];
    }
}

// NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [_results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    SGRSearchResult *result = [_results objectAtIndex:rowIndex];
    id objectValue = nil;
    
    if ([[aTableColumn identifier] isEqualToString:SGRResultsTableColumnIcon]) {
        NSString *path = [NSString stringWithFormat:@"%@/%@", _path, [result path]];
        objectValue = path; 
    }
    else if ([[aTableColumn identifier] isEqualToString:SGRResultsTableColumnPath])
        objectValue = [result path];
    else if ([[aTableColumn identifier] isEqualToString:SGRResultsTableColumnLineNumber])
        objectValue = [result lineNumber];
    else if ([[aTableColumn identifier] isEqualToString:SGRResultsTableColumnLineStringValue])
        objectValue = [result lineStringValue];
    
    return objectValue;
}


@end

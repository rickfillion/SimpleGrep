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
    if ([searchString length] == 0)
    {
        return;
    }
    [_searchController searchFor:searchString inFolder:_path recursively:[recursiveCheckboxButton state]];
}

- (IBAction)chooseFolder:(id)sender
{
    int result = 0;
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    result = [openPanel runModalForDirectory:_path file:nil];
    if (result == NSCancelButton)
        return;
    
    [_path release];
    _path = [[[openPanel filenames] lastObject] retain];
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
    NSTableColumn *iconColumn = nil;
    NSCell *iconCell = nil;
    NSTableColumn *pathColumn = nil;
    NSTableColumn *lineNumberColumn = nil;
    NSTableColumn *lineStringValueColumn = nil;

    // Get rid of whatever was in there.
    while ([[resultsTableView tableColumns] count] > 0) 
    {
        [resultsTableView removeTableColumn:[[resultsTableView tableColumns] objectAtIndex:0]];
    }
    
    iconColumn = [[[NSTableColumn alloc] initWithIdentifier:SGRResultsTableColumnIcon] autorelease];
    pathColumn = [[[NSTableColumn alloc] initWithIdentifier:SGRResultsTableColumnPath] autorelease];
    lineNumberColumn = [[[NSTableColumn alloc] initWithIdentifier:SGRResultsTableColumnLineNumber] autorelease];
    lineStringValueColumn = [[[NSTableColumn alloc] initWithIdentifier:SGRResultsTableColumnLineStringValue] autorelease];

    iconCell = [[[NSCell alloc] initImageCell: nil] autorelease];
    [iconColumn setDataCell: iconCell];

    [iconColumn setWidth:18.0];
    [pathColumn setWidth:200.0];
    [lineNumberColumn setWidth:40.0];
    [lineStringValueColumn setWidth:230.0];
    
    [[iconColumn headerCell] setStringValue:@""];
    [[pathColumn headerCell] setStringValue:@"Path"];
    [[lineNumberColumn headerCell] setStringValue:@"Line"];
    [[lineStringValueColumn headerCell] setStringValue:@"Sample"];

    [iconColumn setEditable: NO];
    [pathColumn setEditable: NO];
    [lineNumberColumn setEditable: NO];
    [lineStringValueColumn setEditable: NO];
    
    [resultsTableView addTableColumn:iconColumn];
    [resultsTableView addTableColumn:pathColumn];
    [resultsTableView addTableColumn:lineNumberColumn];
    [resultsTableView addTableColumn:lineStringValueColumn];

    [resultsTableView setDrawsGrid: NO];
    [resultsTableView sizeLastColumnToFit];
}

- (void)_tableViewDoubleClick:(id)sender
{
    SGRSearchResult *result = nil;
    NSString *path = nil;
    long clickedRow = [resultsTableView clickedRow];
    if (clickedRow > [_results count]) {
        return;
    }
    
    result = [_results objectAtIndex:clickedRow];
    path = [NSString stringWithFormat:@"%@/%@", _path, [result path]];
    [[NSWorkspace sharedWorkspace] openFile:path];
}

// NSTableViewDelegate

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSString *path = nil;
    NSImage *icon = nil;
    if ([[aTableColumn identifier] isEqualToString:SGRResultsTableColumnIcon]) {
        path = [aCell objectValue];
        icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        [icon setScalesWhenResized: YES];
        [icon setSize:NSMakeSize(16, 16)];
        [aCell setImage:icon];
        [aTableView updateCell: aCell];
    }
}

// NSTableViewDataSource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [_results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
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

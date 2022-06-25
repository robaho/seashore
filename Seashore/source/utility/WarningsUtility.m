#import "WarningsUtility.h"
#import "SeaWindowContent.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaDocument.h"

@interface NoticesItem : NSCollectionViewItem
@end

@implementation WarningsUtility

- (id)init
{
	self = [super init];
    notices = [NSMutableArray array];
	return self;
}

- (void)tableClicked
{
    int row = [noticesView clickedRow];
    int col = [noticesView clickedColumn];
    if(col==1){
        [noticesView beginUpdates];
        [noticesView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationEffectFade];
        [noticesView endUpdates];
        [notices removeObjectAtIndex:row];
    }
    if([notices count]==0){
        [alertButton setHidden:TRUE];
        [win close];
    }
}

- (IBAction)showNotices:(id)sender {
    [noticesView setDelegate:self];
    [noticesView setDataSource:self];
    [noticesView reloadData];
    [noticesView setAction:@selector(tableClicked)];

    // center popup in document window
    NSRect winFrame = [[alertButton window] frame];

    float x = winFrame.size.width/2 - [win frame].size.width/2 + winFrame.origin.x;
    float y = winFrame.size.height/2 - [win frame].size.height/2 + winFrame.origin.y;

    [win setDelegate:self];
    [win setFrameOrigin:NSMakePoint(x,y)];
    [win makeKeyAndOrderFront:self];
    [win setHidesOnDeactivate:TRUE];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [notices count];
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    if([[tableColumn identifier] isEqual:@"notice"]) {
        return [notices objectAtIndex:row];
    }
    if([[tableColumn identifier] isEqual:@"closebox"]) {
        return [NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate];
    }
    return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView
         heightOfRow:(NSInteger)row
{
    NSTableColumn *col = [tableView tableColumns][0];
    NSCell *cell = col.dataCell;
    [cell setStringValue:[notices objectAtIndex:row]];
    float height = [cell cellSizeForBounds:NSMakeRect(0,0,col.width,1000)].height;
    NSLog(@"width %f height %f",col.width,height);
    return height;
}

- (void)addMessage:(NSString *)message level:(int)importance
{
    [alertButton setHidden:FALSE];
    [notices addObject:message];
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    [[notification object] close];
}

@end

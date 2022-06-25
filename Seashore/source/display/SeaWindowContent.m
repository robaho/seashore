#import "SeaWindowContent.h"
#import "SeaController.h"
#import "SeaSupport.h"

@implementation SeaWindowContent

-(void)awakeFromNib
{
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
             [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", rightSideBar, @"view", nil],[NSNumber numberWithInt:kOptionsPanel],
             [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", sidebar, @"view", nil], [NSNumber numberWithInt:kLayersPanel],
             [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", pointInformation, @"view", nil], [NSNumber numberWithInt:kPointInformation],
             [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", statusBar, @"view", nil], [NSNumber numberWithInt:kStatusBar],
             [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", recentsBar, @"view", nil], [NSNumber numberWithInt:kRecentsBar],
             nil];
    
    int i;
    for(i = kOptionsPanel; i <= kRecentsBar; i++){
        NSString *key = [NSString stringWithFormat:@"region%dvisibility", i];
        if([gUserDefaults objectForKey: key] && ![gUserDefaults boolForKey:key]){
            // We need to hide it
            [self setVisibility: NO forRegion: i];
        }
    }

    [contentView setNeedsLayout:YES];
    [contentView setNeedsDisplay:YES];

    if([[SeaController seaSupport] isSupportPurchased]){
        [self hideBanner];
    }
}

-(BOOL)visibilityForRegion:(int)region
{
    return [[[dict objectForKey:[NSNumber numberWithInt:region]] objectForKey:@"visibility"] boolValue];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
    if(subview == rightSideBar || subview == sidebar)
        return NO;

    return YES;
}

-(void)setVisibility:(BOOL)visibility forRegion:(int)region
{
    NSMutableDictionary *thisDict = [dict objectForKey:[NSNumber numberWithInt:region]];
    BOOL currentVisibility = [[thisDict objectForKey:@"visibility"] boolValue];

    // Check to see if we are already in the proper state
    if(currentVisibility == visibility){
        return;
    }

    NSView *view = [thisDict objectForKey:@"view"];
    NSView *parent = [view superview];

    [view setHidden:!visibility];

    [parent setNeedsLayout:TRUE];
    [parent setNeedsDisplay:TRUE];

    if([parent isKindOfClass:NSSplitView.class]){
        NSSplitView *sv = (NSSplitView*)parent;
        [sv adjustSubviews];
    }

    [gUserDefaults setBool: visibility forKey:[NSString stringWithFormat:@"region%dvisibility", region]];
    [thisDict setObject:[NSNumber numberWithBool:visibility] forKey:@"visibility"];
}

-(void)hideBanner
{
    NSLog(@"hiding banner");

    NSView *parent = [banner superview];
    if(parent==NULL)
        return;

    [banner removeFromSuperview];

    [goldStar setHidden:![[SeaController seaSupport] isSupportPurchased]];

    [parent layout];
    [parent display];
}

-(IBAction)showSupportSeashore:(id)sender
{
    [[SeaController seaSupport] showSupportSeashore:sender];
}

@end

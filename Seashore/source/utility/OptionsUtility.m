#import "OptionsUtility.h"
#import "ToolboxUtility.h"
#import "AbstractOptions.h"
#import "SeaTools.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "ZoomOptions.h"
#import "AbstractSelectOptions.h"
#import "SeaDocument.h"
#import "AbstractTool.h"
#import "SeaWindowContent.h"

@implementation OptionsUtility

- (id)init
{
    currentTool = -1;
    
    return self;
}

- (void)awakeFromNib
{
    blankView = [VerticalView view];
    Label *label = [Label smallLabel];
    [label setTitle:@"No tool selected."];
    [blankView addSubview:label];
    
    lastView = blankView;
    [view addSubview:blankView];

    [view setNeedsLayout:YES];
    [view setNeedsDisplay:YES];
}

- (void)shutdown
{
}

- (id)getOptions:(int)toolId {
    id tool = [[document tools] getTool:toolId];
    return [tool getOptions];
}

- (void)update
{
    int tool = [toolboxUtility tool];

    NSRect frame = [lastView frame];
    // If there are no current options put up a blank view
    if (tool == -1) {
        [view replaceSubview:lastView with:blankView];
        lastView = blankView;
        currentTool = -1;
    } else if (currentTool != tool) {
        currentTool = tool;
        AbstractOptions *options = [[document currentTool] getOptions];
        [view replaceSubview:lastView with:options];
        lastView = options;
    }

    NSView *parent = [view superview];

    [parent layout];
    [parent setNeedsDisplay:TRUE];
}

- (IBAction)show:(id)sender
{
    [[[document window] contentView] setVisibility:YES forRegion:kOptionsPanel];
}

- (IBAction)hide:(id)sender
{
    [[[document window] contentView] setVisibility:NO forRegion:kOptionsPanel];
}

- (IBAction)toggle:(id)sender
{
    if([self visible]){
        [self hide:sender];
    }else{
        [self show:sender];
    }
}

- (void)viewNeedsDisplay
{
    [view setNeedsDisplay:YES];
}

- (BOOL)visible
{
    return [[[document window] contentView] visibilityForRegion: kOptionsPanel];
}

@end

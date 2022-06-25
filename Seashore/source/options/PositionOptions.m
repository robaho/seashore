#import "PositionOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "AspectRatio.h"

@implementation PositionOptions

- (void)awakeFromNib
{
}

- (BOOL)maintainAspectRatio
{
    return [maintainAspectCheckbox state] == NSOnState;
}
- (BOOL)autoApply
{
    return [autoApplyMoveOnlyCheckbox state] == NSOnState;
}

- (IBAction)scaleAndRotateChanged:(id)sender {
    [[document docView] setNeedsDisplay:TRUE];
}

- (BOOL)scaleAndRotateLinked
{
    return [scaleAndRotateLinkedCheckbox state] == NSOnState;
}

- (void)shutdown
{
}

@end

#import "PositionOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "AspectRatio.h"
#import "PositionTool.h"

@implementation PositionOptions

- (id)init:(id)document
{
    self = [super init:document];
    [modifierPopup setHidden:TRUE];

    maintainAspectCheckbox = [SeaCheckbox checkboxWithTitle:@"Maintain aspect ratio" Listener:NULL];
    [self addSubview:maintainAspectCheckbox];
    scaleAndRotateLinkedCheckbox = [SeaCheckbox checkboxWithTitle:@"Scale & rotate linked layers" Listener:self];
    [self addSubview:scaleAndRotateLinkedCheckbox];
    autoApplyMoveOnlyCheckbox = [SeaCheckbox checkboxWithTitle:@"Auto apply transform" Listener:NULL];
    [self addSubview:autoApplyMoveOnlyCheckbox];
    [self addSubview:[SeaSeperator withTitle:@""]];

    PositionTool *tool = [[document tools] getTool:kPositionTool];

    [self addSubview:[SeaButton compactButton:@"Scale/Position Layer to Fit" target:tool action:@selector(scaleToFit:)]];

    [self addSubview:[SeaSeperator withTitle:@""]];

    [self addSubview:[SeaButton compactButton:@"Reset Transform" target:tool action:@selector(reset:)]];
    [self addSubview:[SeaButton compactButton:@"Apply Transform" target:tool action:@selector(apply:)]];
    [self addSubview:[SeaSeperator withTitle:@""]];
    [self addSubview:[SeaButton compactButton:@"Zoom to Fit Layer Boundary" target:tool action:@selector(zoomToFitBoundary:)]];

    return self;
}

- (BOOL)maintainAspectRatio
{
    return [maintainAspectCheckbox isChecked];
}
- (BOOL)autoApply
{
    return [autoApplyMoveOnlyCheckbox isChecked];
}

- (void)componentChanged:(id)sender {
    [[document docView] setNeedsDisplay:TRUE];
}

- (BOOL)scaleAndRotateLinked
{
    return [scaleAndRotateLinkedCheckbox isChecked];
}

- (void)shutdown
{
}

@end

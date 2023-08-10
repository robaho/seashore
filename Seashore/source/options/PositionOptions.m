#import "PositionOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "AspectRatio.h"
#import "PositionTool.h"
#import "SeaPrefs.h"

@implementation PositionOptions

- (id)init:(id)document
{
    self = [super init:document];
    [modifierPopup setHidden:TRUE];

    NSControlSize size = [[SeaController seaPrefs] controlSize];

    maintainAspectCheckbox = [SeaCheckbox checkboxWithTitle:@"Maintain aspect ratio" Listener:NULL Size:size];
    [self addSubview:maintainAspectCheckbox];
    scaleAndRotateLinkedCheckbox = [SeaCheckbox checkboxWithTitle:@"Scale & rotate linked layers" Listener:self Size:size];
    [self addSubview:scaleAndRotateLinkedCheckbox];
    [self addSubview:[SeaSeperator withTitle:@""]];

    PositionTool *tool = [[document tools] getTool:kPositionTool];

    [self addSubview:[SeaButton compactButton:@"Scale/Position Layer to Fit" target:tool action:@selector(scaleToFit:) size:size]];
    [self addSubview:[SeaButton compactButton:@"Zoom to Fit Layer Boundary" target:tool action:@selector(zoomToFitBoundary:) size:size]];

    [self addSubview:[SeaSeperator withTitle:@""]];

    [self addSubview:[SeaButton compactButton:@"Reset Transform" target:tool action:@selector(reset:) size:size]];
    [self addSubview:[SeaButton compactButton:@"Apply Transform" target:tool action:@selector(apply:) size:size]];

    return self;
}

- (BOOL)maintainAspectRatio
{
    return [maintainAspectCheckbox isChecked];
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

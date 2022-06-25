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
    view.borderMargin=16;
    [view addSubview:blankView positioned:NSWindowAbove relativeTo:horizontalLine ];
    lastView = blankView;

    [view setNeedsLayout:YES];
    [view setNeedsDisplay:YES];

    NSArray *allTools = [[document tools] allTools];
    NSEnumerator *e = [allTools objectEnumerator];
    AbstractTool *tool;
    while(tool = [e nextObject]){
        [tool setOptions: [self getOptions:[tool toolId]]];
    }
}

- (void)shutdown
{
    int i = 0;
    id options = NULL;
    
    do {
        options = [self getOptions:i];
        [options shutdown];
        i++;
    } while (options != NULL);
}

- (AbstractOptions*)currentOptions
{
    if (document == NULL)
        return NULL;
    else
        return [self getOptions:[toolboxUtility tool]];
}

- (AbstractOptions*)getOptions:(int)whichTool
{
    switch (whichTool) {
        case kRectSelectTool:
            return rectSelectOptions;
        break;
        case kEllipseSelectTool:
            return ellipseSelectOptions;
        break;
        case kLassoTool:
            return lassoOptions;
        break;
        case kPolygonLassoTool:
            return polygonLassoOptions;
        break;
        case kPositionTool:
            return positionOptions;
        break;
        case kZoomTool:
            return zoomOptions;
        break;
        case kPencilTool:
            return pencilOptions;
        break;
        case kBrushTool:
            return brushOptions;
        break;
        case kBucketTool:
            return bucketOptions;
        break;
        case kTextTool:
            return textOptions;
        break;
        case kEyedropTool:
            return eyedropOptions;
        break;
        case kEraserTool:
            return eraserOptions;
        break;
        case kSmudgeTool:
            return smudgeOptions;
        break;
        case kGradientTool:
            return gradientOptions;
        break;
        case kWandTool:
            return wandOptions;
        break;
        case kCloneTool:
            return cloneOptions;
        break;
        case kCropTool:
            return cropOptions;
        break;
        case kEffectTool:
            return effectOptions;
        break;
    }
    
    return NULL;
}

- (void)update
{
    AbstractOptions *currentOptions = [self currentOptions];

    NSRect frame = [lastView frame];
    // If there are no current options put up a blank view
    if (currentOptions == NULL) {
        [view replaceSubview:lastView with:blankView];
        lastView = blankView;
        currentTool = -1;
    } else if (currentTool != [toolboxUtility tool]) {
        [view replaceSubview:lastView with:[currentOptions view]];
        lastView = [currentOptions view];
        currentTool = [toolboxUtility tool];
    }

    NSView *parent = [view superview];

    [view setNeedsLayout:TRUE];
    [view setNeedsDisplay:TRUE];
    [parent setNeedsLayout:TRUE];
    [parent setNeedsDisplay:TRUE];
    [lastView setFrame:frame];
    [lastView setNeedsLayout:TRUE];
    [lastView setNeedsDisplay:TRUE];

    if(currentOptions) {
        [currentOptions activate:document];
        [currentOptions update:self];
    }
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
    [view setNeedsDisplay: YES];
}

- (BOOL)visible
{
    return [[[document window] contentView] visibilityForRegion: kOptionsPanel];
}

@end

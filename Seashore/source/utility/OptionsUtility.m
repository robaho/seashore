#import "OptionsUtility.h"
#import "ToolboxUtility.h"
#import "AbstractOptions.h"
#import "SeaTools.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "ZoomOptions.h"
#import "AbstractSelectOptions.h"
#import "UtilitiesManager.h"
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
	[view addSubview:blankView];
	lastView = blankView;
	
	NSArray *allTools = [[document tools] allTools];
	NSEnumerator *e = [allTools objectEnumerator];
	AbstractTool *tool;
	while(tool = [e nextObject]){
		[tool setOptions: [self getOptions:[tool toolId]]];
	}
	
	[[SeaController utilitiesManager] setOptionsUtility: self for:document];
}

- (void)dealloc
{
	[super dealloc];
}

- (void)activate
{
	[self update];
}

- (void)deactivate
{
	[self update];
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

- (id)currentOptions
{
	if (document == NULL)
		return NULL;
	else
		return [self getOptions:[toolboxUtility tool]];
}

- (id)getOptions:(int)whichTool
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
	id currentOptions = [self currentOptions];
	
	// If there are no current options put up a blank view
	if (currentOptions == NULL) {
		[view replaceSubview:lastView with:blankView];
		lastView = blankView;
		currentTool = -1;
		return;
	}
	
	// Otherwise select the current options are up-to-date with the current tool
	if (currentTool != [toolboxUtility tool]) {
		[view replaceSubview:lastView with:[(AbstractOptions *)currentOptions view]];
		lastView = [(AbstractOptions *)currentOptions view];
		currentTool = [toolboxUtility tool];
	}
	
	// Update the options
	[(AbstractOptions *)currentOptions activate:document];
	[currentOptions update];
}

- (IBAction)show:(id)sender
{
	[[[document window] contentView] setVisibility:YES forRegion:kOptionsBar];
}

- (IBAction)hide:(id)sender
{
	[[[document window] contentView] setVisibility:NO forRegion:kOptionsBar];
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
	return [[[document window] contentView] visibilityForRegion: kOptionsBar];
}

@end

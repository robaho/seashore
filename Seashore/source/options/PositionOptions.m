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
	if ([gUserDefaults objectForKey:@"position anchor"] == NULL) {
		[canAnchorCheckbox setState:NSOffState];
	}
	else {
		[canAnchorCheckbox setState:[gUserDefaults boolForKey:@"position anchor"]];
	}
	function = kMovingLayer;
}

- (BOOL)canAnchor
{
	return [canAnchorCheckbox state];
}

- (int)toolFunction
{
	return function;
}
- (void)setFunctionFromIndex:(unsigned int)index
{
	switch (index) {
		case kShiftModifier:
			function = kScalingLayer;
			break;
		case kControlModifier:
			function = kRotatingLayer;
			break;
		default:
			function = kMovingLayer;
			break;
	}
	// Let's not check for floating, maybe we can do it all
	/*if(function == kRotatingLayer){
		if(![[document selection] floating])
			function = kMovingLayer;
	}else if(function == kScalingLayer){
		if([[document selection] floating])
			function = kMovingLayer;
	}*/
}

- (void)updateModifiers:(unsigned int)modifiers
{
	[super updateModifiers:modifiers];
	int modifier = [super modifier];
	[self setFunctionFromIndex: modifier];
}

- (IBAction)modifierPopupChanged:(id)sender
{
	[self setFunctionFromIndex: [[sender selectedItem] tag]];	
	
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	for (i = 0; i < [documents count]; i++) {
		[[(SeaDocument *)[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (void)shutdown
{
	[gUserDefaults setObject:[canAnchorCheckbox state] ? @"YES" : @"NO" forKey:@"position anchor"];
}

@end

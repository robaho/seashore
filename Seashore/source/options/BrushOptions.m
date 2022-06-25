#import "BrushOptions.h"
#import "ToolboxUtility.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaController.h"
#import "SeaDocument.h"

enum {
	kQuadratic,
	kLinear,
	kSquareRoot
};

@implementation BrushOptions

- (void)awakeFromNib
{
	int rate, style;
	BOOL fadeOn, pressureOn;
	
	if ([gUserDefaults objectForKey:@"brush fade"] == NULL) {
		[fadeCheckbox setState:NSOffState];
		[fadeCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"fade-out", @"Fade-out: %d"), 10]];
		[fadeSlider setIntValue:10];
		[fadeSlider setEnabled:NO];
	}
	else {
		rate = [gUserDefaults integerForKey:@"brush fade rate"];
		if (rate < 1 || rate > 120)
			rate = 10;
		fadeOn = [gUserDefaults boolForKey:@"brush fade"];
		[fadeCheckbox setState:fadeOn];
		[fadeCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"fade-out", @"Fade-out: %d"), rate]];
		[fadeSlider setIntValue:rate];
		[fadeSlider setEnabled:fadeOn];
	}
	
	if ([gUserDefaults objectForKey:@"brush pressure"] == NULL) {
		[pressureCheckbox setState:NSOffState];
		[pressurePopup selectItemAtIndex:kLinear];
		[pressurePopup setEnabled:NO];
	}
	else {
		style = [gUserDefaults integerForKey:@"brush pressure style"];
		if (style < kQuadratic || style > kSquareRoot)
			style = kLinear;
		pressureOn = [gUserDefaults boolForKey:@"brush pressure"];
		[pressureCheckbox setState:pressureOn];
		[pressurePopup selectItemAtIndex:style];
		[pressurePopup setEnabled:pressureOn];
	}
	
	if ([gUserDefaults objectForKey:@"brush scale"] == NULL) {
		[scaleCheckbox setState:NSOnState];
	}
	else {
		[scaleCheckbox setState:[gUserDefaults boolForKey:@"brush scale"]];
	}
	
	isErasing = NO;
}

- (IBAction)update:(id)sender
{
	[fadeSlider setEnabled:[fadeCheckbox state]];
	[fadeCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"fade-out", @"Fade-out: %d"), [fadeSlider intValue]]];
	[pressurePopup setEnabled:[pressureCheckbox state]];
}

- (BOOL)fade
{
	return [fadeCheckbox state];
}

- (int)fadeValue
{
	return [fadeSlider intValue];
}

- (int)pressureValue:(NSEvent *)event
{
	double p;
	
	if ([pressureCheckbox state] == NSOffState)
		return 255;
	
	if (event == NULL)
		return 255;
			
	p = [event pressure];

	switch ([pressurePopup indexOfSelectedItem]) {
		case kLinear:
			return (int)(p * 255.0);
		break;
		case kQuadratic:
			return (int)((p * p) * 255.0);
		break;
		case kSquareRoot:
			return (int)(sqrt(p) * 255.0);
		break;
	}

	return 255;
}

- (BOOL)scale
{
	return [scaleCheckbox state];
}

- (BOOL)brushIsErasing
{
	return isErasing;
}

- (int)opacity
{
    return 255; // only color opacity is used
}

- (void)updateModifiers:(unsigned int)modifiers
{
	[super updateModifiers:modifiers];
	int modifier = [super modifier];
	
	switch (modifier) {
		case kAltModifier:
			isErasing = YES;
			break;
		default:
			isErasing = NO;
			break;
	}
}

- (IBAction)modifierPopupChanged:(id)sender
{
	switch ([[sender selectedItem] tag]) {
		case kAltModifier:
			isErasing = YES;
			break;
		default:
			isErasing = NO;
			break;
	}
    
}

- (void)shutdown
{
	[gUserDefaults setObject:[fadeCheckbox state] ? @"YES" : @"NO" forKey:@"brush fade"];
	[gUserDefaults setInteger:[fadeSlider intValue] forKey:@"brush fade rate"];
	[gUserDefaults setObject:[pressureCheckbox state] ? @"YES" : @"NO" forKey:@"brush pressure"];
	[gUserDefaults setInteger:[pressurePopup indexOfSelectedItem] forKey:@"brush pressure style"];
	[gUserDefaults setInteger:[scaleCheckbox state] forKey:@"brush scale"];
}

@end

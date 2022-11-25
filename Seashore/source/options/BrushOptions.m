#import "BrushOptions.h"
#import "ToolboxUtility.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaController.h"
#import "SeaDocument.h"

@implementation BrushOptions

- (id)init:(id)document
{
    self = [super init:document];

    [super clearModifierMenu];
    [super addModifierMenuItem:@"Erase (Option)" tag:1];
    [super addModifierMenuItem:@"Draw straight lines (Shift)" tag:2];
    [super addModifierMenuItem:@"Draw striaght lines at 45° (Shift + Control)" tag:4];
    [self addSubview:modifierPopup positioned:NSWindowBelow relativeTo:opacitySlider];

    fadeSlider = [SeaSlider sliderWithCheck:@"Fade-out" Min:1 Max:120 Listener:NULL];
    [self addSubview:fadeSlider];

    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"Lighter" action:NULL keyEquivalent:@""];
    [menu addItemWithTitle:@"Normal" action:NULL keyEquivalent:@""];
    [menu addItemWithTitle:@"Darker" action:NULL keyEquivalent:@""];

    pressurePopup = [SeaPopup popupWithCheck:@"Pressure sensitive" Menu:menu Listener:NULL];
    [self addSubview:pressurePopup];

	if ([gUserDefaults objectForKey:@"brush fade"] == NULL) {
        [fadeSlider setIntValue:10];
	}
	else {
        [fadeSlider setIntValue:[gUserDefaults integerForKey:@"brush fade rate"]];
        [fadeSlider setChecked:[gUserDefaults boolForKey:@"brush fade"]];
	}
	
	if ([gUserDefaults objectForKey:@"brush pressure"] == NULL) {
		[pressurePopup selectItemAtIndex:kLinear];
	}
	else {
		int style = [gUserDefaults integerForKey:@"brush pressure style"];
		if (style < kQuadratic || style > kSquareRoot)
			style = kLinear;
        [pressurePopup selectItemAtIndex:style];
        [pressurePopup setChecked:[gUserDefaults boolForKey:@"brush pressure"]];
	}

    scalingCheckbox = [SeaCheckbox checkboxWithTitle:@"Brush scaling" Listener:NULL];

    [self addSubview:scalingCheckbox];
	
	if ([gUserDefaults objectForKey:@"brush scale"] == NULL) {
		[scalingCheckbox setChecked:true];
	}
	else {
		[scalingCheckbox setChecked:[gUserDefaults boolForKey:@"brush scale"]];
	}

    [super loadOpacity:@"brush opacity"];

	isErasing = NO;

    return self;
}

- (BOOL)fade
{
	return [fadeSlider isChecked];
}

- (int)fadeValue
{
	return [fadeSlider intValue];
}

- (int)pressureValue:(NSEvent *)event
{
	double p;
	
	if (![pressurePopup isChecked])
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
	return [scalingCheckbox isChecked];
}

- (BOOL)brushIsErasing
{
	return isErasing;
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

- (void)shutdown
{
	[gUserDefaults setObject:[fadeSlider isChecked] ? @"YES" : @"NO" forKey:@"brush fade"];
	[gUserDefaults setInteger:[fadeSlider intValue] forKey:@"brush fade rate"];
	[gUserDefaults setObject:[pressurePopup isChecked] ? @"YES" : @"NO" forKey:@"brush pressure"];
	[gUserDefaults setInteger:[pressurePopup indexOfSelectedItem] forKey:@"brush pressure style"];
	[gUserDefaults setInteger:[scalingCheckbox isChecked] forKey:@"brush scale"];
    [gUserDefaults setInteger:[opacitySlider integerValue] forKey:@"brush opacity"];
}

@end

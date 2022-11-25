#import "SmudgeOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation SmudgeOptions

- (id)init:(id)document
{
    self = [super init:document];

    [modifierPopup setHidden:TRUE];

    [texturesButton setHidden:true];
    [fadeSlider setHidden:true];
    [scalingCheckbox setHidden:true];
    [opacitySlider setHidden:true];

    [modifierPopup setHidden:TRUE];

    rateSlider = [SeaSlider compactSliderWithTitle:@"Rate" Min:0 Max:100 Listener:NULL];
    [self addSubview:rateSlider];

    int value;
	if ([gUserDefaults objectForKey:@"smudge rate"] == NULL) {
		value = 50;
	}
	else {
		value = [gUserDefaults integerForKey:@"smudge rate"];
	}
	[rateSlider setIntValue:value];

    if ([gUserDefaults objectForKey:@"brush pressure"] == NULL) {
        [pressurePopup selectItemAtIndex:kLinear];
    }
    else {
        int style = [gUserDefaults integerForKey:@"smudge pressure style"];
        if (style < kQuadratic || style > kSquareRoot)
            style = kLinear;
        BOOL pressureOn = [gUserDefaults boolForKey:@"smudge pressure"];
        [pressurePopup selectItemAtIndex:style];
        [pressurePopup setChecked:pressureOn];
    }

    return self;
}

- (int)rate
{
	return [rateSlider intValue] * 2.55;
}

- (void)shutdown
{
	[gUserDefaults setInteger:[rateSlider intValue] forKey:@"smudge rate"];
    [gUserDefaults setObject:[pressurePopup isChecked] ? @"YES" : @"NO" forKey:@"smudge pressure"];
    [gUserDefaults setInteger:[pressurePopup indexOfSelectedItem] forKey:@"smudge pressure style"];
}

@end

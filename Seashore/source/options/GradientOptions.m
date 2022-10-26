#import "GradientOptions.h"
#import "SeaController.h"
#import "SeaTools.h"
#import "SeaHelp.h"
#import <GIMPCore/GIMPCore.h>

@implementation GradientOptions

- (void)awakeFromNib
{
	int index;
	
	if ([gUserDefaults objectForKey:@"gradient type"] == NULL) {
		[typePopup selectItemAtIndex:GIMP_GRADIENT_LINEAR];
	}
	else {
		index = [typePopup indexOfItemWithTag:[gUserDefaults integerForKey:@"gradient type"]];
		if (index != -1)
			[typePopup selectItemAtIndex:index];
		else
			[typePopup selectItemAtIndex:0];
	}
	
	if ([gUserDefaults objectForKey:@"gradient repeat"] == NULL) {
		[repeatPopup selectItemAtIndex:GIMP_REPEAT_NONE];
	}
	else {
		index = [repeatPopup indexOfItemWithTag:[gUserDefaults integerForKey:@"gradient repeat"]];
		if (index != -1)
			[repeatPopup selectItemAtIndex:index];
		else
			[repeatPopup selectItemAtIndex:0];
	}
    if ([gUserDefaults objectForKey:@"gradient start opacity"] == NULL) {
        [startOpacitySlider setIntValue:100];
    }
    else {
        [startOpacitySlider setIntValue:[gUserDefaults integerForKey:@"gradient start opacity"]];
    }
    if ([gUserDefaults objectForKey:@"gradient end opacity"] == NULL) {
        [endOpacitySlider setIntValue:100];
    }
    else {
        [endOpacitySlider setIntValue:[gUserDefaults integerForKey:@"gradient end opacity"]];
    }

}

- (int)type
{
	return [[typePopup selectedItem] tag];
}

- (int)repeat
{
	return [[repeatPopup selectedItem] tag];
}

- (BOOL)supersample
{
	return NO;
}

- (int)maximumDepth
{
	return 3;
}

- (double)threshold
{
	return 0.2;
}

- (void)shutdown
{
	[gUserDefaults setInteger:[[typePopup selectedItem] tag] forKey:@"gradient type"];
	[gUserDefaults setInteger:[[repeatPopup selectedItem] tag] forKey:@"gradient repeat"];
    [gUserDefaults setInteger:[startOpacitySlider intValue] forKey:@"gradient start opacity"];
    [gUserDefaults setInteger:[endOpacitySlider intValue] forKey:@"gradient end opacity"];
}

- (IBAction)update:(id)sender {
    [startOpacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"start opacity", @"Start Opacity: %d%%"), [startOpacitySlider intValue]]];
    [endOpacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"end opacity", @"End Opacity: %d%%"), [endOpacitySlider intValue]]];
    [super update:sender];
}

- (float)startOpacity
{
    return [startOpacitySlider intValue]/100.0;
}
- (float)endOpacity
{
    return [endOpacitySlider intValue]/100.0;
}

@end

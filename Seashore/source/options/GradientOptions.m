#import "GradientOptions.h"
#import "SeaController.h"
#import "SeaTools.h"
#import "SeaHelp.h"
#import <GIMPCore/GIMPCore.h>

@implementation GradientOptions

- (id)init:(id)document
{
    self = [super init:document];

    [super clearModifierMenu];
    [super addModifierMenuItem:@"Lock gradients to 45°" tag:3];

    NSMenu *menu = [[NSMenu alloc]init];
    [menu addItem:[super itemWithTitle:@"Linear" tag:GIMP_GRADIENT_LINEAR]];
    [menu addItem:[super itemWithTitle:@"Bi-Linear" tag:GIMP_GRADIENT_BILINEAR]];
    [menu addItem:[super itemWithTitle:@"Radial" tag:GIMP_GRADIENT_RADIAL]];
    [menu addItem:[super itemWithTitle:@"Square" tag:GIMP_GRADIENT_SQUARE]];
    [menu addItem:[super itemWithTitle:@"Conical (symmetric)" tag:GIMP_GRADIENT_CONICAL_SYMMETRIC]];
    [menu addItem:[super itemWithTitle:@"Conical (asymmetric)" tag:GIMP_GRADIENT_CONICAL_ASYMMETRIC]];
    [menu addItem:[super itemWithTitle:@"Spiral (clockwise)" tag:GIMP_GRADIENT_SPIRAL_CLOCKWISE]];
    [menu addItem:[super itemWithTitle:@"Spiral (anti-clockwise)" tag:GIMP_GRADIENT_SPIRAL_ANTICLOCKWISE]];

    typePopup = [SeaPopup compactWithTitle:@"Gradient style" Menu:menu Listener:NULL];
    [self addSubview:typePopup];

    menu = [[NSMenu alloc]init];
    [menu addItem:[super itemWithTitle:@"None" tag:GIMP_REPEAT_NONE]];
    [menu addItem:[super itemWithTitle:@"Sawtooth wave" tag:GIMP_REPEAT_SAWTOOTH]];
    [menu addItem:[super itemWithTitle:@"Triangular wave" tag:GIMP_REPEAT_TRIANGULAR]];

    repeatPopup = [SeaPopup compactWithTitle:@"Repeating pattern" Menu:menu Listener:NULL];
    [self addSubview:repeatPopup];

    startOpacitySlider = [SeaSlider compactSliderWithTitle:@"Start opacity" Min:0 Max:100 Listener:NULL];
    [self addSubview:startOpacitySlider];
    endOpacitySlider = [SeaSlider compactSliderWithTitle:@"End opacity" Min:0 Max:100 Listener:NULL];
    [self addSubview:endOpacitySlider];

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
    return self;
}

- (int)type
{
	return [[typePopup selectedItem] tag];
}

- (int)repeat
{
	return [repeatPopup indexOfSelectedItem];
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

- (float)startOpacity
{
    return [startOpacitySlider intValue]/100.0;
}
- (float)endOpacity
{
    return [endOpacitySlider intValue]/100.0;
}

@end

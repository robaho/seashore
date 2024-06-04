#import "EraserOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaPrefs.h"
#import "SeaLayer.h"
#import "SeaDocument.h"

@implementation EraserOptions

- (id)init:(id)document
{
    self = [super init:document];

    [super clearModifierMenu];
    [super addModifierMenuItem:@"Erase with Background Color (Option)" tag:1];
    [super addModifierMenuItem:@"Draw straight lines (Shift)" tag:2];
    [super addModifierMenuItem:@"Draw striaght lines at 45° (Shift + Control)" tag:4];

    NSControlSize size = [[SeaController seaPrefs] controlSize];

    [texturesButton setHidden:true];
    [fadeSlider setHidden:true];
    [pressurePopup setHidden:true];
    [scalingCheckbox setHidden:true];

	int value;

    mimicBrushCheckbox = [SeaCheckbox checkboxWithTitle:@"Mimic Brush Fading" Listener:NULL Size:size];
    [self addSubview:mimicBrushCheckbox];
	
	if ([gUserDefaults objectForKey:@"eraser opacity"] == NULL) {
		value = 100;
	}
	else {
		value = [gUserDefaults integerForKey:@"eraser opacity"];
	}
	[opacitySlider setIntValue:value];
	[mimicBrushCheckbox setChecked:[gUserDefaults boolForKey:@"eraser mimicBrush"]];

    erasingNote = [Label labelWithSize:size];
    [erasingNote makeNote];
    [erasingNote setTitle:@"Layer has alpha disabled. Eraser uses background color."];

    [self addSubview:erasingNote];

    return self;
}

- (BOOL)brushIsErasing
{
    return TRUE;
}

- (BOOL)isEraseWithBackground
{
    // brushIsErasing means alternate mouse button (option) is being used
    return [super brushIsErasing];
}

- (BOOL)mimicBrush
{
	return [mimicBrushCheckbox isChecked];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[opacitySlider intValue] forKey:@"eraser opacity"];
	[gUserDefaults setObject:[mimicBrushCheckbox isChecked] ? @"YES" : @"NO" forKey:@"eraser mimicBrush"];
}

- (void)update:(id) sender
{
    SeaLayer *layer = [[document contents] activeLayer];
    erasingNote.hidden = [layer hasAlpha];
}

@end

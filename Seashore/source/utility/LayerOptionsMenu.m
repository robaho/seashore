#import "Seashore.h"
#import "LayerOptionsMenu.h"

@implementation LayerOptionsMenu


typedef struct {
    NSString *title;
    int tag;
} BlendMenuItem;

static BlendMenuItem items[] = { // see map in XcfExporter
    {@"Normal", kCGBlendModeNormal},
    {NULL,-1}, // seperator
    {@"Darken", kCGBlendModeDarken}, // Darken Only
    {@"Multiply", kCGBlendModeMultiply }, // Multiply
    {@"Color Burn", kCGBlendModeColorBurn}, // Burn
    {NULL,-1},
    {@"Lighten", kCGBlendModeLighten}, // Lighten Only
    {@"Screen", kCGBlendModeScreen}, // Screen
    {@"Color Dodge", kCGBlendModeColorDodge}, // Dodge
    {@"Plus Lighter", kCGBlendModePlusLighter}, // Addition
//    {@"Plus Darker", kCGBlendModePlusDarker}, // ????
    {NULL,-1},
    {@"Overlay", kCGBlendModeOverlay}, // Overlay
    {@"Soft Light", kCGBlendModeSoftLight}, // Soft Light
    {@"Hard Light", kCGBlendModeHardLight}, // Hard Light
    {NULL,-1},
    {@"Difference", kCGBlendModeDifference}, // Difference
    {@"Exclusion", kCGBlendModeExclusion}, // Exclusion
    {NULL,-1},
    {@"Hue", kCGBlendModeHue}, // LCH Hue
    {@"Saturation", kCGBlendModeSaturation}, // LCH Chroma
    {@"Color", kCGBlendModeColor}, // HSL Color
    {@"Luminosity", kCGBlendModeLuminosity}, // LCH Lightness
};

-(void)awakeFromNib
{
    for(int i=0;i<(sizeof(items)/sizeof(items[0]));i++) {
        NSString *s = items[i].title;
        if(!s) {
            [self addItem:[NSMenuItem separatorItem]];
        } else {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:s action:NULL keyEquivalent:@""];
            [item setTag:items[i].tag];
            [self addItem:item];
        }
    }
}

@end

#import "SeaSlider.h"

@implementation SeaSlider

// Use a fixed value width to ensure alignment.
#define VALUE_WIDTH 50

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    slider = [[NSSlider alloc] init];
    title = [[Label alloc] init];
    value = [[Label alloc] init];

    [slider setMinValue:0];
    [slider setMaxValue:100];
    [slider setContinuous:TRUE];
    [slider setAltIncrementValue:0.01];

    [slider setTarget:self];
    [slider setAction:@selector(sliderChanged:)];

    [self addSubview:slider];
    [self addSubview:title];
    [self addSubview:value];

    return self;
}

- (void)layout
{
    NSRect bounds = self.bounds;
    if(compact) {
        int w = bounds.size.width - VALUE_WIDTH;
        int h = bounds.size.height;
        [title  setFrame:NSMakeRect(0,0,w*.50,h)];
        [slider setFrame:NSMakeRect(w*.50,0,w*.50,h)];
        [value setFrame:NSMakeRect(w,0,VALUE_WIDTH,h)];
    } else {
        float half = bounds.size.height / 2;
        [slider setFrame:NSMakeRect(0,0,bounds.size.width-VALUE_WIDTH,half)];
        [value  setFrame:NSMakeRect(bounds.size.width-VALUE_WIDTH,0,50,half)];
        [title  setFrame:NSMakeRect(0,half,bounds.size.width,half)];
    }
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(100,compact ? 20:40);
}

- (void)setIntValue:(int)value
{
    if(value<[slider minValue] || value > [slider maxValue])
        value = ([slider minValue]+[slider maxValue])/2;
    format = 0;
    [slider setIntValue:value];
    [self updateValue];
}
- (int)intValue
{
    return [slider intValue];
}
- (void)setFloatValue:(float)value
{
    if(value<[slider minValue] || value > [slider maxValue])
        value = ([slider minValue]+[slider maxValue])/2;
    if([slider maxValue]==1) {
        format = 1;
        [slider setFloatValue:value];
    } else {
        [slider setFloatValue:value];
        format = 2;
    }

    [self updateValue];
}
- (float)floatValue
{
    return [slider floatValue];
}

- (void)updateValue
{
    switch(format){
        case 0:
            [value setStringValue:[NSString stringWithFormat:@"%d", [slider intValue]]];
            break;
        case 1:
            [value setStringValue:[NSString stringWithFormat:@"%.0f%%", [slider floatValue]*100]];
            break;
        case 2:
            [value setStringValue:[NSString stringWithFormat:@"%.2f", [slider floatValue]]];
            break;
        default:
            [value setStringValue:[slider stringValue]];
    }
}

- (void)sliderChanged:(id)sender
{
    [self updateValue];
    [listener componentChanged:self];
}

+ (SeaSlider*)sliderWithTitle:(NSString*)title Min:(double)min Max:(double) max Listener:(id<Listener>)listener
{
    SeaSlider *slider = [[SeaSlider  alloc] init];
    [slider->title setStringValue:title];
    [slider->slider setMinValue:min];
    [slider->slider setMaxValue:max];
    slider->listener = listener;
    return slider;
}

+ (SeaSlider*)compactSliderWithTitle:(NSString*)title Min:(double)min Max:(double) max Listener:(id<Listener>)listener
{
    SeaSlider *slider = [[SeaSlider  alloc] init];
    slider->compact = TRUE;
    [slider->title setStringValue:title];
    [slider->title setControlSize:NSMiniControlSize];
    [slider->title setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
    [slider->slider setMinValue:min];
    [slider->slider setMaxValue:max];
    slider->listener = listener;
    return slider;
}



@end

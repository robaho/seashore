#import "SeaSlider.h"
#import "SeaSizes.h"

@implementation SeaSlider

// Use a fixed value width to ensure alignment.
#define VALUE_WIDTH 50

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    slider = [[NSSlider alloc] init];
    title = [[Label alloc] init];
    value = [[Label alloc] init];

    checkbox = [[NSButton alloc] init];
    [checkbox setButtonType:NSButtonTypeSwitch];
    [checkbox setHidden:TRUE];
    [checkbox setTarget:self];
    [checkbox setAction:@selector(checkboxChanged:)];

    [slider setMinValue:0];
    [slider setMaxValue:100];
    [slider setContinuous:TRUE];
    [slider setAltIncrementValue:0.01];
    [slider setCtrlSize:NSControlSizeSmall];

    [slider setTarget:self];
    [slider setAction:@selector(sliderChanged:)];

    [value setTitle:@"1000%"];
    value_width = [value intrinsicContentSize].width;

    [self addSubview:slider];
    [self addSubview:title];
    [self addSubview:value];
    [self addSubview:checkbox];

    return self;
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self layout];
}

- (void)layout
{
    NSRect bounds = self.bounds;

    if(compact) {
        int w = bounds.size.width;
        int h = bounds.size.height;

        int half = w/2;

        [title  setFrame:NSMakeRect(0,0,half,h)];
        if(half<value_width) {
            [slider setFrame:NSMakeRect(half,0,0,h)];
            [value setFrame:NSMakeRect(half,0,half,h)];
        } else {
            [slider setFrame:NSMakeRect(half,0,half-value_width,h)];
            [value setFrame:NSMakeRect(w-value_width,0,value_width,h)];
        }

        if(checkable) {
            [checkbox setFrame:NSMakeRect(0,0,half,h)];
        } else {
            [title setFrame:NSMakeRect(0,0,half,h)];
        }
    } else {
        int w = bounds.size.width;
        int h = bounds.size.height;
        float half = bounds.size.height / 2;
        [title  setFrame:NSMakeRect(0,half,bounds.size.width,half)];
        if(w<value_width) {
            [slider setFrame:NSMakeRect(0,0,0,half)];
            [value  setFrame:NSMakeRect(0,0,w,half)];
        } else {
            [slider setFrame:NSMakeRect(0,0,w-value_width,half)];
            [value  setFrame:NSMakeRect(w-value_width,0,value_width,half)];
        }
    }
}

- (bool)isChecked {
    return [checkbox state] == NSControlStateValueOn;
}

- (void)setChecked:(bool)state {
    if(state) {
        [checkbox setState:NSControlStateValueOn];
        [slider setEnabled:TRUE];
    } else {
        [checkbox setState:NSControlStateValueOff];
        [slider setEnabled:FALSE];
    }
    [self setNeedsDisplay:TRUE];
}

- (NSSize)intrinsicContentSize
{
    float sh = [SeaSizes heightOf:slider];

    if(checkable) {
        return NSMakeSize(100,MAX([SeaSizes heightOf:checkbox],sh));
    } else {
        if(compact)
            return NSMakeSize(100,MAX(title.intrinsicContentSize.height,sh));
        else
            return NSMakeSize(100,title.intrinsicContentSize.height+sh);
    }
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
- (void)setMaxValue:(double)value
{
    [slider setMaxValue:value];
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
    if(listener) [listener componentChanged:self];
}

- (void)checkboxChanged:(id)sender
{
    [slider setEnabled:[self isChecked]];
    [self updateValue];
    if(listener) [listener componentChanged:self];
}

+ (SeaSlider*)sliderWithTitle:(NSString*)title Min:(double)min Max:(double) max Listener:(nullable id<Listener>)listener
{
    SeaSlider *slider = [[SeaSlider  alloc] init];
    [slider->title setTitle:title];
    [slider->slider setMinValue:min];
    [slider->slider setMaxValue:max];
    slider->listener = listener;
    return slider;
}

+ (SeaSlider*)sliderWithCheck:(NSString*)title Min:(double)min Max:(double) max Listener:(nullable id<Listener>)listener
{
    SeaSlider *slider = [SeaSlider compactSliderWithTitle:title Min:min Max:max Listener:listener];
    [slider->checkbox setCtrlSize:NSControlSizeMini];
    [slider->checkbox setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]]];
    [slider->checkbox setTitle:title];
    slider->checkable=true;
    [slider->checkbox setHidden:FALSE];
    [slider->title setHidden:TRUE];

    return slider;
}

+ (SeaSlider*)compactSliderWithTitle:(NSString*)title Min:(double)min Max:(double) max Listener:(nullable id<Listener>)listener
{
    SeaSlider *slider = [[SeaSlider alloc] init];
    slider->compact = TRUE;
    [slider->title setTitle:title];
    [slider->title setCtrlSize:NSMiniControlSize];
    [slider->title setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
    [slider->value setCtrlSize:NSMiniControlSize];
    [slider->value setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
    [slider->slider setCtrlSize:NSMiniControlSize];
    [slider->slider setMinValue:min];
    [slider->slider setMaxValue:max];
    slider->listener = listener;
    return slider;
}

@end

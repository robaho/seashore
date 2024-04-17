#import "SeaSlider.h"
#import "SeaSizes.h"

@implementation SeaSlider

// Use a fixed value width to ensure alignment.
#define VALUE_WIDTH 50

#define WPM_SLIDER_MIN 0.0
#define WPM_SLIDER_MAX 1.0
#define WPM_SCALE_MIN 1
#define WPM_SCALE_MAX 101


- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    slider = [[NSSlider alloc] init];
    title = [[Label alloc] init];
    value = [[Label alloc] init];

    max_value = 1.0;
    min_value = 0.0;

    checkbox = [[NSButton alloc] init];
    [checkbox setButtonType:NSButtonTypeSwitch];
    [checkbox setHidden:TRUE];
    [checkbox setTarget:self];
    [checkbox setAction:@selector(checkboxChanged:)];

    [slider setContinuous:TRUE];
    [slider setMinValue:WPM_SLIDER_MIN];
    [slider setMaxValue:WPM_SLIDER_MAX];
    [slider setCtrlSize:NSControlSizeSmall];

    [slider setTarget:self];
    [slider setAction:@selector(sliderChanged:)];

    stepper = [[NSStepper alloc] init];
    stepper.maxValue = 1;
    stepper.minValue = -1;

    [value setTitle:@"1000%%"];
    value_width = [value intrinsicContentSize].width;

    [self addSubview:slider];
    [self addSubview:title];
    [self addSubview:value];
    [self addSubview:checkbox];
    [self addSubview:stepper];

    stepper.hidden = true;
    [stepper setTarget:self];
    [stepper setAction:@selector(stepperAction:)];

    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect)
                                                  owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];

    return self;
}

- (void)stepperAction:(NSStepper*)sender
{
    double adjustment = (max_value <= 1 || min_value < 0) ? 0.01 : 1;
    double position = [slider floatValue];
    double value = [self valueForSliderPosition:position];

    if (sender.intValue > 0){
        //positive side was pressed
        [slider setDoubleValue:[self sliderPositionForValue:(value+adjustment)]];
    } else if(sender.intValue < 0){
        //negative side was pressed
        [slider setDoubleValue:[self sliderPositionForValue:(value-adjustment)]];
    }
    sender.intValue = 0;
    [self sliderChanged:self];
}

- (void)mouseEntered:(NSEvent *)event {
    stepper.hidden = false;
}
- (void)mouseExited:(NSEvent *)event {
    stepper.hidden = true;
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

        [title setFrame:NSMakeRect(0,0,half,h)];
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
        [stepper setFrame:NSMakeRect(w-16,0,16,h)];
    } else {
        int w = bounds.size.width;
        int h = bounds.size.height;
        float half = bounds.size.height / 2;
        [title setFrame:NSMakeRect(0,half,bounds.size.width,half)];
        if(w<value_width) {
            [slider setFrame:NSMakeRect(0,0,0,half)];
            [value  setFrame:NSMakeRect(0,0,w,half)];
        } else {
            [slider setFrame:NSMakeRect(0,0,w-value_width,half)];
            [value  setFrame:NSMakeRect(w-value_width,0,value_width,half)];
        }
        [stepper setFrame:NSMakeRect(w-16,0,16,half)];
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

-(double) valueForSliderPosition: (double) position {
    if(min_value<0) { // linear scaling
        return [slider doubleValue] * (max_value-min_value) + min_value;
    }

    // Input will be between min and max
    static double min = WPM_SLIDER_MIN;
    static double max = WPM_SLIDER_MAX;

    // Output will be between minv and maxv
    double minv = log(WPM_SCALE_MIN);
    double maxv = log(WPM_SCALE_MAX);


    // Adjustment factor
    double scale = (maxv - minv) / (max - min);

    double wpm = exp(minv + (scale * (position - min)));
    double percent = (wpm-1)/100.0;
    return (max_value-min_value)*percent + min_value;
}

-(double) sliderPositionForValue: (double) value {

    if(min_value<0) { // linear scaling
        return (value-min_value)/(max_value-min_value);
    }

    // Output will be between min and max
    static double min = WPM_SLIDER_MIN;
    static double max = WPM_SLIDER_MAX;

    // Input will be between minv and maxv
    double minv = log(WPM_SCALE_MIN);
    double maxv = log(WPM_SCALE_MAX);

    double percent = (value-min_value)/(max_value-min_value);
    double wpm = (percent*100.0)+1.0;
    // Adjustment factor
    double scale = (maxv - minv) / (max - min);

    return (((log(wpm) - minv) / scale) + min);
}

- (void)setIntValue:(int)value
{
    if(value<min_value || value > max_value)
        value = (min_value+max_value)/2;

    format = 0;
    [slider setDoubleValue:[self sliderPositionForValue:value]];

    [self updateValue];
}
- (int)intValue
{
    return (int)[self floatValue];
}
- (void)setFloatValue:(float)value
{
    if(value<min_value || value > max_value)
        value = (min_value+max_value)/2;

    if(max_value==1) {
        format = 1;
    } else {
        format = 2;
    }

    [slider setDoubleValue:[self sliderPositionForValue:value]];
    [self updateValue];
}
- (void)setMaxValue:(double)value
{
    max_value = value;
}
- (float)floatValue
{
    return [self valueForSliderPosition:[slider doubleValue]];
}

- (void)updateValue
{
    switch(format){
        case 0:
            [value setStringValue:[NSString stringWithFormat:@"%d", [self intValue]]];
            break;
        case 1:
            [value setStringValue:[NSString stringWithFormat:@"%.0f%%", [self floatValue]*100]];
            break;
        case 2:
            [value setStringValue:[NSString stringWithFormat:@"%.2f", [self floatValue]]];
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
    return [SeaSlider sliderWithTitle:title Min:min Max:max Listener:listener Size:NSControlSizeSmall];
}
+ (SeaSlider*)sliderWithTitle:(NSString*)title Min:(double)min Max:(double) max Listener:(nullable id<Listener>)listener Size:(NSControlSize)size
{
    SeaSlider *slider = [[SeaSlider  alloc] init];
    [slider->title setTitle:title];
    slider->min_value = min;
    slider->max_value = max;
    slider->listener = listener;
    [slider->title setCtrlSize:size];
    [slider->value setCtrlSize:size];
    [slider->slider setCtrlSize:size];
    return slider;
}

+ (SeaSlider*)sliderWithCheck:(NSString*)title Min:(double)min Max:(double) max Listener:(nullable id<Listener>)listener Size:(NSControlSize)size
{
    SeaSlider *slider = [SeaSlider compactSliderWithTitle:title Min:min Max:max Listener:listener Size:size];
    [slider->checkbox setCtrlSize:size];
    [slider->checkbox setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:size]]];
    [slider->checkbox setTitle:title];
    slider->checkable=true;
    [slider->checkbox setHidden:FALSE];
    [slider->title setHidden:TRUE];

    return slider;
}

+ (SeaSlider*)compactSliderWithTitle:(NSString*)title Min:(double)min Max:(double) max Listener:(nullable id<Listener>)listener Size:(NSControlSize)size
{
    SeaSlider *slider = [SeaSlider sliderWithTitle:title Min:min Max:max Listener:listener Size:size];
    slider->compact = TRUE;
    return slider;
}

+ (SeaSlider*)compactSliderWithTitle:(NSString*)title Min:(double)min Max:(double)max Listener:(nullable id<Listener>)listener
{
    return [SeaSlider compactSliderWithTitle:title Min:min Max:max Listener:listener Size:NSMiniControlSize];
}

@end

#import "CoreImagePlugin.h"

typedef enum {
    kPT_Integer,
    kPT_Float,
    kPT_Angle,
    kPT_Point,
    kPT_Color,
    kPT_Bool,
} CIPropertyType;

typedef struct {
    int propertyEnum;
    const NSString* label;
    const NSString* userdefault;
    const NSString* filterProperty;
    CIPropertyType type;
    double min,max,defvalue;
} Property;

static Property PropertyMeta[] = {
    {0,0,0},
    {kCI_Radius,@"Radius",@"radius",@"inputRadius",kPT_Integer,1,1000,10},
    {kCI_Intensity,@"Intensity",@"intensity",@"inputIntensity",kPT_Float,0,10,1.0},
    {kCI_Intensity1000,@"Intensity",@"intensity",@"inputIntensity",kPT_Float,0,1000,1.0},
    {kCI_Angle,@"Angle",@"angle",@"inputAngle",kPT_Angle,-360,360,0},
    {kCI_AcuteAngle,@"Acute Angle",@"acuteangle",@"inputAcuteAngle",kPT_Angle,-360,360,90},
    {kCI_Width,@"Width",@"width",@"inputWidth",kPT_Integer,1,100,10},
    {kCI_Width1000,@"Width",@"width",@"inputWidth",kPT_Integer,1,1000,10},
    {kCI_Sharpness,@"Sharpness",@"sharpness",@"inputSharpness",kPT_Float,0,1,.7},
    {kCI_Brightness,@"Brightness",@"brightness",@"inputBrightness",kPT_Float,-1,1,0},
    {kCI_Brightness100,@"Brightness",@"brightness",@"inputBrightness",kPT_Float,0,100,3},
    {kCI_Contrast,@"Contrast",@"contrast",@"inputContrast",kPT_Float,0,5,1},
    {kCI_Saturation,@"Saturation",@"saturation",@"inputSaturation",kPT_Float,0,5,1},
    {kCI_Scale,@"Scale",@"scale",@"inputScale",kPT_Float,0,5,.5},
    {kCI_Scale1,@"Scale",@"scale",@"inputScale",kPT_Float,0,1,.5},
    {kCI_Scale100,@"Scale",@"scale",@"inputScale",kPT_Float,0,100,10},
    {kCI_Scale1000,@"Scale",@"scale",@"inputScale",kPT_Float,0,1000,50},
    {kCI_ScaleNeg1,@"Scale",@"scale",@"inputScale",kPT_Float,-1,1,0},
    {kCI_Strength,@"Strength",@"strength",@"inputStrength",kPT_Float,0,5,.5},
    {kCI_Overlap,@"Overlap",@"overlap",@"inputOverlap",kPT_Float,0,5,.75},
    {kCI_NoiseLevel,@"Noise Level",@"noiselevel",@"inputNoiseLevel",kPT_Float,0,1,.02},
    {kCI_Levels,@"Levels",@"levels",@"inputLevels",kPT_Integer,1,16,6},
    {kCI_Concentration,@"Concentration",@"concentration",@"inputConcentration",kPT_Float,0,2,.1},
    {kCI_Opacity,@"Opacity",@"opacity",@"inputOpacity",kPT_Float,-10,10,0},
    {kCI_Rotations,@"Rotations",@"rotations",@"inputAngle",kPT_Float,-1000,1000,0},
    {kCI_PointCenter,@"Center Point",NULL,@"inputCenter",kPT_Point,0,0,0},
    {kCI_PointRadius,@"Radius",NULL,@"inputRadius",kPT_Point,0,0,0},
    {kCI_PointWidth,@"Width",NULL,@"inputWidth",kPT_Point,0,0,0},
    {kCI_PointAngle,@"Angle",NULL,@"inputAngle",kPT_Point,0,0,0},
    {kCI_FocalLength,@"Focal Length",NULL,@"inputFocalLength",kPT_Float,1,500,50},
    {kCI_Crop,@"Crop",NULL,@"inputCrop",kPT_Float,0,500,0},
    {kCI_GCR,@"Gray Component Replacement",@"gcr",@"inputGCR",kPT_Float,0,1,1},
    {kCI_UCR,@"Under Color Removal",@"ucr",@"inputUCR",kPT_Float,0,1,.5},
    {kCI_Exposure,@"Exposure",@"exposure",@"inputEV",kPT_Float,-3,3,.5},
    {kCI_Color,@"Color",@"color",@"inputColor",kPT_Color,0,0,0},
    {kCI_Color0,@"Color 0",@"color0",@"inputColor0",kPT_Color,0,0,0},
    {kCI_Color1,@"Color 1",@"color1",@"inputColor1",kPT_Color,0,0,1},
    {kCI_Gamma,@"Gamma",@"gamma",@"inputPower",kPT_Float,0,3,1.0},
    {kCI_Refraction,@"Refraction",@"refraction",@"inputRefraction",kPT_Float,-5,5,1.7},
    {kCI_Point0,@"Point 0",NULL,@"inputPoint0",kPT_Point,0,0,0},
    {kCI_Point1,@"Point 1",NULL,@"inputPoint1",kPT_Point,0,0,1},
    {kCI_Point2,@"Point 2",NULL,@"inputPoint2",kPT_Point,0,0,2},
    {kCI_Point3,@"Point 3",NULL,@"inputPoint3",kPT_Point,0,0,3},
    {kCI_Pitch,@"Pitch",@"pitch",@"inputPitch",kPT_Angle,-360,360,0},
    {kCI_Roll,@"Roll",@"roll",@"inputRoll",kPT_Angle,-360,360,0},
    {kCI_Yaw,@"Yaw",@"yaw",@"inputYaw",kPT_Angle,-360,360,0},
    {kCI_Vibrance,@"Amount",@"amount",@"inputAmount",kPT_Float,-5,5,0},
    {kCI_GaussianSigma,@"Gaussian Sigma",@"gaussianSigma",@"inputGaussianSigma",kPT_Float,0,5,1.9},
    {kCI_ThresholdLow,@"Low Threshold",@"thresholdLow",@"inputThresholdLow",kPT_Float,0,1,0.02},
    {kCI_ThresholdHigh,@"High Threshold",@"thresholdHigh",@"inputThresholdHigh",kPT_Float,0,1,0.05},
    {kCI_HysteresisPasses,@"Hysterisis Passes",@"hysteresisPasses",@"inputHysteresisPasses",kPT_Integer,0,20,1},
    {kCI_Perceptual,@"Perceptual",@"perceptual",@"inputPerceptual",kPT_Bool,0,1,0}
};

@protocol Component
-(void)setIntValue:(int)value;
-(void)setFloatValue:(float)value;
-(int)intValue;
-(float)floatValue;
-(NSColor*)colorValue;
-(void)setColorValue:(NSColor*)value;
-(NSPoint*)pointValue:(int)index;
-(void)setChecked:(bool)value;
-(bool)isChecked;
@end

@interface PropertyEntry : NSObject
@property id<Component> component;
@property Property meta;
@property NSString *filterProperty;
@end

@implementation PropertyEntry
@end

@implementation CoreImagePlugin

- (void)addProperty:(CIProperty)property
{
    Property meta = PropertyMeta[property];
    PropertyEntry *entry = [[PropertyEntry alloc] init];
    entry.meta = meta;

    switch(meta.type){
        case kPT_Float:
        case kPT_Integer:
        case kPT_Angle: {
            SeaSlider *slider = [SeaSlider sliderWithTitle:meta.label Min:meta.min Max:meta.max Listener:self Size:defaultControlSize];
            [self->panel addSubview:slider];
            entry.component = slider;
        }
            break;
        case kPT_Color: {
            SeaColorWell *cw = [SeaColorWell colorWellWithTitle:meta.label Listener:self Size:defaultControlSize];
            [self->panel addSubview:cw];
            entry.component = cw;
        }
            break;
        case kPT_Bool: {
            SeaCheckbox *cb = [SeaCheckbox checkboxWithTitle:meta.label Listener:self Size:defaultControlSize];
            [self->panel addSubview:cb];
            entry.component = cb;
        }
            break;
        case kPT_Point:
            break;
    }

    entry.filterProperty = entry.meta.filterProperty;

    [properties addObject:entry];
}

-(void)setFilterProperty:(CIProperty)property property:(NSString*)filterProperty
{
    for(PropertyEntry *e in properties){
        if(e.meta.propertyEnum==property){
            e.filterProperty = filterProperty;
        }
    }
}

- (void)componentChanged:(id)component
{
    [pluginData settingsChanged];
}

- (NSView*)initialize
{
    for(PropertyEntry* p in properties){
        NSString *setting = [NSString stringWithFormat:@"%@.%@",filterName,p.meta.userdefault];
        switch(p.meta.type) {
            case kPT_Integer:
            case kPT_Angle:
                [p.component setIntValue:UserIntDefault(setting,p.meta.defvalue)];
                break;
            case kPT_Float:
                [p.component setFloatValue:UserFloatDefault(setting,p.meta.defvalue)];
                break;
            case kPT_Point:
                break;
            case kPT_Color:
                [p.component setColorValue:(p.meta.defvalue==0) ? [pluginData foreColor] : [pluginData backColor]];
                break;
            case kPT_Bool:
                [p.component setChecked:(p.meta.defvalue==1)];
                break;
        }
    }
    return panel;
}

-(void)apply:(id)sender
{
    for(PropertyEntry* p in properties){
        NSString *setting = [NSString stringWithFormat:@"%@.%@",filterName,p.meta.userdefault];
        switch(p.meta.type) {
            case kPT_Integer:
            case kPT_Angle:
                [gUserDefaults setInteger:[p.component intValue] forKey:setting];
                break;
            case kPT_Float:
                [gUserDefaults setFloat:[p.component floatValue] forKey:setting];
                break;
            case kPT_Bool:
                [gUserDefaults setBool:[p.component isChecked] forKey:setting];
                break;
            case kPT_Point:
            case kPT_Color:
                break;

        }
    }
}

- (float)floatValue:(CIProperty)property
{
    for(PropertyEntry* p in properties){
        if(p.meta.propertyEnum==property) {
            return [p.component floatValue];
        }
    }
    @throw [NSException exceptionWithName:@"CoreImagePropertyNotFound" reason:[NSString stringWithFormat:@"The property \"%d\" was not found.", property] userInfo:NULL];
}
- (int)intValue:(CIProperty)property
{
    for(PropertyEntry* p in properties){
        if(p.meta.propertyEnum==property) {
            return [p.component intValue];
        }
    }
    @throw [NSException exceptionWithName:@"CoreImagePropertyNotFound" reason:[NSString stringWithFormat:@"The property \"%d\" was not found.", property] userInfo:NULL];
}
- (CIColor*)colorValue:(CIProperty)property
{
    for(PropertyEntry* p in properties){
        if(p.meta.propertyEnum==property) {
            return createCIColor([p.component colorValue]);
        }
    }
    @throw [NSException exceptionWithName:@"CoreImagePropertyNotFound" reason:[NSString stringWithFormat:@"The property \"%d\" was not found.", property] userInfo:NULL];
}

-(CIVector*)centerPointValue
{
    int height = [pluginData height];
    int width = [pluginData width];
    if(points==0){
        return [CIVector vectorWithX:width/2 Y:height/2];
    } else {
        return [self pointValue:0];
    }
}

-(CIVector*)pointValue:(int)index
{
    int height = [pluginData height];

    IntPoint point = [pluginData point:index];
    return [CIVector vectorWithX:point.x Y:height - point.y];
}

-(int)radiusValue
{
    return calculateRadius([pluginData point:0], [pluginData point:1]);
}

-(float)angleValue
{
    return calculateAngle([pluginData point:0], [pluginData point:1]);
}

-(float)radiansValue:(CIProperty)property
{
    for(PropertyEntry* p in properties){
        if(p.meta.propertyEnum==property) {
            return [p.component floatValue] * PI / 180;
        }
    }
    @throw [NSException exceptionWithName:@"CoreImagePropertyNotFound" reason:[NSString stringWithFormat:@"The property \"%d\" was not found.", property] userInfo:NULL];
}

-(CoreImagePlugin*)initWithManager:(id<PluginData>)pluginData filter:(NSString* _Nullable)filterName points:(int)points properties:(CIProperty)property,...
{
    va_list args;
    va_start(args, property);
    return [self initWithManager:pluginData filter:filterName points:points bg:FALSE property:property vaList:args];
}

-(CoreImagePlugin*)initWithManager:(id<PluginData>)pluginData filter:(NSString* _Nullable)filterName points:(int)points bg:(BOOL)bg properties:(CIProperty)property,...
{
    va_list args;
    va_start(args, property);
    return [self initWithManager:pluginData filter:filterName points:points bg:bg property:property vaList:args];
}

-(CoreImagePlugin*)initWithManager:(id<PluginData>)pluginData filter:(NSString* _Nullable)filterName points:(int)points bg:(BOOL)bg property:(CIProperty)property vaList:(va_list)vaList
{
    self = [super initWithManager:pluginData];

    self->points = points;
    self->filterName = filterName;
    self->bg = bg;

    if(self->filterName) {
        [self getFilterInstance:self->filterName];
    }

    self->properties = [NSMutableArray array];
    self->panel = [VerticalView view];

    if(property) {
        [self addProperty:property];
        CIProperty p;
        while (p = va_arg(vaList, id))
        {
            [self addProperty:p];
        }
        va_end(vaList);
    }

    // if we have no properties, make the view nil to simplify hierarchy 
    if([[self->panel subviews] count]==0){
        self->panel=nil;
    }

    return self;
}

- (int)points
{
    return self->points;
}

- (void)execute
{
    CIFilter *filter = [self createFilter];
    [self applyFilter:filter];
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData {
    return TRUE;
}

- (CIFilter*)getFilterInstance:(NSString *)name
{
    CIFilter *filter = [CIFilter filterWithName:name];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", name] userInfo:NULL];
    }
    [filter setDefaults];
    return filter;
}

-(CIFilter*)createFilter
{
    CIFilter *filter = [self getFilterInstance:filterName];

    for(PropertyEntry* p in properties){
        NSString *filterProperty = p.filterProperty;

        // only attempt to set vaid properties - allows override to re-use them
        if(![[filter inputKeys] containsObject:filterProperty])
            continue;

        switch(p.meta.type) {
            case kPT_Integer:
                [filter setValue:[NSNumber numberWithInt:[p.component intValue]] forKey:filterProperty];
                break;
            case kPT_Float:
                [filter setValue:[NSNumber numberWithFloat:[p.component floatValue]] forKey:filterProperty];
                break;
            case kPT_Angle: {
                float rads = [p.component intValue] * PI / 180;
                [filter setValue:[NSNumber numberWithFloat:rads] forKey:filterProperty];
                break;
            }
            case kPT_Color: {
                NSColor *c = [p.component colorValue];
                [filter setValue:createCIColor(c) forKey:filterProperty];
                break;
            }
            case kPT_Bool: {
                [filter setValue:[NSNumber numberWithBool:[p.component isChecked]] forKey:filterProperty];
                break;
            }
            case kPT_Point: {
                switch(p.meta.propertyEnum) {
                    case kCI_PointCenter:
                        [filter setValue:[self centerPointValue] forKey:filterProperty];
                        break;
                    case kCI_PointRadius:
                    case kCI_PointWidth:
                    {
                        [filter setValue:[NSNumber numberWithInt:[self radiusValue]] forKey:filterProperty];
                        break;
                    }
                    case kCI_Point0: {
                        [filter setValue:[self pointValue:0] forKey:filterProperty];
                        break;
                    }
                    case kCI_Point1: {
                        [filter setValue:[self pointValue:1] forKey:filterProperty];
                        break;
                    }
                    case kCI_PointAngle: {
                        IntPoint point = [pluginData point:0];
                        IntPoint apoint = [pluginData point:1];
                        float rads = calculateAngle(point,apoint);
                        [filter setValue:[NSNumber numberWithFloat:rads] forKey:filterProperty];
                        break;
                    }
                }
            }
        }
    }
    return filter;
}

- (void)applyFilter:(CIFilter*)filter
{
    if(bg) {
        bool opaque = ![pluginData hasAlpha];

        if (opaque){
            [super applyFilterBG:filter];
        } else {
            [super applyFilter:filter];
        }
    } else {
        [super applyFilter:filter];
    }
}

@end

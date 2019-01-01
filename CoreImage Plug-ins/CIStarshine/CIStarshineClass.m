#import "CIStarshineClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIStarshineClass

- (id)initWithManager:(SeaPlugins *)manager
{
    seaPlugins = manager;
    [NSBundle loadNibNamed:@"CIStarshine" owner:self];
    mainNSColor = NULL;
    running = NO;
    
    return self;
}

- (int)type
{
    return 1;
}

- (int)points
{
    return 2;
}

- (NSString *)name
{
    return [gOurBundle localizedStringForKey:@"name" value:@"Starshine" table:NULL];
}

- (NSString *)groupName
{
    return [gOurBundle localizedStringForKey:@"groupName" value:@"Generate" table:NULL];
}

- (NSString *)instruction
{
    return [gOurBundle localizedStringForKey:@"instruction" value:@"Needs localization." table:NULL];
}

- (NSString *)sanity
{
    return @"Seashore Approved (Bobo)";
}

- (void)run
{
    PluginData *pluginData;
    
    if ([gUserDefaults objectForKey:@"CIStarshine.scale"])
        scale = [gUserDefaults floatForKey:@"CIStarshine.scale"];
    else
        scale = 15;
    if ([gUserDefaults objectForKey:@"CIStarshine.opacity"])
        opacity = [gUserDefaults floatForKey:@"CIStarshine.opacity"];
    else
        opacity = -2.0;
    if ([gUserDefaults objectForKey:@"CIStarshine.width"])
        star_width = [gUserDefaults floatForKey:@"CIStarshine.width"];
    else
        star_width = 2.5;
    
    if (scale < 0 || scale > 100)
        scale = 15;
    if (opacity < -8.0 || opacity > 0.0)
        opacity = -2.0;
    if (star_width < 0.0 || star_width > 10.0)
        star_width = 2.5;
    
    [scaleLabel setStringValue:[NSString stringWithFormat:@"%d", scale]];
    [scaleSlider setFloatValue:scale];
    [opacityLabel setStringValue:[NSString stringWithFormat:@"%.1f", opacity]];
    [opacitySlider setFloatValue:opacity];
    [widthLabel setStringValue:[NSString stringWithFormat:@"%.1f", star_width]];
    [widthSlider setFloatValue:star_width];
    
    mainNSColor = [[mainColorWell color] colorUsingColorSpaceName:MyRGBSpace];
    
    refresh = YES;
    success = NO;
    running = YES;
    pluginData = [(SeaPlugins *)seaPlugins data];
    [self preview:self];
    if ([pluginData window])
        [NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
    else
        [NSApp runModalForWindow:panel];
    // Nothing to go here
}

- (IBAction)apply:(id)sender
{
    PluginData *pluginData;
    
    pluginData = [(SeaPlugins *)seaPlugins data];
    if (refresh) [self execute];
    [pluginData apply];
    
    [panel setAlphaValue:1.0];
    
    [NSApp stopModal];
    if ([pluginData window]) [NSApp endSheet:panel];
    [panel orderOut:self];
    success = YES;
    running = NO;
    
    [gUserDefaults setInteger:scale forKey:@"CIStarshine.scale"];
    [gUserDefaults setFloat:opacity forKey:@"CIStarshine.opacity"];
    [gUserDefaults setFloat:star_width forKey:@"CIStarshine.width"];
    
    [gColorPanel orderOut:self];

}

- (void)reapply
{
    PluginData *pluginData;
    
    pluginData = [(SeaPlugins *)seaPlugins data];
    [self execute];
    [pluginData apply];
}

- (BOOL)canReapply
{
    return NO;
}

- (IBAction)preview:(id)sender
{
    PluginData *pluginData;
    
    pluginData = [(SeaPlugins *)seaPlugins data];
    if (refresh) [self execute];
    [pluginData preview];
    refresh = NO;
}

- (IBAction)cancel:(id)sender
{
    PluginData *pluginData;
    
    pluginData = [(SeaPlugins *)seaPlugins data];
    [pluginData cancel];
    
    [panel setAlphaValue:1.0];
    
    [NSApp stopModal];
    [NSApp endSheet:panel];
    [panel orderOut:self];
    success = NO;
    running = NO;
    [gColorPanel orderOut:self];
}

- (void)setColor:(NSColor *)color
{
    PluginData *pluginData;
    
    mainNSColor = [color colorUsingColorSpaceName:MyRGBSpace];
    if (running) {
        refresh = YES;
        [self preview:self];
        pluginData = [(SeaPlugins *)seaPlugins data];
        if ([pluginData window]) [panel setAlphaValue:0.4];
    }
}

- (IBAction)update:(id)sender
{
    PluginData *pluginData;
    
    scale = [scaleSlider intValue];
    opacity = [opacitySlider floatValue];
    star_width = [widthSlider floatValue];
    
    [panel setAlphaValue:1.0];
    
    [scaleLabel setStringValue:[NSString stringWithFormat:@"%d", scale]];
    [opacityLabel setStringValue:[NSString stringWithFormat:@"%.1f", opacity]];
    [widthLabel setStringValue:[NSString stringWithFormat:@"%.1f", star_width]];
    
    refresh = YES;
    if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
        [self preview:self];
        pluginData = [(SeaPlugins *)seaPlugins data];
        if ([pluginData window]) [panel setAlphaValue:0.4];
    }
}

- (void)execute
{
    PluginData *pluginData = [seaPlugins data];
    
    int height = [pluginData height];
    
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];
    
    int radius = calculateRadius(point,apoint);
    
    CIColor *mainColor = [CIColor colorWithRed:[mainNSColor redComponent] green:[mainNSColor greenComponent] blue:[mainNSColor blueComponent] alpha:[mainNSColor alphaComponent]];
    float angle = calculateAngle(point,apoint);
    
    CIFilter *filter = [CIFilter filterWithName:@"CIStarShineGenerator"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIStarshineGenerator"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:apoint.x Y:height - apoint.y] forKey:@"inputCenter"];
    [filter setValue:mainColor forKey:@"inputColor"];
    [filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithInt:scale] forKey:@"inputCrossScale"];
    [filter setValue:[NSNumber numberWithFloat:angle] forKey:@"inputCrossAngle"];
    [filter setValue:[NSNumber numberWithFloat:opacity] forKey:@"inputCrossOpacity"];
    [filter setValue:[NSNumber numberWithFloat:star_width] forKey:@"inputCrossWidth"];
    [filter setValue:[NSNumber numberWithInt:-2] forKey:@"inputEpsilon"];
    CIImage *halo = [filter valueForKey: @"outputImage"];
    
    // Run filter
    filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [filter setDefaults];
    [filter setValue:halo forKey:@"inputImage"];
    [filter setValue:createCIImage(pluginData) forKey:@"inputBackgroundImage"];
    CIImage *output = [filter valueForKey: @"outputImage"];

    renderCIImage(pluginData,output);
}

- (BOOL)validateMenuItem:(id)menuItem
{
    PluginData *pluginData;
    
    pluginData = [(SeaPlugins *)seaPlugins data];
    
    if (pluginData != NULL) {

        if ([pluginData channel] == kAlphaChannel)
            return NO;
        
        if ([pluginData spp] == 2)
            return NO;
    
    }
    
    return YES;
}

@end

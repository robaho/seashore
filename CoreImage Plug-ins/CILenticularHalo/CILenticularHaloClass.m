#import "CILenticularHaloClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CILenticularHaloClass

- (id)initWithManager:(SeaPlugins *)manager
{
    seaPlugins = manager;
    [NSBundle loadNibNamed:@"CILenticularHalo" owner:self];
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
    return 3;
}

- (NSString *)name
{
    return [gOurBundle localizedStringForKey:@"name" value:@"Halo" table:NULL];
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
    
    if ([gUserDefaults objectForKey:@"CILenticularHalo.overlap"])
        overlap = [gUserDefaults floatForKey:@"CILenticularHalo.overlap"];
    else
        overlap = 0.77;
    if ([gUserDefaults objectForKey:@"CILenticularHalo.strength"])
        strength = [gUserDefaults floatForKey:@"CILenticularHalo.strength"];
    else
        strength = 0.5;
    if ([gUserDefaults objectForKey:@"CILenticularHalo.contrast"])
        contrast = [gUserDefaults floatForKey:@"CILenticularHalo.contrast"];
    else
        contrast = 1.0;
            
    if (overlap < 0.0 || overlap > 1.0)
        overlap = 0.77;
    if (strength < 0.0 || strength > 3.0)
        strength = 0.5;
    if (contrast < 0.0 || contrast > 5.0)
        contrast = 1.0;
            
    [overlapLabel setStringValue:[NSString stringWithFormat:@"%.2f", overlap]];
    [overlapSlider setFloatValue:overlap * 100.0];
    [strengthLabel setStringValue:[NSString stringWithFormat:@"%.1f", strength]];
    [strengthSlider setFloatValue:strength];
    [contrastLabel setStringValue:[NSString stringWithFormat:@"%.1f", contrast]];
    [contrastSlider setFloatValue:contrast];
    
    mainNSColor = [mainColorWell color];
    
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
        
    [gUserDefaults setFloat:overlap forKey:@"CILenticularHalo.overlap"];
    [gUserDefaults setFloat:strength forKey:@"CILenticularHalo.strength"];
    [gUserDefaults setFloat:contrast forKey:@"CILenticularHalo.contrast"];
    
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
    
    mainNSColor = color;
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
    
    overlap = roundf([overlapSlider floatValue]) / 100.0;
    strength = [strengthSlider floatValue];
    contrast = [contrastSlider floatValue];
    
    [panel setAlphaValue:1.0];
    
    [overlapLabel setStringValue:[NSString stringWithFormat:@"%.2f", overlap]];
    [strengthLabel setStringValue:[NSString stringWithFormat:@"%.1f", strength]];
    [contrastLabel setStringValue:[NSString stringWithFormat:@"%.1f", contrast]];
    
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
    
    IntPoint point1 = [pluginData point:0];
    IntPoint point2 = [pluginData point:1];
    IntPoint point3 = [pluginData point:2];
    
    CIColor *mainColor = createCIColor(mainNSColor);
    
    float halo_radius = abs(point2.x - point1.x) * abs(point2.x - point1.x) + abs(point2.y - point1.y) * abs(point2.y - point1.y);
    halo_radius = sqrt(halo_radius);
    
    float halo_width = abs(point3.x - point1.x) * abs(point3.x - point1.x) + abs(point3.y - point1.y) * abs(point3.y - point1.y);
    halo_width = sqrt(halo_width);
    halo_width = fabs(halo_width - halo_radius);

    CIFilter *filter = [CIFilter filterWithName:@"CILenticularHaloGenerator"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CILenticularHaloGenerator"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:point1.x Y:height - point1.y] forKey:@"inputCenter"];
    [filter setValue:mainColor forKey:@"inputColor"];
    [filter setValue:[NSNumber numberWithFloat:halo_radius] forKey:@"inputHaloRadius"];
    [filter setValue:[NSNumber numberWithFloat:halo_width] forKey:@"inputHaloWidth"];
    [filter setValue:[NSNumber numberWithFloat:overlap] forKey:@"inputHaloOverlap"];
    [filter setValue:[NSNumber numberWithFloat:strength] forKey:@"inputStriationStrength"];
    [filter setValue:[NSNumber numberWithFloat:contrast] forKey:@"inputStriationContrast"];
    [filter setValue:[NSNumber numberWithInt:0] forKey:@"inputTime"];
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

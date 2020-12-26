#import "CISunbeamsClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CISunbeamsClass

- (id)initWithManager:(PluginData *)data
{
    pluginData = data;
    [NSBundle loadNibNamed:@"CISunbeams" owner:self];
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
    return [gOurBundle localizedStringForKey:@"name" value:@"Sunbeams" table:NULL];
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
    if ([gUserDefaults objectForKey:@"CISunbeams.strength"])
        strength = [gUserDefaults floatForKey:@"CISunbeams.strength"];
    else
        strength = 0.5;
    if ([gUserDefaults objectForKey:@"CISunbeams.contrast"])
        contrast = [gUserDefaults floatForKey:@"CISunbeams.contrast"];
    else
        contrast = 1.0;
    
    if (strength < 0.0 || strength > 3.0)
        strength = 0.5;
    if (contrast < 0.0 || contrast > 5.0)
        contrast = 1.0;
    
    [strengthLabel setStringValue:[NSString stringWithFormat:@"%.1f", strength]];
    [strengthSlider setFloatValue:strength];
    [contrastLabel setStringValue:[NSString stringWithFormat:@"%.1f", contrast]];
    [contrastSlider setFloatValue:contrast];
    
    mainNSColor = [mainColorWell color];
    
    refresh = YES;
    success = NO;
    running = YES;
    [self preview:self];
    if ([pluginData window])
        [NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
    else
        [NSApp runModalForWindow:panel];
    // Nothing to go here
}

- (IBAction)apply:(id)sender
{
    if (refresh) [self execute];
    [pluginData apply];
    
    [panel setAlphaValue:1.0];
    
    [NSApp stopModal];
    if ([pluginData window]) [NSApp endSheet:panel];
    [panel orderOut:self];
    success = YES;
    running = NO;
    
    [gUserDefaults setFloat:strength forKey:@"CISunbeams.strength"];
    [gUserDefaults setFloat:contrast forKey:@"CISunbeams.contrast"];
    
    [gColorPanel orderOut:self];

}

- (void)reapply
{
    [self execute];
    [pluginData apply];
}

- (BOOL)canReapply
{
    return NO;
}

- (IBAction)preview:(id)sender
{
    if (refresh) [self execute];
    [pluginData preview];
    refresh = NO;
}

- (IBAction)cancel:(id)sender
{
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
    mainNSColor = color;
    if (running) {
        refresh = YES;
        [self preview:self];
        if ([pluginData window]) [panel setAlphaValue:0.4];
    }
}

- (IBAction)update:(id)sender
{
    strength = [strengthSlider floatValue];
    contrast = [contrastSlider floatValue];
    
    [panel setAlphaValue:1.0];
    
    [strengthLabel setStringValue:[NSString stringWithFormat:@"%.1f", strength]];
    [contrastLabel setStringValue:[NSString stringWithFormat:@"%.1f", contrast]];
    
    refresh = YES;
    if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
        [self preview:self];
        if ([pluginData window]) [panel setAlphaValue:0.4];
    }
}

- (void)execute
{
    int height = [pluginData height];
    
    IntPoint point1 = [pluginData point:0];
    IntPoint point2 = [pluginData point:1];
    IntPoint point3 = [pluginData point:2];
    int halo_radius = calculateRadius(point2,point3);
    int halo_width = abs(calculateRadius(point1,point3) - halo_radius);
    
    CIColor *mainColor = createCIColor(mainNSColor);

    CIFilter *filter = [CIFilter filterWithName:@"CISunbeamsGenerator"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CISunbeamsGenerator"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:point1.x Y:height - point1.y] forKey:@"inputCenter"];
    [filter setValue:mainColor forKey:@"inputColor"];
    [filter setValue:[NSNumber numberWithFloat:halo_radius] forKey:@"inputSunRadius"];
    [filter setValue:[NSNumber numberWithFloat:halo_width] forKey:@"inputMaxStriationRadius"];
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

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
    if (pluginData != NULL) {

        if ([pluginData channel] == kAlphaChannel)
            return NO;
        
        if ([pluginData spp] == 2)
            return NO;
    
    }
    
    return YES;
}

@end

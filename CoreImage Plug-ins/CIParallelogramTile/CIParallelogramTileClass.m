#import "CIParallelogramTileClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIParallelogramTileClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CIParallelogramTile" owner:self];
	
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Parallelogram" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Tile" table:NULL];
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
	if ([gUserDefaults objectForKey:@"CIParallelogramTile.acute"])
		acute = [gUserDefaults floatForKey:@"CIParallelogramTile.acute"];
	else
		acute = 0.78;
	
	if (acute < -1.57 || acute > 1.57)
		acute = 0.78;
	
	[acuteLabel setStringValue:[NSString stringWithFormat:@"%.2f", acute]];
	[acuteSlider setFloatValue:acute * 100.0];
	
	refresh = YES;
	success = NO;
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
	
	[gUserDefaults setFloat:acute forKey:@"CILineScreen.acute"];
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
}

- (IBAction)update:(id)sender
{
    acute = roundf([acuteSlider floatValue]) / 100.0;
    if (acute > -0.015 && acute < 0.00) acute = 0.00; /* Force a zero point */
    
    [panel setAlphaValue:1.0];
    
    [acuteLabel setStringValue:[NSString stringWithFormat:@"%.2f", acute]];
    
    refresh = YES;
    if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
        [self preview:self];
        if ([pluginData window]) [panel setAlphaValue:0.4];
    }
}

- (void)execute
{
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];
    
    float angle = calculateAngle(point,apoint);
    int radius = calculateRadius(point,apoint);
    
    CIFilter *filter = [CIFilter filterWithName:@"CIParallelogramTile"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIParallelogramTile"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:angle] forKey:@"inputAngle"];
    [filter setValue:[NSNumber numberWithFloat:acute] forKey:@"inputAcuteAngle"];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:radius] forKey:@"inputWidth"];

    bool opaque = ![pluginData hasAlpha];
    if (opaque){
        applyFilter(pluginData,filter);
    } else {
        applyFilterBG(pluginData,filter);
    }

}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

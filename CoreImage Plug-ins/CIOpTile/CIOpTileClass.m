#import "CIOpTileClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIOpTileClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CIOpTile" owner:self];
	
	return self;
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 1;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Circular Screen" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Halftone" table:NULL];
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
	if ([gUserDefaults objectForKey:@"CIOpTile.width"])
		squareWidth = [gUserDefaults integerForKey:@"CIOpTile.width"];
	else
		squareWidth = 65;
	angle = 0.0;
	if ([gUserDefaults objectForKey:@"CIOpTile.scale"])
		scale = [gUserDefaults floatForKey:@"CIOpTile.scale"];
	else
		scale = 2.8;
			
	if (squareWidth < 10 || squareWidth > 400)
		squareWidth = 65;
	if (scale < 0.1 || scale > 10.0)
		scale = 2.8;
			
	[squareWidthLabel setStringValue:[NSString stringWithFormat:@"%d", squareWidth]];
	[squareWidthSlider setIntValue:squareWidth];
	[angleLabel setStringValue:[NSString stringWithFormat:@"%.2f", angle]];
	[angleSlider setFloatValue:angle * 100.0];
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%.1f", scale]];
	[scaleSlider setFloatValue:scale];
	
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
		
	[gUserDefaults setInteger:squareWidth forKey:@"CIOpTile.width"];
	[gUserDefaults setFloat:scale forKey:@"CIOpTile.scale"];
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
	squareWidth = [squareWidthSlider intValue];
	angle = roundf([angleSlider floatValue]) / 100.0;
	scale = [scaleSlider floatValue];
	if (angle > -0.035 && angle < 0.00) angle = 0.00; /* Force a zero point */
	
	[panel setAlphaValue:1.0];
	
	[squareWidthLabel setStringValue:[NSString stringWithFormat:@"%d", squareWidth]];
	[angleLabel setStringValue:[NSString stringWithFormat:@"%.2f", angle]];
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%.1f", scale]];
	
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
    
    CIFilter *filter = [CIFilter filterWithName:@"CIOpTile"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIOpTile"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:squareWidth] forKey:@"inputWidth"];
    [filter setValue:[NSNumber numberWithFloat:angle] forKey:@"inputAngle"];
    [filter setValue:[NSNumber numberWithFloat:scale] forKey:@"inputScale"];

    bool opaque = ![pluginData hasAlpha];
    
    if (opaque){
        applyFilterBG(pluginData,filter);
    } else {
        applyFilter(pluginData,filter);
    }
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

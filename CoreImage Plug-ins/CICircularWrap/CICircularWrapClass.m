#import "CICircularWrapClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CICircularWrapClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CICircularWrap" owner:self];
	
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Circular Wrap" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Distort" table:NULL];
}

- (NSString *)instruction
{
	return [gOurBundle localizedStringForKey:@"instruction" value:@"Needs localization." table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

#define PI 3.14159265

- (void)run
{
	IntPoint point, apoint;
	int radius;
	
    CGRect bounds = determineContentBorders(pluginData);

	point = [pluginData point:0];
	apoint = [pluginData point:1];
    
    radius = calculateRadius(point,apoint);

	angle = 0.0;
	if (bounds.size.width < PI * radius) angle = PI / 2.0 + bounds.size.width / (2.0 * radius);
	else if (bounds.size.width < 2.0 * PI * radius) angle = (- 3 * PI + bounds.size.width / radius) / 2.0;
	
	[angleLabel setStringValue:[NSString stringWithFormat:@"%.2f", angle * -1.0]];
	[angleSlider setFloatValue:angle * -100.0];
	
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
		
	[gUserDefaults setFloat:angle forKey:@"CICircularWrap.angle"];
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
	angle = [angleSlider floatValue] / -100.0;
	if (angle > 0.0 && angle < 0.02) angle = 0.0; /* Force a zero point */
	
	[panel setAlphaValue:1.0];
	
	[angleLabel setStringValue:[NSString stringWithFormat:@"%.2f", angle * -1.0]];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    int width = [pluginData width];
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];
    
    int radius = calculateRadius(point,apoint);
    
    CGRect bounds = determineContentBorders(pluginData);
    
    CIImage *inputImage = croppedCIImage(pluginData,bounds);
    
    CIFilter *filter = [CIFilter filterWithName:@"CICircularWrap"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICircularWrap"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:inputImage forKey:@"inputImage"];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:radius] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithFloat:angle] forKey:@"inputAngle"];
    CIImage *outputImage = [filter valueForKey:@"outputImage"];
    
    bool opaque = ![pluginData hasAlpha];
    
    if (opaque) {
        CIColor *backColor = createCIColor([pluginData backColor]);

        filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
        [filter setDefaults];
        [filter setValue:backColor forKey:@"inputColor"];
        CIImage *background = [filter valueForKey: @"outputImage"];
        filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [filter setDefaults];
        [filter setValue:background forKey:@"inputBackgroundImage"];
        [filter setValue:outputImage forKey:@"inputImage"];
        outputImage = [filter valueForKey:@"outputImage"];
    }
    
    renderCIImage(pluginData,outputImage);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end

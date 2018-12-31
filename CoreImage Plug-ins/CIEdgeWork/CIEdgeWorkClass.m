#import "CIEdgeWorkClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIEdgeWorkClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CIEdgeWork" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Edges" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Stylize" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	
	if ([gUserDefaults objectForKey:@"CIEdgeWork.radius"])
		radius = [gUserDefaults floatForKey:@"CIEdgeWork.radius"];
	else
		radius = 3.0;
	refresh = YES;
	
	if (radius < 0.1 || radius > 20.0)
		radius = 3.0;
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%.1f", radius]];
	
	[radiusSlider setIntValue:radius];
	
	success = NO;
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
		
	[gUserDefaults setFloat:radius forKey:@"CIEdgeWork.radius"];
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
	return success;
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
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	radius = roundf([radiusSlider floatValue] * 10.0) / 10.0;
	
	[panel setAlphaValue:1.0];
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%.1f", radius]];
	
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
    
    CIFilter *filter = [CIFilter filterWithName:@"CIEdgeWork"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIEdgeWork"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputRadius"];
    
    bool opaque = ![pluginData hasAlpha];
    
    if (opaque){
        applyFilterFGBG(pluginData,filter);
    } else {
        applyFilterFG(pluginData,filter);
    }
}


- (unsigned char *)edges:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *imm_output, *imm_output2, *output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	CGImageDestinationRef temp_writer;
	NSMutableData *temp_handler;
	NSBitmapImageRep *temp_rep;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	BOOL opaque;
	CIColor *backColor, *foreColor;
	IntRect selection;
	
	// Check if image is opaque
	opaque = ![pluginData hasAlpha];
	if (opaque && [pluginData spp] == 4) backColor = [CIColor colorWithRed:[[pluginData backColor] redComponent] green:[[pluginData backColor] greenComponent] blue:[[pluginData backColor] blueComponent]];
	else if (opaque) backColor = [CIColor colorWithRed:[[pluginData backColor] whiteComponent] green:[[pluginData backColor] whiteComponent] blue:[[pluginData backColor] whiteComponent]];
	
	// Get foreground color
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[pluginData displayProf], kCIContextWorkingColorSpace, (id)[pluginData displayProf], kCIContextOutputColorSpace, NULL]];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	imm_output = [filter valueForKey: @"outputImage"];

	// Add foreground
	
	// Add opaque background (if required)
	if (opaque) {
		filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
		[filter setDefaults];
		[filter setValue:backColor forKey:@"inputColor"];
		background = [filter valueForKey: @"outputImage"]; 
		filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
		[filter setDefaults];
		[filter setValue:background forKey:@"inputBackgroundImage"];
		[filter setValue:imm_output2 forKey:@"inputImage"];
		output = [filter valueForKey:@"outputImage"];
	}
	else {
		output = imm_output2;
	}
	
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		
		// Crop to selection
		filter = [CIFilter filterWithName:@"CICrop"];
		[filter setDefaults];
		[filter setValue:output forKey:@"inputImage"];
		[filter setValue:[CIVector vectorWithX:selection.origin.x Y:height - selection.size.height - selection.origin.y Z:selection.size.width W:selection.size.height] forKey:@"inputRectangle"];
		crop_output = [filter valueForKey:@"outputImage"];
		
		// Create output core image
		rect.origin.x = selection.origin.x;
		rect.origin.y = height - selection.size.height - selection.origin.y;
		rect.size.width = selection.size.width;
		rect.size.height = selection.size.height;
		temp_image = [context createCGImage:output fromRect:rect];		
		
	}
	else {
	
		// Create output core image
		rect.origin.x = 0;
		rect.origin.y = 0;
		rect.size.width = width;
		rect.size.height = height;
		temp_image = [context createCGImage:output fromRect:rect];
		
	}
	
	// Get data from output core image
	temp_handler = [NSMutableData dataWithLength:0];
	temp_writer = CGImageDestinationCreateWithData((CFMutableDataRef)temp_handler, kUTTypeTIFF, 1, NULL);
	CGImageDestinationAddImage(temp_writer, temp_image, NULL);
	CGImageDestinationFinalize(temp_writer);
	temp_rep = [NSBitmapImageRep imageRepWithData:temp_handler];
	resdata = [temp_rep bitmapData];
		
	return resdata;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end

#import "CMYKClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CMYKClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Convert to CMYK" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Effect" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
    PluginData *pluginData;
    IntRect selection;
    
    unsigned char *data, *overlay, *replace;
    int width, height, spp, channel;
    
    pluginData = [(SeaPlugins *)seaPlugins data];
    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kReplacingBehaviour];
    selection = [pluginData selection];
    
    spp = [pluginData spp];
    
    width = [pluginData width];
    height = [pluginData height];
    
    data = [pluginData data];
    overlay = [pluginData overlay];
    replace = [pluginData replace];
    
    int selwidth = selection.size.width;
    int selheight = selection.size.height;
    
    int sely = height-(selection.origin.y+selheight); // need to reverse coordinates
    
    NSRect to = NSMakeRect(0,0,selwidth,selheight);
    NSRect from = NSMakeRect(selection.origin.x,sely,selwidth,selheight);
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height
                                                                      bitsPerSample:8 samplesPerPixel:spp hasAlpha:TRUE isPlanar:NO
                                                                     colorSpaceName:(spp == 4) ? MyRGBSpace : MyGraySpace
                                                                        bytesPerRow:width * spp bitsPerPixel:8 * spp];
    

    NSColorSpaceName csname = NSDeviceCMYKColorSpace;
    int dspp = 4;
    
    unsigned char *buffer = malloc(selwidth*selheight*dspp);
    
    memset(buffer,0,selwidth*selheight*dspp);
    
    NSBitmapImageRep *tmp = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&buffer pixelsWide:selwidth pixelsHigh:selheight
                                                                 bitsPerSample:8 samplesPerPixel:dspp hasAlpha:FALSE isPlanar:NO
                                                                colorSpaceName:csname
                                                                   bytesPerRow:selwidth*dspp bitsPerPixel:8*dspp];
    
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:tmp];
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:ctx];
    
    [imageRep drawInRect:to fromRect:from operation:NSCompositingOperationCopy fraction:1 respectFlipped:NO hints:NULL];
    
    // now draw image back into overlay buffer
    
    NSBitmapImageRep *overlayRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&overlay pixelsWide:width pixelsHigh:height
                                                                        bitsPerSample:8 samplesPerPixel:spp hasAlpha:TRUE isPlanar:NO
                                                                       colorSpaceName:(spp == 4) ? MyRGBSpace : MyGraySpace
                                                                          bytesPerRow:width * spp bitsPerPixel:8 * spp];
    
    ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:overlayRep];
    
    [NSGraphicsContext setCurrentContext:ctx];
    
    [tmp drawAtPoint:from.origin];
    
    [NSGraphicsContext restoreGraphicsState];
    
    int j,pos;
    
    for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
        pos = j * width + selection.origin.x;
        memset(replace+pos,255,selection.size.width);
    }

    [pluginData apply];
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return YES;
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

#import "CMYKClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CMYKClass

- (id)initWithManager:(id<PluginData>)data
{
	pluginData = data;
	
	return self;
}

- (void)execute
{
    IntRect selection;
    
    unsigned char *data, *overlay, *replace;
    int width, height;
    
    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kReplacingBehaviour];
    selection = [pluginData selection];
    
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
                                                                      bitsPerSample:8 samplesPerPixel:4 hasAlpha:TRUE isPlanar:NO
                                                                     colorSpaceName:MyRGBSpace
                                                                        bytesPerRow:width * 4 bitsPerPixel:8 * 4];
    

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
    
    [imageRep drawInRect:to fromRect:from operation:NSCompositeCopy fraction:1 respectFlipped:NO hints:NULL];
    
    [NSGraphicsContext restoreGraphicsState];
    
    // now copy into overlay
    
    for(int row=0;row<selheight;row++){
        for(int col=0;col<selwidth;col++){
            int index = (row+selection.origin.y)*width+(col+selection.origin.x);
            int sindex = (row*selwidth)*dspp+col*dspp;

            double c = buffer[sindex]/255.0;
            double m = buffer[sindex+1]/255.0;
            double y = buffer[sindex+2]/255.0;
            double k = buffer[sindex+3]/255.0;

            int r = 255 * (1-c)*(1-k);
            int g = 255 * (1-m)*(1-k);
            int b = 255 * (1-y)*(1-k);
            
            overlay[index*SPP+CR]=r;
            overlay[index*SPP+CG]=g;
            overlay[index*SPP+CB]=b;
            overlay[index*SPP+alphaPos]=data[index*SPP+alphaPos];
            replace[index]=255;
        }
    }
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
    if ([pluginData channel] == kAlphaChannel)
        return NO;
	
	return YES;
}

@end

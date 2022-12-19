#import "GreyscaleClass.h"

@implementation GreyscaleClass

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
    
    for(int row=0;row<selheight;row++){
        for(int col=0;col<selwidth;col++){
            int rindex = (row+selection.origin.y)*width+(col+selection.origin.x);
            int index = rindex*4;
            int gray = ((int)data[index+0] + (int)data[index+1] + (int)data[index+2]) / 3;
            overlay[index]=overlay[index+1]=overlay[index+2]=gray;
            overlay[index+3]=data[index+3];
            replace[rindex]=255;
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

#import "GreyscaleClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation GreyscaleClass

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
	return [gOurBundle localizedStringForKey:@"name" value:@"Convert to Grayscale" table:NULL];
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
	int width, height, spp;
	
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
    
    for(int row=0;row<selheight;row++){
        for(int col=0;col<selwidth;col++){
            int rindex = (row+selection.origin.y)*width+(col+selection.origin.x);
            int index = rindex*spp;
            int gray = ((int)data[index+0] + (int)data[index+1] + (int)data[index+2]) / 3;
            overlay[index]=overlay[index+1]=overlay[index+2]=gray;
            overlay[index+3]=data[index+3];
            replace[rindex]=255;
        }
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

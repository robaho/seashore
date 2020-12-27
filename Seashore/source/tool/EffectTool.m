#import "EffectTool.h"
#import "SeaController.h"
#import "SeaPlugins.h"
#import "PluginClass.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaTools.h"
#import "EffectOptions.h"

@implementation EffectTool

- (int)toolId
{
	return kEffectTool;
}

- (id)init
{
	if(![super init])
		return NULL;
	count = 0;
	return self;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    if(!currentPlugin) {
        return;
    }
    
	float xScale, yScale;
	IntPoint layerOff;
	
	if (count < kMaxEffectToolPoints) {
		points[count] = where;
		count++;
		layerOff.x = [[[document contents] activeLayer] xoff];
		layerOff.y = [[[document contents] activeLayer] yoff];
		xScale = [[document contents] xscale];
		yScale = [[document contents] yscale];
		[[document docView] setNeedsDisplayInRect:NSMakeRect((where.x + layerOff.x) * xScale - 4, (where.y + layerOff.y) * yScale - 4, 8, 8)];
	}
	
	if (count == [currentPlugin points]) {
		[currentPlugin run];
		count = 0;
	}
	
	[options updateClickCount:self];
}

- (void)selectEffect:(PluginClass*)plugin
{
    PluginData* data = [document pluginData];
    if(![[plugin class] validatePlugin:data]){
        currentPlugin = nil;
        return;
    }
    currentPlugin = [[plugin class] alloc];
    currentPlugin = [currentPlugin initWithManager:data];
    [self reset];
}

- (void)reset
{
	count = 0;
	[options updateClickCount:self];
}

- (IntPoint)point:(int)index
{
	return points[index];
}

- (int)clickCount
{
	return count;
}

- (IntRect) selectionRect
{
	NSLog(@"Effect tool invalidly getting asked its selection rect");
	return IntMakeRect(0, 0, 0, 0);
}

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (EffectOptions*)newoptions;
}
- (PluginClass*)plugin
{
    return currentPlugin;
}


@end

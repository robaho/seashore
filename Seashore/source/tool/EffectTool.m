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
	seaPlugins = [SeaController seaPlugins];
	return self;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	id pointEffect = [seaPlugins activePointEffect];
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
	
	if (count == [pointEffect points]) {
		[pointEffect run];
		[seaPlugins cancelReapply];
		count = 0;
	}
	
	[(EffectOptions *)options updateClickCount:self];
}

- (void)reset
{
	count = 0;
	[(EffectOptions *)options updateClickCount:self];
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

@end

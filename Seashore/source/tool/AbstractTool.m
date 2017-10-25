#import "AbstractTool.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "AbstractOptions.h"
#import "SeaDocument.h"
#import "SeaContent.h"

@implementation AbstractTool

- (int)toolId
{
	return -1;
}

- (id)init
{
	self = [super init];
	if(self){
		intermediate = NO;
	}
	return self;
}


- (void)setOptions:(id)newOptions
{
	options = newOptions;
}

- (BOOL)acceptsLineDraws
{
	return NO;
}

- (BOOL)useMouseCoalescing
{
	return YES;
}

- (BOOL)foregroundIsTexture
{
	return [options useTextures];
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
}

- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event;
{
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event;
{
}

- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event;
{
}

- (BOOL)isFineTool
{
	return NO;
}

- (BOOL) intermediate
{
	return intermediate;
}


@end

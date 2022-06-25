#import "AbstractTool.h"
#import "SeaController.h"
#import "OptionsUtility.h"
#import "SeaController.h"
#import "TextureUtility.h"
#import "AbstractOptions.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaSelection.h"
#import "SeaLayer.h";

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
	return [[self getOptions] useTextures];
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

- (BOOL) intermediate
{
	return intermediate;
}

- (void) switchingTools:(BOOL)active
{
}

- (void)endLineDrawing
{
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors*)cursors
{
    if(!IntPointInRect(p, [[[document contents] activeLayer] globalRect])) {
        [[cursors noopCursor] set];
        return;
    }
    if(![[document selection] inSelection:p]){
        [[cursors noopCursor] set];
        return;
    }
    [[self toolCursor:cursors] set];
}

- (NSCursor*)toolCursor:(SeaCursors*)cursors
{
    return [cursors crosspointCursor];
}

@end

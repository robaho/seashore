#import "PluginData.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaSelection.h"
#import "SeaWhiteboard.h"
#import "SeaHelpers.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "EffectTool.h"
#import "SeaTools.h"

@implementation PluginData

- (IntRect)selection
{
	if ([[(SeaDocument *)document selection] active])
		return [[(SeaDocument *)document selection] localRect];
	else
		return IntMakeRect(0, 0, [(SeaLayer *)[[document contents] activeLayer] width], [(SeaLayer *)[[document contents] activeLayer] height]);
}

- (bool)inSelection:(IntPoint)point
{
    SeaLayer *layer = [[document contents] activeLayer];

    return [[(SeaDocument*)document selection] inSelection:IntOffsetPoint(point,[layer xoff],[layer yoff])];
}

- (unsigned char *)data
{
	return [[[document contents] activeLayer] data];
}

- (CGImageRef)bitmap
{
    return [[[document contents] activeLayer] bitmap];
}

- (unsigned char *)replace
{
	return [[document whiteboard] replace];
}

- (unsigned char *)overlay
{
	return [[document whiteboard] overlay];
}

- (int)spp
{
	return [[document contents] spp];
}

- (int)channel
{
    return [[document contents] selectedChannel];	
}

- (int)width
{
	return [[[document contents] activeLayer] width];
}

- (int)height
{
	return [[[document contents] activeLayer] height];
}

- (BOOL)hasAlpha
{
	return [[[document contents] activeLayer] hasAlpha];
}

- (IntPoint)point:(int)index;
{
	return [(EffectTool*)[[document tools] getTool:kEffectTool] point:index];
}

- (NSColor *)foreColor
{
    return [[document contents] foreground];
}

- (NSColor *)backColor
{
    return [[document contents] background];
}

- (void)setOverlayBehaviour:(int)value
{
	[[document whiteboard] setOverlayBehaviour:value];
}

- (void)setOverlayOpacity:(int)value
{
	[[document whiteboard] setOverlayOpacity:value];
}

- (void)settingsChanged
{
    EffectTool *tool = [[document tools] getTool:kEffectTool];
    [tool settingsChanged];
}

- (void)apply
{
    [[document helpers] overlayChanged:[self selection]];
	[[document helpers] applyOverlay];
}

- (void)preview
{
	[[document helpers] overlayChanged:[self selection]];
}

- (void)cancel
{
	[[document whiteboard] clearOverlay];
}

@end

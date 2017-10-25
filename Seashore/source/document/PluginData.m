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

- (unsigned char *)data
{
	return [(SeaLayer *)[[document contents] activeLayer] data];
}

- (unsigned char *)whiteboardData
{
	return [(SeaWhiteboard *)[document whiteboard] data];
}

- (unsigned char *)replace
{
	return [(SeaWhiteboard *)[document whiteboard] replace];
}

- (unsigned char *)overlay
{
	return [(SeaWhiteboard *)[document whiteboard] overlay];
}

- (int)spp
{
	return [[document contents] spp];
}

- (int)channel
{
	if ([[(SeaDocument *)document selection] floating])
		return kAllChannels;
	else
		return [[document contents] selectedChannel];	
}

- (int)width
{
	return [(SeaLayer *)[[document contents] activeLayer] width];
}

- (int)height
{
	return [(SeaLayer *)[[document contents] activeLayer] height];
}

- (BOOL)hasAlpha
{
	return [(SeaLayer *)[[document contents] activeLayer] hasAlpha];
}

- (IntPoint)point:(int)index;
{
	return [[[document tools] getTool:kEffectTool] point:index];
}

- (NSColor *)foreColor:(BOOL)calibrated
{
	if (calibrated)
		if ([[document contents] spp] == 2)
			return [[[document contents] foreground] colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
		else
			return [[[document contents] foreground] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	else
		return [[document contents] foreground];
}

- (NSColor *)backColor:(BOOL)calibrated
{
	if (calibrated)
		if ([[document contents] spp] == 2)
			return [[[document contents] background] colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
		else
			return [[[document contents] background] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	else
		return [[document contents] background];
}

- (CGColorSpaceRef)displayProf
{
	return [[document whiteboard] displayProf];
}

- (id)window
{
	if ([[SeaController seaPrefs] effectsPanel])
		return NULL;
	else
		return [document window];
}

- (void)setOverlayBehaviour:(int)value
{
	[[document whiteboard] setOverlayBehaviour:value];
}

- (void)setOverlayOpacity:(int)value
{
	[[document whiteboard] setOverlayOpacity:value];
}

- (void)applyWithNewDocumentData:(unsigned char *)data spp:(int)spp width:(int)width height:(int)height
{
	NSDocument *newDocument;
	
	if (data == NULL || data == [(SeaWhiteboard *)[document whiteboard] data] || data == [(SeaLayer *)[[document contents] activeLayer] data]) {
		NSRunAlertPanel(@"Critical Plug-in Malfunction", @"The plug-in has returned the same pointer passed to it (or returned NULL). This is a critical malfunction, please refrain from further use of this plug-in and contact the plug-in's developer.", @"Ok", NULL, NULL);
	}
	else {
		newDocument = [[SeaDocument alloc] initWithData:data type:(spp == 4) ? 0 : 1 width:width height:height];
		[[NSDocumentController sharedDocumentController] addDocument:newDocument];
		[newDocument makeWindowControllers];
		[newDocument showWindows];
		[newDocument autorelease];
	}
}

- (void)apply
{
	[(SeaHelpers *)[document helpers] applyOverlay];
}

- (void)preview
{
	[(SeaHelpers *)[document helpers] overlayChanged:[self selection] inThread:NO];
}

- (void)cancel
{
	[(SeaWhiteboard *)[document whiteboard] clearOverlay];
	[(SeaHelpers *)[document helpers] overlayChanged:[self selection] inThread:NO];
}

@end

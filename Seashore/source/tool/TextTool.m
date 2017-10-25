#import "TextTool.h"
#import "SeaLayer.h"
#import "SeaWhiteboard.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "StandardMerge.h"
#import "SeaTools.h"
#import "SeaHelpers.h"
#import "TextOptions.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "SeaTexture.h"
#import "Bucket.h"
#import "Bitmap.h"
#import "OptionsUtility.h"

extern id gNewFont;

@implementation TextTool

- (int)toolId
{
	return kTextTool;
}

- (id)init
{
	if(![super init])
		return NULL;
	// Set up the font manager
	fontManager = [NSFontManager sharedFontManager];
	running = NO;
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)mouseUpAt:(IntPoint)iwhere withEvent:(NSEvent *)theEvent
{
	// Display the preview text box
	where = iwhere;
	running = YES;
	previewRect = IntMakeRect(0, 0, 0, 0);
	[textbox setUsesFontPanel:NO];
	[panel setAlphaValue:0.6];
	[movePanel setAlphaValue:0.6];
	[self preview:NULL];
	[NSApp beginSheet:panel modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IntRect)drawOverlay
{
	int i, j, k, width, height, spp = [[document contents] spp], ispp, ispp2 = 0;
	NSFont *font;
	IntSize fontSize;
	NSDictionary *attributes;
	unsigned char *bitmapData, *bitmapData2 = NULL, *initData, *initData2, *overlay, *data, *replace;
	unsigned char basePixel[4];
	NSColor *color;
	NSString *text;
	IntPoint pos, off;
	id layer, activeTexture = [[[SeaController utilitiesManager] textureUtilityFor:document] activeTexture];
	NSBitmapImageRep *initRep, *initRep2 = NULL, *imageRep, *imageRep2 = NULL;
	NSImage *image, *image2 = NULL;
	NSMutableParagraphStyle *paraStyle;
	int slantWidth;
	int outline = [options outline];
	
	// Set up the colour
	if ([options useTextures])
		color = [activeTexture textureAsNSColor:(spp == 4)];
	else
		color = [[document contents] foreground];
	[[document whiteboard] setOverlayBehaviour:kReplacingBehaviour];
	[[document whiteboard] setOverlayOpacity:255];
	
	// Get the font
	font = (gNewFont) ? gNewFont : [fontManager selectedFont];
	if (font == NULL) return IntMakeRect(0, 0, 0, 0);
	paraStyle = [[NSMutableParagraphStyle alloc] init];
	[paraStyle setAlignment:[options alignment]];
	if (outline)
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, color, NSForegroundColorAttributeName, paraStyle, NSParagraphStyleAttributeName, [NSNumber numberWithInt:outline], NSStrokeWidthAttributeName, NULL];
	else
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, color, NSForegroundColorAttributeName, paraStyle, NSParagraphStyleAttributeName, NULL];
	[paraStyle autorelease];
	text = [[textbox textStorage] string];
	fontSize = NSSizeMakeIntSize([text sizeWithAttributes:attributes]);
	fontSize.width += [[NSString stringWithString:@"x"] sizeWithAttributes:attributes].width;
	slantWidth = ceil(MAX(sin([font italicAngle]) * [font pointSize], 0.0));
	if (outline) slantWidth += (outline + 1) / 2;
	fontSize.width += slantWidth * 2;
	overlay = [[document whiteboard] overlay];
	replace = [[document whiteboard] replace];
	layer = [[document contents] activeLayer];
	data = [(SeaLayer *)layer data];
	width = [(SeaLayer *)layer width];
	height = [(SeaLayer *)layer height];
	
	// Determine the position
	switch([options alignment]){
		case NSRightTextAlignment:
			pos.x = where.x - fontSize.width;
			break;
		case NSCenterTextAlignment:
			pos.x = where.x - (int)round(fontSize.width / 2);
			break;
		default:
			pos.x = where.x;
			break;
	}
	pos.y = where.y - [font ascender];
	off.x = [(SeaLayer *)layer xoff];
	off.y = [(SeaLayer *)layer yoff];
	
	// Create the initial data
	if ([options allowFringe]) {
		initData = [[document contents] bitmapUnderneath:IntMakeRect(off.x + pos.x, off.y + pos.y, fontSize.width, fontSize.height)];
		initData2 = calloc(fontSize.width * fontSize.height * spp, sizeof(unsigned char));
	}
	else {
		initData = malloc(fontSize.width * fontSize.height * spp);
		for (j = 0; j < fontSize.height; j++) {
			for (i = 0; i < fontSize.width; i++) {
				if (pos.y + j < height && pos.x + i < width) {
					for (k = 0; k < spp; k++)
						initData[(j * fontSize.width + i) * spp + k] = data[((pos.y + j) * width + pos.x + i) * spp + k];
				}
				else {
					for (k = 0; k < spp; k++)
						initData[(j * fontSize.width + i) * spp + k] = 0;
				}
			}
		}
	}
	
	// Draw the text
	if (![options allowFringe]) premultiplyBitmap(spp, initData, initData, fontSize.height * fontSize.width);
	initRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&initData pixelsWide:fontSize.width pixelsHigh:fontSize.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:fontSize.width * spp bitsPerPixel:8 * spp];
	image = [[NSImage alloc] initWithSize:IntSizeMakeNSSize(fontSize)];
	[image addRepresentation:initRep];
	[image lockFocus];
	[text drawInRect:NSMakeRect(slantWidth, 0.0, fontSize.width - slantWidth, fontSize.height) withAttributes:attributes];
	imageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, [(NSImage *)image size].width, [(NSImage *)image size].height)];
	[image unlockFocus];
	ispp = [imageRep samplesPerPixel];
	bitmapData = [imageRep bitmapData];
	if (ispp == 4) unpremultiplyBitmap(ispp, bitmapData, bitmapData, fontSize.height * fontSize.width);
	if ([options allowFringe]) unpremultiplyBitmap(spp, initData, initData, fontSize.height * fontSize.width);
	
	// Calculate fringe mask
	if ([options allowFringe]) {
		initRep2 = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&initData2 pixelsWide:fontSize.width pixelsHigh:fontSize.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:fontSize.width * spp bitsPerPixel:8 * spp];
		image2 = [[NSImage alloc] initWithSize:IntSizeMakeNSSize(fontSize)];
		[image2 addRepresentation:initRep2];
		[image2 lockFocus];
		[text drawInRect:NSMakeRect(slantWidth, 0.0, fontSize.width - slantWidth, fontSize.height) withAttributes:attributes];
		imageRep2 = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, [(NSImage *)image2 size].width, [(NSImage *)image2 size].height)];
		[image2 unlockFocus];
		ispp2 = [imageRep2 samplesPerPixel];
		bitmapData2 = [imageRep2 bitmapData];
		if (ispp2 == 4) unpremultiplyBitmap(ispp2, bitmapData2, bitmapData2, fontSize.height * fontSize.width);
	}
	
	// Go through all pixels and change them
	basePixel[spp - 1] = 0xFF;
	for (j = 0; j < fontSize.height; j++) {
		for (i = 0; i < fontSize.width; i++) {
			if (pos.x + i >= 0 && pos.y + j >= 0 && pos.x + i < width && pos.y + j < height) {
				for (k = 0; k < ispp; k++)
					basePixel[k] = bitmapData[(j * fontSize.width + i) * ispp + k];
				for (k = 0; k < spp; k++)
					overlay[((pos.y + j) * width + pos.x + i) * spp + k] = basePixel[k];
				
				if ([options allowFringe] && (ispp2 == 2 || ispp2 == 4)) {
					if (bitmapData2[(j * fontSize.width + i + 1) * ispp2 - 1] == 0)
						replace[(pos.y + j) * width + pos.x + i] = 0;
					else
						replace[(pos.y + j) * width + pos.x + i] = 255;
				}
				else {
					replace[(pos.y + j) * width + pos.x + i] = 255;
				}
			
			}
		}
	}
	
	// Clean-up everything
	[image autorelease];
	[imageRep autorelease];
	[initRep autorelease];
	if ([options allowFringe]) {
		[image2 autorelease];
		[imageRep2 autorelease];
		[initRep2 autorelease];
	}
	free(initData);
	
	return IntMakeRect(pos.x, pos.y, fontSize.width, fontSize.height);
}

- (IBAction)apply:(id)sender
{	
	// End the panel
	if (sender != NULL) {
		[NSApp stopModal];
		[NSApp endSheet:panel];
		[panel orderOut:self];
	}
	running = NO;
	
	// Apply the changes
	[[document whiteboard] clearOverlay];
	if ([[[textbox textStorage] string] length] > 0) {
		[self drawOverlay];
		[(SeaHelpers *)[document helpers] applyOverlay];
	}
}

- (IBAction)cancel:(id)sender
{
	// End the panel
	[[document whiteboard] clearOverlay];
	if (previewRect.size.width != 0) {
		[[document helpers] overlayChanged:previewRect inThread:NO];
	}
	running = NO;
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
}

- (IBAction)preview:(id)sender
{
	// Apply the changes
	if (running) {
		[[document whiteboard] clearOverlay];
		if (previewRect.size.width != 0) {
			[[document helpers] overlayChanged:previewRect inThread:NO];
		}
		if ([[[textbox textStorage] string] length] > 0) {
			previewRect = [self drawOverlay];
			[[document helpers] overlayChanged:previewRect inThread:NO];
		}
	}
}

- (IBAction)showFonts:(id)sender
{
	[fontManager orderFrontFontPanel:self];
}

- (void)textDidChange:(NSNotification *)notification
{
	[self preview:notification];
}

- (IBAction)move:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	[NSApp beginSheet:movePanel modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)doneMove:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:movePanel];
	[movePanel orderOut:self];
	[self apply:NULL];
}

- (IBAction)cancelMove:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:movePanel];
	[movePanel orderOut:self];
	[NSApp beginSheet:panel modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (void)setNudge:(IntPoint)nudge
{
	where.x += nudge.x;
	where.y += nudge.y;
	[self preview:NULL];
}

- (void)centerHorizontally
{
	IntSize fontSize;
	NSDictionary *attributes;
	NSString *text;
	int width;
	id layer;
	
	layer = [[document contents] activeLayer];
	attributes = [NSDictionary dictionaryWithObjectsAndKeys:[fontManager selectedFont], NSFontAttributeName, NULL];
	text = [[textbox textStorage] string];
	fontSize = NSSizeMakeIntSize([text sizeWithAttributes:attributes]);
	width = [(SeaLayer *)layer width];
	where.x = width / 2 - fontSize.width / 2;
	[self preview:NULL];
}

- (void)centerVertically
{
	IntSize fontSize;
	NSDictionary *attributes;
	NSString *text;
	int height;
	id layer, font;
	
	layer = [[document contents] activeLayer];
	font = [fontManager selectedFont];
	attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, NULL];
	text = [[textbox textStorage] string];
	fontSize = NSSizeMakeIntSize([text sizeWithAttributes:attributes]);
	height = [(SeaLayer *)layer height];
	where.y = height / 2 + [font ascender] - fontSize.height / 2;
	[self preview:NULL];
}

@end

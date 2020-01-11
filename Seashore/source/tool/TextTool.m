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

- (void)mouseUpAt:(IntPoint)iwhere withEvent:(NSEvent *)theEvent
{
	// Display the preview text box
	where = iwhere;
	running = YES;
	previewRect = IntMakeRect(0, 0, 0, 0);
	[textbox setUsesFontPanel:NO];
    [textbox setTextColor:[NSColor controlTextColor]];
	[panel setAlphaValue:0.75];
	[movePanel setAlphaValue:0.75];
	[self preview:NULL];
	[NSApp beginSheet:panel modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

typedef struct {
    IntRect rect;
    unsigned char *data;
} result;

- (result)drawOverlay:(BOOL)preview
{
	int i, j, k, width, height, spp = [[document contents] spp];
	NSFont *font;
	IntSize fontSize;
	NSDictionary *attributes;
	unsigned char *bitmapData, *initData, *overlay, *data, *replace;
	unsigned char basePixel[4];
	NSColor *color;
	NSString *text;
	IntPoint pos, off;
    SeaLayer *layer;
    id activeTexture = [[document textureUtility] activeTexture];
    NSBitmapImageRep *initRep;
	NSMutableParagraphStyle *paraStyle;
	int slantWidth;
	int outline = [options outline];
    
    result r;
	
	// Set up the colour
	if ([options useTextures])
		color = [activeTexture textureAsNSColor:(spp == 4)];
	else
		color = [[document contents] foreground];
	[[document whiteboard] setOverlayBehaviour:kReplacingBehaviour];
	[[document whiteboard] setOverlayOpacity:255];
	
	// Get the font
	font = (gNewFont) ? gNewFont : [fontManager selectedFont];
    if (font == NULL) {
        r.rect = IntMakeRect(0, 0, 0, 0);
        r.data = NULL;
        return r;
    }
    
	paraStyle = [[NSMutableParagraphStyle alloc] init];
	[paraStyle setAlignment:[options alignment]];
	if (outline)
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, color, NSForegroundColorAttributeName, paraStyle, NSParagraphStyleAttributeName, [NSNumber numberWithInt:outline], NSStrokeWidthAttributeName, NULL];
	else
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, color, NSForegroundColorAttributeName, paraStyle, NSParagraphStyleAttributeName, NULL];
	text = [[textbox textStorage] string];
	fontSize = NSSizeMakeIntSize([text sizeWithAttributes:attributes]);
	fontSize.width += [@"x" sizeWithAttributes:attributes].width;
	slantWidth = ceil(MAX(sin([font italicAngle]) * [font pointSize], 0.0));
	if (outline) slantWidth += (outline + 1) / 2;
	fontSize.width += slantWidth * 2;
	overlay = [[document whiteboard] overlay];
	replace = [[document whiteboard] replace];
	layer = [[document contents] activeLayer];
	data = [layer data];
	width = [layer width];
	height = [layer height];
	
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
	off.x = [layer xoff];
	off.y = [layer yoff];
    
    initData = malloc(fontSize.width * fontSize.height * spp);
    if(!preview && [options shouldAddTextAsNewLayer]) {
        memset(initData,0,fontSize.width * fontSize.height * spp);
    } else {
        // copy background for proper anti-aliasing
        for (j = 0; j < fontSize.height; j++) {
            for (i = 0; i < fontSize.width; i++) {
                int dy = pos.y + j;
                int dx = pos.x + i;
                if (dy>=0 && dy < height && dx>=0 && dx < width) {
                    for (k = 0; k < spp; k++)
                        initData[(j * fontSize.width + i) * spp + k] = data[((dy) * width + dx) * spp + k];
                }
                else {
                    for (k = 0; k < spp; k++)
                        initData[(j * fontSize.width + i) * spp + k] = 0;
                }
            }
        }
    }
    
	// Draw the text
	initRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&initData pixelsWide:fontSize.width pixelsHigh:fontSize.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? MyRGBSpace : MyGraySpace bytesPerRow:fontSize.width * spp bitsPerPixel:8 * spp];
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:initRep];
    ctx.shouldAntialias=TRUE;
    [NSGraphicsContext setCurrentContext:ctx];
    
    unpremultiplyBitmap(spp,initData,initData,fontSize.width*fontSize.height);

    [text drawInRect:NSMakeRect(slantWidth, 0.0, fontSize.width - slantWidth, fontSize.height) withAttributes:attributes];
    
    [NSGraphicsContext restoreGraphicsState];
    
    if(!preview && [options shouldAddTextAsNewLayer]){
        r.rect = IntMakeRect(pos.x,pos.y,fontSize.width,fontSize.height);
        r.data = initData;
        return r;
    }
    
    bitmapData = initData;

	// Go through all pixels and change them
	basePixel[spp - 1] = 0xFF;
	for (j = 0; j < fontSize.height; j++) {
		for (i = 0; i < fontSize.width; i++) {
			if (pos.x + i >= 0 && pos.y + j >= 0 && pos.x + i < width && pos.y + j < height) {
				for (k = 0; k < spp; k++)
					overlay[((pos.y + j) * width + pos.x + i) * spp + k] = bitmapData[(j * fontSize.width + i) * spp + k];
				
                replace[(pos.y + j) * width + pos.x + i] = 255;
			}
		}
	}
	free(initData);
    
    r.rect = IntConstrainRect(IntMakeRect(pos.x, pos.y, fontSize.width, fontSize.height),IntMakeRect(0,0,width,height));
    r.data = NULL;
    return r;
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
    
    [[document whiteboard] clearOverlay];
    if ([[[textbox textStorage] string] length] <= 0) {
        return;
    }
    
    result r = [self drawOverlay:NO];
    
    if(r.data!=NULL){
        NSString *text = [[textbox textStorage] string];
        SeaLayer *activeLayer = [[document contents] activeLayer];
        r.rect = IntOffsetRect(r.rect,[activeLayer xoff],[activeLayer yoff]);
         
        SeaLayer *layer = [[SeaLayer alloc] initWithDocument:document rect:r.rect data:r.data spp:[[document contents] spp]];
        free(r.data);
        
        NSMutableString *name = [[NSMutableString alloc] initWithString:text];
        for(int i=0;i<[name length];i++) {
            if([name characterAtIndex:i]<=32){
                [name replaceCharactersInRange:NSMakeRange(i,1) withString:@"."];
            }
        }
        [layer setName:name];
        [[document contents] addLayerObject:layer];
    } else {
        if(r.rect.size.height<=0 || r.rect.size.width<=0)
            return;
        // Apply the changes into the current layer
        [[document helpers] applyOverlay];
    }
}

- (IBAction)cancel:(id)sender
{
	// End the panel
	[[document whiteboard] clearOverlay];
	if (previewRect.size.width != 0) {
		[[document helpers] overlayChanged:previewRect];
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
			[[document helpers] overlayChanged:previewRect];
		}
		if ([[[textbox textStorage] string] length] > 0) {
            result r = [self drawOverlay:YES];
			[[document helpers] overlayChanged:r.rect];
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

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (TextOptions*)newoptions;
}


@end

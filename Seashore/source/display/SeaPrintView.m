#import "SeaPrintView.h"
#import "SeaView.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaLayer.h"
#import "ToolboxUtility.h"
#import "SeaWhiteboard.h"
#import "SeaTools.h"
#import "PositionTool.h"
#import "PencilTool.h"
#import "BrushTool.h"
#import "SeaLayerUndo.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "SeaPrefs.h"
#import "SeaController.h"

@implementation SeaPrintView

- (id)initWithDocument:(id)doc 
{	
	NSRect frame;
		
	// Remember the document this view is displaying
	document = doc;

	// Determine the frame at 100% 72-dpi
	frame = NSMakeRect(0, 0, [(SeaContent *)[document contents] width] * (72.0 / (float)[[document contents] xres]), [(SeaContent *)[document contents] height] * (72.0 / (float)[[document contents] yres]));

	// Initialize superclass
	if ([super initWithFrame:frame] == NULL)
		return NULL;
	
    return self;
}

- (void)drawRect:(NSRect)rect
{
    NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];
    
    NSRect pbounds = [pi imageablePageBounds];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(0,0,pbounds.size.width,pbounds.size.height)] setClip];
    
    float xoff = (pbounds.size.width-rect.size.width)/2;
    float yoff = (pbounds.size.height-rect.size.height)/2;
    
    NSAffineTransform* xform = [NSAffineTransform transform];
    [xform translateXBy:xoff yBy:yoff];
    [xform concat];

    [[NSColor whiteColor] set];
    [[NSBezierPath bezierPathWithRect:rect] fill];
    
	NSImage *image = NULL;

	// Get the correct image for displaying, this has the correct dpi
	image = [[document whiteboard] printableImage];
	
	// Set the background color
    
	// We want our image flipped
	[image setFlipped:YES];
	
	// Draw the image to screen
    [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (BOOL)knowsPageRange:(NSRangePointer)range
{
    range->length=1;
    range->location=1;
    return YES;
}
- (NSRect)rectForPage:(long)page
{
    int width = [[document contents] width];
    int height = [[document contents] height];
    int xres = [[document contents] xres], yres = [[document contents] yres];

    NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];
    float scale = [pi scalingFactor];
    
    NSRect rect = NSMakeRect(0,0,width*scale*(72.0/xres),height*scale*(72.0/yres));
    [self setFrameSize:rect.size];
    return rect;
}

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)isOpaque
{
	return YES;
}

@end

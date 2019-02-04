#import "SVGContent.h"
#import "SeaController.h"
#import "SeaDocumentController.h"
#import "SeaWarning.h"
#import "CocoaLayer.h"
#import <PocketSVG/PocketSVG.h>

@interface FlippedView : NSView
@end
@implementation FlippedView

extern id layerFromSVG(id doc, SVGLayer *svg,IntSize size);

- (BOOL)isFlipped
{
    return YES;
}
@end

@implementation SVGContent

+ (BOOL)typeIsViewable:(NSString *)aType
{
	return [[SeaDocumentController sharedDocumentController] type: aType isContainedInDocType: @"SVG document"];
}

- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path
{
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
		
	// Load nib file
	[NSBundle loadNibNamed:@"SVGContent" owner:self];

    SVGLayer *svg = [[SVGLayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]];
    
	// Run the scaling panel
	[scalePanel center];
    
    trueSize = IntMakeSize(svg.preferredFrameSize.width,svg.preferredFrameSize.height);
	size.width = trueSize.width; size.height = trueSize.height;
	[sizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", size.width, size.height]];
	[scaleSlider setIntValue:2];
	[NSApp runModalForWindow:scalePanel];
	[scalePanel orderOut:self];
    
    id layer = layerFromSVG(doc, svg, size);
    if(layer==NULL)
        return NULL;
	
	// Determine the height and width of the image
    height = size.height;
    width = size.width;
    type = XCF_RGB_IMAGE;
	
	// Determine the resolution of the image
	xres = yres = 72; 
	
    // Rename the layer
    [(SeaLayer *)layer setName:[[NSString alloc] initWithString:[[path lastPathComponent] stringByDeletingPathExtension]]];
    
    layers = [NSArray arrayWithObject:layer];

	return self;
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (IBAction)update:(id)sender
{
	double factor;
	
	switch ([scaleSlider intValue]) {
		case 0:
			factor = 0.5;
		break;
		case 1:
			factor = 0.75;
		break;
		case 2:
			factor = 1.0;
		break;
		case 3:
			factor = 1.5;
		break;
		case 4:
			factor = 2.0;
		break;
		case 5:
			factor = 3.75;
		break;
		case 6:
			factor = 5.0;
		break;
		case 7:
			factor = 7.5;
		break;
		case 8:
			factor = 10.0;
		break;
		case 9:
			factor = 25.0;
		break;
		case 10:
			factor = 50.0;
		break;
		default:
			factor = 1.0;
		break;
	}
	
	size.width = trueSize.width * factor;
	size.height = trueSize.height * factor;
	
	[sizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", size.width, size.height]];
}

@end

id layerFromSVG(id doc, SVGLayer *svg,IntSize size) {
    int width = size.width;
    int height = size.height;
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height
                                                                      bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
                                                                     colorSpaceName:MyRGBSpace bytesPerRow:width*4
                                                                       bitsPerPixel:8*4];
    
    
    NSView *view = [[FlippedView alloc]init];
    view.layer = svg;
    [svg setFrame:NSMakeRect(0,0,size.width,size.height)];
    [view setFrame:[svg frame]];
    [svg setNeedsDisplay];
    [svg setGeometryFlipped:TRUE];
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep];
    [NSGraphicsContext setCurrentContext:ctx];
    [view displayRectIgnoringOpacity:[svg frame] inContext:ctx];
    [NSGraphicsContext restoreGraphicsState];
    
    return [[CocoaLayer alloc] initWithImageRep:imageRep document:doc spp:4];
}

#import "SVGImporter.h"
#import "CocoaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaView.h"
#import "CenteringClipView.h"
#import "SeaOperations.h"
#import "SeaAlignment.h"
#import "SeaController.h"
#import "SeaWarning.h"

#include <PocketSVG/PocketSVG.h>

@interface FlippedView : NSView
@end
@implementation FlippedView

- (BOOL)isFlipped
{
    return YES;
}
@end

@implementation SVGImporter

- (BOOL)addToDocument:(id)doc contentsOfFile:(NSString *)path
{
    SeaLayer *layer = [self loadSVGLayer:doc path:path];
    if(layer==NULL)
        return NO;
    
	// Rename the layer
	[layer setName:[[NSString alloc] initWithString:[[path lastPathComponent] stringByDeletingPathExtension]]];
	
	// Add the layer
	[[doc contents] addLayerObject:layer];
	
	// Position the new layer correctly
	[[(SeaOperations *)[doc operations] seaAlignment] centerLayerHorizontally:NULL];
	[[(SeaOperations *)[doc operations] seaAlignment] centerLayerVertically:NULL];
	
	return YES;
}

- (SeaLayer*)loadSVGLayer:(id)doc path:(NSString*)path
{
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

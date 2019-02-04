#import "SVGContent.h"
#import "SeaController.h"
#import "SeaDocumentController.h"
#import "SeaWarning.h"
#import "CocoaLayer.h"
#import "SVGImporter.h"
#import "SeaLayer.h"

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
    
    SeaLayer *layer = [[[SVGImporter alloc] init] loadSVGLayer:doc path:path];
    if(layer==NULL)
        return NULL;
		
	// Load nib file
	
	// Determine the height and width of the image
    height = layer.height;
    width = layer.width;
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


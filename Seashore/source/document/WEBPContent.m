#import "WEBPContent.h"
#import "SeaController.h"
#import "SeaDocumentController.h"
#import "CocoaLayer.h"
#import "WEBPImporter.h"
#import "SeaLayer.h"

@implementation WEBPContent

+ (BOOL)typeIsEditable:(NSString *)aType
{
	return [[SeaDocumentController sharedDocumentController] type: aType isContainedInDocType: @"WEBP image"];
}

- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path
{
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
    
    SeaLayer *layer = [[[WEBPImporter alloc] init] loadLayer:doc path:path];
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
    [(SeaLayer *)layer setName:[[NSString alloc] initWithString:[path lastPathComponent]]];
    
    layers = [NSArray arrayWithObject:layer];

	return self;
}

@end


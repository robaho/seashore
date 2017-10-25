#import "SeaApplication.h"
#import "SeaDocumentController.h"

@implementation SeaApplication

- (unsigned int)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return NSFontPanelFaceModeMask | NSFontPanelSizeModeMask | NSFontPanelCollectionModeMask;
}

@end

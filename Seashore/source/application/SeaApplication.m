#import "SeaApplication.h"
#import "SeaDocumentController.h"

@implementation SeaApplication

- (unsigned int)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return NSFontPanelFaceModeMask | NSFontPanelSizeModeMask | NSFontPanelCollectionModeMask;
}

- (void)terminate:(_Nullable id)sender
{
    [super terminate:sender];
}




@end

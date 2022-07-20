#import "CropOptions.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaDocument.h"
#import "SeaTools.h"
#import "CropTool.h"
#import "SeaMargins.h"
#import "SeaOperations.h"
#import "SeaContent.h"
#import "AspectRatio.h"
#import "SeaLayer.h"

#define customItemIndex 2

@implementation CropOptions

- (void)awakeFromNib
{	
	[aspectRatio awakeWithMaster:self andString:@"crop"];
}

- (NSSize)ratio
{
	return [aspectRatio ratio];
}

- (int)aspectType
{
	return [aspectRatio aspectType];
}

- (IBAction)cropImage:(id)sender
{
	IntRect cropRect;
	int width, height;
	
	cropRect = [(CropTool*)[document currentTool] cropRect];
	if (cropRect.size.width < kMinImageSize) { NSBeep(); return; }
	if (cropRect.size.height < kMinImageSize) { NSBeep(); return; }
	if (cropRect.size.width > kMaxImageSize) { NSBeep(); return; }
	if (cropRect.size.height > kMaxImageSize) { NSBeep(); return; }
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	[(SeaMargins *)[(SeaOperations *)[document operations] seaMargins] setMarginLeft:-cropRect.origin.x top:-cropRect.origin.y right:(cropRect.origin.x + cropRect.size.width) - width bottom:(cropRect.origin.y + cropRect.size.height) - height index:kAllLayers];
    [(CropTool*)[document currentTool] clearCrop];
}

- (IBAction)cropLayer:(id)sender {
    IntRect cropRect;
    int width, height;
    
    int index = [[document contents] activeLayerIndex];
    SeaLayer *activeLayer = [[document contents] layer:index];
    
    cropRect = [(CropTool*)[document currentTool] cropRect];
    cropRect = IntConstrainRect([activeLayer globalRect], cropRect);
    
    cropRect.origin.x -= [activeLayer xoff];
    cropRect.origin.y -= [activeLayer yoff];

    if (cropRect.size.width < kMinImageSize) { NSBeep(); return; }
    if (cropRect.size.height < kMinImageSize) { NSBeep(); return; }
    if (cropRect.size.width > kMaxImageSize) { NSBeep(); return; }
    if (cropRect.size.height > kMaxImageSize) { NSBeep(); return; }
    
    width = [activeLayer width];
    height = [activeLayer height];
    
    [(SeaMargins *)[(SeaOperations *)[document operations] seaMargins] setMarginLeft:-cropRect.origin.x top:-cropRect.origin.y right:(cropRect.origin.x + cropRect.size.width) - width bottom:(cropRect.origin.y + cropRect.size.height) - height index:index];
    
    [(CropTool*)[document currentTool] clearCrop];
}

- (void)shutdown
{
	[aspectRatio shutdown];
}

@end

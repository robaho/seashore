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
	
	cropRect = [[document currentTool] cropRect];
	if (cropRect.size.width < kMinImageSize) { NSBeep(); return; }
	if (cropRect.size.height < kMinImageSize) { NSBeep(); return; }
	if (cropRect.size.width > kMaxImageSize) { NSBeep(); return; }
	if (cropRect.size.height > kMaxImageSize) { NSBeep(); return; }
	width = [(SeaContent *)[gCurrentDocument contents] width];
	height = [(SeaContent *)[gCurrentDocument contents] height];
	[(SeaMargins *)[(SeaOperations *)[gCurrentDocument operations] seaMargins] setMarginLeft:-cropRect.origin.x top:-cropRect.origin.y right:(cropRect.origin.x + cropRect.size.width) - width bottom:(cropRect.origin.y + cropRect.size.height) - height index:kAllLayers];
    [[gCurrentDocument currentTool] clearCrop];
}

- (IBAction)cropLayer:(id)sender {
    IntRect cropRect;
    int width, height;
    
    int index = [[document contents] activeLayerIndex];
    SeaLayer *activeLayer = [[document contents] layer:index];
    
    cropRect = [[document currentTool] cropRect];
    cropRect = IntConstrainRect([activeLayer localRect], cropRect);
    
    cropRect.origin.x -= [activeLayer xoff];
    cropRect.origin.y -= [activeLayer yoff];

    if (cropRect.size.width < kMinImageSize) { NSBeep(); return; }
    if (cropRect.size.height < kMinImageSize) { NSBeep(); return; }
    if (cropRect.size.width > kMaxImageSize) { NSBeep(); return; }
    if (cropRect.size.height > kMaxImageSize) { NSBeep(); return; }
    
    width = [activeLayer width];
    height = [activeLayer height];
    
    [(SeaMargins *)[(SeaOperations *)[document operations] seaMargins] setMarginLeft:-cropRect.origin.x top:-cropRect.origin.y right:(cropRect.origin.x + cropRect.size.width) - width bottom:(cropRect.origin.y + cropRect.size.height) - height index:index];
    
    [[document currentTool] clearCrop];
}



- (void)shutdown
{
	[aspectRatio shutdown];
}

@end

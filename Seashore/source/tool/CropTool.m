#import "CropTool.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "CropOptions.h"
#import "SeaContent.h"
#import "SeaTools.h"
#import "AspectRatio.h"
#import "SeaLayer.h"

@implementation CropTool

- (int)toolId
{
	return kCropTool;
}	

- (id)init
{
	if(![super init])
		return NULL;
	
	cropRect.size.width = cropRect.size.height = 0;
	return self;
}

- (void)cropRectChanged:(IntRect)dirty
{
    [[document helpers] selectionChanged:dirty];
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    int modifier = [(CropOptions*)options modifier];
    
    if (modifier == kControlModifier) {
        [self clearCrop];
    }
    
    [self mouseDownAt: where
              forRect: cropRect
         withMaskRect: IntZeroRect
              andMask: NULL];

    cropRect = [super postScaledRect];
    [[document helpers] selectionChanged];
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	IntRect draggedRect = [self mouseDraggedTo: where
									   forRect: cropRect
									   andMask: NULL];

    [self setCropRect:draggedRect];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [self mouseDraggedTo:where withEvent:event];
    [self mouseUpAt:where forRect:IntZeroRect andMask:NULL];
    [[document helpers] selectionChanged];
}

- (void)aspectChanged
{
    IntRect old = cropRect;
    [super aspectChanged];
    cropRect = [super postScaledRect];
    [self cropRectChanged:IntSumRects(old,cropRect)];
}

- (IntRect)cropRect
{
    return cropRect;
}

- (void)clearCrop
{
	cropRect.size.width = cropRect.size.height = 0;
	[[document helpers] selectionChanged];
}

- (void)adjustCrop:(IntPoint)offset
{
    IntRect old = cropRect;
	cropRect.origin.x += offset.x;
	cropRect.origin.y += offset.y;
    [self cropRectChanged:IntSumRects(old,cropRect)];
}

- (void)setCropRect:(IntRect)newCropRect
{
    IntRect old = cropRect;
	cropRect = newCropRect;
    [self cropRectChanged:IntSumRects(old,cropRect)];
}

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (CropOptions*)newoptions;
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors*)cursors
{
    return [cursors handleRectCursors:cropRect point:p cursor:[cursors crosspointCursor]];
}


@end

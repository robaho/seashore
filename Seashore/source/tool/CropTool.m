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

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	if(cropRect.size.width > 0 && cropRect.size.height > 0){
		[self mouseDownAt: where
				  forRect: cropRect
				  andMask: NULL];
	}
	
	if(![self isMovingOrScaling]){
		int aspectType = [options aspectType];
		NSSize ratio;
		double xres, yres;
		int modifier = [(CropOptions*)options modifier];
		id activeLayer;
		
		// Make where appropriate
		activeLayer = [[document contents] activeLayer];
		where.x += [activeLayer xoff];
		where.y += [activeLayer yoff];
		
		// Check if location is in existing rect
		startPoint = where;
		
		// Start the cropping rectangle
		oneToOne = (modifier == kShiftModifier);
		if (aspectType == kNoAspectType || aspectType == kRatioAspectType || oneToOne) {
			cropRect.origin.x = startPoint.x;
			cropRect.origin.y = startPoint.y;
			cropRect.size.width = 0;
			cropRect.size.height = 0;
		}
		else {
			ratio = [options ratio];
			cropRect.origin.x = startPoint.x;
			cropRect.origin.y = startPoint.y;
			xres = [[document contents] xres];
			yres = [[document contents] yres];
			switch (aspectType) {
				case kExactPixelAspectType:
					cropRect.size.width = ratio.width;
					cropRect.size.height = ratio.height;
				break;
				case kExactInchAspectType:
					cropRect.size.width = ratio.width * xres;
					cropRect.size.height = ratio.height * yres;
				break;
				case kExactMillimeterAspectType:
					cropRect.size.width = ratio.width * xres * 0.03937;
					cropRect.size.height = ratio.height * yres * 0.03937;
				break;
			}
			[[document helpers] selectionChanged];
		}
	}
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	IntRect draggedRect = [self mouseDraggedTo: where
									   forRect: cropRect
									   andMask: NULL];
	
	if(![self isMovingOrScaling]){
	
		int aspectType = [options aspectType];
		NSSize ratio;
		id activeLayer;
		
		// Make where appropriate
		activeLayer = [[document contents] activeLayer];
		where.x += [activeLayer xoff];
		where.y += [activeLayer yoff];
		
		if (aspectType == kNoAspectType || aspectType == kRatioAspectType || oneToOne) {

			// Determine the width of the cropping rectangle
			if (startPoint.x < where.x) {
				cropRect.origin.x = startPoint.x;
				cropRect.size.width = where.x - startPoint.x;
			}
			else {
				cropRect.origin.x = where.x;
				cropRect.size.width = startPoint.x - where.x;
			}
			
			// Determine the height of the cropping rectangle
			if (oneToOne) {
				if (startPoint.y < where.y) {
					cropRect.size.height = cropRect.size.width;
					cropRect.origin.y = startPoint.y;
				}
				else {
					cropRect.size.height = cropRect.size.width;
					cropRect.origin.y = startPoint.y - cropRect.size.height;
				}
			}
			else if (aspectType == kRatioAspectType) {
				ratio = [options ratio];
				if (startPoint.y < where.y) {
					cropRect.size.height = cropRect.size.width * ratio.height;
					cropRect.origin.y = startPoint.y;
				}
				else {
					cropRect.size.height = cropRect.size.width * ratio.height;
					cropRect.origin.y = startPoint.y - cropRect.size.height;
				}
			}
			else {
				if (startPoint.y < where.y) {
					cropRect.origin.y = startPoint.y;
					cropRect.size.height = where.y - startPoint.y;
				}
				else {
					cropRect.origin.y = where.y;
					cropRect.size.height = startPoint.y - where.y;
				}
			}
			
		}
		else {
		
			cropRect.origin.x = where.x;
			cropRect.origin.y = where.y;
			
		}

		// Update the changes
		[[document helpers] selectionChanged];
	} else {
		[self setCropRect:draggedRect];
	}

}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[self mouseDraggedTo:where withEvent:event];
	
	scalingDir = kNoDir;
	translating = NO;
}

- (IntRect)cropRect
{
	int width, height;
	
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	return IntConstrainRect(cropRect, IntMakeRect(0, 0, width, height));
}

- (void)clearCrop
{
	cropRect.size.width = cropRect.size.height = 0;
	[[document helpers] selectionChanged];
}

- (void)adjustCrop:(IntPoint)offset
{
	cropRect.origin.x += offset.x;
	cropRect.origin.y += offset.y;
	[[document helpers] selectionChanged];
}

- (void)setCropRect:(IntRect)newCropRect
{
	cropRect = newCropRect;
	[[document helpers] selectionChanged];
}


@end

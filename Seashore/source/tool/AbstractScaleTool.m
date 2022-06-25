#import "AbstractScaleTool.h"
#import "AbstractTool.h"
#import "SeaController.h"
#import "OptionsUtility.h"
#import "SeaController.h"
#import "TextureUtility.h"
#import "AbstractSelectOptions.h"
#import "SeaSelection.h"
#import "AbstractScaleTool.h"
#import "AbstractScaleOptions.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaHelpers.h"
#import "AspectRatio.h"
#import "SeaLayer.h"

@implementation AbstractScaleTool
- (id)init
{
	if (![super init])
		return NULL;

	translating = NO;
	scalingDir = kNoDir;

	return self;
}

- (BOOL) isMovingOrScaling
{
	return (translating || scalingDir > kNoDir);
}

- (AbstractScaleOptions*)scaleOptions {
    return (AbstractScaleOptions*)[self getOptions];
}

- (void)mouseDownAt:(IntPoint)localPoint forRect:(IntRect)globalRect withMaskRect:(IntRect)maskRect andMask:(unsigned char *)mask
{
	translating = NO;
	scalingDir = kNoDir;
	
    SeaLayer *layer = [[document contents] activeLayer];
    IntPoint globalPoint = IntOffsetPoint(localPoint, [layer xoff], [layer yoff]);

	if([[self scaleOptions] ignoresMove]){
        preScaledRect = IntMakeRect(globalPoint.x,globalPoint.y,0,0);
		return;
	}
	
	// We need the global point for the handles
	// Check if location is in existing rect
    scalingDir = getHandle(globalPoint,globalRect,[[document scrollView] magnification]);

	// But the local rect for the moving
    IntRect localRect = IntOffsetRect(globalRect,-[layer xoff],-[layer yoff]);

	if(scalingDir > kNoDir){
        preScaledRect = globalRect;

        if(mask){
            int len = preScaledRect.size.width * preScaledRect.size.height;
			preScaledMask = malloc(len);
            memcpy(preScaledMask, mask, len);
		} else {
			preScaledMask = NULL;
		}
	} else if (IntPointInRect(localPoint, localRect) ){
		// 2. Moving Selection
		translating = YES;
		moveOrigin = localPoint;
    } else {
        preScaledRect = IntMakeRect(globalPoint.x,globalPoint.y,0,0);
        
        NSSize ratio = [[self scaleOptions] ratio];
        int aspectType = [[self scaleOptions] aspectType];
        double xres = [[document contents] xres];
        double yres = [[document contents] yres];

        switch (aspectType) {
            case kExactPixelAspectType:
                preScaledRect.size.width = ratio.width;
                preScaledRect.size.height = ratio.height;
                break;
            case kExactInchAspectType:
                preScaledRect.size.width = ratio.width * xres;
                preScaledRect.size.height = ratio.height * yres;
                break;
            case kExactMillimeterAspectType:
                preScaledRect.size.width = ratio.width * xres * 0.03937;
                preScaledRect.size.height = ratio.height * yres * 0.03937;
                break;
        }
    }

    postScaledRect = preScaledRect;
}

- (IntRect)mouseDraggedTo:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask
{
    BOOL usesAspect = NO;
    NSSize ratio = [[self scaleOptions] ratio];
    int aspectType = [[self scaleOptions] aspectType];

    if ([[self scaleOptions] isOneToOne]) {
        ratio = NSMakeSize(1, 1);
        aspectType = kRatioAspectType;
    }

    SeaLayer *layer = [[document contents] activeLayer];
    NSPoint globalPoint = IntPointMakeNSPoint(IntOffsetPoint(localPoint, [layer xoff], [layer yoff]));

	if(scalingDir > kNoDir){

		float newHeight = preScaledRect.size.height;
		float newWidth  = preScaledRect.size.width;
		float newX = preScaledRect.origin.x;
		float newY = preScaledRect.origin.y;

        if(aspectType == kRatioAspectType){
            usesAspect = YES;
        }

		switch(scalingDir){
			case kULDir:
				newWidth = preScaledRect.origin.x -  globalPoint.x + preScaledRect.size.width;
				newX = globalPoint.x;
				if(usesAspect){
					newHeight = newWidth * ratio.height;
					newY = preScaledRect.origin.y + preScaledRect.size.height - newHeight;
				}else{
					newHeight = preScaledRect.origin.y - globalPoint.y + preScaledRect.size.height;
					newY = globalPoint.y;
				}
				break;
			case kUDir:
				newHeight = preScaledRect.origin.y - globalPoint.y + preScaledRect.size.height;
				newY = globalPoint.y;
				break;
			case kURDir:
				newWidth = globalPoint.x - preScaledRect.origin.x;
				if(usesAspect){
					newHeight = newWidth * ratio.height;
					newY = preScaledRect.origin.y + preScaledRect.size.height - newHeight;
				}else{
					newHeight = preScaledRect.origin.y - globalPoint.y + preScaledRect.size.height;
					newY = globalPoint.y;
				}
				break;
			case kRDir:
				newWidth = globalPoint.x - preScaledRect.origin.x;
				break;
			case kDRDir:
				newWidth = globalPoint.x - preScaledRect.origin.x;
				if(usesAspect){
					newHeight = newWidth * ratio.height;
				}else{
					newHeight = globalPoint.y - preScaledRect.origin.y;
				}
				break;
			case kDDir:
				newHeight = globalPoint.y - preScaledRect.origin.y;
				break;
			case kDLDir:
				newX = globalPoint.x;
				newWidth = preScaledRect.origin.x -  globalPoint.x + preScaledRect.size.width;
				if(usesAspect){
					newHeight = newWidth * ratio.height;
				}else{
					newHeight = globalPoint.y - preScaledRect.origin.y;
				}
				break;
			case kLDir:
				newX = globalPoint.x;
				newWidth = preScaledRect.origin.x -  globalPoint.x + preScaledRect.size.width;
				break;
			default:
				NSLog(@"Scaling direction not supported.");
		}

		return IntMakeRect((int)newX, (int)newY, (int)newWidth, (int)newHeight);
	} else if (translating) {
        return IntMakeRect(0,0,0,0);
    } else {
        if (aspectType == kNoAspectType || aspectType == kRatioAspectType) {

            IntPoint startPoint = preScaledRect.origin;

            // Determine the width of the selection rectangle
            if (startPoint.x < globalPoint.x) {
                postScaledRect.size.width = globalPoint.x - startPoint.x;
                postScaledRect.origin.x = startPoint.x;
            } else {
                postScaledRect.origin.x = globalPoint.x;
                postScaledRect.size.width = startPoint.x - globalPoint.x;
            }

            // Determine the height of the selection rectangle
            if (aspectType == kRatioAspectType) {
                if (startPoint.y < globalPoint.y) {
                    postScaledRect.size.height = postScaledRect.size.width * ratio.height;
                    postScaledRect.origin.y = startPoint.y;
                }
                else {
                    postScaledRect.size.height = postScaledRect.size.width * ratio.height;
                    postScaledRect.origin.y = startPoint.y - postScaledRect.size.height;
                }
            }
            else {
                if (startPoint.y < globalPoint.y) {
                    postScaledRect.size.height = globalPoint.y - startPoint.y;
                    postScaledRect.origin.y = startPoint.y;
                }
                else {
                    postScaledRect.origin.y = globalPoint.y;
                    postScaledRect.size.height = startPoint.y - globalPoint.y;
                }
            }
        }

    }
	return IntMakeRect(0,0,0,0);
}

- (void)mouseUpAt:(IntPoint)localPoin forRect:(IntRect)globalRect andMask:(unsigned char *)mask
{
	if(scalingDir > kNoDir){
		if(preScaledMask)
			free(preScaledMask);
	}
}

- (IntRect) preScaledRect
{
	return preScaledRect;
}

- (unsigned char *) preScaledMask
{
	return preScaledMask;
}

- (IntRect) postScaledRect
{
	return postScaledRect;
}

@end

int getHandle(IntPoint point, IntRect rect, float scale)
{
    float size = (1/scale)*8;
    float half = size/2;

    BOOL inTop = point.y >= rect.origin.y - half && point.y <= rect.origin.y +half;
    BOOL inMiddle = point.y >= rect.origin.y + rect.size.height/2 - half && point.y <= rect.origin.y +rect.size.height/2 + half;
    BOOL inBottom = point.y >= rect.origin.y + rect.size.height - half && point.y <= rect.origin.y+rect.size.height + half;

    BOOL inLeft = point.x >= rect.origin.x - half && point.x <= rect.origin.x+half;
    BOOL inCenter = point.x >= rect.origin.x +rect.size.width/2 -half && point.x <= rect.origin.x+rect.size.width/2+half;
    BOOL inRight = point.x >= rect.origin.x +rect.size.width -half && point.x <= rect.origin.x+rect.size.width+half;

    if(inTop && inLeft )
        return kULDir;
    if(inTop&& inCenter)
        return kUDir;
    if(inTop && inRight)
        return kURDir;
    if(inMiddle && inRight)
        return kRDir;
    if(inBottom && inRight)
        return kDRDir;
    if(inBottom && inCenter)
        return kDDir;
    if(inBottom && inLeft)
        return kDLDir;
    if(inMiddle && inLeft)
        return kLDir;

    return kNoDir;
}

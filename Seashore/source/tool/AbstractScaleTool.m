#import "AbstractScaleTool.h"
#import "AbstractTool.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
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
	preScaledMask = NULL;
	
	return self;
}

- (BOOL) isMovingOrScaling
{
	return (translating || scalingDir > kNoDir);
}

- (void)mouseDownAt:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask
{
	translating = NO;
	scalingDir = kNoDir;
	
	if([options ignoresMove]){
		return;
	}
	
	// We need the global point for the handles
	NSPoint globalPoint = IntPointMakeNSPoint(localPoint);
	globalPoint.x += [[[document contents] activeLayer] xoff];
	globalPoint.y += [[[document contents] activeLayer] yoff];
	globalPoint.x *= [[document contents] xscale];
	globalPoint.y *= [[document contents] yscale];
	
	// Check if location is in existing rect
	scalingDir = [self point:globalPoint
			   isInHandleFor:globalRect
				  ];

	// But the local rect for the moving
	IntRect localRect = globalRect;
	
	localRect.origin.x -= [[[document contents] activeLayer]  xoff];
	localRect.origin.y -= [[[document contents] activeLayer]  yoff];
	
	
	if(scalingDir > kNoDir){
		// 1. Resizing selection
		preScaledRect = globalRect;
		if(mask){
			preScaledMask = malloc(globalRect.size.width * globalRect.size.height);
			memcpy(preScaledMask, mask, globalRect.size.width * globalRect.size.height);
		} else {
			preScaledMask = NULL;
		}
	} else if (	IntPointInRect(localPoint, localRect) ){
		// 2. Moving Selection
		translating = YES;
		moveOrigin = localPoint;
		oldOrigin =  localRect.origin;
	}

}

- (IntRect)mouseDraggedTo:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask
{
	if(scalingDir > kNoDir){
		IntRect currTempRect;
		// We need the global point for the handles
		NSPoint globalPoint = IntPointMakeNSPoint(localPoint);
		globalPoint.x += [[[document contents] activeLayer] xoff];
		globalPoint.y += [[[document contents] activeLayer] yoff];
		currTempRect = globalRect;

		BOOL usesAspect = NO;
		NSSize ratio = NSZeroSize;
		if([options aspectType] == kRatioAspectType){
			usesAspect = YES;
			ratio = [options ratio];
		}
		
		float newHeight = preScaledRect.size.height;
		float newWidth  = preScaledRect.size.width;
		float newX = preScaledRect.origin.x;
		float newY = preScaledRect.origin.y;
		
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
		IntPoint newOrigin;
		// Move the thing
		newOrigin.x = oldOrigin.x + (localPoint.x - moveOrigin.x);
		newOrigin.y = oldOrigin.y + (localPoint.y - moveOrigin.y);
		return IntMakeRect(newOrigin.x, newOrigin.y, globalRect.size.width, globalRect.size.height);
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


- (int)point:(NSPoint) point isInHandleFor:(IntRect)rect
{
	
	float xScale = [[document contents] xscale];
	float yScale = [[document contents] yscale];
	rect = IntMakeRect(rect.origin.x * xScale, rect.origin.y * yScale, rect.size.width * xScale, rect.size.height * yScale);
	
	BOOL inTop = point.y + 5 > rect.origin.y && point.y - 3 < rect.origin.y;
	BOOL inMiddle = point.y+ 4 > (rect.origin.y + rect.size.height / 2) && point.y - 4 < (rect.origin.y + rect.size.height / 2);
	BOOL inBottom = point.y+ 3> (rect.origin.y + rect.size.height) && point.y - 5< (rect.origin.y + rect.size.height);
	
	BOOL inLeft = point.x + 5 > rect.origin.x && point.x -3  < rect.origin.x;
	BOOL inCenter = point.x + 4 > (rect.origin.x + rect.size.width / 2) && point.x - 4 < (rect.origin.x + rect.size.width / 2);
	BOOL inRight =  point.x + 3 > (rect.origin.x + rect.size.width) && point.x - 5 < (rect.origin.x + rect.size.width);
	
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

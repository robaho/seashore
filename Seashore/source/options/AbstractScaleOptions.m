#import "AbstractScaleOptions.h"
#import "AbstractScaleTool.h"
#import "AspectRatio.h"
#import "SeaDocument.h"

@implementation AbstractScaleOptions

- (id)init
{
	self = [super init];
	if(self){
		aspectType = kNoAspectType;
	}
	return self;
}

- (void)updateModifiers:(unsigned int)modifiers
{
	[super updateModifiers:modifiers];

	if ([super modifier] == kShiftModifier) {
		aspectType = kRatioAspectType;
	} else {
		aspectType = kNoAspectType;
	}
    [self aspectChanged:self];
}

- (NSSize)ratio
{
	if(aspectType == kRatioAspectType){
		return NSMakeSize(1, 1);
	}
	return NSZeroSize;
}

- (int)aspectType
{
	return aspectType;
}

- (void)setOneToOne:(BOOL)b
{
    oneToOne = b;
}

- (BOOL)isOneToOne
{
    return oneToOne;
}

- (void)aspectChanged:(id)sender
{
    [(AbstractScaleTool*)[document currentTool] aspectChanged];
}

@end

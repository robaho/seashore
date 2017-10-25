#import "AbstractScaleOptions.h"
#import "AspectRatio.h"

@implementation AbstractScaleOptions

- (id)init
{
	self = [super init];
	if(self){
		aspectType = kNoAspectType;
		ignoresMove = NO;
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

- (void)setIgnoresMove:(BOOL)ignoring
{
	ignoresMove = ignoring;
}

- (BOOL)ignoresMove
{
	return ignoresMove;
}

@end

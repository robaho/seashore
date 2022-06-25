#import "AbstractSelectOptions.h"
#import "SeaSelection.h"
#import "SeaDocument.h"

@implementation AbstractSelectOptions

- (id)init
{
	self = [super init];
	mode = kDefaultMode;
	
	return self;
}

- (int)selectionMode
{
	return mode;
}

- (void)setSelectionMode:(int)newMode
{
	mode = newMode;
	if(mode == kDefaultMode){
		[self setIgnoresMove:NO];
	}else {
		[self setIgnoresMove:YES];
	}

}

- (void)setModeFromModifier:(unsigned int)modifier
{
	switch (modifier) {
		case kNoModifier:
			[self setSelectionMode: kDefaultMode];
			break;
		case kControlModifier:
			[self setSelectionMode: kForceNewMode];
			break;
		case kShiftModifier:
			[self setSelectionMode: kDefaultMode];
			break;
		case kShiftControlModifier:
			[self setSelectionMode: kAddMode];
			break;
		case kAltControlModifier:
			[self setSelectionMode: kSubtractMode];
			break;
		case kReservedModifier1:
			[self setSelectionMode: kMultiplyMode];
			break;
		case kReservedModifier2:
			[self setSelectionMode: kSubtractProductMode];
			break;
		default:
			[self setSelectionMode: kDefaultMode];
			break;
	}
}

- (void)updateModifiers:(unsigned int)modifiers
{
	[super updateModifiers:modifiers];
	int modifier = [super modifier];
	[self setModeFromModifier: modifier];
}

- (IBAction)modifierPopupChanged:(id)sender
{
	[self setModeFromModifier: [[sender selectedItem] tag]];
}
@end

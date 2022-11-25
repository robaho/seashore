#import "AbstractSelectOptions.h"
#import "SeaSelection.h"
#import "SeaDocument.h"

@implementation AbstractSelectOptions

- (id)init:(id)document
{
    self = [super init:document];

    [self addModifierMenuItem:@"Float selection (Option)" tag:1];
    [self addModifierMenuItem:@"1:1 aspect ratio (Shift)" tag:2];
    [self addModifierMenuItem:@"Force new selection (Control)" tag:3];
    [self addModifierMenuItem:@"Add to selection (Control + Shift)" tag:4];
    [self addModifierMenuItem:@"Subtract from selection (Control + Option)" tag:5];
    [self addModifierMenuItem:@"Use intersect of selection" tag:20];
    [self addModifierMenuItem:@"Use inverse intersect of selection" tag:21];

    [self addSubview:modifierPopup];

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

@end

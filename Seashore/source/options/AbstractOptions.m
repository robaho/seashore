#import "AbstractOptions.h"
#import "SeaController.h"
#import "ToolboxUtility.h"
#import "SeaPrefs.h"
#import "SeaDocument.h"
#import "AspectRatio.h"
#import "TextureUtility.h"

@implementation AbstractOptions

- (id)init:(id)document {
    self = [super init];

    modifierPopup = [[NSPopUpButton alloc] init];
    [modifierPopup setControlSize:NSControlSizeMini];
    [modifierPopup setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]]];
    [modifierPopup setTarget:self];
    [modifierPopup setAction:@selector(modifierPopupChanged:)];
    [self addModifierMenuItem:@"No modifiers active" tag:0];
    [self addSubview:modifierPopup];

    self->document = document;
    return self;
}
- (void)modifierPopupChanged:(id)sender
{
    [self updateModifiers:[self modifierMask]];
}

- (void)activate:(id)sender
{
}

- (void)addModifierMenuItem:(NSString*)title tag:(int)tag
{
    [[modifierPopup menu] addItem:[self itemWithTitle:title tag:tag]];
}

- (NSMenuItem*)itemWithTitle:(NSString *)title tag:(int)tag
{
    NSMenuItem *item = [[NSMenuItem alloc] init];
    [item setTitle:title];
    [item setTag:tag];
    return item;
}

- (void)clearModifierMenu
{
    [[modifierPopup menu] removeAllItems];
    [self addModifierMenuItem:@"No modifiers active" tag:0];
}

- (void)update:(id)sender
{
}

- (void)forceAlt
{
	forceAlt = YES;
    int modifiers = [self modifierMask];
    [self updateModifiers:modifiers];
}

- (void)unforceAlt
{
	if (forceAlt) {
        forceAlt = NO;
		[self updateModifiers:0];
	}
    [modifierPopup setEnabled:TRUE];
}

- (int)modifierMask
{
    if(forceAlt) {
        return kAltModifier;
    }
    
    int modifier = [self modifier];
    int mask = 0;
    switch(modifier) {
        case kReservedModifier1:
            mask = NSAlternateKeyMask | NSControlKeyMask | NSFunctionKeyMask; break;
        case kReservedModifier2:
            mask = NSAlternateKeyMask | NSShiftKeyMask | NSFunctionKeyMask; break;
        case kAltControlModifier:
            mask = NSAlternateKeyMask | NSControlKeyMask; break;
        case kShiftControlModifier:
            mask = NSShiftKeyMask | NSControlKeyMask; break;
        case kControlModifier:
            mask = NSControlKeyMask; break;
        case kShiftModifier:
            mask = NSShiftKeyMask; break;
        case kAltModifier:
            mask = NSAlternateKeyMask; break;
    }
    return mask;
}

- (void)updateModifiers:(unsigned int)modifiers
{
	int index;

    if ([[document currentTool] intermediate]) {
        [modifierPopup setEnabled:FALSE];
        // do not allow modifier change while tool active
        return;
    }
    [modifierPopup setEnabled:TRUE];

	if (modifierPopup) {

        if(forceAlt){
            modifiers |= NSAlternateKeyMask;
        }

        modifiers = modifiers & NSEventModifierFlagDeviceIndependentFlagsMask;

        if(modifiers == (NSAlternateKeyMask | NSControlKeyMask | NSFunctionKeyMask)) {
            index = [modifierPopup indexOfItemWithTag:kReservedModifier1];
            if (index > 0) [modifierPopup selectItemAtIndex:index];
        } else if (modifiers == (NSAlternateKeyMask | NSShiftKeyMask | NSFunctionKeyMask)) {
            index = [modifierPopup indexOfItemWithTag:kReservedModifier2];
            if (index > 0) [modifierPopup selectItemAtIndex:index];
        } else if (modifiers == (NSAlternateKeyMask | NSControlKeyMask)) {
			index = [modifierPopup indexOfItemWithTag:kAltControlModifier];
			if (index > 0) [modifierPopup selectItemAtIndex:index];
		}
		else if (modifiers == (NSShiftKeyMask | NSControlKeyMask)) {
			index = [modifierPopup indexOfItemWithTag:kShiftControlModifier];
			if (index > 0) [modifierPopup selectItemAtIndex:index];
		}
		else if (modifiers == (NSControlKeyMask)) {
			index = [modifierPopup indexOfItemWithTag:kControlModifier];
			if (index > 0) [modifierPopup selectItemAtIndex:index];
		}
		else if (modifiers == (NSShiftKeyMask)) {
			index = [modifierPopup indexOfItemWithTag:kShiftModifier];
			if (index > 0) [modifierPopup selectItemAtIndex:index];
		}
		else if (modifiers == (NSAlternateKeyMask)) {
			index = [modifierPopup indexOfItemWithTag:kAltModifier];
			if (index > 0) [modifierPopup selectItemAtIndex:index];
		}
		else {
			[modifierPopup selectItemAtIndex:kNoModifier];
		}
	}
}

- (int)modifier
{
	return [[modifierPopup selectedItem] tag];
}

- (BOOL)useTextures
{
    return [[document toolboxUtility] foregroundIsTexture];
}

- (void)shutdown
{
}

@end

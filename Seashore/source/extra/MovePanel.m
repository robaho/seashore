#import "MovePanel.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"
#import "TextTool.h"
#import "SeaTools.h"

@implementation MovePanel

- (IBAction)changeSpecialFont:(id)sender
{
	[[[[SeaController utilitiesManager] optionsUtilityFor:gCurrentDocument] getOptions:kTextTool] changeFont:sender];
}

- (void)keyDown:(NSEvent *)theEvent
{
	int whichKey;
	unichar key;
	BOOL altKey = ([theEvent modifierFlags] & NSAlternateKeyMask) >> 19;

	// Go through all keys
	for (whichKey = 0; whichKey < [[theEvent characters] length]; whichKey++) {
	
		// Find the key
		key = [[theEvent charactersIgnoringModifiers] characterAtIndex:whichKey];
		
		// For arrow nudging
		switch (key) {
			case NSUpArrowFunctionKey:
				if (altKey)
					[textTool setNudge:IntMakePoint(0, -10)];
				else
					[textTool setNudge:IntMakePoint(0, -1)];
			break;
			case NSDownArrowFunctionKey:
				if (altKey)
					[textTool setNudge:IntMakePoint(0, 10)];
				else
					[textTool setNudge:IntMakePoint(0, 1)];
			break;
			case NSLeftArrowFunctionKey:
				if (altKey)
					[textTool setNudge:IntMakePoint(-10, 0)];
				else
					[textTool setNudge:IntMakePoint(-1, 0)];
			break;
			case NSRightArrowFunctionKey:
				if (altKey)
					[textTool setNudge:IntMakePoint(10, 0)];
				else
					[textTool setNudge:IntMakePoint(1, 0)];
			break;
			case 'h':
			case 'H':
				[textTool centerHorizontally];
			break;
			case 'v':
			case 'V':
				[textTool centerVertically];
			break;
			default:
				[super keyDown:theEvent];
			break;
		}
	
	}
}

@end

#import "NSTextViewRedirect.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"
#import "SeaTools.h"
#import "TextTool.h"

@implementation NSTextViewRedirect

- (IBAction)changeSpecialFont:(id)sender
{
	[[[[SeaController utilitiesManager] optionsUtilityFor:gCurrentDocument] getOptions:kTextTool] changeFont:sender];
}

@end

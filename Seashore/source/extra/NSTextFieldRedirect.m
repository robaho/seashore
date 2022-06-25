#import "NSTextFieldRedirect.h"
#import "SeaController.h"
#import "OptionsUtility.h"
#import "SeaTools.h"
#import "TextTool.h"
#import "SeaDocument.h"

@implementation NSTextFieldRedirect

- (void)changeSpecialFont:(id)sender
{
	[[[gCurrentDocument optionsUtility] getOptions:kTextTool] changeFont:sender];
}

@end

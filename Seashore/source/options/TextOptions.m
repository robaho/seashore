#import "TextOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaPrefs.h"
#import "SeaProxy.h"
#import "TextTool.h"
#import "SeaDocument.h"

id gNewFont;

@implementation TextOptions

- (void)awakeFromNib
{	
	int ivalue;
	BOOL bvalue;
	NSFont *font;
	
	// Handle the text alignment
	if ([gUserDefaults objectForKey:@"text alignment"] == NULL) {
		ivalue = NSLeftTextAlignment;
	}
	else {
		ivalue = [gUserDefaults integerForKey:@"text alignment"];
		if (ivalue < 0 || ivalue >= [alignmentControl segmentCount])
			ivalue = NSLeftTextAlignment;
	}
	[alignmentControl setSelectedSegment:ivalue];
	
	// Handle the text outline slider
	if ([gUserDefaults objectForKey:@"text outline slider"] == NULL) {
		ivalue = 5;
	}
	else {
		ivalue = [gUserDefaults integerForKey:@"text outline slider"];
		if (ivalue < 1 || ivalue > 24)
			ivalue = 5;
	}
	[outlineSlider setIntValue:ivalue];
	
	// Handle the text outline checkbox
	if ([gUserDefaults objectForKey:@"text outline checkbox"] == NULL) {
		bvalue = NO;
	}
	else {
		bvalue = [gUserDefaults boolForKey:@"text outline checkbox"];
	}
	[outlineCheckbox setState:bvalue];
	
	// Enable or disable the slider appropriately
	if ([outlineCheckbox state])
		[outlineSlider setEnabled:YES];
	else
		[outlineSlider setEnabled:NO];
	
	// Show the slider value
	[outlineCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"outline", @"Outline: %d pt"), [outlineSlider intValue]]];
	
	// Handle the text fringe checkbox
	if ([gUserDefaults objectForKey:@"text fringe checkbox"] == NULL) {
		bvalue = YES;
	}
	else {
		bvalue = [gUserDefaults boolForKey:@"text fringe checkbox"];
	}
	[fringeCheckbox setState:bvalue];
	
	// Set up font manager
	gNewFont = NULL;
	fontManager = [NSFontManager sharedFontManager];
	[fontManager setAction:@selector(changeSpecialFont:)];
	if ([gUserDefaults objectForKey:@"text font"] == NULL) {
		font = [NSFont userFontOfSize:0];
		[fontManager setSelectedFont:font isMultiple:NO];
		[fontLabel setStringValue:[NSString stringWithFormat:@"%@ %d pt",  [font displayName],  (int)[font pointSize]]];
	}
	else {
		font = [NSFont fontWithName:[gUserDefaults objectForKey:@"text font"] size:[gUserDefaults integerForKey:@"text size"]];
		[fontManager setSelectedFont:font isMultiple:NO];
		[fontLabel setStringValue:[NSString stringWithFormat:@"%@ %d pt",  [font displayName],  (int)[font pointSize]]];
	}
}

- (IBAction)showFonts:(id)sender
{
	[fontManager orderFrontFontPanel:self];
}

- (IBAction)changeFont:(id)sender
{
	gNewFont = [sender convertFont:[sender selectedFont]];
	[fontLabel setStringValue:[NSString stringWithFormat:@"%@ %d pt",  [gNewFont displayName],  (int)[gNewFont pointSize]]];
	[(TextTool *)[[document tools] getTool:kTextTool] preview:NULL];
	gNewFont = NULL;
}

- (NSTextAlignment)alignment
{
	switch ([alignmentControl selectedSegment]) {
		case 0:
			return NSLeftTextAlignment;
		break;
		case 1:
			return NSCenterTextAlignment;
		break;
		case 2:
			return NSRightTextAlignment;
		break;
	}
	
	return NSLeftTextAlignment;
}

- (int)outline
{
	if ([outlineCheckbox state]) {
		return [outlineSlider intValue];
	}
	
	return 0;
}

- (BOOL)useSubpixel
{
	return YES;
}

- (BOOL)useTextures
{
	return [[SeaController seaPrefs] useTextures];
}

- (BOOL)allowFringe
{
	return [fringeCheckbox state];
}

- (IBAction)update:(id)sender
{
	// Enable or disable the slider appropriately
	if ([outlineCheckbox state])
		[outlineSlider setEnabled:YES];
	else
		[outlineSlider setEnabled:NO];
	
	// Show the slider value
	[outlineCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"outline", @"Outline: %d pt"), [outlineSlider intValue]]];
		
	// Update the text tool
	[(TextTool *)[[document tools] getTool:kTextTool] preview:NULL];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[alignmentControl selectedSegment] forKey:@"text alignment"];
	[gUserDefaults setObject:[outlineCheckbox state] ? @"YES" : @"NO" forKey:@"text outline checkbox"];
	[gUserDefaults setInteger:[outlineSlider intValue] forKey:@"text outline slider"];
	[gUserDefaults setObject:[fringeCheckbox state] ? @"YES" : @"NO" forKey:@"text fringe checkbox"];
	[gUserDefaults setObject:[[fontManager selectedFont] fontName] forKey:@"text font"];
	[gUserDefaults setInteger:(int)[[fontManager selectedFont] pointSize] forKey:@"text size"];
}

@end

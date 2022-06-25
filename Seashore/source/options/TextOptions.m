#import "TextOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaPrefs.h"
#import "SeaProxy.h"
#import "TextTool.h"
#import "SeaDocument.h"
#import "SeaHelpers.h"

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
	fontManager = [NSFontManager sharedFontManager];
    [fontManager setAction:@selector(changeSpecialFont:)];
	if ([gUserDefaults objectForKey:@"text font"] != NULL && [gUserDefaults objectForKey:@"text size"]!=NULL) {
		font = [NSFont fontWithName:[gUserDefaults objectForKey:@"text font"] size:[gUserDefaults integerForKey:@"text size"]];
		[fontManager setSelectedFont:font isMultiple:NO];
        [fontLabel setStringValue:[NSString stringWithFormat:@"%@ %d",[font displayName],(int)[font pointSize]]];
	}

    [textArea setDelegate:self];
}

- (void)activate:(id)sender
{
    [super activate:sender];
    [self update:sender];
    [[textArea window] makeFirstResponder:textArea];
}

-(void)controlTextDidChange:(NSNotification *)obj
{
    [self update:textArea];
}

- (IBAction)showFonts:(id)sender
{
	[fontManager orderFrontFontPanel:self];
}

- (IBAction)changeFont:(id)sender
{
    NSFont *oldFont = [fontManager selectedFont];
    NSFont *font = [sender convertFont:oldFont];

    [fontLabel setStringValue:[NSString stringWithFormat:@"%@ %d",[font displayName],(int)[font pointSize]]];
    [self update:sender];
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

- (IBAction)update:(id)sender
{
	// Enable or disable the slider appropriately
	if ([outlineCheckbox state])
		[outlineSlider setEnabled:YES];
	else
		[outlineSlider setEnabled:NO];
	
	// Show the slider value
	[outlineCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"outline", @"Outline: %d pt"), [outlineSlider intValue]]];

    if([[document toolboxUtility] tool]!=kTextTool)
        return;

    TextTool *tool = (TextTool*)[document currentTool];

    bool enable = ![[textArea stringValue] isEqualTo:@""] && !IntRectIsEmpty([tool textRect]);

    [addNewLayerButton setEnabled:enable];
    [mergeWithLayerButton setEnabled:enable];

    if(enable) {
        [addNewLayerButton setToolTip:@""];
        [mergeWithLayerButton setToolTip:@""];
    } else {
        NSString *tip = LOCALSTR(@"textToolRequires",@"Rectange & text cannot be empty");
        [addNewLayerButton setToolTip:tip];
        [mergeWithLayerButton setToolTip:tip];
    }

    [[document helpers] selectionChanged];
}

- (NSString*)text
{
    return [textArea stringValue];
}

- (IBAction)toggleTextures:(id)sender
{
    NSWindow *w = [document window];
    NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
    [[document textureUtility] showPanelFrom: p onWindow: w];
}

-(float)lineSpacing
{
    return [lineSpacing floatValue];
}

-(void)reset
{
    [textArea setStringValue:@""];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[alignmentControl selectedSegment] forKey:@"text alignment"];
	[gUserDefaults setObject:[outlineCheckbox state] ? @"YES" : @"NO" forKey:@"text outline checkbox"];
	[gUserDefaults setInteger:[outlineSlider intValue] forKey:@"text outline slider"];
	[gUserDefaults setObject:[[fontManager selectedFont] displayName] forKey:@"text font"];
	[gUserDefaults setInteger:(int)[[fontManager selectedFont] pointSize] forKey:@"text size"];
}

@end

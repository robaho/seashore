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
#import "SeaSelection.h"

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
    font = [sender convertFont:[fontManager selectedFont]];

    [fontLabel setStringValue:[NSString stringWithFormat:@"%@ %d",[font displayName],(int)[font pointSize]]];
    [self update:sender];
}

- (IBAction)changeColor:(id)sender
{
    color = [gColorPanel color];
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

    [verticalMargin setMaxValue:([tool bounds].size.height)];

    [tool updateLayer];

    [[document helpers] selectionChanged];
}

- (TextProperties*)properties
{
    TextProperties* props = [[TextProperties alloc] init];
    props.text = [textArea stringValue];
    props.lineSpacing = [lineSpacing floatValue];
    props.verticalMargin = [verticalMargin floatValue];
    props.outline = [outlineCheckbox state] ? [outlineSlider intValue] : 0;
    props.alignment = [self alignment];
    props.font = font==NULL ? [fontManager selectedFont] : font;
    props.color = color==NULL ? [[document contents] foreground] : color;
    props.textPath = textPath;

    return props;
}

- (void)setProperties:(TextProperties *)props
{
    NSString *text = props.text;

    SeaLayer *layer = [[document contents] activeLayer];
    if([layer isTextLayer]){
        [textArea setEnabled:TRUE];
        if(!text)
            [textArea setStringValue:@""];
        else
            [textArea setStringValue:text];
    } else {
        [textArea setStringValue:@"Select text layer or Click/Drag to create a new layer."];
        [textArea setEnabled:FALSE];
    }

    [lineSpacing setFloatValue:props.lineSpacing];
    [verticalMargin setFloatValue:props.verticalMargin];
    [outlineSlider setIntValue:props.outline];
    
    color = props.color;

    if(color) {
        [colorWell setColor:color];
    } else {
        [colorWell setColor:[[document contents] foreground]];
    }

    font = props.font;

    if(font) {
        [fontLabel setStringValue:[NSString stringWithFormat:@"%@ %d",[font displayName],(int)[font pointSize]]];
        [fontManager setSelectedFont:font isMultiple:FALSE];
    }

    switch (props.alignment) {
        case NSLeftTextAlignment:
            [alignmentControl setSelectedSegment:0];
            break;
        case NSCenterTextAlignment:
            [alignmentControl setSelectedSegment:1];
            break;
        case  NSRightTextAlignment:
            [alignmentControl setSelectedSegment:2];
            break;
    }

    textPath = props.textPath;
}

- (void)shutdown
{
	[gUserDefaults setInteger:[alignmentControl selectedSegment] forKey:@"text alignment"];
	[gUserDefaults setObject:[outlineCheckbox state] ? @"YES" : @"NO" forKey:@"text outline checkbox"];
	[gUserDefaults setInteger:[outlineSlider intValue] forKey:@"text outline slider"];
	[gUserDefaults setObject:[[fontManager selectedFont] displayName] forKey:@"text font"];
	[gUserDefaults setInteger:(int)[[fontManager selectedFont] pointSize] forKey:@"text size"];
}

- (BOOL)useTextures
{
    return false;
}

@end

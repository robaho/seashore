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

- (id)init:(id)document
{
    self = [super init:document];

    [modifierPopup setHidden:TRUE];

    self.lastFills = TRUE;

    AbstractTool *tool = [[document tools] getTool:kTextTool];

    alignmentControl = [[NSSegmentedControl alloc] init];
    [alignmentControl setControlSize:NSSmallControlSize];
    [alignmentControl setSegmentCount:3];
    [alignmentControl setImage:[NSImage imageNamed:@"left-align"] forSegment:0];
    [alignmentControl setImage:[NSImage imageNamed:@"center-align"] forSegment:1];
    [alignmentControl setImage:[NSImage imageNamed:@"right-align"] forSegment:2];
    [alignmentControl setTarget:self];
    [alignmentControl setAction:@selector(update:)];
    [self addSubview:alignmentControl];

    outlineSlider = [SeaSlider sliderWithCheck:@"Outline (pt)" Min:1 Max:36 Listener:self];
    [self addSubview:outlineSlider];

    fontButton = [SeaButton compactButton:@"Fonts" withLabel:@"Font" target:self action:@selector(showFonts:)];
    [self addSubview:fontButton];

    colorWell = [SeaColorWell compactWithTitle:@"Color" Listener:self];
    [self addSubview:colorWell];

    lineSpacingSlider = [SeaSlider compactSliderWithTitle:@"Line spacing" Min:0 Max:2 Listener:self];
    [self addSubview:lineSpacingSlider];

    verticalMarginSlider = [SeaSlider compactSliderWithTitle:@"Vertical margin" Min:0 Max:5000 Listener:self];
    [self addSubview:verticalMarginSlider];

    boundsButton = [SeaButton compactButton:@"Set Text Bounds from Selection" target:tool action:@selector(setTextBoundsFromSelection:)];
    [self addSubview:boundsButton];

    [lineSpacingSlider setFloatValue:1.0];

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
	}
	[outlineSlider setIntValue:ivalue];
	
	// Handle the text outline checkbox
	if ([gUserDefaults objectForKey:@"text outline checkbox"] == NULL) {
		bvalue = NO;
	}
	else {
		bvalue = [gUserDefaults boolForKey:@"text outline checkbox"];
	}
	[outlineSlider setChecked:bvalue];

    [verticalMarginSlider setFloatValue:0.0];

	// Show the slider value
	fontManager = [NSFontManager sharedFontManager];
    [fontManager setAction:@selector(changeSpecialFont:)];
	if ([gUserDefaults objectForKey:@"text font"] != NULL && [gUserDefaults objectForKey:@"text size"]!=NULL) {
		font = [NSFont fontWithName:[gUserDefaults objectForKey:@"text font"] size:[gUserDefaults integerForKey:@"text size"]];
		[fontManager setSelectedFont:font isMultiple:NO];
        [fontButton setLabel:[NSString stringWithFormat:@"%@ %d",[font displayName],(int)[font pointSize]]];
	}

    textArea = [[NSTextFieldRedirect alloc] init];
    [self addSubview:textArea];

    [textArea setDelegate:self];

    return self;
}

- (void)componentChanged:(id)sender
{
    [self update:sender];
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

    [fontButton setLabel:[NSString stringWithFormat:@"%@ %d",[font displayName],(int)[font pointSize]]];
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
    if([[document toolboxUtility] tool]!=kTextTool)
        return;

    color = [colorWell colorValue];

    TextTool *tool = (TextTool*)[document currentTool];

    [verticalMarginSlider setMaxValue:([tool bounds].size.height)];

    [tool updateLayer];
}

- (TextProperties*)properties
{
    TextProperties* props = [[TextProperties alloc] init];
    props.text = [textArea stringValue];
    props.lineSpacing = [lineSpacingSlider floatValue];
    props.verticalMargin = [verticalMarginSlider floatValue];
    props.outline = [outlineSlider isChecked] ? [outlineSlider intValue] : 0;
    props.alignment = [self alignment];
    props.font = font==NULL ? [fontManager selectedFont] : font;
    props.color = color==NULL ? [[document contents] foreground] : color;
    props.textPath = textPath;

    return props;
}

- (void)setProperties:(TextProperties *)props
{
    NSString *text = props.text;

    if(props==NULL) {
        [textArea setPlaceholderString:@"Select text layer or Click/Drag to create a new layer."];
        [textArea setStringValue:@""];
        [textArea setEnabled:FALSE];
        return;
    }

    [textArea setPlaceholderString:@"Enter text here."];
    [textArea setEnabled:TRUE];
    if(!text) {
        [textArea setStringValue:@""];
    } else {
        [textArea setStringValue:text];
    }

    [lineSpacingSlider setFloatValue:props.lineSpacing];
    [verticalMarginSlider setFloatValue:props.verticalMargin];
    [outlineSlider setIntValue:props.outline];
    
    color = props.color;

    if(color) {
        [colorWell setColorValue:color];
    } else {
        [colorWell setColorValue:[[document contents] foreground]];
    }

    font = props.font;

    if(font) {
        [fontButton setLabel:[NSString stringWithFormat:@"%@ %d",[font displayName],(int)[font pointSize]]];
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

    [[textArea window] makeFirstResponder:textArea];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[alignmentControl selectedSegment] forKey:@"text alignment"];
	[gUserDefaults setBool:[outlineSlider isChecked] forKey:@"text outline checkbox"];
	[gUserDefaults setInteger:[outlineSlider intValue] forKey:@"text outline slider"];
	[gUserDefaults setObject:[[fontManager selectedFont] displayName] forKey:@"text font"];
	[gUserDefaults setInteger:(int)[[fontManager selectedFont] pointSize] forKey:@"text size"];
}

- (BOOL)useTextures
{
    return false;
}

@end

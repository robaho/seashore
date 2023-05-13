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

@implementation MyTextView
- (void)changeColor:(id)sender
{
}
- (void)setPlaceholderString:(NSString*)s
{
    NSDictionary *attrs;

    if (@available(macOS 10.10, *)) {
        attrs = [NSDictionary dictionaryWithObject:[NSColor placeholderTextColor] forKey:NSForegroundColorAttributeName];
    } else {
        attrs = [NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
    }
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:s attributes:attrs];
    [self setValue:as forKey:@"placeholderAttributedString"];
}
@end
@implementation TextOptions

- (id)init:(id)document
{
    self = [super init:document];

    [modifierPopup setHidden:TRUE];

    self.lastFills = TRUE;

    AbstractTool *tool = [[document tools] getTool:kTextTool];

    alignmentControl = [[NSSegmentedControl alloc] init];
    [alignmentControl setCtrlSize:NSSmallControlSize];
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

//    [self addSubview:[SizeableView withSize:NSMakeSize(-1,6)]];

    textControls = [[NSSegmentedControl alloc] init];
    [[textControls cell] setTrackingMode:NSSegmentSwitchTrackingSelectAny];
    [textControls setCtrlSize:NSSmallControlSize];
    [textControls setSegmentCount:4];
    [textControls setImage:[NSImage imageNamed:@"boldTemplate"] forSegment:0];
    [textControls setImage:[NSImage imageNamed:@"italicTemplate"] forSegment:1];
    [textControls setImage:[NSImage imageNamed:@"underlineTemplate"] forSegment:2];
    [textControls setImage:[NSImage imageNamed:@"strikethroughTemplate"] forSegment:3];
    [textControls setTarget:self];
    [textControls setAction:@selector(textControlsChanged:)];
    [self addSubview:textControls];

    [self addSubview:[SizeableView withSize:NSMakeSize(-1,6)]];

    textArea = [[MyTextView alloc] init];
    [self addSubview:textArea];

    [textArea setUsesFontPanel:NO];
    [textArea setDelegate:self];
    [textArea setRichText:TRUE];
//    [textArea setAllowsEditingTextAttributes:FALSE];

    return self;
}

//- (NSFontPanelModeMask)validModesForFontPanel:(NSFontPanel *)fontPanel
//{
//    return NSFontPanelModeMaskCollection | NSFontPanelSizeModeMask;
//}

- (void)textDidChange:(id)sender
{
    [self update:sender];
}

- (NSDictionary<NSAttributedStringKey, id> *)textView:(NSTextView *)textView
                         shouldChangeTypingAttributes:(NSDictionary<NSString *,id> *)oldTypingAttributes
                                         toAttributes:(NSDictionary<NSAttributedStringKey, id> *)newTypingAttributes
{
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithDictionary:newTypingAttributes];
    [copy setValue:[NSColor textColor] forKey:NSForegroundColorAttributeName];
    return copy;
}

- (void)textViewDidChangeSelection:(id)sender
{
    [self update:textArea];
}

- (void)textControlsChanged:(id)sender
{
    NSRange r = [textArea selectedRange];
    if(r.length==0) {
        [self update:textArea];
    } else {
        [[textArea textStorage] setAttributes:[self typingAttrs] range:r];
        [self update:sender];
    }
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

- (IBAction)changeSpecialFont:(id)sender
{
    font = [sender convertFont:[fontManager selectedFont]];

    [fontButton setLabel:[NSString stringWithFormat:@"%@ %d",[font displayName],(int)[font pointSize]]];
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

- (NSDictionary<NSAttributedStringKey, id> *) typingAttrs
{
    NSMutableDictionary<NSAttributedStringKey,id> *attrs = [NSMutableDictionary dictionary];

    NSFont *font = [NSFont systemFontOfSize:12];
    attrs[NSFontAttributeName] = font;
    attrs[NSForegroundColorAttributeName] = [NSColor textColor];

    if([textControls isSelectedForSegment:0]) {
        font = [fontManager convertFont:font toHaveTrait:NSFontBoldTrait];;
        attrs[NSFontAttributeName] = font;
    }
    if([textControls isSelectedForSegment:1]) {
        font = [fontManager convertFont:font toHaveTrait:NSFontItalicTrait];
        attrs[NSFontAttributeName] = font;
    }
    if([textControls isSelectedForSegment:2]) {
        attrs[NSUnderlineStyleAttributeName] = [NSNumber numberWithInt:1];
    }
    if([textControls isSelectedForSegment:3]) {
        attrs[NSStrikethroughStyleAttributeName] = [NSNumber numberWithInt:1];
    }

    return attrs;
}

- (IBAction)update:(id)sender
{
    if (propertiesChanging)
        return;

    if([[document toolboxUtility] tool]!=kTextTool)
        return;

    color = [colorWell colorValue];

    TextTool *tool = (TextTool*)[document currentTool];

    [verticalMarginSlider setMaxValue:([tool bounds].size.height)];

    [tool updateLayer];

    [textArea setTypingAttributes:[self typingAttrs]];
}

- (TextProperties*)properties
{
    TextProperties* props = [[TextProperties alloc] init];
    props.text = [[textArea attributedString] copy];
    props.lineSpacing = [lineSpacingSlider floatValue];
    props.verticalMargin = [verticalMarginSlider floatValue];
    props.outline = [outlineSlider isChecked] ? [outlineSlider intValue] : 0;
    props.alignment = [self alignment];
    props.font = font==NULL ? [fontManager selectedFont] : font;
    props.color = color==NULL ? [[document contents] foreground] : color;
    props.textPath = textPath;

    return props;
}

+ (NSAttributedString*)removeColor:(NSAttributedString*)s
{
    NSMutableAttributedString *ms = [[NSMutableAttributedString alloc] initWithAttributedString:s];
    [ms addAttribute:NSForegroundColorAttributeName value:[NSColor textColor] range:NSMakeRange(0,ms.length)];
    return ms;
}

- (void)setProperties:(TextProperties *)props
{
    propertiesChanging = true;

    NSAttributedString *text = props.text;
    NSAttributedString *empty = [[NSAttributedString alloc] init];

    if(props==NULL) {
        [textArea setPlaceholderString:@"Select text layer or Click/Drag to create a new layer."];
        [[textArea textStorage] setAttributedString:empty];
        [textArea setEditable:FALSE];
        propertiesChanging = false;
        return;
    }

    [textArea setPlaceholderString:@"Enter text here."];
    [textArea setEditable:TRUE];
    if(!text) {
//        [[textArea textStorage] setAttributedString:empty];
    } else {
        [[textArea textStorage] setAttributedString:[TextOptions removeColor:text]];
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

    propertiesChanging=false;
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

- (int)aspectType
{
    return kNoAspectType;
}

@end

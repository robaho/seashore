#import "AspectRatio.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "Units.h"
#import "AbstractScaleOptions.h"
#import <SeaComponents/SeaComponents.h>
#import "SeaPrefs.h"

#define customItemIndex 2

@implementation AspectRatio

- (id)init:(id)document master:(id)imaster andString:(id)iprefString
{
    self = [super init];

    NSControlSize size = [[SeaController seaPrefs] controlSize];

    self->document = document;

    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"1 to 1" action:NULL keyEquivalent:@""];
    [menu addItemWithTitle:@"3 to 4" action:NULL keyEquivalent:@""];
    [menu addItemWithTitle:@"1 to 2" action:NULL keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Custom..." action:NULL keyEquivalent:@""];

    [NSBundle loadNibNamed:@"AspectRatioPanel" owner:self];

    ratioPopup = [SeaPopup popupWithCheck:@"Aspect Ratio" Menu:menu Listener:self Size:size];

	int ratioIndex;
	id customItem;
	
	master = imaster;
	prefString = iprefString;

	if ([gUserDefaults objectForKey:[NSString stringWithFormat:@"%@ ratio index", prefString]] == NULL) {
		[ratioPopup selectItemAtIndex:0];
	}
	else {
		ratioIndex = [gUserDefaults integerForKey:[NSString stringWithFormat:@"%@ ratio index", prefString]];
		if (ratioIndex < 0 || ratioIndex > customItemIndex) ratioIndex = 0;
		[ratioPopup selectItemAtIndex:ratioIndex];
	}

	if ([gUserDefaults objectForKey:[NSString stringWithFormat:@"%@ ratio horiz", prefString]] == NULL) {
		ratioX = 2.0;
	}
	else {
		ratioX = [gUserDefaults integerForKey:[NSString stringWithFormat:@"%@ ratio horiz", prefString]];
	}
	
	if ([gUserDefaults objectForKey:[NSString stringWithFormat:@"%@ ratio vert", prefString]] == NULL) {
		ratioY = 1.0;
	}
	else {
		ratioY = [gUserDefaults integerForKey:[NSString stringWithFormat:@"%@ ratio vert", prefString]];
	}
	
	if ([gUserDefaults objectForKey:[NSString stringWithFormat:@"%@ ratio type", prefString]] == NULL) {
		aspectType = kRatioAspectType;
	}
	else {
		aspectType = [gUserDefaults integerForKey:[NSString stringWithFormat:@"%@ ratio type", prefString]];
	}
	
	customItem = [ratioPopup itemAtIndex:customItemIndex];
	switch (aspectType) {
		case kRatioAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%g to %g", ratioX, ratioY]];
		break;
		case kExactPixelAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%d by %d px", (int)ratioX, (int)ratioY]];
		break;
		case kExactInchAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%g by %g in", ratioX, ratioY]];
		break;
		case kExactMillimeterAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%g by %g mm", ratioX, ratioY]];
		break;
	}

	forgotX = 472;
	forgotY = 364;

    return self;
}

- (void)componentChanged:(id)sender {
    if([ratioPopup indexOfSelectedItem]==4) {
        [self setCustomItem:sender];
    }
}


- (NSSize)ratio
{
	NSSize result;
	
	switch ([ratioPopup indexOfSelectedItem]) {
		case 0:
			result = NSMakeSize(1.0, 1.0);
		break;
		case 1:
			result = NSMakeSize(4.0 / 3.0, 3.0 / 4.0);
		break;
		case 2:
			if (aspectType == kRatioAspectType)
				result = NSMakeSize(ratioX / ratioY, ratioY / ratioX);
			else if (aspectType == kExactPixelAspectType)
				result = NSMakeSize((int)ratioX, (int)ratioY);
			else
				result = NSMakeSize(ratioX, ratioY);
		break;
		default:
			result = NSMakeSize(1.0, 1.0);
		break;
	}

	if (result.width <= 0.0) result.width = 1.0;
	if (result.height <= 0.0) result.height = 1.0;
	
	return result;
}

- (int)aspectType
{
	int result;
	
	if ([ratioPopup isChecked]) {
		if ([ratioPopup indexOfSelectedItem] < customItemIndex)
			result = kRatioAspectType;
		else
			result = aspectType;
	}
	else {
		result = kNoAspectType;
	}
	
	return result;
}

- (IBAction)update:(id)sender;
{
}

- (void)shutdown
{
	[gUserDefaults setInteger:[ratioPopup indexOfSelectedItem] forKey:[NSString stringWithFormat:@"%@ ratio index", prefString]];
	[gUserDefaults setFloat:ratioX forKey:[NSString stringWithFormat:@"%@ ratio horiz", prefString]];
	[gUserDefaults setFloat:ratioY forKey:[NSString stringWithFormat:@"%@ ratio vert", prefString]];
	[gUserDefaults setInteger:aspectType forKey:[NSString stringWithFormat:@"%@ ratio type", prefString]];
}

- (NSView*)view {
    return ratioPopup;
}

- (IBAction)setCustomItem:(id)sender
{
    [xRatioValue setStringValue:[NSString stringWithFormat:@"%g", ratioX]];
    [yRatioValue setStringValue:[NSString stringWithFormat:@"%g", ratioY]];
    switch (aspectType) {
        case kRatioAspectType:
            [toLabel setStringValue:@"to"];
            [aspectTypePopup selectItemAtIndex:0];
            break;
        case kExactPixelAspectType:
            [toLabel setStringValue:@"by"];
            [aspectTypePopup selectItemAtIndex:1];
            break;
        case kExactInchAspectType:
            [toLabel setStringValue:@"by"];
            [aspectTypePopup selectItemAtIndex:2];
            break;
        case kExactMillimeterAspectType:
            [toLabel setStringValue:@"by"];
            [aspectTypePopup selectItemAtIndex:3];
            break;
    }

    [panel center];
    [panel makeFirstResponder:xRatioValue];
    [NSApp beginSheet:panel modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)applyCustomItem:(id)sender
{
    id customItem;

    if (aspectType == kExactPixelAspectType) {
        ratioX = [xRatioValue intValue];
        ratioY = [yRatioValue intValue];
    }
    else {
        ratioX = [xRatioValue floatValue];
        ratioY = [yRatioValue floatValue];
    }
    customItem = [ratioPopup itemAtIndex:customItemIndex];
    switch (aspectType) {
        case kRatioAspectType:
            [customItem setTitle:[NSString stringWithFormat:@"%g to %g", ratioX, ratioY]];
            break;
        case kExactPixelAspectType:
            [customItem setTitle:[NSString stringWithFormat:@"%d by %d px", (int)ratioX, (int)ratioY]];
            break;
        case kExactInchAspectType:
            [customItem setTitle:[NSString stringWithFormat:@"%g by %g in", ratioX, ratioY]];
            break;
        case kExactMillimeterAspectType:
            [customItem setTitle:[NSString stringWithFormat:@"%g by %g mm", ratioX, ratioY]];
            break;
    }
    [NSApp stopModal];
    [NSApp endSheet:panel];
    [panel orderOut:self];
    [ratioPopup selectItemAtIndex:customItemIndex];
    [(AbstractScaleOptions*)master aspectChanged:sender];
}

- (IBAction)changeCustomAspectType:(id)sender
{
    float xres = [[document contents] xres], yres = [[document contents] yres];
    int oldType;

    oldType = aspectType;
    aspectType = [aspectTypePopup indexOfSelectedItem] - 1;
    if (oldType != kRatioAspectType) {
        forgotX = PixelsFromFloat([xRatioValue floatValue], oldType, xres);
        forgotY = PixelsFromFloat([yRatioValue floatValue], oldType, yres);
    }
    switch (aspectType) {
        case kRatioAspectType:
            ratioX = 2;
            ratioY = 1;
            [xRatioValue setStringValue:[NSString stringWithFormat:@"%d", (int)ratioX]];
            [yRatioValue setStringValue:[NSString stringWithFormat:@"%d", (int)ratioY]];
            [toLabel setStringValue:@"to"];
            [aspectTypePopup setTitle:@"ratio"];
            break;
        case kExactPixelAspectType:
            [xRatioValue setStringValue:StringFromPixels(forgotX, aspectType, xres)];
            [yRatioValue setStringValue:StringFromPixels(forgotY, aspectType, yres)];
            ratioX = [xRatioValue floatValue];
            ratioY = [yRatioValue floatValue];
            [toLabel setStringValue:@"by"];
            [aspectTypePopup setTitle:@"px"];
            break;
        case kExactInchAspectType:
            [xRatioValue setStringValue:StringFromPixels(forgotX, aspectType, xres)];
            [yRatioValue setStringValue:StringFromPixels(forgotY, aspectType, yres)];
            ratioX = [xRatioValue floatValue];
            ratioY = [yRatioValue floatValue];
            [toLabel setStringValue:@"by"];
            [aspectTypePopup setTitle:@"in"];
            break;
        case kExactMillimeterAspectType:
            [xRatioValue setStringValue:StringFromPixels(forgotX, aspectType, xres)];
            [yRatioValue setStringValue:StringFromPixels(forgotY, aspectType, yres)];
            ratioX = [xRatioValue floatValue];
            ratioY = [yRatioValue floatValue];
            [toLabel setStringValue:@"by"];
            [aspectTypePopup setTitle:@"mm"];
            break;
    }
}

@end

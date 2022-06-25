#import "InfoUtility.h"
#import "SeaDocument.h"
#import "ToolboxUtility.h"
#import "SeaTools.h"
#import "EyedropTool.h"
#import "SeaSelection.h"
#import "SeaView.h"
#import "SeaContent.h"
#import "SeaPrefs.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "PositionTool.h"
#import "RectSelectTool.h"
#import "EllipseSelectTool.h"
#import "CropTool.h"
#import "Units.h"
#import "SeaWindowContent.h"
#import "PositionTool.h"

@implementation InfoUtility

- (id)init
{
	return self;
}

- (void)awakeFromNib
{
	// Shown By Default
    [toggleButton setState:[self visible]];
}

- (void)shutdown
{	
}

- (IBAction)show:(id)sender
{
	[[[document window] contentView] setVisibility: YES forRegion: kPointInformation];
    [toggleButton setState:1];
}

- (IBAction)hide:(id)sender
{
	[[[document window] contentView] setVisibility: NO forRegion: kPointInformation];	
    [toggleButton setState:0];
}

- (IBAction)toggle:(id)sender
{
	if ([self visible]) {
		[self hide:sender];
	}
	else {
		[self show:sender];
        [self update];
	}
}

- (void)doUpdate
{
    IntPoint point, delta;
    IntSize size;
    NSColor *color;
    int xres, yres, units;

    // Show no values
    if (!document) {
        [xValue setStringValue:@""];
        [yValue setStringValue:@""];
        [widthValue setStringValue:@""];
        [heightValue setStringValue:@""];
        [deltaX setStringValue:@""];
        [deltaY setStringValue:@""];
        [redValue setStringValue:@""];
        [greenValue setStringValue:@""];
        [blueValue setStringValue:@""];
        [alphaValue setStringValue:@""];
        [radiusValue setStringValue:@""];
        [colorWell setColor: [NSColor colorWithCalibratedWhite: 0 alpha:1.0]];
        return;
    }

    // Set the radius value
    [radiusValue setIntValue:[[[document tools] getTool:kEyedropTool] sampleSize]];

    // Update the document information
    xres = [[document contents] xres];
    yres = [[document contents] yres];

    int curToolIndex = [[document currentTool] toolId];

    // Get the selection
    if (curToolIndex == kCropTool) {
        size = [(CropTool*)[document currentTool] cropRect].size;
    }
    else if (curToolIndex == kPositionTool) {
        size = [(PositionTool*)[document currentTool] bounds].size;
    }
    else if ([[document selection] active]) {
        size = [[document selection] localRect].size;
    }
    else {
        size.height = size.width = 0;
    }

    point = [[document docView] getMousePosition:YES];
    delta = [[document docView] delta];
    units = [document measureStyle];

    NSString *label = UnitsString(units);
    [widthValue setStringValue:[StringFromPixels(size.width, units, xres) stringByAppendingFormat:@" %@", label]];
    [heightValue setStringValue:[StringFromPixels(size.height, units, yres) stringByAppendingFormat:@" %@", label]];
    [deltaX setStringValue:[StringFromPixels(delta.x, units, xres) stringByAppendingFormat:@" %@", label]];
    [deltaY setStringValue:[StringFromPixels(delta.y, units, yres) stringByAppendingFormat:@" %@", label]];
    [xValue setStringValue:[StringFromPixels(point.x, units, xres) stringByAppendingFormat:@" %@", label]];
    [yValue setStringValue:[StringFromPixels(point.y, units, yres) stringByAppendingFormat:@" %@", label]];

    // Update the RGBA values
    color = [[[document tools] getTool:kEyedropTool] getColor];
    if (color) {
        [colorWell setColor:color];
        if ([[color colorSpaceName] isEqualToString:MyRGBSpace]) {
            [redValue setIntValue:[color redComponent] * 255.0];
            [greenValue setIntValue:[color greenComponent] * 255.0];
            [blueValue setIntValue:[color blueComponent] * 255.0];
            [alphaValue setIntValue:[color alphaComponent] * 255.0];
        }
        else if ([[color colorSpaceName] isEqualToString:MyGraySpace]) {
            [redValue setIntValue:[color whiteComponent] * 255.0];
            [greenValue setIntValue:[color whiteComponent] * 255.0];
            [blueValue setIntValue:[color whiteComponent] * 255.0];
            [alphaValue setIntValue:[color alphaComponent] * 255.0];
        }
        else {
            NSLog(@"Color space not recognized by information utility.");
        }
    }

    if(point.x == -1 || !color){
        [xValue setStringValue:@""];
        [yValue setStringValue:@""];
        [redValue setStringValue:@""];
        [greenValue setStringValue:@""];
        [blueValue setStringValue:@""];
        [alphaValue setStringValue:@""];

        [colorWell setColor: [NSColor colorWithCalibratedWhite: 0 alpha:1.0]];
    }
}

- (void)update
{
   if (![self visible])
        return;

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doUpdate) object:NULL];
    [self performSelector:@selector(doUpdate) withObject:NULL afterDelay:0.005];
	
}

- (BOOL)visible
{
	return [[[document window] contentView] visibilityForRegion: kPointInformation];
}

@end

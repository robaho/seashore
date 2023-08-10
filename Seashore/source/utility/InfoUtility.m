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
#import "TextTool.h"
#import "ZoomTool.h"
#import <SeaComponents/SeaComponents.h>

@implementation InfoUtility

- (id)init
{
	return self;
}

- (void)awakeFromNib
{
    NSControlSize size = [[SeaController seaPrefs] controlSize];

    VerticalView *left = [VerticalView view];
    xValue = [SeaLabelledValue withLabel:@"X" size:size];
    yValue = [SeaLabelledValue withLabel:@"Y" size:size];
    widthValue = [SeaLabelledValue withLabel:@"Width" size:size];
    heightValue = [SeaLabelledValue withLabel:@"Height" size:size];
    deltaX = [SeaLabelledValue withLabel:@"Delta X" size:size];
    deltaY = [SeaLabelledValue withLabel:@"Delta Y" size:size];

    [left addSubviews:xValue,yValue,widthValue,heightValue,deltaX,deltaY,nil];

    VerticalView *right = [VerticalView view];
    redValue = [SeaLabelledValue withLabel:@"Red" size:size];
    greenValue = [SeaLabelledValue withLabel:@"Green" size:size];
    blueValue = [SeaLabelledValue withLabel:@"Blue" size:size];
    alphaValue = [SeaLabelledValue withLabel:@"Alpha" size:size];
    radiusValue = [SeaLabelledValue withLabel:@"Radius" size:size];
    colorWell = [SeaLabelledValue withLabel:@"Color" size:size];

    [colorWell setColorValue:[NSColor colorWithCalibratedWhite: 0 alpha:1.0]];

    [right addSubviews:redValue,greenValue,blueValue,alphaValue,radiusValue,colorWell,nil];

    [view setSubviews:[NSArray array]];
    [view addSubview:left];
    [view addSubview:right];

    [layersView layout];
    [layersView setNeedsDisplay:TRUE];

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
        [colorWell setColorValue:NULL];
        return;
    }

    // Set the radius value
    [radiusValue setIntValue:[(EyedropTool*)[[document tools] getTool:kEyedropTool] sampleSize]];

    // Update the document information
    xres = [[document contents] xres];
    yres = [[document contents] yres];

    int curToolIndex = [[document currentTool] toolId];

    point = [[document docView] getMousePosition:YES];

    // Get the selection
    if (curToolIndex == kCropTool) {
        IntRect bounds = [(CropTool*)[document currentTool] cropRect];
        size = bounds.size;
        if(!IntRectIsEmpty(bounds))
            point = bounds.origin;
    }
    else if (curToolIndex == kPositionTool) {
        IntRect bounds = [(PositionTool*)[document currentTool] bounds];
        size = bounds.size;
        if(!IntRectIsEmpty(bounds))
            point = bounds.origin;
    }
    else if (curToolIndex == kTextTool) {
        IntRect bounds = [(TextTool*)[document currentTool] bounds];
        size = bounds.size;
        if(!IntRectIsEmpty(bounds))
            point = bounds.origin;
    }
    else if (curToolIndex == kZoomTool) {
        IntRect bounds = [(ZoomTool*)[document currentTool] zoomRect];
        size = bounds.size;
        if(!IntRectIsEmpty(bounds))
            point = bounds.origin;
    }
    else if ([[document selection] active]) {
        size = [[document selection] globalRect].size;
        point = [[document selection] globalRect].origin;
    }
    else {
        size.height = size.width = 0;
    }

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
    color = [(EyedropTool*)[[document tools] getTool:kEyedropTool] getColor];
    if (color) {
        [colorWell setColorValue:color];
        if ([[color colorSpaceName] isEqualToString:MyRGBSpace]) {
            [redValue setIntValue:round([color redComponent] * 255.0)];
            [greenValue setIntValue:round([color greenComponent] * 255.0)];
            [blueValue setIntValue:round([color blueComponent] * 255.0)];
            [alphaValue setIntValue:round([color alphaComponent] * 255.0)];
        }
        else if ([[color colorSpaceName] isEqualToString:MyGraySpace]) {
            [redValue setIntValue:round([color whiteComponent] * 255.0)];
            [greenValue setIntValue:round([color whiteComponent] * 255.0)];
            [blueValue setIntValue:round([color whiteComponent] * 255.0)];
            [alphaValue setIntValue:round([color alphaComponent] * 255.0)];
        }
        else {
            NSLog(@"Color space not recognized by information utility.");
        }
    }

    if(point.x == -1){
        [xValue setStringValue:@""];
        [yValue setStringValue:@""];
    }
    if(!color) {
        [redValue setStringValue:@""];
        [greenValue setStringValue:@""];
        [blueValue setStringValue:@""];
        [alphaValue setStringValue:@""];
        [radiusValue setStringValue:@""];

        [colorWell setColorValue:NULL];
    }
}

- (void)update
{
    [toggleButton setState:[self visible]];
    
    if (![self visible])
        return;

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doUpdate) object:NULL];
    [self performSelector:@selector(doUpdate) withObject:NULL afterDelay:0.025];
	
}

- (BOOL)visible
{
	return [[[document window] contentView] visibilityForRegion: kPointInformation];
}

@end

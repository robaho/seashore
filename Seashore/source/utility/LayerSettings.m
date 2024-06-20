#import "LayerSettings.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "LayersUtility.h"
#import "SeaDocument.h"
#import "SeaHelpers.h"
#import "Units.h"
#import "InfoPanel.h"

@implementation LayerSettings

- (void)awakeFromNib
{
	settingsLayer = nil;
	[(InfoPanel *)panel setPanelStyle:kHorizontalPanelStyle];	
}

- (void)showSettings:(SeaLayer *)layer from:(NSPoint)point
{
	id contents = [document contents];
	float xres, yres;

    [[document helpers] endLineDrawing];
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	units = [document measureStyle];
	
    [layerTitle setStringValue:[layer name]];
    [layerTitle setEnabled:YES];

	[leftValue setStringValue:StringFromPixels([layer xoff],units,xres)];
	[topValue setStringValue:StringFromPixels([layer yoff], units, yres)];
	[widthValue setStringValue:StringFromPixels([layer width],units,xres)];
	[heightValue setStringValue:StringFromPixels([layer height],units, yres)];	
	[leftUnits setStringValue:UnitsString(units)];
	[topUnits setStringValue:UnitsString(units)];
	[widthUnits setStringValue:UnitsString(units)];
	[heightUnits setStringValue:UnitsString(units)];
	
	if (document && layer) {
		
        [opacitySlider setIntValue:[layer opacity]];
        [opacitySlider setEnabled:YES];
        [opacityLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", (float)[layer opacity] / 2.55]];
		
        [modePopup selectItemAtIndex:[modePopup indexOfItemWithTag:[layer mode]]];
        [modePopup setEnabled:YES];
		
		[linkedCheckbox setEnabled: YES];
		[linkedCheckbox setState:[layer linked]];

		[alphaEnabledCheckbox setEnabled: [layer canToggleAlpha]];
		[alphaEnabledCheckbox setState:[layer hasAlpha]];
	}else{
		// Turn off the opacity
		[opacitySlider setIntValue:255];
		[opacitySlider setEnabled:NO];
		[opacityLabel setStringValue:@"100.0%"];
		
		// Turn off the mode
		[modePopup selectItemAtIndex:0];
		[modePopup setEnabled:NO];
		
		[linkedCheckbox setEnabled:NO];
		[alphaEnabledCheckbox setEnabled:NO];
	}
	
	// Display layer settings panel
	[panel orderFrontToGoal:point onWindow: [document window]];
	
	settingsLayer = layer;

    xoff = [layer xoff];
    yoff = [layer yoff];

	[NSApp runModalForWindow:panel];
}

- (IBAction)apply:(id)sender
{
	id contents = [document contents];
	SeaLayer* layer = settingsLayer;
	int newLeftValue, newTopValue;
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];

	// Parse width and height	
	newLeftValue = PixelsFromFloat([leftValue floatValue],units, xres);
	newTopValue = PixelsFromFloat([topValue floatValue],units,yres);
	
	if (xoff != newLeftValue || yoff != newTopValue)
		[self setOffsetsLeft:newLeftValue top:newTopValue index:[layer index]];
	
	// Change the layer's name
	if ([layer name]) {
		if (![[layerTitle stringValue] isEqualToString:[layer name]])
			[self setName:[NSString stringWithString:[layerTitle stringValue]] index:[layer index]];
	}
	
	// End the panel
	[NSApp stopModal];
	[[document window] removeChildWindow:panel];
	[panel orderOut:self];

	settingsLayer = nil;
}

- (IBAction)cancel:(id)sender
{
	settingsLayer = nil;
	[NSApp stopModal];
	[[document window] removeChildWindow:panel];
	[panel orderOut:self];
}

- (void)setOffsetsLeft:(int)left top:(int)top index:(int)index
{
	SeaLayer* layer;
	IntPoint oldOffsets;
	
	// Correct the index
	if (index == kActiveLayer)
		index = [[document contents] activeLayerIndex];
	layer = [[document contents] layer:index];
	
	oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
	[[[document undoManager] prepareWithInvocationTarget:self] setOffsetsLeft:oldOffsets.x top:oldOffsets.y index:index];
	
	[layer setOffsets:IntMakePoint(left, top)];
	
	[[document helpers] layerOffsetsChanged:index from:oldOffsets];
}

- (void)setName:(NSString *)newName index:(int)index
{
	SeaLayer* layer;
	
	// Correct the index
	if (index == kActiveLayer)
		index = [[document contents] activeLayerIndex];
	layer = [[document contents] layer:index];
	
	[[[document undoManager] prepareWithInvocationTarget:self] setName:[layer name] index:index];
	
	[layer setName:newName];
	
	[[document helpers] layerTitleChanged];
}

- (IBAction)changeMode:(id)sender
{
	SeaLayer* layer = settingsLayer;
	
	[[[document undoManager] prepareWithInvocationTarget:self] undoMode:[layer index] to:[layer mode]];
	[layer setMode:(int)[[modePopup selectedItem] tag]];
	[[document helpers] layerAttributesChanged:kActiveLayer hold:YES];
}

- (void)undoMode:(int)index to:(int)value
{
	SeaLayer* layer = [[document contents] layer:index];
	
	[[[document undoManager] prepareWithInvocationTarget:self] undoMode:index to:[layer mode]];
	[layer setMode:value];
	[[document helpers] layerAttributesChanged:index hold:NO];
}

- (IBAction)changeOpacity:(id)sender
{
	SeaLayer* layer = settingsLayer;
	
	if ([[NSApp currentEvent] type] == NSLeftMouseDown)
		[[[document undoManager] prepareWithInvocationTarget:self] undoOpacity:[layer index] to:[layer opacity]];

    [layer setOpacity:[opacitySlider intValue]];
    [[document helpers] layerAttributesChanged:kActiveLayer hold:YES];
    
	[opacityLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", (float)[opacitySlider intValue] / 2.55]];
}

- (void)undoOpacity:(int)index to:(int)value
{
	SeaLayer* layer = [[document contents] layer:index];
	
	[[[document undoManager] prepareWithInvocationTarget:self] undoOpacity:index to:[layer opacity]];
	[layer setOpacity:value];
	[[document helpers] layerAttributesChanged:index hold:NO];
}


- (IBAction)changeLinked:(id)sender
{
	[[document contents] setLinked:[linkedCheckbox state] forLayer: [settingsLayer index]];
	[linkedCheckbox setState:[settingsLayer linked]];
}

- (IBAction)changeEnabledAlpha:(id)sender
{
	SeaLayer* layer = settingsLayer;

	if([layer canToggleAlpha]){
		[layer toggleAlpha];
	}
	[alphaEnabledCheckbox setState: [layer hasAlpha]];
}

@end

#import "StatusUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaHelpers.h"
#import "Units.h"
#import "LayerControlView.h"
#import "ToolboxUtility.h"
#import "SeaView.h"
// #import "WebSlider.h"
#import "SeaWindowContent.h"

@implementation StatusUtility
- (void)awakeFromNib
{
	[[SeaController utilitiesManager] setStatusUtility: self for:document];
	
	[(LayerControlView *)view setHasResizeThumb: NO];
	
	// This is how you're SUPPOSED to change these things
	[[channelSelectionPopup itemAtIndex: 0] setTitle: @""];
	[[channelSelectionPopup itemAtIndex: 0] setImage: [NSImage imageNamed: @"channels-menu"]];
	// But this is what apparently works in 10.4
	[channelSelectionPopup setTitle: @""];
	[channelSelectionPopup setImage: [NSImage imageNamed: @"channels-menu"]];
	
	/*
	 
	// Stub function calls for when this feature is implemented
	 
	if([(SeaContent *)[document contents] type] == 0){	
		[(WebSlider *)redSlider setSliderType: kRedSlider];
		[(WebSlider *)greenSlider setSliderType: kGreenSlider];
		[(WebSlider *)blueSlider setSliderType: kBlueSlider];
	}else{
		[(WebSlider *)redSlider setSliderType: kGraySlider];
		[(WebSlider *)greenSlider setSliderType: kGraySlider];
		[(WebSlider *)blueSlider setSliderType: kGraySlider];
	}
	[(WebSlider *)alphaSlider setSliderType:kAlphaSlider];
	*/
	
	[self update];
}

- (IBAction)show:(id)sender
{
	[[[document window] contentView] setVisibility: YES forRegion: kStatusBar];
	[self update];
	[self updateZoom];
	[self updateQuickColor];
}

- (IBAction)hide:(id)sender
{
	[[[document window] contentView] setVisibility: NO forRegion: kStatusBar];
}

- (IBAction)toggle:(id)sender
{
	if([[[document window] contentView] visibilityForRegion: kStatusBar]) {
		[self hide:sender];
	}else{
		[self show:sender];
	}
}

- (void)update
{
	if(document){
		SeaContent *contents = [document contents];

		// Set the channel selections correction
		int i;
		for(i = 0; i < 3; i++){
			if([contents selectedChannel] == i){
				[[channelSelectionPopup itemAtIndex: i + 1] setState: YES];
			}else{
				[[channelSelectionPopup itemAtIndex: i + 1] setState: NO];
			}
		}
		
		[channelSelectionPopup selectItemAtIndex:([contents selectedChannel] + 1)];
		[channelSelectionPopup setEnabled:YES];
		[trueViewCheckbox setImage:[NSImage imageNamed:([contents trueView] ? @"trueview-sel" : @"trueview-not" )]];
		[trueViewCheckbox setEnabled:YES];
		
		int newUnits = [document measureStyle];
		NSString *statusString = @"";
		unichar ch = 0x00B7; // replace this with your code pointNSString
		NSString *divider = [NSString stringWithCharacters:&ch length:1];
		if([view frame].size.width > 445){
			statusString = [statusString stringByAppendingFormat: @"%@ %C %@ %@", StringFromPixels([contents width] , newUnits, [contents xres]), 0x00D7, StringFromPixels([contents height], newUnits, [contents yres]), UnitsString(newUnits)];
		}
		if([view frame].size.width > 480){
			statusString = [[NSString stringWithFormat:@"%.0f%% %@ ", [contents xscale] * 100, divider] stringByAppendingString: statusString];
		}
		if([view frame].size.width > 525){
			statusString = [statusString stringByAppendingFormat: @" %@ %d dpi", divider, [contents xres]];
		}
		if([view frame].size.width > 575){
			statusString = [statusString stringByAppendingFormat: @" %@ %@", divider, [contents type] ? @"Grayscale" : @"Full Color"];
		}
		
		[dimensionLabel setStringValue: statusString];		

		[view setNeedsDisplay: YES];
	}else{
		// Disable the channel selections
		[channelSelectionPopup setEnabled:NO];
		[channelSelectionPopup selectItemAtIndex:0];
		[trueViewCheckbox setEnabled:NO];
		[trueViewCheckbox setImage:[NSImage imageNamed:@"trueview-not"]];
		
		[dimensionLabel setStringValue:@""];		
	}
}

-(void)updateZoom
{
	if(document){
		[zoomSlider setIntValue: (int)log2([[document contents] xscale])];	
	}else{
		[zoomSlider setEnabled: NO];
		[zoomSlider setIntValue: 0];
	}
}

-(void)updateQuickColor
{
	if(document){
		SeaContent *contents = [document contents];
		NSColor *foreground = [contents foreground];
		// REMEBER, FIRST WE NEED TO GET THE APPROPRIATE COLOR SPACE
		if(![contents type]){
			[redBox setIntValue: (int)round([foreground redComponent] * 255)];
			[blueBox setIntValue: (int)round([foreground blueComponent] * 255)];
			[greenBox setIntValue: (int)round([foreground greenComponent] * 255)];
		}else{
			[redBox setIntValue: (int)round([foreground whiteComponent] * 255)];
			[blueBox setIntValue: (int)round([foreground whiteComponent] * 255)];
			[greenBox setIntValue: (int)round([foreground whiteComponent] * 255)];
		}
		[alphaBox setIntValue: (int)round([foreground alphaComponent] * 255)];
		
		/*[redSlider setNeedsDisplay: YES];
		[greenSlider setNeedsDisplay: YES];
		[blueSlider setNeedsDisplay:YES];
		[alphaSlider setNeedsDisplay:YES];*/
		
	}else{
		
		[redBox setIntValue: 0];
		[blueBox setIntValue: 0];
		[greenBox setIntValue: 0];
		[alphaBox setIntValue: 0];
		
	}
}

- (IBAction)changeChannel:(id)sender
{
	[NSMenu popUpContextMenu:[sender menu] withEvent:[[NSEvent alloc] init]  forView: sender];
}

- (IBAction)channelChanged:(id)sender
{
	[[document contents] setSelectedChannel:[sender tag] % 10];
	[[document helpers] channelChanged];	
}

- (IBAction)trueViewChanged:(id)sender
{
	[[document contents] setTrueView:![[document contents] trueView]];
	[[document helpers] channelChanged];	
	[self update];
}

- (IBAction)quickColorChange:(id)sender
{
	ToolboxUtility *util = (ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document];
	
	//NSLog(@"red value %d set to color value %f (which currently is %f or %d)",[redBox intValue], (float)[redBox intValue] / 255.0, ([foreground redComponent]), (int)round([foreground redComponent] * 255));
	if([(SeaContent *)[document contents] type]){
		[util setForeground: [NSColor colorWithCalibratedWhite:[sender intValue] / 255.0 alpha:[alphaBox intValue] /255.0]];
	}else{
		[util setForeground: [NSColor colorWithCalibratedRed:[redBox intValue] / 255.0 + 1.0/512.0 green:[greenBox intValue] / 255.0 blue:[blueBox intValue]/255.0 alpha:[alphaBox intValue] /255.0]];
	}
	[util update:YES];
}

- (IBAction)changeZoom:(id)sender
{
	[(SeaView *)[document docView] zoomTo: [sender intValue]];
}

- (IBAction)zoomIn:(id)sender
{
	[(SeaView *)[document docView] zoomIn: self];
}

- (IBAction)zoomOut:(id)sender
{
	[(SeaView *)[document docView] zoomOut: self];
}

- (IBAction)zoomNormal:(id)sender
{
	[(SeaView *)[document docView] zoomNormal: self];
}

- (id)view
{
	return view;
}

@end

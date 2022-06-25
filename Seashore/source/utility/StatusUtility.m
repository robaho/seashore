#import "StatusUtility.h"
#import "SeaController.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaHelpers.h"
#import "Units.h"
#import "ToolboxUtility.h"
#import "SeaView.h"
#import "SeaWindowContent.h"

@implementation StatusUtility
- (void)awakeFromNib
{
}

- (void)shutdown
{
}

- (IBAction)show:(id)sender
{
	[[[document window] contentView] setVisibility: YES forRegion: kStatusBar];
	[self update];
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
    [self updateZoom];
    
	if(document){
		SeaContent *contents = [document contents];
        
		[channelSelectionPopup setEnabled:YES];
        [channelSelectionPopup setState:[contents selectedChannel]!=kAllChannelsView];
		[trueViewCheckbox setEnabled:YES];
        [trueViewCheckbox setState:[contents trueView]];
		
		int newUnits = [document measureStyle];
		NSString *statusString = @"";
		unichar ch = 0x00B7; // replace this with your code pointNSString
		NSString *divider = [NSString stringWithCharacters:&ch length:1];
        statusString = [statusString stringByAppendingFormat: @"%@ %C %@ %@", StringFromPixels([contents width] , newUnits, [contents xres]), 0x00D7, StringFromPixels([contents height], newUnits, [contents yres]), UnitsString(newUnits)];
        statusString = [[NSString stringWithFormat:@"%.0f%% %@ ", [[document docView] zoom] * 100, divider] stringByAppendingString: statusString];
        statusString = [statusString stringByAppendingFormat: @" %@ %d dpi", divider, [contents xres]];
        statusString = [statusString stringByAppendingFormat: @" %@ %@", divider, [contents type] ? @"Grayscale" : @"Full Color"];
        
        SeaColorProfile *cp = [[document whiteboard] proofProfile];
        if(cp!=NULL && cp.cs!=NULL) {
            statusString = [statusString stringByAppendingFormat: @" %@ %@", divider, [cp desc]];
        }
		
		[dimensionLabel setStringValue: statusString];		

		[view setNeedsDisplay: YES];
	}else{
		// Disable the channel selections
		[channelSelectionPopup setEnabled:NO];
		[channelSelectionPopup selectItemAtIndex:0];
		[trueViewCheckbox setEnabled:NO];
        [trueViewCheckbox setState:NSControlStateValueOff];

		[dimensionLabel setStringValue:@""];		
	}
}

-(void)updateZoom
{
	if(document){
        int val = (int)log2([[document docView] zoom]);
		[zoomSlider setIntValue:val ];
	}else{
		[zoomSlider setEnabled: NO];
		[zoomSlider setIntValue: 0];
	}
}

- (IBAction)channelClicked:(id)sender
{
    NSMenu *menu = [channelSelectionPopup menu];
    [NSMenu popUpContextMenu:menu withEvent:[[NSApplication sharedApplication] currentEvent] forView:(NSButton *)sender];
}


- (IBAction)channelChanged:(id)sender
{
	[[document contents] setSelectedChannel:[sender tag] % 450];
	[[document helpers] channelChanged];	
}

- (IBAction)trueViewChanged:(id)sender
{
	[[document contents] setTrueView:![[document contents] trueView]];
	[[document helpers] channelChanged];	
	[self update];
}

- (IBAction)changeZoom:(id)sender
{
	[[document docView] zoomTo: [sender intValue]];
}

- (IBAction)zoomIn:(id)sender
{
	[[document docView] zoomIn: self];
}

- (IBAction)zoomOut:(id)sender
{
	[[document docView] zoomOut: self];
}

- (IBAction)zoomNormal:(id)sender
{
	[[document docView] zoomNormal: self];
}

- (IBAction)zoomToFit:(id)sender
{
    [[document docView] zoomToFit: self];
}

- (id)view
{
	return view;
}

- (BOOL)validateMenuItem:(id)menuItem
{
    int channel = [[document contents] selectedChannel];
    int tag = 450 + channel;

    [menuItem setState:[menuItem tag]==tag];

    return TRUE;
}

@end

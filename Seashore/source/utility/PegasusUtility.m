#import "PegasusUtility.h"
#import "SeaLayer.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "LayerSettings.h"
#import "SeaHelpers.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "UtilitiesManager.h"
#import "SeaProxy.h"
#import "SeaWindowContent.h"

@implementation PegasusUtility

- (id)init
{
	return self;
}

- (void)awakeFromNib
{
	// Enable the utility
	enabled = YES;
	
	[[SeaController utilitiesManager] setPegasusUtility: self for:document];
}

- (void)dealloc
{
	//if ([layersView documentView]) [[layersView documentView] autorelease];
	[super dealloc];
}

- (void)activate
{
	// Get the LayersView and LayerSettings to activate
	[(LayerSettings *)layerSettings activate];
	[self update:kPegasusUpdateAll];
}

- (void)deactivate
{
	// Get the LayersView and LayerSettings to deactivate
	[layerSettings deactivate];
	[self update:kPegasusUpdateAll];
}

- (void)update:(int)updateCode
{
	id layer = [[document contents] activeLayer];
	
	switch (updateCode) {
		case kPegasusUpdateAll:
			if (document && layer && enabled) {
				// Enable the layer buttons
				[newButton setEnabled:YES];
				[duplicateButton setEnabled:YES];
				[upButton setEnabled:YES];
				[downButton setEnabled:YES];
				[deleteButton setEnabled:YES];
			}
			else {
				// Disable the layer buttons
				[newButton setEnabled:NO];
				[duplicateButton setEnabled:NO];
				[upButton setEnabled:NO];
				[downButton setEnabled:NO];
				[deleteButton setEnabled:NO];
			}
		break;
	}
	[dataSource update];
}

- (id)layerSettings
{
	return layerSettings;
}

- (IBAction)show:(id)sender
{
	[[[document window] contentView] setVisibility: YES forRegion: kSidebar];
}

- (IBAction)hide:(id)sender
{
	[[[document window] contentView] setVisibility: NO forRegion: kSidebar];
}

- (void)setEnabled:(BOOL)value
{
	enabled = value;
	[self update:kPegasusUpdateAll];
}

- (IBAction)toggleLayers:(id)sender
{
	if ([self visible])
		[self hide:sender];
	else
		[self show:sender];
}

- (BOOL)validateMenuItem:(id)menuItem
{
	id layer = [[document contents] activeLayer];
	
	// Switch to the appropriate code block given menu item
	switch ([menuItem tag]) {
		case 1002:
			if (![layer hasAlpha])
				return NO;
		break;
	}
	
	return YES;
}

- (BOOL)visible
{
	return [[[document window] contentView] visibilityForRegion: kSidebar];
}

- (IBAction)addLayer:(id)sender
{
	[(SeaContent*)[document contents] addLayer:kActiveLayer];
}

- (IBAction)duplicateLayer:(id)sender
{
	id selection = [document selection];
	
	if (![selection floating]) {
		[(SeaContent *)[document contents] duplicateLayer:kActiveLayer];
	}
}

- (IBAction)deleteLayer:(id)sender
{
	if ([[document contents] layerCount] > 1){
		[(SeaContent *)[document contents] deleteLayer:kActiveLayer];
	}else{
		NSBeep();
	}
}

@end

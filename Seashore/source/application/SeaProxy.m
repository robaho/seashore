#import "SeaProxy.h"
#import "SeaDocument.h"
#import "SeaView.h"
#import "SeaContent.h"
#import "SeaResolution.h"
#import "SeaMargins.h"
#import "SeaScale.h"
#import "SeaWhiteboard.h"
#import "SeaLayer.h"
#import "SeaOperations.h"
#import "SeaSelection.h"
#import "SeaController.h"
#import "SeaTools.h"
#import "ToolboxUtility.h"
#import "SeaFlip.h"
#import "TextureExporter.h"
#import "BrushExporter.h"
#import "SeaAlignment.h"
#import "SeaPlugins.h"
#import "SeaRotation.h"
#import "SeaDocRotation.h"
#import "TextTool.h"
#import "ColorSelectView.h"
#import "SeaHelpers.h"
#import "SeaWindowContent.h"

@implementation SeaProxy

- (IBAction)exportAsTexture:(id)sender
{
	[[gCurrentDocument textureExporter] exportAsTexture:sender];
}

- (IBAction)exportAsBrush:(id)sender
{
    [[gCurrentDocument brushExporter] exportAsBrush:sender];
}


- (IBAction)zoomIn:(id)sender
{
	[[gCurrentDocument docView] zoomIn:sender];
}

- (IBAction)zoomNormal:(id)sender
{
	[[gCurrentDocument docView] zoomNormal:sender];
}

- (IBAction)zoomToFit:(id)sender
{
    [[gCurrentDocument docView] zoomToFit:sender];
}

- (IBAction)zoomOut:(id)sender
{
	[[gCurrentDocument docView] zoomOut:sender];
}

- (IBAction)toggleSoftProof:(id)sender
{
    [[gCurrentDocument whiteboard] toggleSoftProof:(ColorSyncProfileRef)NULL];
}

#ifdef PERFORMANCE
- (IBAction)resetPerformance:(id)sender
{
	[[gCurrentDocument whiteboard] resetPerformance];
}
#endif

- (IBAction)importLayer:(id)sender
{
	[[gCurrentDocument contents] importLayer];
}

- (IBAction)copyMerged:(id)sender
{
	[[gCurrentDocument contents] copyMerged];
}

- (IBAction)flatten:(id)sender
{
	// Warn before flattening the image
	if (NSRunAlertPanel(LOCALSTR(@"flatten title", @"Information will be lost"), LOCALSTR(@"flatten body", @"Parts of the document that are not currently visible will be lost. Are you sure you wish to continue?"), LOCALSTR(@"flatten", @"Flatten"), LOCALSTR(@"cancel", @"Cancel"), NULL) == NSAlertDefaultReturn)
		[[gCurrentDocument contents] flatten];
}

- (IBAction)mergeLinked:(id)sender
{
	[[gCurrentDocument contents] mergeLinked];
}

- (IBAction)mergeDown:(id)sender
{
	[[gCurrentDocument contents] mergeDown];
}

- (IBAction)raiseLayer:(id)sender
{
	[(SeaContent *)[gCurrentDocument contents] raiseLayer:kActiveLayer];
}

- (IBAction)bringToFront:(id)sender
{
	[(SeaContent *)[gCurrentDocument contents] moveLayerOfIndex:kActiveLayer toIndex: 0];
}

- (IBAction)lowerLayer:(id)sender
{
	[(SeaContent *)[gCurrentDocument contents] lowerLayer:kActiveLayer];
}

- (IBAction)sendToBack:(id)sender
{
	[(SeaContent *)[gCurrentDocument contents] moveLayerOfIndex:kActiveLayer toIndex: [(SeaContent *)[gCurrentDocument contents] layerCount]];	
}

- (IBAction)deleteLayer:(id)sender
{
	id document = gCurrentDocument;
	
	if ([[document contents] layerCount] > 1)
		[(SeaContent *)[document contents] deleteLayer:kActiveLayer];
	else
		NSBeep();
}

- (IBAction)addLayer:(id)sender
{
	SeaContent *contents = [gCurrentDocument contents];
	[contents addLayer:kActiveLayer];
}

- (IBAction)duplicateLayer:(id)sender
{
    [(SeaContent *)[gCurrentDocument contents] duplicateLayer:kActiveLayer];
}

- (IBAction)layerAbove:(id)sender
{
	[(SeaContent *)[gCurrentDocument contents] layerAbove];
}

- (IBAction)layerBelow:(id)sender
{
	[(SeaContent *)[gCurrentDocument contents] layerBelow];
}

- (IBAction)setColorSpace:(id)sender
{
	[[gCurrentDocument contents] convertToType:[sender tag] - 240];
}

- (IBAction)toggleLinked:(id)sender
{
	[[gCurrentDocument contents] setLinked: ![[[gCurrentDocument contents] activeLayer] linked] forLayer: kActiveLayer];
}

- (IBAction)clearAllLinks:(id)sender
{
	[[gCurrentDocument contents] clearAllLinks];
}

- (IBAction)toggleFloatingSelection:(id)sender
{
	id selection = [gCurrentDocument selection];
	id contents = [gCurrentDocument contents];
	
	if ([selection floating]) {
		[contents anchorLayer];
	}
	else {
		[contents makeSelectionFloat:NO];
	}
}

- (IBAction)duplicate:(id)sender
{
	[[gCurrentDocument contents] makeSelectionFloat: YES];
}

- (IBAction)toggleLayerAlpha:(id)sender
{
	[[[gCurrentDocument contents] activeLayer] toggleAlpha];
}

- (IBAction)changeSelectedChannel:(id)sender
{
	[[gCurrentDocument contents] setSelectedChannel: [sender tag] % 10];
	[[gCurrentDocument helpers] channelChanged];	
}

- (IBAction)changeTrueView:(id)sender
{
	[[gCurrentDocument contents] setTrueView: ![sender state]];
	[[gCurrentDocument helpers] channelChanged];
}


- (IBAction)alignLeft:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaAlignment] alignLeft:sender];
}

- (IBAction)alignRight:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaAlignment] alignRight:sender];
}

- (IBAction)alignHorizontalCenters:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaAlignment] alignHorizontalCenters:sender];
}

- (IBAction)alignTop:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaAlignment] alignTop:sender];
}

- (IBAction)alignBottom:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaAlignment] alignBottom:sender];
}

- (IBAction)alignVerticalCenters:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaAlignment] alignVerticalCenters:sender];
}

- (IBAction)centerLayerHorizontally:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaAlignment] centerLayerHorizontally:sender];
}

- (IBAction)centerLayerVertically:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaAlignment] centerLayerVertically:sender];
}

- (IBAction)setResolution:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaResolution] run];
}

- (IBAction)setMargins:(id)sender
{
	[(SeaMargins *)[(SeaOperations *)[gCurrentDocument operations] seaMargins] run:YES];
}

- (IBAction)setLayerMargins:(id)sender
{
	[(SeaMargins *)[(SeaOperations *)[gCurrentDocument operations] seaMargins] run:NO];
}

- (IBAction)flipDocHorizontally:(id)sender;
{
	[[(SeaOperations *)[gCurrentDocument operations] seaDocRotation] flipDocHorizontally];
}

- (IBAction)flipDocVertically:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaDocRotation] flipDocVertically];
}

- (IBAction)rotateDocLeft:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaDocRotation] rotateDocLeft];
}

- (IBAction)rotateDocRight:(id)sender
{
	[[(SeaOperations *)[gCurrentDocument operations] seaDocRotation] rotateDocRight];
}

- (IBAction)setLayerRotation:(id)sender
{
	[(SeaRotation *)[(SeaOperations *)[gCurrentDocument operations] seaRotation] run];
}

- (IBAction)condenseLayer:(id)sender
{
	[(SeaMargins *)[(SeaOperations *)[gCurrentDocument operations] seaMargins] condenseLayer:sender];
}

- (IBAction)condenseToSelection:(id)sender
{
	[(SeaMargins *)[(SeaOperations *)[gCurrentDocument operations] seaMargins] condenseToSelection:sender];
}

- (IBAction)expandLayer:(id)sender
{
	[(SeaMargins *)[(SeaOperations *)[gCurrentDocument operations] seaMargins] expandLayer:sender];
}

- (IBAction)setScale:(id)sender
{
	[(SeaScale *)[(SeaOperations *)[gCurrentDocument operations] seaScale] run:YES];
}

- (IBAction)setLayerScale:(id)sender
{
	[(SeaScale *)[(SeaOperations *)[gCurrentDocument operations] seaScale] run:NO];
}

- (IBAction)flipHorizontally:(id)sender
{
	[(SeaFlip *)[(SeaOperations *)[gCurrentDocument operations] seaFlip] run:kHorizontalFlip];
}

- (IBAction)flipVertically:(id)sender
{
	[(SeaFlip *)[(SeaOperations *)[gCurrentDocument operations] seaFlip] run:kVerticalFlip];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	return [gCurrentDocument undoManager];
}

- (IBAction)reapplyEffect:(id)sender
{
	[[SeaController seaPlugins] reapplyEffect:sender];
}

// To Utitilies
- (IBAction)selectTool:(id)sender
{
	[[gCurrentDocument toolboxUtility] selectToolUsingTag:sender];
}

- (IBAction)toggleLayers:(id)sender
{
	[[gCurrentDocument pegasusUtility] toggleLayers:sender];
}

- (IBAction)toggleInformation:(id)sender
{
	[[gCurrentDocument infoUtility] toggle: sender];
}

- (IBAction)toggleOptions:(id)sender
{
	[[gCurrentDocument optionsUtility] toggle: sender];
}

- (IBAction)toggleStatusBar:(id)sender
{
	[[gCurrentDocument statusUtility] toggle: sender];
}

- (IBAction)toggleRecentsBar:(id)sender {
    [[gCurrentDocument recentsUtility] toggle: sender];
}

// To the ColorView
- (IBAction)activateForegroundColor:(id)sender
{
	[(ColorSelectView *)[[gCurrentDocument toolboxUtility] colorView] activateForegroundColor: sender];
}

- (IBAction)activateBackgroundColor:(id)sender
{
	[[[gCurrentDocument toolboxUtility] colorView] activateBackgroundColor: sender];
}

- (IBAction)swapColors:(id)sender
{
	[[[gCurrentDocument toolboxUtility] colorView] swapColors: sender];
}

- (IBAction)defaultColors:(id)sender
{
	[[[gCurrentDocument toolboxUtility] colorView] defaultColors: sender];
}

- (BOOL)validateMenuItem:(id)menuItem
{
	id document = gCurrentDocument;
	id contents = [document contents];
	
	// Never when there is no document
	if (document == NULL)
		return NO;
	
    int tag = (int)[menuItem tag];
	
	// Sometimes we always enable
	if (tag == 999)
		return YES;
	
	// Never when the document is locked
	if ([document locked])
		return NO;
    
    if(tag>=270 && tag<=273){
        return [[gCurrentDocument docView] validateMenuItem:menuItem];
    }
	
	// Sometimes in other cases
	switch (tag) {
		case 200:
			if([[[document window] contentView] visibilityForRegion: kSidebar])
				[menuItem setTitle:@"Hide Layers"];
			else
				[menuItem setTitle:@"Show Layers"];
			return YES;
		break;
		case 192:
			if([[[document window] contentView] visibilityForRegion:kPointInformation])
				[menuItem setTitle:@"Hide Point Information"];
			else
				[menuItem setTitle:@"Show Point Information"];
			return YES;
		break;
		case 191:
			if([[[document window] contentView] visibilityForRegion: kOptionsBar])
				[menuItem setTitle:@"Hide Options Bar"];
			else
				[menuItem setTitle:@"Show Options Bar"];
			return YES;			
		break;
		case 194:
			if([[[document window] contentView] visibilityForRegion:kStatusBar])
				[menuItem setTitle:@"Hide Status Bar"];
			else
				[menuItem setTitle:@"Show Status Bar"];
			return YES;			
		break;
        case 195:
            if([[[document window] contentView] visibilityForRegion:kRecentsBar])
                [menuItem setTitle:@"Hide Recents Bar"];
            else
                [menuItem setTitle:@"Show Recents Bar"];
            return YES;
            break;
		case 210:
			if (![[document docView] canZoomIn])
				return NO;
		break;
		case 211:
			if (![[document docView] canZoomOut])
				return NO;
		break;
		case 213:
		case 214:
			if ([contents canRaise:kActiveLayer] == NO)
				return NO;
		break;
		case 215:
		case 216:
			if ([contents canLower:kActiveLayer] == NO)
				return NO;
		break;
		case 219:
			if ([[document contents] layerCount] <= 1)
				return NO;
		break;
		case 220:
			if ([contents canFlatten] == NO)
				return NO;
		break;
		case 240:
		case 241:
			[menuItem setState:[menuItem tag] == 240 + [(SeaContent *)contents type]];
		break;
		case 250:
			if ([[contents activeLayer] hasAlpha])
				[menuItem setTitle:LOCALSTR(@"disable alpha", @"Disable Alpha Channel")];
			else
				[menuItem setTitle:LOCALSTR(@"enable alpha", @"Enable Alpha Channel")];
			if (![[contents activeLayer] canToggleAlpha])
				return NO;
		break;
		case 264:
			if(![[document selection] active])
				return NO;
		break;
		case 300:
			if ([[document selection] floating])
				[menuItem setTitle:LOCALSTR(@"anchor layer", @"Anchor Layer")];
			else
				[menuItem setTitle:LOCALSTR(@"float selection", @"Float Selection")];
			if (![[document selection] active])
				return NO;
		break;
		case 320:
		case 321:
		case 322:
		case 330:
		case 331:
		case 360:
		case 361:
		case 362:
		case 410:
		case 411:
		case 412:
		case 413:
            // floating is like any other layer
//			if ([[document selection] floating])
//				return NO;
		break;
		case 450:
		case 451:
		case 452:
            // floating is like any other layer
//			if([[document selection] floating])
//				return NO;
			[menuItem setState: [[document contents] selectedChannel] == [menuItem tag] % 10];
		break;
		case 460:
			[menuItem setState: [contents trueView]];
		break;
		case 340:
		case 341:
		case 342:
		case 345:
		case 346:
		case 347:
		case 349:
            // disabled check, because multiple floating layers are allowed
//			if (![[contents activeLayer] linked])
//				return NO;
		break;
		case 382:
			if ([[contents activeLayer] linked]){
				[menuItem setTitle:@"Unlink Layer"];
			}else{
				[menuItem setTitle:@"Link Layer"];
			}
		break;
		case 380:
			if (![[SeaController seaPlugins] hasLastEffect])
				return NO;
		break;
	}
	
	return YES;
}

- (IBAction)crash:(id)sender
{
	int i;
	
	for (i = 0; i < 5000; i++) {
		*((char *)i) = 0xFF;
	}
}

@end

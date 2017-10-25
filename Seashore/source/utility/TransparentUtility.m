#import "TransparentUtility.h"
#import "SeaDocument.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "UtilitiesManager.h"

@implementation TransparentUtility

- (id)init
{
	float values[4];
	NSData *tempData;
	
	// Determine the initial color (from preferences if possible)
	if ([gUserDefaults objectForKey:@"transparency color data"] == NULL) {
		values[0] = values[1] = values[2] = values[3] = 1.0;
		color = [NSColor colorWithCalibratedRed:values[0] green:values[1] blue:values[2] alpha:values[3]];
	}
	else {
		tempData = [gUserDefaults dataForKey:@"transparency color data"];
		if (tempData != nil)
			color = (NSColor *)[NSUnarchiver unarchiveObjectWithData:tempData];
	}
	[color retain];
	
	return self;
}

- (void)dealloc
{
	if (color) [color autorelease];
	[super dealloc];
}

- (IBAction)toggle:(id)sender
{
	BOOL panelOpen = [gColorPanel isVisible] && [[gColorPanel title] isEqualToString:LOCALSTR(@"transparent", @"Transparent")];
	
	if (!panelOpen) {
		[gColorPanel setAction:NULL];
		[gColorPanel setShowsAlpha:NO];
		[gColorPanel setColor:color];
		[gColorPanel orderFront:self];
		[gColorPanel setTitle:LOCALSTR(@"transparent", @"Transparent")];
		[gColorPanel setContinuous:NO];
		[gColorPanel setAction:@selector(changeColor:)];
		[gColorPanel setTarget:self];
	}
	else
		[gColorPanel orderOut:self];
}

- (void)changeColor:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	// Change the colour
	[color autorelease];
	color = [sender color];
	if (![[color colorSpaceName] isEqualToString:NSNamedColorSpace])
		[[sender color] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	[color retain];
	
	// Call for all documents' views to respond to the change
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}

	[gUserDefaults setObject:[NSArchiver archivedDataWithRootObject:color] forKey:@"transparency color data"];

}

- (id)color
{		
	return color;
}

@end

#import "ZoomOptions.h"
#import "ToolboxUtility.h"
#import "SeaDocument.h"
#import "SeaView.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation ZoomOptions

- (void)update
{
	[zoomLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"zoom", @"Zoom: %.0f%%"), [[document docView] zoom] * 100.0]];
}

@end

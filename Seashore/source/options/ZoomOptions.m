#import "ZoomOptions.h"
#import "ToolboxUtility.h"
#import "SeaDocument.h"
#import "SeaView.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation ZoomOptions

- (id)init:(id)document
{
    self = [super init:document];

    [super clearModifierMenu];
    [super addModifierMenuItem:@"Zoom out (Option)" tag:1];
    [self addSubview:modifierPopup];

    zoomLabel = [Label labelWithString:@"Zoom"];
    [self addSubview:zoomLabel];

    [self update:zoomLabel];

    return self;
}

- (IBAction)update:(id)sender
{
	[zoomLabel setTitle:[NSString stringWithFormat:LOCALSTR(@"zoom", @"Zoom: %.0f%%"), [[document docView] zoom] * 100.0]];
}

@end

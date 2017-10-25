#import "WarningsUtility.h"
#import "SeaWindowContent.h"
#import "BannerView.h"
#import "SeaWarning.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaDocument.h"

@implementation WarningsUtility

- (id)init
{
	self = [super init];
	if(self ){
		mostRecentImportance = -1;
	}
	return self;	
}

- (void)setWarning:(NSString *)message ofImportance:(int)importance
{
	[view setBannerText:message defaultButtonText:@"OK" alternateButtonText:NULL andImportance:importance];
	mostRecentImportance = importance;
	[windowContent setVisibility:YES forRegion:kWarningsBar];
}


- (void)showFloatBanner
{
	[view setBannerText:@"Drag the floating layer to position it, then click Anchor to merge it into the layer below." defaultButtonText:@"Anchor" alternateButtonText:@"New Layer" andImportance:kUIImportance];
	mostRecentImportance = kUIImportance;
	[windowContent setVisibility:YES forRegion:kWarningsBar];
}

- (void)hideFloatBanner
{
	mostRecentImportance = -1;
	[windowContent setVisibility:NO forRegion:kWarningsBar];	
}

- (void)keyTriggered
{
	if(mostRecentImportance != -1){
		[self defaultAction: self];
	}
}

- (IBAction)defaultAction:(id)sender
{
	if(mostRecentImportance == kUIImportance){
		mostRecentImportance = -1;
		[windowContent setVisibility:NO forRegion:kWarningsBar];
		[[document contents] toggleFloatingSelection];
	}else{
		mostRecentImportance = -1;
		[windowContent setVisibility:NO forRegion:kWarningsBar];
		[[SeaController seaWarning] triggerQueue: document];
	}
}


- (IBAction)alternateAction:(id)sender
{
	if(mostRecentImportance == kUIImportance){
		mostRecentImportance = -1;
		[windowContent setVisibility:NO forRegion:kWarningsBar];	
		[[document contents] addLayer:kActiveLayer];
	}
}

- (int)activeWarningImportance
{
	return mostRecentImportance;
}

@end

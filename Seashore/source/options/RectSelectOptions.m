#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaDocument.h"
#import "RectSelectOptions.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaContent.h"
#import "SeaSelection.h"
#import "SeaOperations.h"
#import "SeaMargins.h"
#import "Units.h"
#import "AspectRatio.h"

@implementation RectSelectOptions

- (id)init:(id)document
{
    self = [super init:document];

    radiusSlider = [SeaSlider sliderWithCheck:@"Corner Radius" Min:0 Max:80 Listener:NULL];
    [self addSubview:radiusSlider];

    aspectRatio =  [[AspectRatio alloc] init:document master:self andString:[self preferenceName]];
    [self addSubview:[aspectRatio view]];

	if ([gUserDefaults objectForKey:@"rect selection radius enabled"] == NULL)
		[radiusSlider setChecked:NSOffState];
	else
		[radiusSlider setChecked:[gUserDefaults boolForKey:@"rect selection radius enabled"]];

    [radiusSlider setIntValue:8];
	if ([gUserDefaults objectForKey:@"rect selection radius"] != NULL) {
        int value = [gUserDefaults integerForKey:@"rect selection radius"];
        [radiusSlider setIntValue:value];
    }

    return self;
}

- (NSString*)preferenceName {
    return @"rect";
}

- (int)radius
{
	if ([radiusSlider isChecked])
		return [radiusSlider intValue];
	else
		return 0;
}

- (NSSize)ratio
{
	return [aspectRatio ratio];
}

- (int)aspectType
{
	return [aspectRatio aspectType];
}

- (IBAction)update:(id)sender;
{
}

- (void)shutdown
{
	[gUserDefaults setInteger:[radiusSlider intValue] forKey:@"rect selection radius"];
	[gUserDefaults setObject:[radiusSlider isChecked] ? @"YES" : @"NO" forKey:@"rect selection radius enabled"];
	[aspectRatio shutdown];
}

@end

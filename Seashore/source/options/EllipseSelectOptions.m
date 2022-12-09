#import "EllipseSelectOptions.h"
#import "AspectRatio.h"

@implementation EllipseSelectOptions

- (id)init:(id)document
{
    self = [super init:document];
    [radiusSlider setHidden:TRUE];
    return self;
}

- (NSString*)preferenceName {
    return @"ellipse";
}


@end

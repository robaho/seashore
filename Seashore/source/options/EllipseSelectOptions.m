#import "EllipseSelectOptions.h"
#import "AspectRatio.h"

@implementation EllipseSelectOptions

- (void)awakeFromNib
{
    [aspectRatio awakeWithMaster:self andString:@"ellipse"];
}

@end

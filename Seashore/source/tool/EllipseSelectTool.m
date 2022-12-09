#import "EllipseSelectTool.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "EllipseSelectOptions.h"
#import "RectSelectOptions.h"
#import "SeaContent.h"
#import "SeaTools.h"
#import "SeaLayer.h"
#import "SeaWhiteboard.h"
#import "AspectRatio.h"

@implementation EllipseSelectTool

- (void)awakeFromNib {
    options = [[EllipseSelectOptions alloc] init:document];
}

- (int)toolId
{
	return kEllipseSelectTool;
}

- (void)createMask
{
    [[document selection] selectEllipse:[self selectionRect] mode:[options selectionMode]];
}

- (AbstractOptions*)getOptions
{
    return options;
}

@end

#import <SeaComponents/SeaComponents.h>
#import "ToneCurveClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation ToneCurveClass

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data filter:@"CIToneCurve" points:0 properties:NULL];

	pluginData = data;

    panel = [VerticalView view];

    view = [[CurveWithHistogram alloc] init];
    [[view curve] setListener:self];

    [panel addSubview:view];

    return self;
}

- (NSView*)initialize
{
    [self calculateHistogram:pluginData];

    return panel;
}

- (void)componentChanged:(id)slider
{
    [pluginData settingsChanged];
}

- (void)execute
{
    CIFilter *filter = [self getFilterInstance:filterName];

    CurveView *curve = [view curve];

    CGPoint p0 = [curve point:0];
    CGPoint p1 = [curve point:1];
    CGPoint p2 = [curve point:2];
    CGPoint p3 = [curve point:3];
    CGPoint p4 = [curve point:4];

    CIVector *point0 = [CIVector vectorWithX:p0.x Y:p0.y];
    CIVector *point1 = [CIVector vectorWithX:p1.x Y:p1.y];
    CIVector *point2 = [CIVector vectorWithX:p2.x Y:p2.y];
    CIVector *point3 = [CIVector vectorWithX:p3.x Y:p3.y];
    CIVector *point4 = [CIVector vectorWithX:p4.x Y:p4.y];

    [filter setValue:point0 forKey:@"inputPoint0"];
    [filter setValue:point1 forKey:@"inputPoint1"];
    [filter setValue:point2 forKey:@"inputPoint2"];
    [filter setValue:point3 forKey:@"inputPoint3"];
    [filter setValue:point4 forKey:@"inputPoint4"];

    [self applyFilter:filter];
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
	return YES;
}

- (void)calculateHistogram:(id<PluginData>)pluginData
{
    unsigned char *data;
    int width, height;

    data = [pluginData data];
    width = [pluginData width];
    height = [pluginData height];

    int *histogram = calloc(256,sizeof(int));

    // calculate value histogram

    for (int row = 0; row < height; row++) {
        for(int col = 0;col<width;col++) {
            int offset = (row*width+col)*SPP;

            if(data[offset+alphaPos]==0)
                continue; // ignore completely transparent pixels

            IntPoint p = IntMakePoint(col,row);
            if(![pluginData inSelection:p])
                continue;

            int max = 0;
            for (int j = CR; j <= CB; j++)
                max = MAX(max,data[offset + j]);
            histogram[max]++;
        }
    }

    [[view histogram] updateHistogram:0 histogram:histogram];
}

@end

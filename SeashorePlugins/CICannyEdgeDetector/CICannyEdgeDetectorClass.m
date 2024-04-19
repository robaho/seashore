#import "CICannyEdgeDetectorClass.h"

@implementation CICannyEdgeDetectorClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CICannyEdgeDetector" points:0 properties:kCI_GaussianSigma,kCI_ThresholdLow,kCI_ThresholdHigh,kCI_HysteresisPasses,kCI_Perceptual,0];
}

@end

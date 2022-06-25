//
//  AlphaToGrayFilter.m
//  Seashore
//
//  Created by robert engels on 12/31/21.
//

#include <CoreImage/CoreImage.h>
#import "AlphaToGrayFilter.h"

static CIKernel *alphaToGrayKernel = nil;

@implementation AlphaToGrayFilter

@synthesize inputImage;

- (id)init {
  if (alphaToGrayKernel == nil) {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *code =
        [NSString stringWithContentsOfFile:[bundle pathForResource:@"SeaCoreImageKernels"
                                                            ofType:@"cikernel"]];
    NSLog(@"loaded code : %@", code);

    NSArray *kernels = [CIKernel kernelsWithString:code];
    NSLog(@"loaded %d kernels", (int)[kernels count]);
    alphaToGrayKernel = (CIKernel *)kernels[0];
  }
  return [super init];
}

- (CIImage *)outputImage {

    CISampler *sampler = [CISampler samplerWithImage:inputImage];

    NSArray *outputExtent = @[ @(0), @(0),
                               @([inputImage extent].size.width),
                               @([inputImage extent].size.height) ];

    return [self apply:alphaToGrayKernel, sampler, kCIApplyOptionExtent, outputExtent, nil];
}

+ (void)initialize {
  [CIFilter registerFilterName:@"AlphaToGrayFilter"
                   constructor:(id<CIFilterConstructor>)self
               classAttributes:@{
                 kCIAttributeFilterDisplayName : @"Alpha To Gray Filter",
                 kCIAttributeFilterCategories : @[
                   kCICategoryColorAdjustment, kCICategoryVideo, kCICategoryStillImage,
                   kCICategoryInterlaced, kCICategoryNonSquarePixels, kCICategoryCompositeOperation
                 ]
               }];
}

+ (CIFilter *)filterWithName:(NSString *)name {
  CIFilter *filter;
  filter = [[self alloc] init];
  return filter;
}

@end


//
//  AlphaToGrayFilter.h
//  Seashore
//
//  Created by robert engels on 12/31/21.
//

#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface AlphaToGrayFilter : CIFilter
{
    CIImage   *inputImage;
}

@property (retain, nonatomic) CIImage *inputImage;

@end

NS_ASSUME_NONNULL_END

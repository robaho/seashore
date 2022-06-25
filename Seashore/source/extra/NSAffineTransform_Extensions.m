//
//  NSAffineTransform_Extensions.m
//  Seashore
//
//  Created by robert engels on 4/2/22.
//

#import "NSAffineTransform_Extensions.h"

@implementation NSAffineTransform(MyExtensions)
- (CGAffineTransform)cgtransform {
    NSAffineTransformStruct s = self.transformStruct;
    return CGAffineTransformMake(s.m11,s.m12,s.m21,s.m22,s.tX,s.tY);
}

@end

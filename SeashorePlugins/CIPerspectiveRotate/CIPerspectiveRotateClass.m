//
//  CIKeystoneCombinedClass.m
//  CIKeystoneCombined
//
//  Created by robert engels on 12/8/22.
//

#import "CIPerspectiveRotateClass.h"

@implementation CIPerspectiveRotateClass

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data filter:@"CIPerspectiveRotate" points:0 bg:TRUE properties:kCI_FocalLength,kCI_Pitch,kCI_Roll,kCI_Yaw,nil];
    return self;
}

@end

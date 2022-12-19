//
//  CIKeystoneCombinedClass.m
//  CIKeystoneCombined
//
//  Created by robert engels on 12/8/22.
//

#import "CIStraightenClass.h"

@implementation CIStraightenClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIStraightenFilter" points:0 bg:TRUE properties:kCI_Angle,nil];
}

@end

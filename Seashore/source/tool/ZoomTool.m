//
//  ZoomTool.m
//  Seashore
//
//  Created by robert engels on 1/24/19.
//

#import "SeaTools.h"
#import "ZoomTool.h"

@implementation ZoomTool

- (int)toolId
{
    return kZoomTool;
}

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (ZoomOptions*)newoptions;
}

@end



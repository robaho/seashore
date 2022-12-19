//
//  Alpha2GrayClass.m
//  Alpha2Gray
//
//  Created by robert engels on 1/23/19.
//  Copyright © 2019 robert engels. All rights reserved.
//

#import "Alpha2GrayClass.h"

@implementation Alpha2GrayClass

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data];
    [NSBundle loadNibNamed:@"Alpha2Gray" owner:self];
    
    return self;
}

- (void)execute {
    IntRect selection;
    unsigned char *data, *overlay, *replace;
    int pos, i, j, k, width, channel;
    
    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kReplacingBehaviour];
    selection = [pluginData selection];
    width = [pluginData width];
    data = [pluginData data];
    overlay = [pluginData overlay];
    replace = [pluginData replace];
    channel = [pluginData channel];
    
    for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
        for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
            
            pos = j * width + i;
            int offset = pos*SPP;
            
            int alpha = data[offset+alphaPos];
            if(alpha==0){ // skip pure alpha
                replace[pos]=0x00;
                continue;
            } else {
                float r = data[offset+CR];
                float g = data[offset+CG];
                float b = data[offset+CB];
                
                if(r==0 && b==0 && g==0) {
                    // already black with alpha
                    memset(overlay+offset+CR,(255-alpha) & 0xFF,3);
                    overlay[offset+alphaPos]=0xFF;
                } else {
                    int gray = (int)(r*.3 + g*.6 + b*.11);
                    gray = MIN(gray,255);
                    alpha = 255-gray;
                    memset(overlay+offset+CR,0,3);
                    overlay[offset+alphaPos]=(alpha & 0xFF);
                }
            }
            
            replace[pos] = 255;
        }
    }
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
    if ([pluginData channel] != kAllChannels)
        return NO;
    
    return YES;
}

@end

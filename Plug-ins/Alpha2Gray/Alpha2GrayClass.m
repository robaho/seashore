//
//  Alpha2GrayClass.m
//  Alpha2Gray
//
//  Created by robert engels on 1/23/19.
//  Copyright © 2019 robert engels. All rights reserved.
//

#import "Alpha2GrayClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation Alpha2GrayClass

- (NSString *)name
{
    return [gOurBundle localizedStringForKey:@"name" value:@"Alpha To Gray" table:NULL];
}

- (NSString *)groupName
{
    return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Effect" table:NULL];
}

- (id)initWithManager:(PluginData *)data {
    pluginData = data;
    [NSBundle loadNibNamed:@"Alpha2Gray" owner:self];
    
    return self;
}

- (NSString *)sanity
{
    return @"Seashore Approved (Bobo)";
}


- (void)run {
    IntRect selection;
    unsigned char *data, *overlay, *replace;
    int pos, i, j, k, width, spp, channel;
    
    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kReplacingBehaviour];
    selection = [pluginData selection];
    spp = [pluginData spp];
    width = [pluginData width];
    data = [pluginData data];
    overlay = [pluginData overlay];
    replace = [pluginData replace];
    channel = [pluginData channel];
    
    // 0.3R+0.6G+0.11B
    
    for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
        for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
            
            pos = j * width + i;
            
            int alpha = data[pos*spp+3];
            if(alpha==0){ // skip pure alpha
                replace[pos]=0x00;
                continue;
            } else {
                float r = data[pos*spp];
                float g = data[pos*spp+1];
                float b = data[pos*spp+2];
                
                if(r==0 && b==0 && g==0) {
                    // already black with alpha
                    memset(overlay+pos*spp,(255-alpha) & 0xFF,3);
                    overlay[pos*spp+3]=0xFF;
                } else {
                    int gray = (int)(r*.3 + g*.6 + b*.11);
                    gray = MIN(gray,255);
                    alpha = 255-gray;
                    memset(overlay+pos*spp,0,3);
                    overlay[pos*spp+3]=(alpha & 0xFF);
                }
            }
            
            replace[pos] = 255;
        }
    }
    [pluginData apply];
}

- (int)type {
    return 0;
}

- (IBAction)reapply
{
    [self run];
}

- (BOOL)canReapply
{
    return YES;
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
    if ([pluginData channel] != kAllChannels)
        return NO;
    
    if ([pluginData spp] != 4)
        return NO;
    
    return YES;
}


@end

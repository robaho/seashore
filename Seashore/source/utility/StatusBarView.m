//
//  StatusBarView.m
//  Seashore
//
//  Created by robert engels on 1/23/19.
//

#import "StatusBarView.h"

@implementation StatusBarView

-(void)awakeFromNib
{
    [statusLabel setAllowsDefaultTighteningForTruncation:YES];
    [statusLabel setMaximumNumberOfLines:1];
}

-(void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
    [super resizeWithOldSuperviewSize:oldSize];
    
    [zoomControls setHidden:NSIntersectsRect([zoomControls frame], [channelControls frame])];
    NSRect frame = [statusLabel frame];
    frame.size.width = [zoomControls frame].origin.x - [statusLabel frame].origin.x;
    [statusLabel setFrame:frame];
}

@end

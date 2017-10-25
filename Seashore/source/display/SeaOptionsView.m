#import "SeaOptionsView.h"

@implementation SeaOptionsView

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    NSColor *topColor;
    NSColor *fillColor;
    NSColor *bottomColor;
    NSBezierPath *path;
	BOOL usesOldStyle = NO;
	switch ((int)floor(NSAppKitVersionNumber)) {
			case NSAppKitVersionNumber10_3:
			case NSAppKitVersionNumber10_4:
				usesOldStyle = YES;
			break;
	}

    if([window isMainWindow] && usesOldStyle){
        topColor = [NSColor colorWithDeviceWhite:0.91 alpha:1.0];
        fillColor = [NSColor colorWithDeviceWhite:0.84 alpha:1.0];
        bottomColor = [NSColor colorWithDeviceWhite:0.50 alpha:1.0];
    }else if(usesOldStyle){
        topColor = [NSColor colorWithDeviceWhite:0.96 alpha:1.0];
        fillColor = [NSColor colorWithDeviceWhite:0.93 alpha:1.0];
        bottomColor = [NSColor colorWithDeviceWhite:0.50 alpha:1.0];
    }else if([window isMainWindow]){
        topColor = [NSColor colorWithDeviceWhite:0.75 alpha:1.0];
        fillColor = [NSColor colorWithDeviceWhite:0.57 alpha:1.0];
        bottomColor = [NSColor colorWithDeviceWhite:0.50 alpha:1.0];
    }else{
        topColor = [NSColor colorWithDeviceWhite:0.89 alpha:1.0];
        fillColor = [NSColor colorWithDeviceWhite:0.81 alpha:1.0];
        bottomColor = [NSColor colorWithDeviceWhite:0.62 alpha:1.0];
    }

    [topColor set];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(0,[self frame].size.height - 1.0,[self frame].size.width, 1.0)];
    [path fill];
    
    [bottomColor set];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(0,0,[self frame].size.width, 1.0)];
    [path fill];
    
    [fillColor set];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 1.0, [self frame].size.width, [self frame].size.height - 2.0)];
    [path fill];

}

@end

//
//  SeaSizes.m
//  SeaComponents
//
//  Created by robert engels on 12/1/22.
//

#import "SeaSizes.h"

static NSControl *std;

@implementation NSControl(MyExtensions)

- (void)setCtrlSize:(NSControlSize)size
{
    if (@available(macOS 10.10,*)) {
        self.controlSize = size;
    } else {
        self.cell.controlSize = size;
    }
}
- (NSControlSize)ctrlSize
{
    if (@available(macOS 10.10,*)) {
        return self.controlSize;
    } else {
        return self.cell.controlSize;
    }
}
@end

@implementation SeaSizes

+(float)heightOf:(NSControl*)control
{
    if(!std) {
        std = [[NSButton alloc] initWithFrame:NSZeroRect];
    }
    [std setCtrlSize:control.ctrlSize];
    return std.intrinsicContentSize.height;
}

@end

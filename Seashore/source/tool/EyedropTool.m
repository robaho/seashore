#import "EyedropTool.h"
#import "SeaLayer.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaController.h"
#import "ToolboxUtility.h"
#import "OptionsUtility.h"
#import "EyedropOptions.h"
#import "SeaWhiteboard.h"
#import "SeaView.h"
#import "SeaTools.h"
#import "SeaHelpers.h"


@protocol PixelProvider
- (NSColor *)getPixelX:(int)x Y:(int)y;
@end

@implementation EyedropTool

- (void)awakeFromNib {
    options = [[EyedropOptions alloc] init:document];
}

- (int)toolId
{
    return kEyedropTool;
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    ToolboxUtility *toolboxUtility = [document toolboxUtility];
    NSColor *color = [self getColor];
    
    if (color != NULL) {
        if ([(EyedropOptions*)options modifier] == kAltModifier)
            [toolboxUtility setBackground:color];
        else {
            [toolboxUtility setForeground:color];
        }
        [toolboxUtility update:NO];
    }
}

- (int)sampleSize
{
    return [(EyedropOptions*)options sampleSize];
}

static inline NSColor * averagedPixelValue(id<PixelProvider> pp,int radius, IntPoint where)
{
    float colors[] = {0,0,0,0};

    int count = 0;

    for (int j = where.y - radius; j <= where.y + radius; j++) {
        for (int i = where.x - radius; i <= where.x + radius; i++) {
            NSColor *c = [pp getPixelX:i Y:j];
            if(c==NULL)
                continue;
            colors[0] += [c redComponent];
            colors[1] += [c greenComponent];
            colors[2] += [c blueComponent];
            colors[3] += [c alphaComponent];
            count++;
        }
    }

    if(count==0)
        return NULL;

    colors[0] = colors[0]/count;
    colors[1] = colors[1]/count;
    colors[2] = colors[2]/count;
    colors[3] = colors[3]/count;

    return [NSColor colorWithRed:colors[0] green:colors[1] blue:colors[2] alpha:colors[3]];
}

- (NSColor *)getSample:(id<PixelProvider>)pp
{
    IntPoint pos = [[document docView] getMousePosition:NO];
    int radius = [options sampleSize] - 1;

    float t[4];

    NSColor *avg = averagedPixelValue(pp,radius,pos);
    if(avg==NULL)
        return NULL;
    t[0] = [avg redComponent];
    t[1] = [avg greenComponent];
    t[2] = [avg blueComponent];
    t[3] = [avg alphaComponent];
    return [NSColor colorWithDeviceRed:(float)t[0] green:(float)t[1] blue:(float)t[2] alpha:(float)t[3]];
}

- (NSColor *)getColor
{
    if ([options mergedSample]) {
        return [self getSample:[document whiteboard]];
    }
    else {
        return [self getSample:[[document contents] activeLayer]];
    }
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors *)cursors
{
    IntRect r;
    if([options mergedSample]) {
        r = [[document contents] rect];
    } else {
        r = [[[document contents] activeLayer] globalRect];
    }
    if(!IntPointInRect(p, r)) {
        [[cursors noopCursor] set];
        return;
    }
    return [[self toolCursor:cursors] set];
}

- (NSCursor*)toolCursor:(SeaCursors *)cursors
{
    return [cursors eyedropCursor];
}


@end

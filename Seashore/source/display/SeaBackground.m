#import "SeaDocument.h"
#import "SeaBackground.h"
#import "SeaWhiteboard.h"
#import "SeaController.h"
#import "SeaPrefs.h"

@implementation SeaBackground

- (SeaBackground *)initWithDocument:(SeaDocument*)doc
{
    self = [super init];

    document = doc;

    checkerboard = [NSImage imageNamed:@"checkerboard"];

    return self;
}

static void patternCallback(void *info, CGContextRef context) {
    CGImageRef imageRef = (CGImageRef)info;
    CGContextDrawImage(context, CGRectMake(0, 0, 32, 32), imageRef);
}

- (void)drawBackground:(CGContextRef)ctx rect:(NSRect)dirtyRect
{
    static const CGPatternCallbacks callbacks = { .drawPattern = patternCallback};
    static CGPatternRef pattern;
    static float pattern_magnification = 0;
    static CGColorSpaceRef patternSpace = nil;

    float magnification = [[document scrollView] magnification];

    CGRect rect = CGRectMake(0,0,[[document contents] width],[[document contents] height]);

    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);

    if ([[document whiteboard] whiteboardIsLayerSpecific]) {
        CGContextSetFillColorWithColor(ctx, [[NSColor windowBackgroundColor] CGColor]);
        CGContextFillRect(ctx,rect);
    }
    else {
        if([(SeaPrefs *)[SeaController seaPrefs] useCheckerboard]){
            CGImageRef image = [checkerboard CGImageForProposedRect:NULL context:NULL hints:NULL];

            if(magnification!=pattern_magnification) {
                CGAffineTransform tx = CGAffineTransformIdentity;
                tx = CGAffineTransformScale(tx, 0.5/magnification,0.5/magnification);
                CGPatternRelease(pattern);
                pattern = CGPatternCreate(image,CGRectMake(0,0,32,32), tx, 32, 32,kCGPatternTilingConstantSpacing,TRUE,&callbacks);
                pattern_magnification = magnification;
            }
            if(patternSpace==nil){
                patternSpace = CGColorSpaceCreatePattern(NULL);
            }
            CGContextSetFillColorSpace(ctx, patternSpace);
            double alpha = 1.0;
            CGContextSetFillPattern(ctx, pattern, &alpha);
            CGContextFillRect(ctx,[self bounds]);
        }else{
            CGContextSetFillColorWithColor(ctx, [[(SeaPrefs *)[SeaController seaPrefs] transparencyColor] CGColor]);
            CGContextFillRect(ctx,rect);
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    dirtyRect = NSIntegralRect(dirtyRect);
    if(LOG_PERFORMANCE)
        NSLog(@"sea background %@",NSStringFromRect(dirtyRect));
    
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    [self drawBackground:ctx rect:dirtyRect];
}

- (BOOL)isFlipped
{
    return TRUE;
}

- (BOOL)isOpaque
{
    return FALSE;
}

@end

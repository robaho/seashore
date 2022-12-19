#import "EffectTool.h"
#import "SeaController.h"
#import "SeaPlugins.h"
#import <Plugins/PluginClass.h>
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaTools.h"
#import "EffectOptions.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import <CoreImage/CoreImage.h>

@implementation EffectTool

- (void)awakeFromNib {
    options = [[EffectOptions alloc] init:document];
}

- (int)toolId
{
	return kEffectTool;
}

- (id)init
{
	if(![super init])
		return NULL;
	count = 0;
    draggingPointIndex = -1;
	return self;
}

- (BOOL)hasLastEffect
{
    return lastPlugin!=NULL && currentPlugin==NULL;
}

- (IntRect)selection
{
    if ([[document selection] active])
        return [[document selection] localRect];
    else
        return IntMakeRect(0, 0, [[[document contents] activeLayer] width], [[[document contents] activeLayer] height]);
}

- (void)execute
{
    if(count==[currentPlugin points]) {
        [currentPlugin execute];
        [[document helpers] overlayChanged:[self selection]];
    }
}

- (void)clearEffect
{
    currentPlugin = NULL;
    [[document whiteboard] clearOverlay];
    [options installPlugin:NULL View:NULL];
}

- (IBAction)apply:(id)sender
{
    if(!currentPlugin || count < [currentPlugin points])
        return;
    lastPlugin = currentPlugin;
    [[document helpers] overlayChanged:[self selection]];
    [[document helpers] applyOverlay];

    [self clearEffect];
}

- (IBAction)reapply:(id)sender
{
    if(![self hasLastEffect])
        return;

    [lastPlugin execute];
    [[document helpers] overlayChanged:[self selection]];
    [[document helpers] applyOverlay];
}

- (void)clearPointDisplay
{
    for(int i=0;i<count;i++){
        [[document docView] setNeedsDisplayInLayerRect:IntEmptyRect(points[i]):26];
    }
}

- (IntRect)handleRect:(IntPoint)p
{
    int width = 8 / [[document docView] zoom];
    return IntMakeRect(p.x-width/2,p.y-width/2,width,width);
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    if(!currentPlugin) {
        return;
    }
    
    draggingPointIndex=-1;
    
	if (count < [currentPlugin points]) {
        lastPointTime = getCurrentMillis();
		points[count] = where;
		count++;

        [[document docView] setNeedsDisplayInLayerRect:IntEmptyRect(where):26];

        [options updateClickCount:self];
        
        if (count == [currentPlugin points]) {
            [self performSelector:@selector(execute) withObject:NULL afterDelay:0];
        }
    } else if(count>0) {
        // see if we are in a point and if so start dragging
        for(int i=0;i<count;i++){
            IntRect r = [self handleRect:points[i]];
            if(IntPointInRect(where, r)) {
                draggingPointIndex = i;
                draggingPointStart = where;
                draggingPointOriginal = points[i];
                break;
            }
        }
    }
}
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    lastPointTime = getCurrentMillis();

    if(draggingPointIndex>=0){
        [[document docView] setNeedsDisplayInLayerRect:IntEmptyRect(points[draggingPointIndex]):26];
        points[draggingPointIndex] = IntOffsetPoint(draggingPointOriginal, where.x-draggingPointStart.x, where.y-draggingPointStart.y);
        [self performSelector:@selector(execute) withObject:NULL afterDelay:.1];
        for(int i=0;i<count;i++){
            [[document docView] setNeedsDisplayInLayerRect:IntEmptyRect(points[i]):26];
        }
    }
}
- (void)mouseMovedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    if(!currentPlugin || [currentPlugin points]==0 || count==0) {
        return;
    }

    lastPointTime = getCurrentMillis();

    for(int i=0;i<count;i++){
        [[document docView] setNeedsDisplayInLayerRect:IntEmptyRect(points[i]):26];
    }
    [self performSelector:@selector(clearPointDisplay) withObject:NULL afterDelay:.5];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    draggingPointIndex=-1;
}

- (void)selectEffect:(id<PluginClass>)plugin
{
    SeaPluginData* data = [document pluginData];
    Class class = [plugin class];
    if(![class validatePlugin:data]){
        currentPlugin = nil;
        return;
    }
    currentPlugin = [object_getClass(plugin) alloc];
    @try {
        currentPlugin = [currentPlugin initWithManager:data];
    } @catch (NSException *exception) {
        currentPlugin = nil;
        NSLog(@"unable to open plugin %@ %@",exception,[exception callStackSymbols]);
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error Initializing Plugin. Please file a bug." defaultButton:NULL alternateButton:NULL otherButton:NULL informativeTextWithFormat:@"%@.%@",object_getClassName(plugin),[exception reason]];
        [alert runModal];
        return;
    }

    if([currentPlugin respondsToSelector:@selector(initialize)]) {
        pluginView = [currentPlugin initialize];
    } else {
        pluginView = NULL;
    }
    count = 0;
    [options installPlugin:currentPlugin View:pluginView];
    [self settingsChanged];
}

- (IBAction)reset:(id)sender
{
    if([currentPlugin points] && count>0) {
        count = 0;
        [options updateClickCount:self];
        [[document whiteboard] clearOverlay];
    } else {
        [self clearEffect];
    }
}

- (IntPoint)point:(int)index
{
	return points[index];
}

- (int)clickCount
{
	return count;
}

- (IntRect)selectionRect
{
	NSLog(@"Effect tool invalidly getting asked its selection rect");
	return IntMakeRect(0, 0, 0, 0);
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (id<PluginClass>)plugin
{
    return currentPlugin;
}
- (void)settingsChanged
{
    if(currentPlugin && count == [currentPlugin points]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(execute) object:nil];
        [self performSelector:@selector(execute) withObject:NULL afterDelay:.100 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    }
}

- (void)switchingTools:(BOOL)active
{
    if(!active)
        [[document whiteboard] clearOverlay];
    else {
        [self settingsChanged];
    }
}

- (BOOL)shouldDrawPoints
{
    if(!currentPlugin)
        return FALSE;

    return count<[currentPlugin points] || draggingPointIndex>=0 || getCurrentMillis()-lastPointTime < 500;
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors*)cursors
{
    int xoff = [[[document contents] activeLayer] xoff];
    int yoff = [[[document contents] activeLayer] yoff];

    if(currentPlugin && count==[currentPlugin points]) {
        for(int i=0;i<count;i++) {
            if(IntPointInRect(p,[cursors handleRect:IntOffsetPoint(points[i],xoff,yoff)])) {
                [[cursors handCursor] set];
                return;
            }
        }
    }
    [super updateCursor:p cursors:cursors];
}

- (IntPoint)convertCIPoint:(CGPoint)p
{
    int height = [[[document contents] activeLayer] height];

//     [CIVector vectorWithX:point.x Y:height - point.y];

    return IntMakePoint(p.x,height-p.y);
}

- (void)detectRectangle:(id)sender
{
    if (@available(macOS 10.10, *)) {
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:NULL options:NULL];
        CIImage *image = [self createCIImage];
        NSArray<CIFeature*> *features = [detector featuresInImage:image];
        if([features count]>0 && [currentPlugin points]>=4) {
            CIRectangleFeature *feature = (CIRectangleFeature*)features[0];
            points[0] = [self convertCIPoint:feature.topLeft];
            points[1] = [self convertCIPoint:feature.topRight];
            points[2] = [self convertCIPoint:feature.bottomRight];
            points[3] = [self convertCIPoint:feature.bottomLeft];
        }
        if(count<4) {
            count=4;
        }
        [options updateClickCount:self];
        if (count == [currentPlugin points]) {
            [self performSelector:@selector(execute) withObject:NULL afterDelay:0];
        }
    }
}

- (CIImage*)createCIImage
{
    CGImageRef bitmap = [[[document contents] activeLayer] bitmap];
    CIImage *inputImage = [CIImage imageWithCGImage:bitmap];
    CGImageRelease(bitmap);
    return inputImage;
}





@end

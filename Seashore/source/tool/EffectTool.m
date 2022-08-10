#import "EffectTool.h"
#import "SeaController.h"
#import "SeaPlugins.h"
#import "PluginClass.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaTools.h"
#import "EffectOptions.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"

@implementation EffectTool

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
    int xoff = [[[document contents] activeLayer] xoff];
    int yoff = [[[document contents] activeLayer] yoff];

    for(int i=0;i<count;i++){
        IntPoint where = points[i];
        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(IntOffsetPoint(where,xoff,yoff)):26];
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
    
	if (count < [currentPlugin points]) {
        lastPointTime = getCurrentMillis();
		points[count] = where;
		count++;

        int xoff = [[[document contents] activeLayer] xoff];
        int yoff = [[[document contents] activeLayer] yoff];

        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(IntOffsetPoint(where,xoff,yoff)):26];

        [options updateClickCount:self];
        
        if (count == [currentPlugin points]) {
            [self performSelector:@selector(execute) withObject:NULL afterDelay:0];
        }
    } else if(count>0) {
        // see if we are in a point and if so start dragging
        draggingPointIndex=-1;
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
    if(draggingPointIndex>=0){
        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(points[draggingPointIndex]):26];
        points[draggingPointIndex] = IntOffsetPoint(draggingPointOriginal, where.x-draggingPointStart.x, where.y-draggingPointStart.y);
        [self performSelector:@selector(execute) withObject:NULL afterDelay:.1];
        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(points[draggingPointIndex]):26];
    }
}
- (void)mouseMovedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    if(!currentPlugin || [currentPlugin points]==0 || count==0) {
        return;
    }

    lastPointTime = getCurrentMillis();

    int xoff = [[[document contents] activeLayer] xoff];
    int yoff = [[[document contents] activeLayer] yoff];

    for(int i=0;i<count;i++){
        IntPoint where = points[i];
        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(IntOffsetPoint(where,xoff,yoff)):26];
    }
    [self performSelector:@selector(clearPointDisplay) withObject:NULL afterDelay:.5];
}

- (void)selectEffect:(PluginClass*)plugin
{
    PluginData* data = [document pluginData];
    if(![[plugin class] validatePlugin:data]){
        currentPlugin = nil;
        return;
    }
    currentPlugin = [[plugin class] alloc];
    @try {
        currentPlugin = [currentPlugin initWithManager:data];
    } @catch (NSException *exception) {
        currentPlugin = nil;
        NSLog(@"unable to open plugin %@ %@",exception,[exception callStackSymbols]);
        [NSAlert alertWithMessageText:@"Error Initializing Plugin" defaultButton:NULL alternateButton:NULL otherButton:NULL informativeTextWithFormat:@"%@",[exception reason]];
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

- (void)reset
{
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
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (EffectOptions*)newoptions;
}
- (PluginClass*)plugin
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

    return count<[currentPlugin points] || getCurrentMillis()-lastPointTime < 500;
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors*)cursors
{
    if(currentPlugin && count==[currentPlugin points]) {
        for(int i=0;i<count;i++) {
            if(IntPointInRect(p,[cursors handleRect:points[i]])) {
                [[cursors handCursor] set];
                return;
            }
        }
    }
    [super updateCursor:p cursors:cursors];
}



@end

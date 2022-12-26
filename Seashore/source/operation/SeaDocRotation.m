#import "SeaDocument.h"
#import "SeaLayerUndo.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "SeaDocRotation.h"

@implementation SeaDocRotation

- (void)flipDocHorizontally
{
	int i, layerCount;

    @synchronized(document.mutex) {
        [[document selection] clearSelection];
        layerCount = [[document contents] layerCount];
        for (i = 0; i < layerCount; i++) {
            [[[document contents] layer:i] flipHorizontally];
        }
        [[document helpers] boundariesAndContentChanged];
    }
	
    [[[document undoManager] prepareWithInvocationTarget:self] flipDocHorizontally];
}

- (void)flipDocVertically
{
	int i, layerCount;

    @synchronized (document.mutex) {
        [[document selection] clearSelection];
        layerCount = [[document contents] layerCount];
        for (i = 0; i < layerCount; i++) {
            [[[document contents] layer:i] flipVertically];
        }
        [[document helpers] boundariesAndContentChanged];
    }

    [[[document undoManager] prepareWithInvocationTarget:self] flipDocVertically];
}

- (void)rotateDocLeft
{
	int i, layerCount, width, height;

    @synchronized (document.mutex) {
        [[document selection] clearSelection];
        layerCount = [[document contents] layerCount];
        for (i = 0; i < layerCount; i++) {
            [[[document contents] layer:i] rotateLeft];
        }
        width = [(SeaContent *)[document contents] width];
        height = [(SeaContent *)[document contents] height];
        [[document contents] setWidth:height height:width];
        [[document helpers] boundariesAndContentChanged];
    }
	

    [[[document undoManager] prepareWithInvocationTarget:self] rotateDocRight];
}

- (void)rotateDocRight
{
	int i, layerCount, width, height;

    @synchronized (document.mutex) {
        [[document selection] clearSelection];
        layerCount = [[document contents] layerCount];
        for (i = 0; i < layerCount; i++) {
            [[[document contents] layer:i] rotateRight];
        }
        width = [(SeaContent *)[document contents] width];
        height = [(SeaContent *)[document contents] height];
        [[document contents] setWidth:height height:width];
        [[document helpers] boundariesAndContentChanged];
    }
	

    [[[document undoManager] prepareWithInvocationTarget:self] rotateDocLeft];
}

@end

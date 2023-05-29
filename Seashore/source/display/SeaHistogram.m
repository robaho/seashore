//
//  SeaHistogram.m
//  Seashore
//
//  Created by robert engels on 7/5/22.
//

#import "SeaHistogram.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaLayer.h"
#import <SeaComponents/SeaComponents.h>

@implementation SeaHistogram

extern dispatch_queue_t queue;

- (void)awakeFromNib
{
    [super awakeFromNib];
    if ([gUserDefaults objectForKey:@"histogram mode"] != NULL) {
        [modeComboBox selectItemAtIndex:[gUserDefaults integerForKey:@"histogram mode"]];
    }
    if ([gUserDefaults objectForKey:@"histogram source"] != NULL) {
        [sourceComboBox selectItemAtIndex:[gUserDefaults integerForKey:@"histogram source"]];
    }
    self.identifier = @"SeaHistogram";
    self.innerInset = 5;
}

- (void)update
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(calculateHistogram) object:nil];
    [self performSelector:@selector(calculateHistogram) withObject:nil afterDelay:.5 inModes:@[NSRunLoopCommonModes]];
}

- (IBAction)optionsChanged:(id)sender {
    [self calculateHistogram];
}

static void histoByAddress(unsigned char *data,int width,int height,int mode,HistogramView *histogramView) {
    int *histogram = calloc(256*3,sizeof(int)); // allocate enough for all planes
    int bytesPerRow = width*SPP;

    for (int row=0;row<height;row++) {
        for(int col=0;col<width;col++) {
            int offset = row*bytesPerRow+col*SPP;

            if(data[offset+alphaPos]==0)
                continue; // ignore completely transparent pixels

            int max = 0;
            switch(mode) {
                case 0: // value
                    for (int i = CR; i <= CB; i++)
                        max = MAX(max,data[offset + i]);
                    histogram[max]++;
                    break;
                case 1: // red
                case 2: // green
                case 3: // blue
                    histogram[data[offset+mode-1+CR]]++;
                    break;
                case 4:
                    for (int i = 0; i < SPP-1; i++) {
                        int value = data[offset+i+CR];
                        histogram[i*256+value]++;
                    }
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(),^{
        [histogramView updateHistogram:mode histogram:histogram];
    });
}

static void histoForLayer(NSData* data,int width,int height,int mode,HistogramView *histogramView) {
    histoByAddress((unsigned char*)[data bytes],width,height,mode,histogramView);
}
static void histoForImage(CGContextRef ctx,int width,int height,int mode,HistogramView *histogramView) {
    histoByAddress(CGBitmapContextGetData(ctx),width,height,mode,histogramView);
    CGContextRelease(ctx);
}

- (void)calculateHistogram
{
    SeaContent *contents = [document contents];

    int sw,sh;

    int mode = [modeComboBox indexOfSelectedItem];

    if([contents type]==XCF_GRAY_IMAGE)
        mode = 0; // only value supported

    int source = [sourceComboBox indexOfSelectedItem];

    CGContextRef ctx=NULL;

    if(source==0) { // layer
        NSData *data_ref = [[document whiteboard] layerData];
        SeaLayer *layer = [contents activeLayer];
        int sw = [layer width], sh = [layer height];

        dispatch_async(queue, ^{
            histoForLayer(data_ref,sw,sh,mode,histogramView);
        });
    } else { // image
        CGContextRef ctx = [[document whiteboard] dataCtx];
        CGContextRetain(ctx);
        int sw = [contents width], sh = [contents height];

        dispatch_async(queue, ^{
            histoForImage(ctx,sw,sh,mode,histogramView);
        });
    }
}

- (void)shutdown
{
    [gUserDefaults setInteger:[modeComboBox indexOfSelectedItem] forKey:@"histogram mode"];
    [gUserDefaults setInteger:[sourceComboBox indexOfSelectedItem] forKey:@"histogram source"];
}


@end

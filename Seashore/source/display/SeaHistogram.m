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
    if ([gUserDefaults objectForKey:@"histogram mode"] != NULL) {
        [modeComboBox selectItemAtIndex:[gUserDefaults integerForKey:@"histogram mode"]];
    }
    if ([gUserDefaults objectForKey:@"histogram source"] != NULL) {
        [sourceComboBox selectItemAtIndex:[gUserDefaults integerForKey:@"histogram source"]];
    }
}

- (void)update
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(calculateHistogram) object:nil];
    [self performSelector:@selector(calculateHistogram) withObject:nil afterDelay:.5 inModes:@[NSRunLoopCommonModes]];
}

- (IBAction)optionsChanged:(id)sender {
    [self calculateHistogram];
}

- (void)calculateHistogram
{
    SeaContent *contents = [document contents];

    int spp = [contents spp];
    int sw,sh;

    int source = [sourceComboBox indexOfSelectedItem];

    NSData *data_ref;
    CGContextRef ctx=NULL;

    if(source==0) { // layer
        data_ref = [[document whiteboard] layerData];
        SeaLayer *layer = [contents activeLayer];

        sw = [layer width];
        sh = [layer height];
    } else { // image
        ctx = [[document whiteboard] dataCtx];
        CGContextRetain(ctx);
        sw = [contents width];
        sh = [contents height];
    }

    int mode = [modeComboBox indexOfSelectedItem];

    if(spp==2)
        mode = 0; // only value supported

    dispatch_async(queue, ^{

        unsigned char *data;
        int bytesPerRow;
        if(ctx!=NULL) {
            data = CGBitmapContextGetData(ctx);
            bytesPerRow = CGBitmapContextGetBytesPerRow(ctx);
        } else {
            data = [data_ref bytes];
            bytesPerRow = sw*spp;
        }

        int *histogram = calloc(256*3,sizeof(int)); // allocate enough for all planes

        for (int row=0;row<sh;row++) {
            for(int col=0;col<sw;col++) {
                int offset = row*bytesPerRow+col*spp;

                if(data[offset+spp-1]==0)
                    continue; // ignore completely transparent pixels

                int max = 0;
                switch(mode) {
                    case 0: // value
                        for (int i = 0; i < spp - 1; i++)
                            max = MAX(max,data[offset + i]);
                        histogram[max]++;
                        break;
                    case 1: // red
                    case 2: // green
                    case 3: // blue
                        histogram[data[offset+mode-1]]++;
                        break;
                    case 4:
                        for (int i = 0; i < spp - 1; i++) {
                            int value = data[offset+i];
                            histogram[i*256+value]++;
                        }
                }
            }
        }
        CGContextRelease(ctx);

        dispatch_async(dispatch_get_main_queue(),^{
            [histogramView updateHistogram:mode histogram:histogram];
        });
    });
}

- (void)shutdown
{
    [gUserDefaults setInteger:[modeComboBox indexOfSelectedItem] forKey:@"histogram mode"];
    [gUserDefaults setInteger:[sourceComboBox indexOfSelectedItem] forKey:@"histogram source"];
}


@end

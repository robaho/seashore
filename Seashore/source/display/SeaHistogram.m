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

- (void)update
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(calculateHistogram) object:nil];
    [self performSelector:@selector(calculateHistogram) withObject:nil afterDelay:.5];
}

- (IBAction)modeChanged:(id)sender {
    [self calculateHistogram];
}

- (void)calculateHistogram
{
    NSData *data_ref = [[document whiteboard] layerData];

    SeaContent *contents = [document contents];
    SeaLayer *layer = [contents activeLayer];

    int spp = [contents spp];
    int lw = [layer width];
    int lh = [layer height];
    int xoff = [layer xoff];
    int yoff = [layer yoff];

    int mode = [modeComboBox indexOfSelectedItem];

    if(spp==2)
        mode = 0; // only value supported

    dispatch_async(queue, ^{

        unsigned char *data = [data_ref bytes];

        int *histogram = calloc(256*3,sizeof(int)); // allocate enough for all planes

        for (int row=0;row<lh;row++) {
            for(int col=0;col<lw;col++) {
                int offset = (row*lw+col)*spp;

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

        dispatch_async(dispatch_get_main_queue(),^{
            [histogramView updateHistogram:mode histogram:histogram];
        });
    });
}


@end

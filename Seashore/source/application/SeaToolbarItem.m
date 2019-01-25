#import "SeaToolbarItem.h"
#import "SeaController.h"
#import "SeaProxy.h"

@implementation SeaToolbarItem

-(void)validate
{
    NSView *view = [self view];
    if([view isKindOfClass:[NSSegmentedControl class]]){
        // if this is for a segmented control, it is assumed the tag in each segment is for a menu item
        // some tags are less than 100 (the tool identifiers), and these are always enabled and they do
        // not correspond to a menu item 
        SeaProxy *sp = [SeaController seaProxy];
        NSSegmentedControl *sc = (NSSegmentedControl*)view;
        NSSegmentedCell *cell = [sc cell];
        for(int i=0;i<[sc segmentCount];i++){
            NSMenuItem *mi = [[NSMenuItem alloc] init];
            [mi setTag:[cell tagForSegment:i]];
            [cell setEnabled:[sp validateMenuItem:mi] forSegment:i];
        }
    } else {
        [self setEnabled:YES];
    }
}

@end

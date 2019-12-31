//
//  RecentsBarView.h
//  Seashore
//
//  Created by robert engels on 2/4/19.
//

#import <Cocoa/Cocoa.h>
#import "SeaDocument.h"

NS_ASSUME_NONNULL_BEGIN

@interface RecentsBarView : NSView <NSCollectionViewDelegate>
{
    __weak SeaDocument *document;
    IBOutlet NSCollectionView *cview;
}
@end

NS_ASSUME_NONNULL_END

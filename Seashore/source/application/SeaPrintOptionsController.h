//
//  SeaPrintOptionsContoller.h
//  Seashore
//
//  Created by robert engels on 1/12/19.
//

#import <Cocoa/Cocoa.h>
#import "SeaDocument.h"

NS_ASSUME_NONNULL_BEGIN

@interface SeaPrintOptionsController : NSViewController<NSPrintPanelAccessorizing>
{
    __weak SeaDocument *document;
}
- (SeaPrintOptionsController*)initWithDocument:(SeaDocument*)document;
- (IBAction)scaleTypeChange:(id)sender;
- (IBAction)scaleFitTypeChange:(id)sender;
@property BOOL scaleByAmount;
@property BOOL scaleToFit;
@property float scaleAmount;
@property BOOL scaleEntireImage;
@property BOOL scaleFillPaper;
@end

NS_ASSUME_NONNULL_END

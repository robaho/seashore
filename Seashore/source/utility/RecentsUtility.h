//
//  RecentsUtility.h
//  Seashore
//
//  Created by robert engels on 2/4/19.
//

#import <Foundation/Foundation.h>
#import "SeaBrush.h"
#import "BrushOptions.h"
#import "PencilOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface RecentsUtility : NSObject
{
    // The document that owns the utility
    __weak IBOutlet id document;
    
    // The actual view that is the recents bar
    __weak IBOutlet id view;
    
    NSMutableArray *memories;
}


/*!
 @method        show:
 @discussion    Shows the utility's window.
 @param        sender
 Ignored.
 */
- (IBAction)show:(id)sender;

/*!
 @method        hide:
 @discussion    Hides the utility's window.
 @param        sender
 Ignored.
 */
- (IBAction)hide:(id)sender;

/*!
 @method        toggle:
 @discussion    Toggles the visibility of the options bar.
 @param        sender
 Ignored.
 */
- (IBAction)toggle:(id)sender;

- (void)rememberBrush:(BrushOptions*)options;

- (void)rememberPencil:(PencilOptions*)options;

- (int)memoryCount;
- (id)memoryAt:(int)index;


@end

NS_ASSUME_NONNULL_END

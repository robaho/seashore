//
//  RecentsUtility.h
//  Seashore
//
//  Created by robert engels on 2/4/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RecentsUtility : NSObject
{
    // The document that owns the utility
    __weak IBOutlet id document;
    
    // The actual view that is the status bar
    __weak IBOutlet id view;
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


@end

NS_ASSUME_NONNULL_END

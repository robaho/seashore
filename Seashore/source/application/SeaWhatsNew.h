//
//  SeaWhatsNew.h
//  Seashore
//
//  Created by robert engels on 6/21/22.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaWhatsNew : NSObject
{
    IBOutlet id window;
    __unsafe_unretained IBOutlet NSTextView *textView;
}
- (IBAction)showWhatsNew:(id)sender;
@end

NS_ASSUME_NONNULL_END

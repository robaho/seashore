//
//  SeaColorProfiles.h
//  Seashore
//
//  Created by robert engels on 1/2/19.
//

#import "Seashore.h"

@interface SeaColorProfile : NSObject {
}
@property (nonatomic,strong) NSString *desc;
@property (nonatomic,strong) NSURL *url;
@property ColorSyncProfileRef profile;
@property (nonatomic,strong) NSColorSpace *cs;
@end

@interface SeaColorMenuItem : NSMenuItem {
}
@property (nonatomic,strong) SeaColorProfile *profile;
@end

@interface SeaColorProfiles : NSObject {
    IBOutlet NSMenu *proofMenu;
    NSArray<SeaColorProfile*> *profiles;
    ColorSyncProfileRef profile;
}

/*!
 @method        init
 @discussion    Initializes an instance of this class.
 @result        Returns instance upon success (or NULL otherwise).
 */
- (id)init;

/*!
 @method        awakeFromNib
 @discussion    Adds plug-ins to the menu.
 */
- (void)awakeFromNib;

- (BOOL)validateMenuItem:(SeaColorMenuItem*)menuItem;

@end

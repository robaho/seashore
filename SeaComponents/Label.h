//
//  Label.h
//  SeaComponents
//
//  Created by robert engels on 3/6/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface Label : NSTextField

-(NSString*)title;
-(void)setTitle:(NSString*)title;
-(void)makeSmall;
-(void)makeCompact;
-(void)makeRegular;

+ (Label*)label;
+ (Label*)compactLabel;
+ (Label*)smallLabel;
@end


NS_ASSUME_NONNULL_END

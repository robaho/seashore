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
-(void)makeMultiline;
-(void)makeNote;

+ (Label*)label;
+ (Label*)compactLabel;
+ (Label*)smallLabel;
+ (Label*)labelWithSize:(NSControlSize)size;
@end


NS_ASSUME_NONNULL_END

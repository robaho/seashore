//
//  SeaLabelledValue.h
//  SeaComponents
//
//  Created by robert engels on 11/27/22.
//

#import <Cocoa/Cocoa.h>
#import <SeaComponents/Label.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaLabelledValue : NSView
{
    Label *label;
    Label *value;
    NSColorWell *colorWell;
}

-(void)setStringValue:(NSString*)value;
-(void)setIntValue:(int)value;
-(void)setColorValue:(NSColor*)color;

+(SeaLabelledValue*)withLabel:(NSString*)label;
+(SeaLabelledValue*)withLabel:(NSString*)label size:(NSControlSize)size;

@end

NS_ASSUME_NONNULL_END

//
//  NSBezierPath_Extensions.h
//  Seashore
//
//  Created by robert engels on 8/3/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBezierPath(MyExtensions)

+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)cgPath;
- (CGPathRef)cgPath;
+(NSBezierPath*)fromString:(NSString*)s;
-(NSString*)toString;



@end

NS_ASSUME_NONNULL_END

//
//  SeashoreTests.m
//  SeashoreTests
//
//  Created by robert engels on 12/26/21.
//

#import "ConnectedComponents.h"
#import "StandardMerge.h"
#import "NSBezierPath_Extensions.h"

#import <XCTest/XCTest.h>

@interface SeashoreTests : XCTestCase

@end

@implementation SeashoreTests

- (void)setUp {
    rgbCS = CGColorSpaceCreateDeviceRGB();
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testMaskToPaths2 {
    int w=16,h=16;
    unsigned char *mask = calloc(w*h,1);
    CGContextRef ctx = CGBitmapContextCreate(mask,w,h,8,w,CGColorSpaceCreateDeviceGray(),kCGImageAlphaNone);
    CGContextSetFillColorWithColor(ctx,CGColorCreateGenericRGB(1,1,1,1));
    CGContextFillRect(ctx,CGRectMake(4,4,w/2,h/2));
    NSBezierPath *path = [ConnectedComponents getPaths:mask width:w height:h];
    NSLog(@"path is %@",path);
}

- (void)testPathEncoding {
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(1,-1)];
    [path lineToPoint:NSMakePoint(3,-3)];
    [path curveToPoint:NSMakePoint(6,-6) controlPoint1:NSMakePoint(8,-8) controlPoint2:NSMakePoint(10,-10)];
    [path closePath];

    NSString *s = [path toString];

    NSBezierPath *decode = [NSBezierPath fromString:s];

    assert(NSEqualRects([path bounds],[decode bounds]));
    assert(NSEqualRects([path controlPointBounds],[decode controlPointBounds]));
}


- (void)testAlphaBlendSymetry {
    unsigned char temp0[4] = { 0xFF,0xFF,0xFF,0xFF};
    unsigned char temp1[4] = { 0xFF,0xFF,0xFF,0xFF};
    unsigned char tempR[4];

    merge_pm(4, temp1, temp0, tempR, 255);

    assert(tempR[0]==0xFF);
    assert(tempR[1]==0xFF);
    assert(tempR[2]==0xFF);
    assert(tempR[3]==0xFF);
}

- (void)testBlendWhiteOnWhite {
    unsigned char temp0[4] = { 0xFF,0xFF,0xFF,0xFF};
    unsigned char temp1[4] = { 0x7f,0x7f,0x7f,0x7f};
    unsigned char tempR[4];

    merge_pm(4, temp1, temp0, tempR, 255);

    assert(tempR[0]==0xFF);
    assert(tempR[1]==0xFF);
    assert(tempR[2]==0xFF);
    assert(tempR[3]==0xFF);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

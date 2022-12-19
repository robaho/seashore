//
//  SeashoreTests.m
//  SeashoreTests
//
//  Created by robert engels on 12/26/21.
//

#import "ConnectedComponents.h"
#import "StandardMerge.h"
#import "NSBezierPath_Extensions.h"
#import <Accelerate/Accelerate.h>

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
    unsigned char top[4] = { 0xFF,0xFF,0xFF,0xFF};
    unsigned char bottom[4] = { 0xFF,0xFF,0xFF,0xFF};
    unsigned char tempR[4];

    merge_pm(top,bottom,tempR, 255);

    assert(tempR[0]==0xFF);
    assert(tempR[1]==0xFF);
    assert(tempR[2]==0xFF);
    assert(tempR[3]==0xFF);
}

- (void)testBlendWhiteOnWhite {
    unsigned char bottom[4] = { 0xFF,0xFF,0xFF,0xFF};
    unsigned char top[4] = { 0x7f,0x7f,0x7f,0x7f};
    unsigned char tempR[4];

    merge_pm(top, bottom, bottom, 255);

    assert(tempR[0]==0xFF);
    assert(tempR[1]==0xFF);
    assert(tempR[2]==0xFF);
    assert(tempR[3]==0xFF);
}

- (void)test_merge_pm {
    unsigned char bottom[4] = { 0x7f,0xFF,0xFF,0xFF}; // ARGB non premuliplied
    unsigned char top[4] = { 0x7f,0x7f,0x7f,0x7f}; // ARGB premultipled
    unsigned char dst[4];

    merge_pm(top, bottom, dst, 255);

    assert(dst[0]==0xBF);
    assert(dst[1]==0xFF);
    assert(dst[2]==0xFF);
    assert(dst[3]==0xFF);
}

- (void)test_merge_pm_2 {
    unsigned char bottom[4] = { 0x7f,0xFF,0xF0,0xD0}; // ARGB non premuliplied
    unsigned char top[4] = { 0x7f,0x7f,0x7f,0x7f}; // ARGB premultipled
    unsigned char dst[4];

    merge_pm(top, bottom, dst, 255);

    assert(dst[0]==0xBF);
    assert(dst[1]==0xFF);
    assert(dst[2]==0xF9);
    assert(dst[3]==0xEF);
}


- (void)testVImageComposite {
    CGContextRef ctx = CGBitmapContextCreate(NULL, 400,400,8, 0,CGColorSpaceCreateDeviceRGB(),kCGImageAlphaPremultipliedFirst);
    CGContextClearRect(ctx, CGRectMake(0,0,400,400));
    CGContextSetFillColorWithColor(ctx,[NSColor redColor].CGColor);
    CGContextFillRect(ctx,CGRectMake(50,50,100,100));
    CGImageRef bottom = CGBitmapContextCreateImage(ctx);
    CGContextSetAlpha(ctx, 1);
    CGContextClearRect(ctx, CGRectMake(0,0,400,400));
    CGContextSetFillColorWithColor(ctx,[NSColor blueColor].CGColor);
    CGContextFillRect(ctx,CGRectMake(100,100,100,100));
    CGImageRef top = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);

    vImage_Buffer bottomB = {};
    vImage_Buffer topB = {};

    vImage_CGImageFormat iFormat = {};
    vImageBuffer_InitWithCGImage(&bottomB, &iFormat, NULL, bottom, 0);
    vImageBuffer_InitWithCGImage(&topB, &iFormat, NULL, top, 0);
    vImagePremultipliedConstAlphaBlend_ARGB8888(&topB, 127, &bottomB, &bottomB, 0);
    

    vImage_Error err;
    CGImageRef result = vImageCreateCGImageFromBuffer(&bottomB, &iFormat, NULL, NULL, 0,&err);
    //

}

- (void)testPixelAccess
{
    uint8_t argb[] = { 0x00, 0x01, 0x02, 0x03};
//    uint32_t argb_i = htonl(*(uint32_t*)argb);
    uint32_t argb_i = *(uint32_t*)argb;

    assert(((argb_i>>0) & 0xFF) == 0x00);
    assert(((argb_i>>8) & 0xFF) == 0x01);
    assert(((argb_i>>16) & 0xFF) == 0x02);
    assert(((argb_i>>24) & 0xFF) == 0x03);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

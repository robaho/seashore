//
//  NSBezierPath_Extensions.m
//  Seashore
//
//  Created by robert engels on 8/3/22.
//

#import "NSBezierPath_Extensions.h"

@implementation NSBezierPath(MyExtensions)

static void CGPathToBezierPathApplierFunction(void *info, const CGPathElement *element) {
    NSBezierPath *bezierPath = (__bridge NSBezierPath *)info;
    CGPoint *points = element->points;
    switch(element->type) {
        case kCGPathElementMoveToPoint: [bezierPath moveToPoint:points[0]]; break;
        case kCGPathElementAddLineToPoint: [bezierPath lineToPoint:points[0]]; break;
        case kCGPathElementAddQuadCurveToPoint: {
            NSPoint qp0 = bezierPath.currentPoint, qp1 = points[0], qp2 = points[1], cp1, cp2;
            CGFloat m = (2.0 / 3.0);
            cp1.x = (qp0.x + ((qp1.x - qp0.x) * m));
            cp1.y = (qp0.y + ((qp1.y - qp0.y) * m));
            cp2.x = (qp2.x + ((qp1.x - qp2.x) * m));
            cp2.y = (qp2.y + ((qp1.y - qp2.y) * m));
            [bezierPath curveToPoint:qp2 controlPoint1:cp1 controlPoint2:cp2];
            break;
        }
        case kCGPathElementAddCurveToPoint: [bezierPath curveToPoint:points[2] controlPoint1:points[0] controlPoint2:points[1]]; break;
        case kCGPathElementCloseSubpath: [bezierPath closePath]; break;
    }
}

+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)cgPath {
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
    CGPathApply(cgPath, (__bridge void *)bezierPath, CGPathToBezierPathApplierFunction);
    return bezierPath;
}

- (CGPathRef)cgPath
{
    int numElements = [self elementCount];

    CGMutablePathRef path = CGPathCreateMutable();
    NSPoint points[3];

    for (int i = 0; i < numElements; i++)
    {
        switch ([self elementAtIndex:i associatedPoints:points])
        {
            case NSMoveToBezierPathElement:
                CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                break;

            case NSLineToBezierPathElement:
                CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                break;

            case NSCurveToBezierPathElement:
                CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                      points[1].x, points[1].y,
                                      points[2].x, points[2].y);
                break;

            case NSClosePathBezierPathElement:
                CGPathCloseSubpath(path);
                break;
        }
    }

    CGPathRef immutablePath = CGPathCreateCopy(path);
    CGPathRelease(path);

    return immutablePath;
}

-(NSString*)toString
{
    NSMutableString *ms = [NSMutableString string];
    int n = (int)[self elementCount];
    NSPoint points[4];
    for(int i=0;i<n;i++) {
        if(i>0) {
            [ms appendString:@";"];
        }
        NSBezierPathElement e = [self elementAtIndex:i associatedPoints:points];
        switch(e){
            case NSMoveToBezierPathElement:
                [ms appendFormat:@"M[%@]",NSStringFromPoint(points[0])];
                break;
            case NSLineToBezierPathElement:
                [ms appendFormat:@"L[%@]",NSStringFromPoint(points[0])];
                break;
            case NSCurveToBezierPathElement:
                [ms appendFormat:@"C[%@,%@,%@]",NSStringFromPoint(points[2]),NSStringFromPoint(points[0]),NSStringFromPoint(points[1])];
                break;
            case NSClosePathBezierPathElement:
                [ms appendFormat:@"X"];
                break;
        }
    }
    return ms;
}

void parsePoints(NSString* s,NSPoint points[]) {
    NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:@"(\\{[^\\}]*\\})." options:0 error:nil];

    NSArray *matches = [exp matchesInString:s options:0 range:NSMakeRange(0,[s length])];
    for(int i=0;i<[matches count];i++) {
        NSTextCheckingResult *match = matches[i];
        NSString *ps = [s substringWithRange:[match rangeAtIndex:1]];
        points[i]=NSPointFromString(ps);
    }
}

+(NSBezierPath*)fromString:(NSString*)s
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSPoint points[4];

    for(NSString* segment in [s componentsSeparatedByString:@";"]) {
        parsePoints(segment,points);
        switch([segment characterAtIndex:0]) {
            case 'M':
                [path moveToPoint:points[0]]; break;
            case 'L':
                [path lineToPoint:points[0]]; break;
            case 'C':
                [path curveToPoint:points[0] controlPoint1:points[1] controlPoint2:points[2]]; break;
            case 'X':
                [path closePath]; break;
        }
    }
    return path;
}

@end

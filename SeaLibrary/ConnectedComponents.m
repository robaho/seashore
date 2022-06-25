#import "ConnectedComponents.h"
#import "Constants.h"
#import "Globals.h"

#import <AppKit/AppKit.h>

#define THRESHOLD 32

@interface Run:NSObject

@property int x;
@property int ymin;
@property int ymax;

+ (Run*)init_x:(int)x ymin:(int)ymin ymax:(int)ymax;
@end

@implementation Run
+ (Run*)init_x:(int)x ymin:(int)ymin ymax:(int)ymax
{
    Run *run = [Run alloc];
    run.x = x;
    run.ymin = ymin;
    run.ymax = ymax;
    return run;
}

@end

@interface Vec:NSObject

@property int x;
@property int y;

+ (Vec*)x:(int)x y:(int)y;
-(NSString*)description;
@end

@implementation Vec
+ (Vec*)x:(int)x y:(int)y
{
    Vec *v = [[Vec alloc] init];
    v.x = x;
    v.y = y;
    return v;
}
-(NSString*)description
{
    return [[NSString alloc] initWithFormat:@"%d,%d",self.x,self.y];
}
@end

@interface Edge:NSObject

@property Vec* p0;
@property Vec* p1;

+ (Edge*)p1:(Vec*)p0 p2:(Vec*)p1;
@end

@implementation Edge
+ (Edge*)p1:(Vec*)p0 p2:(Vec*)p1
{
    Edge *e = [[Edge alloc] init];
    e.p0 = p0;
    e.p1 = p1;
    return e;
}
@end

@interface Comp:NSObject
@property int index;
@property int ymin;
@property int ymax;
@property NSMutableArray<Vec*> *points;
@property Vec *leftmost;
@property NSMutableArray<NSNumber*> *inside;
@property NSMutableArray<NSNumber*> *contains;
@end

@implementation Comp
+ (Comp*)init_index:(int)index edge:(Edge*)edge
{
    Comp *c = [[Comp alloc] init];
    c.index = index;
    c.ymin = edge.p0.y;
    c.ymax = edge.p1.y;
    c.points = [NSMutableArray arrayWithObjects:edge.p0,edge.p1,nil];
    c.leftmost = edge.p0;
    c.inside = [NSMutableArray array];
    c.contains = [NSMutableArray array];
    return c;
}

@end


@implementation NSMutableArray (JSMethods)

- (void)reverse {
    if ([self count] <= 1)
        return;
    NSUInteger i = 0;
    NSUInteger j = [self count] - 1;
    while (i < j) {
        [self exchangeObjectAtIndex:i
                  withObjectAtIndex:j];

        i++;
        j--;
    }
}

- (void)unshift:(NSArray*)array {
    for(int i=0;i<[array count];i++){
        [self insertObject:array[i] atIndex:i];
    }
}

- (void)unshiftElement:(NSObject*)element {
    [self insertObject:element atIndex:0];
}

- (NSArray*)slice:(int)start end:(int)end {
    if(end==-1)
        end = (int)[self count];
    NSRange range = NSMakeRange(start,end-start);
    return [self subarrayWithRange:range];
}

@end

@implementation ConnectedComponents

static Comp* undefined;

- (ConnectedComponents*)init
{
    undefined = [[Comp alloc] init];

    hash = [NSMutableDictionary dictionary];
    components = [NSMutableArray array];
    unused = [NSMutableArray array];
    closed = [NSMutableArray array];
    active = [NSMutableSet set];

    return self;
}

static Edge* edge(int x1,int y1,int x2,int y2)
{
    return [Edge p1:[Vec x:x1 y:y1] p2:[Vec x:x2 y:y2]];
}

static Edge* vEdge(Run* run,int x)
{
//    let vEdge = (x) => { return (run) => [Vec(x,run.ymin),Vec(x,run.ymax)] };
    return edge(x,run.ymin,x,run.ymax);
}

- (int)newComponentIndex
{
    // unused should be a stack/linked-list but not available
    if([unused count]>0){
        int index = unused[0].intValue;
        [unused removeObjectAtIndex:0];
        return index;
    }
//    for (int i = 0; i < [components count]; i++) {
//        if (components[i] == undefined) {
//            return i;
//        }
//    }
    return (int)[components count];
}

// Internal procedure to fix fields `contains` and `inside`. Called
// by addVerticalEdge when component j is merged into component i
- (void)_mergeComponents:(int)i j:(int)j {
    Comp *ci = components[i];
    Comp *cj = components[j];

    if (cj.leftmost.x < ci.leftmost.x) {
        ci.leftmost = cj.leftmost;
    }

    NSMutableArray<NSNumber*> *icontains = [ci contains];
    NSMutableArray<NSNumber*> *jcontains = [cj contains];

    for (int indexi = (int)[icontains count]-1; indexi >=0; indexi--) {
        NSNumber *k = icontains[indexi];
        int indexj = (int)[jcontains indexOfObject:k];
        if (indexj >= 0) {
            [icontains removeObjectAtIndex:indexi];
            [jcontains removeObjectAtIndex:indexj];
            NSMutableArray *inside = components[k.intValue].inside;
            int a = (int)[inside indexOfObject:@(i)]; assert(a>=0);
            int b = (int)[inside indexOfObject:@(j)]; assert(b>=0);
            assert(abs(b-a) == 1);
            int min = MIN(a,b);
            [inside removeObjectAtIndex:min];
            [inside removeObjectAtIndex:min];
        }
    }
    for (NSNumber *k in jcontains) {
        NSMutableArray *inside = components[k.intValue].inside;
        int indexj = (int)[inside indexOfObject:@(j)]; assert(indexj>=0);
        inside[indexj] = @(i);
//        assert([icontains indexOfObject:k] == NSNotFound);
        [icontains addObject:k];
    }
}

- (void)addVerticalEdge:(Edge*)edge
{
    int newIndex = [self newComponentIndex];
    Comp *component = [Comp init_index:newIndex edge:edge];
    components [component.index] = component;

    if (hash[@(component.ymin)] != NULL) {
        Comp *c = hash[@(component.ymin)];
        hash[@(component.ymin)] = NULL;
        components[component.index] = undefined;
        if (c.ymin == component.ymin) {
            c.ymin = component.ymax;
            [c.points unshiftElement:component.points[1]];
        }
        else {
            assert(c.ymax == component.ymin);
            c.ymax = component.ymax;
            [c.points addObject:component.points[1]];
        }
        component = c;
    }

    if (hash[@(component.ymin)] != NULL && hash[@(component.ymin)].index != component.index) {
        Comp* c2 = hash[@(component.ymin)];
        assert (component.index != c2.index);
        assert (c2.ymin == component.ymin);

        [c2.points reverse];
        [component.points unshift:[c2.points slice:0 end:[c2.points count]-1]];
        component.ymin = c2.ymax;
        hash[@(c2.ymax)] = NULL;
        if (component.index != newIndex && c2.index != newIndex) {
            [self _mergeComponents:component.index j:c2.index];
        }
        components[c2.index] = undefined;
        [unused addObject:@(c2.index)];
        hash[@(c2.ymin)] = NULL;
        [active removeObject:c2];
    }
    else {
        if (hash[@(component.ymax)] != NULL) {
            Comp *c = hash[@(component.ymax)];
            hash[@(component.ymax)] = NULL;
            if (c != component) {
                if (component.index != newIndex && c.index != newIndex) {
                    [self _mergeComponents:c.index j:component.index];
                }
                components[component.index] = undefined;
                [unused addObject:@(component.index)];
                [active removeObject:component];
                if (c.ymax == component.ymax) {
                    c.ymax = component.ymin;
                    [component.points reverse];
                    [c.points addObjectsFromArray:[component.points slice:1 end:-1]];
                }
                else {
                    assert(c.ymin == component.ymax);
                    c.ymin = component.ymin;
                    [c.points unshift:[component.points slice:0 end:[component.points count]-1]];
                }
                component = c;
            }
        }
    }
    if (component.ymin < component.ymax) {
        hash[@(component.ymin)] = hash[@(component.ymax)] = component;
        [active addObject:component];
    }
    else {
        // Component has been closed. Look up for components in the
        // scanline that contain it
        for (Comp *c in active) {
            if (c && c != component && c.ymin < edge.p0.y && c.ymax > edge.p1.y) {
                [component.inside addObject:@(c.index)];
                [c.contains addObject:@(component.index)];
                assert([active containsObject:c]);
            }
        }
        [component.inside sortUsingComparator:^NSComparisonResult(NSNumber *obj1,NSNumber *obj2) {
            int result = components[obj1.intValue].ymin - components[obj2.intValue].ymin;
            if(result>0)
                return NSOrderedAscending;
            if(result<0)
                return NSOrderedDescending;
            return NSOrderedSame;
        }];
        [active removeObject:component];
        [closed addObject:component];
    }
}

- (void)addHorizontalEdge:(Edge*)edge
{
    assert(edge.p0.y==edge.p1.y);
    assert(hash[@(edge.p0.y)]!=NULL);

    Comp *c = hash[@(edge.p0.y)];
    if (c != NULL) {
        if (c.ymin == edge.p0.y) {
            [c.points unshiftElement:edge.p1];
        }
        else {
            assert(c.ymax == edge.p0.y);
            [c.points addObject:edge.p1];
        }
    }
    else {
        NSLog(@"Dangling h edge %@",edge);
    }
}

+ (ConnectedComponents*) getCirculations:(unsigned char *)data width:(int)w height:(int)h
{
    NSMutableArray* (^getRuns)(int) = ^NSMutableArray* (int x){
        Run *run = NULL;
        NSMutableArray *runs = [NSMutableArray array];
        for (int y = 0; y < h; y++) {
            unsigned pixel = data[(w*y+x)];
            // determine if in outline - remove noise since it distorts marching ants
            Boolean current = pixel >= THRESHOLD;
            if (current) {
                if (run != NULL) run.ymax = y+1;
                else {
                    run = [Run init_x:x ymin:y ymax:y+1];
                    [runs addObject:run];
                }
            }
            else {
                run = NULL;
            }
        }
        return runs;
    };

    NSMutableArray* (^runDifference)(NSMutableArray*,NSMutableArray*) = ^NSMutableArray* (NSMutableArray *runs0,NSMutableArray *runs1)
    {
        runs0 = [NSMutableArray arrayWithArray:runs0];

        int r0len = (int)[runs0 count];
        int r1len = (int)[runs1 count];

        if (r0len==0) return runs0;
        if (r1len==0) return runs0;

        NSMutableArray * result = [NSMutableArray array];
        int i0=0,i1=0;

        while (i0 < r0len && i1 < r1len ) {
            Run *r0 = runs0[i0];
            Run *r1 = runs1[i1];

            if (r0.ymax <= r1.ymin) {
                [result addObject:r0];
                i0++;
            } else if (r1.ymax <= r0.ymin) {
                i1++;
            } else {
                if (r0.ymin < r1.ymin) {
                    Run *run = [Run init_x:r0.x ymin:r0.ymin ymax:r1.ymin];
                    [result addObject:run];
                    r0 = [Run init_x:r0.x ymin:r1.ymin ymax:r0.ymax];
                } else {
                    r0 = [Run init_x:r0.x ymin:r1.ymax ymax:r0.ymax];
                }
                if (r0.ymax <= r0.ymin) i0++;
                else runs0[i0] = r0;
            }
        }
        [result addObjectsFromArray:[runs0 slice:i0 end:-1]];

        return result;
    };

    NSMutableArray<Run*> *prevRuns = [NSMutableArray array];

    ConnectedComponents *connected = [[ConnectedComponents alloc] init];

    for (int x= 0; x <= w; x++) {
        NSMutableArray<Run*> *runs = (x == w ? [NSMutableArray array] : getRuns(x));
        NSMutableArray<Run*> *currMinusPrev = runDifference(runs, prevRuns);
        NSMutableArray<Run*> *prevMinusCurr = runDifference(prevRuns, runs);

        NSMutableArray<Edge*> *verticalEdges = [NSMutableArray array];
        for(Run *r in currMinusPrev){
            [verticalEdges addObject:vEdge(r,x)];
        }
        for(Run *r in prevMinusCurr){
            [verticalEdges addObject:vEdge(r,x)];
        }

        NSMutableArray<Edge*> *horizontalEdges = [NSMutableArray array];
        for (Run *r in runs) {
            [horizontalEdges addObject:edge(r.x,r.ymin,r.x+1,r.ymin)];
            [horizontalEdges addObject:edge(r.x,r.ymax,r.x+1,r.ymax)];
        }
        for (Edge* vEdge in verticalEdges) {
            [connected addVerticalEdge:vEdge];
        }
        for (Edge *hEdge in horizontalEdges) {
            [connected addHorizontalEdge:hEdge];
        }

        prevRuns = runs;
    }

    return connected;
}

- (CGPathRef)paths
{
    CGMutablePathRef paths = CGPathCreateMutable();

    NSMutableArray<Comp*> *comps = [NSMutableArray arrayWithArray:closed];
    [comps reverse];

    int max = 0;

    for(int i=0;i<[comps count];i++){
        max = MAX(max,[comps[i].inside count]);
    }
    max+=1;

    //    int maxLevel = Math.max(...comps.map((c)=>c.inside.length))+1;

    for (Comp *comp in comps) {
        CGMutablePathRef path = CGPathCreateMutable();
        for(Vec *p in comp.points) {
            if(CGPathIsEmpty(path)) {
                CGPathMoveToPoint(path,NULL,p.x,p.y);
            }
            CGPathAddLineToPoint(path,NULL,p.x,p.y);
        }
        CGPathAddPath(paths,NULL,path);
        CGPathRelease(path);
    }

    return paths;
}

#define SCALE_SIZE 256

+ (CGPathRef)getPaths:(unsigned char *)image width:(int)width height:(int)height
{

    NSLog(@"rect bounds %@",NSStringFromIntRect(IntMakeRect(0,0,width,height)));

    float scale=1;

    int w = width;
    int h = height;

    unsigned char *scaledImage = NULL;

    if(width*height>SCALE_SIZE*SCALE_SIZE){
        // scale area to reduce computation, then scale the path back after
        // this is fine since it is only "representative"
        
        long start = getCurrentMillis();

        scale = MIN(SCALE_SIZE/(float)width,SCALE_SIZE/(float)height);
        w = scale * width;
        h = scale * height;

        // scale image
        scaledImage = calloc(w*h,1);
        CGContextRef dst = CGBitmapContextCreate(scaledImage,w,h,8,w,grayCS,kCGImageAlphaNone);
        CGContextRef src = CGBitmapContextCreate(image,width,height,8,width,grayCS,kCGImageAlphaNone);
        CGImageRef srcI = CGBitmapContextCreateImage(src);

        CGRect r = CGRectMake(0,0,w,h);
        CGContextDrawImage(dst,r,srcI);
        CGImageRef dstI = CGBitmapContextCreateImage(dst);
        CGImageRelease(srcI);
        CGImageRelease(dstI);
        CGContextRelease(src);
        CGContextRelease(dst);

        image = scaledImage;

        NSLog(@"marching ants scale time %ld",getCurrentMillis()-start);
    }

    long start = getCurrentMillis();

    ConnectedComponents *cc = [ConnectedComponents getCirculations:image width:w height:h];

    CGPathRef path = [cc paths];

    NSLog(@"marching ants path time %ld",getCurrentMillis()-start);

    CGRect bounds =CGPathGetBoundingBox(path);
    NSLog(@"path bounds0 = %@",NSStringFromRect(bounds));

    if(scaledImage) {
        CGAffineTransform tx = CGAffineTransformIdentity;
        tx = CGAffineTransformScale(tx, 1/scale, 1/scale);
        CGPathRef copy = CGPathCreateCopyByTransformingPath(path, &tx);
        CGPathRelease(path);
        path = copy;
        
        free(scaledImage);

        NSLog(@"path bounds = %@",NSStringFromRect(CGPathGetBoundingBox(path)));
    }
    return path;
}

@end

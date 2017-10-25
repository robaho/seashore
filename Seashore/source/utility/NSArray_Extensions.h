#import <Foundation/Foundation.h>

@interface NSArray(MyExtensions)
- (BOOL)containsObjectIdenticalTo:(id)object;
@end

@interface NSMutableArray(MyExtensions)
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(int)index;
@end


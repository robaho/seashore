//
//  NSOutlineView_Extensions.h
//
//  Copyright (c) 2001-2005, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSOutlineView(MyExtensions)

- (NSArray *)allSelectedItems;
- (void)selectItems:(NSArray *)items byExtendingSelection:(BOOL)extend;
- (void)selectRow:(int)row;

@end

@interface SeaOutlineView : NSOutlineView{
}
@end


//
//  NSOutlineView_Extensions.h
//
//  Copyright (c) 2001-2005, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSOutlineView(MyExtensions)

- (NSArray *)allSelectedItems;
- (void)selectItems:(NSArray *)items byExtendingSelection:(BOOL)extend;

@end

@interface SeaOutlineView : NSOutlineView{
	// The document the outline view is in
	IBOutlet id document;
	
	// Whether or not the view is the first responder
	BOOL isFirst;
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation;
@end


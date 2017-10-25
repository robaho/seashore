/*
	NSOutlineView_Extensions.m
	Copyright (c) 2001-2006, Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

        NSOutlineView category (MyExtensions), and subclass (MyOutlineView)
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "NSOutlineView_Extensions.h"
#import "LayerDataSource.h"

#import "SeaDocument.h"
#import "SeaView.h"

@implementation NSOutlineView(MyExtensions)

- (id)selectedItem { 
    return [self itemAtRow: [self selectedRow]]; 
}

- (NSArray *)allSelectedItems {
    NSMutableArray *items = [NSMutableArray array];
    NSIndexSet *selectedIndexes = [self selectedRowIndexes];
	int i;
	for(i = 0; i < [self numberOfRows]; i++){
		if([selectedIndexes containsIndex:i]){
			[items addObject: [self itemAtRow: i]];
		}
	}
    return items;
}

- (void)selectItems:(NSArray *)items byExtendingSelection:(BOOL)extend {
    int i, totalCount = [items count];
    if (extend==NO) [self deselectAll:nil];
    for (i = 0; i < totalCount; i++) {
        int row = [self rowForItem:[items objectAtIndex:i]];
        if(row>=0) [self selectRow: row byExtendingSelection:YES];
    }
}

@end

@implementation SeaOutlineView

/* This NSOutlineView subclass is necessary only if you want to delete items by dragging them to the trash.  In order to support drags to the trash, you need to implement draggedImage:endedAt:operation: and handle the NSDragOperationDelete operation.  For any other operation, pass the message to the superclass */
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    if (operation == NSDragOperationDelete) {
        // Tell all of the dragged nodes to remove themselves from the model.
        NSArray *selection = [(LayerDataSource *)[self dataSource] draggedNodes];
        [selection makeObjectsPerformSelector: @selector(removeFromParent)];
        [self deselectAll:nil];
        [self reloadData];
    } else {
        [super draggedImage:image endedAt:screenPoint operation:operation];
    }
}

-(void)highlightSelectionInClipRect:(NSRect)theClipRect
{
	[[NSBezierPath bezierPathWithRect:theClipRect] fill];
	NSIndexSet *indecies = [self selectedRowIndexes];
	int i;
	for(i = 0; i < [self numberOfRows]; i++){
		if([indecies containsIndex: i]){
			[[NSImage imageNamed:((isFirst && [[self window] isMainWindow]) ?@"sel-gradient" :@"bg-gradient")] drawInRect:[self rectOfRow: i] fromRect:NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];	
		}else{
			[[NSColor colorWithCalibratedRed:228.0/255 green:234.0/255 blue:241.0/255 alpha:1.0] set];
			[[NSBezierPath bezierPathWithRect: [self rectOfRow: i]] fill];
		}
	}
}

-(id)_highlightColorForCell:(NSCell *)cell
{
    return nil;
}

-(BOOL)acceptsFirstResponder
{
	return NO;
}

-(BOOL)resignFirstResponder
{
	isFirst = NO;
	return [super resignFirstResponder];
}

@end


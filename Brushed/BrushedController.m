#import "BrushedController.h"
#import "BrushDocument.h"

#define document [[NSDocumentController sharedDocumentController] currentDocument]

@implementation BrushedController

- (IBAction)copy:(id)sender
{
	NSImage *image = [document brushImage];
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	
	// Copy the image to the pasteboard
	[pasteboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:nil];
	[pasteboard setData:[image TIFFRepresentation] forType:NSTIFFPboardType];
}

- (IBAction)paste:(id)sender
{
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	NSString *dataType = [pasteboard availableTypeFromArray:[NSArray arrayWithObject:NSTIFFPboardType]];
	
	// Copy the image from the pasteboard
	if (dataType) {
		[document changeImage:[NSBitmapImageRep imageRepWithData:[pasteboard dataForType:dataType]]];
	}
}

- (BOOL)validateMenuItem:(id)menuItem
{
	if (document == NULL)
		return NO;
	
	return YES;
}

@end

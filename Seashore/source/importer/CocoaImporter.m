#import "CocoaImporter.h"
#import "CocoaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaView.h"
#import "SeaOperations.h"
#import "SeaAlignment.h"
#import "SeaController.h"

@implementation CocoaImporter

- (BOOL)addToDocument:(id)doc contentsOfFile:(NSString *)path
{
	id imageRep;
	NSImage *image;
    SeaLayer * layer;
	int value;
	// NSPoint centerPoint;
	
	// Open the image
	image = [[NSImage alloc] initWithContentsOfFile:path];
	if (image == NULL) {
		return NO;
	}
	
	// Form a bitmap representation of the file at the specified path
	imageRep = NULL;
	if ([[image representations] count] > 0) {
		imageRep = [[image representations] objectAtIndex:0];
		if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			if ([imageRep isKindOfClass:[NSPDFImageRep class]]) {
                
                NSPDFImageRep *pdfRep = (NSPDFImageRep*)imageRep;
                
                int dpi_index =0;
                if ([gUserDefaults objectForKey:@"pdfDPI"])
                    dpi_index = [gUserDefaults integerForKey:@"pdfDPI"];

                [NSBundle loadNibNamed:@"CocoaContent" owner:self];
                [resMenu setEnabled:YES];
                [resMenu selectItemAtIndex:dpi_index];
                [pdfPanel center];
                [pageLabel setStringValue:[NSString stringWithFormat:@"of %d", [imageRep pageCount]]];
                [NSApp runModalForWindow:pdfPanel];
                [pdfPanel orderOut:self];
                
                value = [pageInput intValue];
                if (value > 0 && value <= [pdfRep pageCount]){
                    [pdfRep setCurrentPage:value - 1];
                }
                
                NSSize sourceSize = [image size];
                NSSize size = sourceSize;
                
                value = [resMenu indexOfSelectedItem];
                switch (value) {
                    case 0:
                        break;
                    case 1:
                        size.width *= 96.0 / 72.0;
                        size.height *= 96.0 / 72.0;
                        break;
                    case 2:
                        size.width *= 150.0 / 72.0;
                        size.height *= 150.0 / 72.0;
                        break;
                    case 3:
                        size.width *= 300.0 / 72.0;
                        size.height *= 300.0 / 72.0;
                        break;
                    case 4:
                        size.width *= 600.0 / 72.0;
                        size.height *= 600.0 / 72.0;
                        break;
                    case 5:
                        size.width *= 900.0 / 72.0;
                        size.height *= 900.0 / 72.0;
                        break;
                    case 6:
                        size.width *= 1200.0 / 72.0;
                        size.height *= 1200.0 / 72.0;
                        break;
                }
                [gUserDefaults setInteger:value forKey:@"pdfDPI"];

                [[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
                [image setSize:size];
                NSRect destinationRect = NSMakeRect( 0, 0, size.width, size.height );
                NSImage* dest = [[NSImage alloc] initWithSize:size];
                [dest lockFocus];
                NSRectFillUsingOperation( destinationRect, NSCompositeClear );
                [image drawInRect: destinationRect
                         fromRect: destinationRect
                        operation: NSCompositeCopy fraction: 1.0];
                
                NSBitmapImageRep* newRep = [[NSBitmapImageRep alloc]
                                            initWithFocusedViewRect: destinationRect];
                [dest unlockFocus];
                imageRep = newRep;

            } else {
                imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
            }
		}
	}
	if (imageRep == NULL) {
		return NO;
	}
		
	// Warn if 16-bit image
	if ([imageRep bitsPerSample] == 16) {
		[[doc warnings] addMessage:LOCALSTR(@"16-bit message", @"Seashore does not support the editing of 16-bit images. This image has been resampled at 8-bits to be imported.") level:kHighImportance];
	}
		
	// Create the layer
	layer = [[CocoaLayer alloc] initWithImageRep:imageRep document:doc spp:[[doc contents] spp]];
	if (layer == NULL) {
		return NO;
	}
	
	// Rename the layer
	[layer setName:[[NSString alloc] initWithString:[path lastPathComponent]]];
	
	// Add the layer
	[[doc contents] addLayerObject:layer];
	
	// Position the new layer correctly
	[[(SeaOperations *)[doc operations] seaAlignment] centerLayerHorizontally:NULL];
	[[(SeaOperations *)[doc operations] seaAlignment] centerLayerVertically:NULL];
	
	return YES;
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

@end

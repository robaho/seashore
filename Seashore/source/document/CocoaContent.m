#import "CocoaContent.h"
#import "CocoaLayer.h"
#import "SeaController.h"
#import "SeaWarning.h"
#import "SeaDocumentController.h"

@implementation CocoaContent

+ (BOOL)typeIsEditable:(NSString *)aType forDoc:(id)doc
{
	SeaDocumentController* controller = (SeaDocumentController*)[NSDocumentController
															sharedDocumentController];				 
	if([controller type: aType isContainedInDocType: @"TIFF image"] ||
	   [controller type: aType isContainedInDocType: @"Portable Network Graphics image"] ||
	   [controller type: aType isContainedInDocType: @"JPEG image"] ||
	   [controller type: aType isContainedInDocType: @"JPEG 2000 image"]){
		return YES;
	}else if ([controller type: aType isContainedInDocType: @"Graphics Interchange Format (GIF)"]){
		[[SeaController seaWarning]
		 addMessage:LOCALSTR(@"gif trans",
							 @"Seashore does not support GIF transparency or animation.")
		 forDocument:doc level:kHighImportance];
		return YES;
	}

	return  NO;
}

+ (BOOL)typeIsViewable:(NSString *)aType forDoc:(id)doc
{
	if ([CocoaContent typeIsEditable:aType forDoc:doc]) {
		return YES;
	}
	
	SeaDocumentController* controller = [SeaDocumentController sharedDocumentController];
	if([controller type: aType isContainedInDocType: @"Portable Document Format (PDF)"] ||
	   [controller type: aType isContainedInDocType: @"QuickDraw picture"] ||
	   [controller type: aType isContainedInDocType: @"Windows bitmap image"]){
		return YES;
	}
	return NO;
}


- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path
{
	id imageRep;
	NSImage *image;
	id layer;
	BOOL test, res_set = NO;
	int value;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Open the image
	image = [[NSImage alloc] initByReferencingFile:path];
	if (image == NULL) {
		[image autorelease];
		[self autorelease];
		return NULL;
	}
	
	// Form a bitmap representation of the file at the specified path
	imageRep = NULL;
	if ([[image representations] count] > 0) {
		imageRep = [[image representations] objectAtIndex:0];
		if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			if ([imageRep isKindOfClass:[NSPDFImageRep class]]) {
				
				[image setScalesWhenResized:YES];
				[image setDataRetained:YES];
				
				[NSBundle loadNibNamed:@"CocoaContent" owner:self];
				[resMenu setEnabled:YES];
				[pdfPanel center];
				[pageLabel setStringValue:[NSString stringWithFormat:@"of %d", [imageRep pageCount]]];
				[resMenu selectItemAtIndex:0];
				[NSApp runModalForWindow:pdfPanel];
				[pdfPanel orderOut:self];

				value = [pageInput intValue];
				if (value > 0 && value <= [imageRep pageCount]){
					[imageRep setCurrentPage:value - 1];
				}

				NSSize sourceSize = [image size];
				NSSize size = sourceSize;
				
				value = [resMenu indexOfSelectedItem];
				switch (value) {
					case 0:
						res_set = YES;
						xres = yres = 72.0;
					break;
					case 1:
						res_set = YES;
						size.width *= 96.0 / 72.0;
						size.height *= 96.0 / 72.0;
						xres = yres = 96.0;
					break;
					case 2:
						res_set = YES;
						size.width *= 150.0 / 72.0;
						size.height *= 150.0 / 72.0;
						xres = yres = 150.0;
					break;
					case 3:
						res_set = YES;
						size.width *= 300.0 / 72.0;
						size.height *= 300.0 / 72.0;
						xres = yres = 300.0;
					break;
					case 4:
						res_set = YES;
						size.width *= 600.0 / 72.0;
						size.height *= 600.0 / 72.0;
						xres = yres = 600.0;
					break;
					case 5:
						res_set = YES;
						size.width *= 900.0 / 72.0;
						size.height *= 900.0 / 72.0;
						xres = yres = 900.0;
					break;
				}
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
				[dest autorelease];
				imageRep = newRep;
			}else {
				imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
			}
		}
	}
	if (imageRep == NULL) {
		[image autorelease];
		[self autorelease];
		return NULL;
	}
	
	// Warn if 16-bit image
	if ([imageRep bitsPerSample] == 16) {
		[[SeaController seaWarning] addMessage:LOCALSTR(@"16-bit message", @"Seashore does not support the editing of 16-bit images. This image has been resampled at 8-bits to be imported.") forDocument:doc level:kHighImportance];
	}
	
	// Determine the height and width of the image
	height = [imageRep pixelsHigh];
	width = [imageRep pixelsWide];
	
	// Determine the resolution of the image
	if (!res_set) {
		xres = roundf(((float)width / [image size].width) * 72);
		yres = roundf(((float)height / [image size].height) * 72);
	}
	
	// Determine the image type
	test = [[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace];
	test = test || [[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace];
	if (test) 
		type = XCF_GRAY_IMAGE;
	else
		type = XCF_RGB_IMAGE;
		
	// Store EXIF data
	exifData = [imageRep valueForProperty:@"NSImageEXIFData"];
	if (exifData) [exifData retain];
	
	// Create the layer
	layer = [[CocoaLayer alloc] initWithImageRep:imageRep document:doc spp:(type == XCF_RGB_IMAGE) ? 4 : 2];
	if (layer == NULL) {
		[image autorelease];
		[self autorelease];
		return NULL;
	}
	layers = [NSArray arrayWithObject:layer];
	[layers retain];
	
	// Now forget the NSImage
	[image autorelease];
	
	return self;
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

@end

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
       [controller type: aType isContainedInDocType: @"HEIC image"] ||
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
	NSImageRep *imageRep;
	NSImage *image;
	id layer;
	BOOL test, res_set = NO;
	int value;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Open the image
	image = [[NSImage alloc] initWithContentsOfFile:path];
	if (image == NULL) {
		return NULL;
	}
	
	// Form a bitmap representation of the file at the specified path
	imageRep = NULL;
	if ([[image representations] count] > 0) {
		imageRep = [[image representations] objectAtIndex:0];
		if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			if ([imageRep isKindOfClass:[NSPDFImageRep class]]) {
                
                int dpi_index =0;
                if ([gUserDefaults objectForKey:@"pdfDPI"])
                    dpi_index = [gUserDefaults integerForKey:@"pdfDPI"];
                
                NSPDFImageRep *pdfRep = (NSPDFImageRep*)imageRep;
				
				[NSBundle loadNibNamed:@"CocoaContent" owner:self];
				[resMenu setEnabled:YES];
                [resMenu selectItemAtIndex:dpi_index];
				[pdfPanel center];
				[pageLabel setStringValue:[NSString stringWithFormat:@"of %d", [pdfRep pageCount]]];
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
                    case 6:
                        res_set = YES;
                        size.width *= 1200.0 / 72.0;
                        size.height *= 1200.0 / 72.0;
                        xres = yres = 1200.0;
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
			}else {
				imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
			}
		}
	}
	if (imageRep == NULL) {
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
	exifData = [(NSBitmapImageRep*)imageRep valueForProperty:@"NSImageEXIFData"];
    
    fileColorSpace = [(NSBitmapImageRep*)imageRep colorSpace];
	
	// Create the layer
	layer = [[CocoaLayer alloc] initWithImageRep:imageRep document:doc spp:(type == XCF_RGB_IMAGE) ? 4 : 2];
	if (layer == NULL) {
		return NULL;
	}
	layers = [NSArray arrayWithObject:layer];
	
	return self;
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

@end

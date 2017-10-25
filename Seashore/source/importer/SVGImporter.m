#import "SVGImporter.h"
#import "CocoaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaView.h"
#import "CenteringClipView.h"
#import "SeaOperations.h"
#import "SeaAlignment.h"
#import "SeaController.h"
#import "SeaWarning.h"

extern IntSize getDocumentSize(char *path);

@implementation SVGImporter

- (BOOL)addToDocument:(id)doc contentsOfFile:(NSString *)path
{
	id imageRep, layer;
	NSImage *image;
	NSString *importerPath;
	NSString *path_in, *path_out, *width_arg, *height_arg;
	NSArray *args;
	NSTask *task;
		
	// Load nib file
	[NSBundle loadNibNamed:@"SVGContent" owner:self];
	
	// Run the scaling panel
	[scalePanel center];
	trueSize = getDocumentSize((char *)[path fileSystemRepresentation]);
	size.width = trueSize.width; size.height = trueSize.height;
	[sizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", size.width, size.height]];
	[scaleSlider setIntValue:2];
	[NSApp runModalForWindow:scalePanel];
	[scalePanel orderOut:self];
	
	// Add all plug-ins to the array
	importerPath = [[gMainBundle builtInPlugInsPath] stringByAppendingString:@"/SVGImporter.app/Contents/MacOS/SVGImporter"];
	if ([gFileManager fileExistsAtPath:importerPath]) {
		if (![gFileManager fileExistsAtPath:@"/tmp/seaimport"]) [gFileManager createDirectoryAtPath:@"/tmp/seaimport" attributes:NULL];
		path_in = path;
		path_out = [NSString stringWithFormat:@"/tmp/seaimport/%@.png", [[path lastPathComponent] stringByDeletingPathExtension]];
		if (size.width > 0 && size.height > 0 && size.width < kMaxImageSize && size.height < kMaxImageSize) {
			width_arg = [NSString stringWithFormat:@"%d", size.width];
			height_arg = [NSString stringWithFormat:@"%d", size.height];
			args = [NSArray arrayWithObjects:path_in, path_out, width_arg, height_arg, NULL];
		}
		else {
			args = [NSArray arrayWithObjects:path_in, path_out, NULL];
		}
		[waitPanel center];
		[waitPanel makeKeyAndOrderFront:self];
		task = [NSTask launchedTaskWithLaunchPath:importerPath arguments:args];
		[spinner startAnimation:self];
		while ([task isRunning]) {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		}
		[spinner stopAnimation:self];
		[waitPanel orderOut:self];
	}
	else {
		[[SeaController seaWarning] addMessage:LOCALSTR(@"SVG message", @"Seashore is unable to open the given SVG file because the SVG Importer is not installed. The installer for this importer can be found on Seashore's website.") level:kHighImportance];
		return NO;
	}
	
	// Open the image
	image = [[NSImage alloc] initByReferencingFile:path_out];
	if (image == NULL) {
		[image autorelease];
		return NO;
	}
	
	// Form a bitmap representation of the file at the specified path
	imageRep = NULL;
	if ([[image representations] count] > 0) {
		imageRep = [[image representations] objectAtIndex:0];
		if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
		}
	}
	if (imageRep == NULL) {
		[image autorelease];
		return NO;
	}
		
	// Create the layer
	layer = [[CocoaLayer alloc] initWithImageRep:imageRep document:doc spp:[[doc contents] spp]];
	if (layer == NULL) {
		[image autorelease];
		return NO;
	}
	
	// Rename the layer
	[(SeaLayer *)layer setName:[[NSString alloc] initWithString:[[path lastPathComponent] stringByDeletingPathExtension]]];
	
	// Add the layer
	[[doc contents] addLayerObject:layer];
	
	// Now forget the NSImage
	[image autorelease];
	
	// Position the new layer correctly
	[[(SeaOperations *)[doc operations] seaAlignment] centerLayerHorizontally:NULL];
	[[(SeaOperations *)[doc operations] seaAlignment] centerLayerVertically:NULL];
	
	return YES;
}


- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (IBAction)update:(id)sender
{
	double factor;
	
	switch ([scaleSlider intValue]) {
		case 0:
			factor = 0.5;
		break;
		case 1:
			factor = 0.75;
		break;
		case 2:
			factor = 1.0;
		break;
		case 3:
			factor = 1.5;
		break;
		case 4:
			factor = 2.0;
		break;
		case 5:
			factor = 3.75;
		break;
		case 6:
			factor = 5.0;
		break;
		case 7:
			factor = 7.5;
		break;
		case 8:
			factor = 10.0;
		break;
		case 9:
			factor = 25.0;
		break;
		case 10:
			factor = 50.0;
		break;
		default:
			factor = 1.0;
		break;
	}
	
	size.width = trueSize.width * factor;
	size.height = trueSize.height * factor;
	
	[sizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", size.width, size.height]];
}

@end

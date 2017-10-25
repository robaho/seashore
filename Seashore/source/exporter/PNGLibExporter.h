/*!
	@class		PNGExporter
	@abstract	Exports to the PNG file format using Cocoa.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#import "Globals.h"
#import "AbstractExporter.h"

@interface PNGExporter : AbstractExporter {

	// YES if full ICC profile should be embedded
	BOOL ICC;

	// YES if interlacing should be used, NO otherwise
	BOOL interlace;

}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		hasOptions
	@discussion	Returns whether or not the exporter offers additional options.
	@result		Returns YES if the exporter offers additional options through
				the showOptions: method, NO otherwise.
*/
- (BOOL)hasOptions;

/*!
	@method		showOptions:
	@discussion	If hasOptions returns YES, this method displays a panel allowing
				the user to configure additional options for the exporter.
	@param		sender
				Ignored.
*/
- (IBAction)showOptions:(id)sender;

/*!
	@method		title
	@discussion	Returns the title of the exporter (as will be displayed in the
				save panel).
	@result		Returns an NSString representing the title of the exporter.
*/
- (NSString *)title;

/*!
	@method		name
	@discussion	Returns the name of the document type associated with this
				exporter. This is equivalent to the CFBundleTypeName in the
				CFBundleDocumentTypes array.
	@result		Returns a NSString representing the document type associated
				with this exporter.
*/
- (NSString *)name;

/*!
	@method		extension
	@discussion	Returns the extension of the file format associated with this
				exporter.
	@result		Returns a NSString representing the extension of the file format
				associated with this exporter.
*/
- (NSString *)extension;

/*!
	@method		writeDocument:toFile:
	@discussion	Writes the given document to disk using the format of the
				exporter.
	@param		document
				The document to write to disk.
	@param		path
				The path at which to write the document.
	@result		Returns YES if the operation was successful, NO otherwise.
*/
- (BOOL)writeDocument:(id)document toFile:(NSString *)path;

@end

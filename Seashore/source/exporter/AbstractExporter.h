#import "Globals.h"

/*!
	@class		AbstractExporter
	@abstract	Acts as a base class for all exporters.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface AbstractExporter : NSObject {

}

/*!
	@method		hasOptions
	@discussion	Returns whether or not the exporter offers additional options.
	@result		Returns YES if the exporter offers additional options through
				the showOptions: method, NO otherwise.  The implementation in
				this class always returns NO.
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
 save panel). This must be equal to the CFBundleTypeName in the
 CFBundleDocumentTypes array.
	@result		Returns an NSString representing the title of the exporter.
*/
- (NSString *)title;

/*!
	@method		extension
	@discussion	Returns the FIRST extension of the file format associated with this
				exporter.
	@result		Returns a NSString representing the extension of the file format
				associated with this exporter.
*/
- (NSString *)extension;

/*!
	@method		optionsString
	@discussion	Returns a brief statement summarizing the current options.
	@result		Returns an NSString summarizing the current options.
*/
- (NSString *)optionsString;

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

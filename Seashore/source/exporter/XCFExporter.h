#import "Seashore.h"
#import "AbstractExporter.h"

/*!
	@class		XCFExporter
	@abstract	Exports to the XCF file format.
	@discussion	The XCF file format is the GIMP's native file format. XCF stands
				for "eXperimental Comupting Facility".
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@class SeaDocument;

@interface XCFExporter : AbstractExporter {
	// The document that is being exported
	SeaDocument *document;
	
	// These hold 64 bytes of temporary information for us 
	int tempIntString[16];
	char tempString[64];
}

@end

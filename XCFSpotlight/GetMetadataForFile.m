#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#include <Cocoa/Cocoa.h>

#import "XCFContent.h"
#import "XCFLayer.h"

/* -----------------------------------------------------------------------------
 Step 1
 Set the UTI types the importer supports
 
 Modify the CFBundleDocumentTypes entry in Info.plist to contain
 an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
 that your importer can handle
 
 ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
 Step 2 
 Implement the GetMetadataForFile function
 
 Implement the GetMetadataForFile function below to scrape the relevant
 metadata from your document and return it as a CFDictionary using standard keys
 (defined in MDItem.h) whenever possible.
 ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
 Step 3 (optional) 
 If you have defined new attributes, update the schema.xml file
 
 Edit the schema.xml file to include the metadata keys that your importer returns.
 Add them to the <allattrs> and <displayattrs> elements.
 
 Add any custom types that your importer requires to the <attributes> element
 
 <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
 
 ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
 Get metadata attributes from file
 
 This function's job is to extract useful information your file format supports
 and return it as a dictionary
 ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
						   CFMutableDictionaryRef attributes, 
						   CFStringRef contentTypeUTI,
						   CFStringRef pathToFile)
{
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
    
    /* Return the attribute keys and attribute values in the dict */
    /* Return true if successful, false if there was no data provided */
    Boolean success=NO;
    NSAutoreleasePool *pool;
	
    // Don't assume that there is an autorelease pool around the calling of this function.
    pool = [[NSAutoreleasePool alloc] init];
    // load the document at the specified location
	XCFContent *contents = [[XCFContent alloc] initWithContentsOfFile: (NSString *)pathToFile];
	if(contents)
	{
		int width = [contents width];
		int height = [contents height];
		[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:width]
											  forKey:(NSString *)kMDItemPixelWidth];

		[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:height]
											  forKey:(NSString *)kMDItemPixelHeight];
		
		if(width > height){
			[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:1]
												  forKey:(NSString *)kMDItemOrientation];
		}else{
			[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:0]
												  forKey:(NSString *)kMDItemOrientation];
		}
		

		[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:[contents spp] * 8]
											  forKey:(NSString *)kMDItemBitsPerSample];
		
		[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:[contents xres]]
											  forKey:(NSString *)kMDItemResolutionWidthDPI];
		
		[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:[contents yres]]
											  forKey:(NSString *)kMDItemResolutionHeightDPI];
		
		if([contents type] == XCF_RGB_IMAGE){
			[(NSMutableDictionary *)attributes setObject:[NSString stringWithString:@"RGB"]	forKey:(NSString *)kMDItemColorSpace];
		}else if([contents type] == XCF_GRAY_IMAGE){
			[(NSMutableDictionary *)attributes setObject:[NSString stringWithString: @"Gray"] forKey:(NSString *)kMDItemColorSpace];
		}
		
		NSMutableArray *names = [NSMutableArray arrayWithCapacity:[contents layerCount]];
		BOOL hasAlpha = NO;
		int i;
		for(i = 0; i < [contents layerCount]; i++){
			XCFLayer *layer = [contents layer:i];
			[names addObject:[layer name]];
			if([layer hasAlpha]) hasAlpha = YES;
		}

		[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithBool:hasAlpha]
											  forKey:(NSString *)kMDItemHasAlphaChannel];
		[(NSMutableDictionary *)attributes setObject:names
											  forKey:(NSString *)kMDItemLayerNames];

		if([contents exifData]){
			NSDictionary *data = [contents exifData];
			if([data objectForKey:@"FNumber"]){
				[(NSMutableDictionary *)attributes setObject:[data objectForKey:@"FNumber"]
													  forKey:(NSString *)kMDItemFNumber];
			}
			
			if([data objectForKey:@"ExifVersion"]){
				[(NSMutableDictionary *)attributes setObject:[[data objectForKey:@"ExifVersion"] componentsJoinedByString:@"."]
													  forKey:(NSString *)kMDItemEXIFVersion];
			}
			
			if([data objectForKey:@"DateTimeOriginal"]){
				[(NSMutableDictionary *)attributes setObject:[data objectForKey:@"DateTimeOriginal"]
													  forKey:(NSString *)kMDItemContentCreationDate];
				
			}
		}
		
		success=YES;
	}
	
	
	/*
    tempDict=[[NSDictionary alloc] initWithContentsOfFile:(NSString *)pathToFile];
    if (tempDict)
    {
		// set the kMDItemTitle attribute to the Title
		[(NSMutableDictionary *)attributes setObject:[tempDict objectForKey:@"title"]
											  forKey:(NSString *)kMDItemTitle];
		
		// set the kMDItemAuthors attribute to an array containing the single Author
		// value
		[(NSMutableDictionary *)attributes setObject:[NSArray arrayWithObject:[tempDict objectForKey:@"author"]]
											  forKey:(NSString *)kMDItemAuthors];
		
		// set our custom document notes attribute to the Notes value
		// (in the real world, you'd likely use the kMDItemTextContent attribute, however that
		// would make it hard to demonstrate using a custom key!)
		[(NSMutableDictionary *)attributes setObject:[tempDict objectForKey:@"notes"]
											  forKey:@"com_apple_myCocoaDocumentApp_myCustomDocument_notes"];
		
		// return YES so that the attributes are imported
		success=YES;
		
		// release the loaded document
		[tempDict release];
    }*/
    [pool release];
    return success;
}

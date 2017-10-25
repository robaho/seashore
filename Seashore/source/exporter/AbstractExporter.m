#import "AbstractExporter.h"

@implementation AbstractExporter

- (BOOL)hasOptions
{
	return NO;
}

- (IBAction)showOptions:(id)sender
{
}

- (NSString *)title
{
	return NULL;
}

- (NSString *)extension
{
	/*if(![self title]){
		NSLog(@"This is an Abstract Class and should not be instantiated");
		return @"";
	}
	
	int i;
	NSArray* allDocumentTypes = [[[NSBundle mainBundle] infoDictionary]
								 valueForKey:@"CFBundleDocumentTypes"];
	for(i = 0; i < [allDocumentTypes count]; i++){
		NSDictionary *typeDict = [allDocumentTypes objectAtIndex:i];
		NSString* key = [typeDict objectForKey:@"CFBundleTypeName"];
		if ([key isEqual: [self title]]) {
			return [[typeDict objectForKey:@"CFBundleTypeExtensions"]objectAtIndex:0];
		}
	}*/
			 
	return @"";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
	return NO;
}

- (NSString *)optionsString
{
	return @"";
}

@end

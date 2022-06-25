#import "XCFImporter.h"
#import "XCFLayer.h"
#import "SeaDocument.h"
#import "SeaAlignment.h"
#import "SeaOperations.h"

@implementation XCFImporter

- (BOOL)addToDocument:(SeaDocument*)doc contentsOfFile:(NSString *)path
{
    SeaDocument *tempDoc = [[SeaDocument alloc] initWithContentsOfFile:path ofType:@"xcf"];
    if(tempDoc==nil){
        return NO;
    }
    
    SeaContent *contents = [tempDoc contents];
    
    int i;
    
	// Add the layers
	for (i = [contents layerCount] - 1; i >= 0; i--) {
        SeaLayer *copy = [[SeaLayer alloc] initWithDocument:doc layer:[contents layer:i]];
        [[doc contents] addLayerObject:copy];
	}
	
	return YES;
}

@end

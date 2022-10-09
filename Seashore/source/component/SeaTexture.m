#import "SeaTexture.h"

@implementation SeaTexture

- (id)initWithContentsOfFile:(NSString *)path
{
	BOOL isDir;
	
	// Check if file is a directory
	if ([gFileManager fileExistsAtPath:path isDirectory:&isDir] && isDir) {
		return NULL;
	}
	
	// Get the image
    image = [[NSImage alloc] initWithContentsOfFile:path];
    if(!image){
        return NULL;
    }
    width = (int)[image size].width;
    height = (int)[image size].height;

	// Remember the texture name
    name = [[path lastPathComponent] stringByDeletingPathExtension];

	return self;
}

- (void)dealloc
{
}

- (NSImage *)thumbnail
{
    return image;
}

- (NSString *)name
{
	return name;
}

- (int)width
{
	return width;
}

- (int)height
{
	return height;
}

- (NSImage*)image
{
    return image;
}

- (NSComparisonResult)compare:(id)other
{
	return [[self name] caseInsensitiveCompare:[other name]];
}

@end

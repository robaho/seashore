#import "CIPerspectiveTileClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIPerspectiveTileClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	
	return self;
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 4;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Perspective" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Tile" table:NULL];
}

- (NSString *)instruction
{
	return [gOurBundle localizedStringForKey:@"instruction" value:@"Needs localization." table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
		
	[self execute];
	[pluginData apply];
	success = YES;
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self execute];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return NO;
}

- (void)execute
{
    PluginData *pluginData = [seaPlugins data];
    
    int height = [pluginData height];
    
    IntPoint point_tl = [pluginData point:0];
    IntPoint point_tr = [pluginData point:1];
    IntPoint point_br = [pluginData point:2];
    IntPoint point_bl = [pluginData point:3];

    CGRect bounds = determineContentBorders(pluginData);
    CIImage *inputImage = croppedCIImage(pluginData,bounds);
    
    CIFilter *filter = [CIFilter filterWithName:@"CIPerspectiveTile"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIPerspectiveTile"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:inputImage forKey:@"inputImage"];
    [filter setValue:[CIVector vectorWithX:point_tl.x Y:height - point_tl.y] forKey:@"inputTopLeft"];
    [filter setValue:[CIVector vectorWithX:point_tr.x Y:height - point_tr.y] forKey:@"inputTopRight"];
    [filter setValue:[CIVector vectorWithX:point_br.x Y:height - point_br.y] forKey:@"inputBottomRight"];
    [filter setValue:[CIVector vectorWithX:point_bl.x Y:height - point_bl.y] forKey:@"inputBottomLeft"];
    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    renderCIImage(pluginData,outputImage);
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end

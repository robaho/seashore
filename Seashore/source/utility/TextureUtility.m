#import "TextureUtility.h"
#import "TextureView.h"
#import "SeaTexture.h"
#import "SeaController.h"
#import "ToolboxUtility.h"
#import "SeaPrefs.h"
#import "SeaProxy.h"
#import "InfoPanel.h"
#import "TextTool.h"
#import "SeaDocument.h"
#import "SeaTools.h"

#ifdef TODO
#warning Make textures shared across all open documents
#endif

@implementation TextureUtility

- (id)init
{		
	[self loadTextures:NO];
	
	if ([gUserDefaults objectForKey:@"active texture group"] == NULL)
		activeGroupIndex = 0;
	else
		activeGroupIndex = [gUserDefaults integerForKey:@"active texture group"];
	if (activeGroupIndex < 0 || activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
		

	[opacitySlider setIntValue:100];
	[opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider intValue]]];
	opacity = 255;
	
	return self;
}

- (void)awakeFromNib
{
	int i;
	
	[super awakeFromNib];

	[view setHasVerticalScroller:YES];
	[view setDocumentView:[[TextureView alloc] initWithMaster:self]];
	[view setLineScroll:kTexturePreviewSize];
	
	[textureGroupPopUp removeAllItems];
	[textureGroupPopUp addItemWithTitle:[groupNames objectAtIndex:0]];
	[[textureGroupPopUp itemAtIndex:0] setTag:0];
	[[textureGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = 1; i < [groupNames count]; i++) {
		[textureGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
		[[textureGroupPopUp itemAtIndex:[[textureGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[textureGroupPopUp selectItemAtIndex:[textureGroupPopUp indexOfItemWithTag:activeGroupIndex]];

    [window setDelegate:self];
	
    // Determine the currently active texture
    if ([gUserDefaults objectForKey:@"active texture"] == NULL)
        selected = NULL;
    else
        [self setActiveTextureIndex:[gUserDefaults integerForKey:@"active texture"]];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[self activeTextureIndex] forKey:@"active texture"];
	[gUserDefaults setInteger:activeGroupIndex forKey:@"active texture group"];
}

- (void)update
{
	activeGroupIndex = [[textureGroupPopUp selectedItem] tag];
	if (activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
    [[view documentView] update];
    [view setNeedsDisplay:YES];
}

- (void)windowDidBecomeMain:(NSNotification*)notification
{
    [[view documentView] update];
}

- (void)loadTextures:(BOOL)update
{
	// Create a dictionary of all textures
	textures = [NSDictionary dictionary];
    [self loadTexturesFromPath:[[gMainBundle resourcePath] stringByAppendingPathComponent:@"/textures"]];
    [self loadTexturesFromPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Seashore/textures"]];
    [self createGroups];
	
	// Update utility if requested
	if (update) [self update];
}

- (void)loadTexturesFromPath:(NSString*)path
{
    NSArray *files;
    BOOL isDirectory;
    id texture;
    int i;
    
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
                               
    // Create a dictionary of all textures
    files = [gFileManager subpathsAtPath:path];
    for (i = 0; i < [files count]; i++) {
        NSString *filepath =[path stringByAppendingPathComponent:files[i]];
        
        [gFileManager fileExistsAtPath:filepath isDirectory:&isDirectory];
        if(isDirectory || ![[filepath pathExtension] isEqualToString:@"png"]){
            continue;
        }

        texture = [[SeaTexture alloc] initWithContentsOfFile:filepath];
        if (texture) {
            [temp setValue:texture forKey:filepath];
        }
    }
    
    [temp setValuesForKeysWithDictionary:textures];
    
    textures = [NSDictionary dictionaryWithDictionary:temp];
    
}

- (void)createGroups
{
    // Create the all group
    NSArray *array = [[textures allValues] sortedArrayUsingSelector:@selector(compare:)];
    groups = [NSArray arrayWithObject:array];
    groupNames = [NSArray arrayWithObject:LOCALSTR(@"all group", @"All")];
    
    NSMutableSet *dirs = [[NSMutableSet alloc] init];
    
    for(NSString *filepath in [textures allKeys]){
        NSArray<NSString *> *comps = [filepath pathComponents];
        // directory is parent component of filename
        NSString *dir = [comps objectAtIndex:([comps count] - 2)];
        [dirs addObject:dir];
    }
    
    NSArray* sorted = [dirs allObjects];
    sorted = [sorted sortedArrayUsingSelector:@selector(compare:)];
    
    for(NSString* dirname in sorted){
        NSArray *groupTextures = [[NSArray alloc] init];
        for(NSString *filepath in [textures allKeys]){
            NSArray<NSString *> *comps = [filepath pathComponents];
            // directory is parent component of filename
            NSString *dir = [comps objectAtIndex:([comps count] - 2)];
            if([dirname isEqualToString:dir]){
                groupTextures = [groupTextures arrayByAddingObject:[textures valueForKey:filepath]];
            }
        }
        if([groupTextures count]>0){
            groupTextures = [groupTextures sortedArrayUsingSelector:@selector(compare:)];
            groups = [groups arrayByAddingObject:groupTextures];
            groupNames = [groupNames arrayByAddingObject:dirname];
        }
    }

}


- (void)addTextureFromPath:(NSString *)path
{
	int i;
    
    SeaTexture *texture = [[SeaTexture alloc] initWithContentsOfFile:path];
    if(!texture){
        return;
    }
    
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithDictionary:textures];
    [copy setValue:texture forKey:path];
    
    textures = [NSDictionary dictionaryWithDictionary:copy];
    
    [self createGroups];

	// Configure the pop-up menu
	[textureGroupPopUp removeAllItems];
	[textureGroupPopUp addItemWithTitle:[groupNames objectAtIndex:0]];
	[[textureGroupPopUp itemAtIndex:0] setTag:0];
	[[textureGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = 1; i < [groupNames count]; i++) {
		[textureGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
		[[textureGroupPopUp itemAtIndex:[[textureGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[textureGroupPopUp selectItemAtIndex:[textureGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
	[self setActiveTextureIndex:-1];
}

- (IBAction)changeGroup:(id)sender
{
	[self update];
}

- (IBAction)changeOpacity:(id)sender
{
	[opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider intValue]]];
	opacity = (int)([opacitySlider intValue] * 2.55 +.5);
}

- (int)opacity
{
	return opacity;
}

- (float)opacity_float
{
    return opacity/255.0;
}
- (void)setOpacity:(int)value
{
    if(value<0 || value>255)
        return;
    [opacitySlider setIntValue:(int)((value/255.0)*100 +0.5)];
    [self changeOpacity:opacitySlider];
}

- (id)activeTexture
{
    return selected;
}

- (int)activeTextureIndex
{
    return [[groups objectAtIndex:activeGroupIndex] indexOfObject:selected];
}

- (void)setActiveGroupIndex:(int)index
{
    activeGroupIndex = index;
    [textureGroupPopUp selectItemAtIndex:[textureGroupPopUp indexOfItemWithTag:activeGroupIndex]];
}

- (void)setActiveTexture:(SeaTexture*)texture
{
    if(texture==NULL){
        [self setActiveTextureIndex:-1];
    } else {
        for(int group=1;group<[groups count];group++){ // don't check all group
            NSArray *textures = [groups objectAtIndex:group];
            for(int index=0;index<[textures count];index++){
                if([textures objectAtIndex:index]==texture){
                    [self setActiveGroupIndex:group];
                    [self setActiveTextureIndex:index];
                    return;
                }
            }
        }
    }
}

- (void)setActiveTextureIndex:(int)index
{
    selected = NULL;
    NSArray *textures = [groups objectAtIndex:activeGroupIndex];
    if (index>=0 && index<[textures count]) {
        selected = [textures objectAtIndex:index];
        [textureNameLabel setStringValue:[selected name]];
        [opacitySlider setEnabled:YES];
    } else {
        [textureNameLabel setStringValue:@""];
        [opacitySlider setEnabled:NO];
    }
    [view setNeedsDisplay:YES];
    [[view documentView] update];
    [colorSelectView setNeedsDisplay:YES];
    [[document docView] setNeedsDisplay:YES];
}

- (NSArray *)textures
{
	return [groups objectAtIndex:activeGroupIndex];
}

- (NSArray *)groupNames
{
	return [groupNames subarrayWithRange:NSMakeRange(1, [groupNames count] - 1)];
}

@end

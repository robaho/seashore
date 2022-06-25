#import "BrushUtility.h"
#import "BrushView.h"
#import "SeaBrush.h"
#import "SeaController.h"
#import "InfoPanel.h"

#ifdef TODO
#warning make brushes shared across all open documents
#endif

@implementation BrushUtility

- (id)init
{		
	[self loadBrushes];
	
	if ([gUserDefaults objectForKey:@"active brush group"] == NULL)
		activeGroupIndex = 0;
	else
		activeGroupIndex = [gUserDefaults integerForKey:@"active brush group"];
	if (activeGroupIndex < 0 || activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
		

	return self;
}

- (void)awakeFromNib
{
	int i;

	[super awakeFromNib];
	
	// Configure the view
	[view setHasVerticalScroller:YES];
	[view setDocumentView:[[BrushView alloc] initWithMaster:self]];
	[view setLineScroll:kBrushPreviewSize];
	
	// Configure the pop-up menu
	[brushGroupPopUp removeAllItems];
	[brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:0]];
	[[brushGroupPopUp itemAtIndex:0] setTag:0];
	if (customGroups != 0) {
		[[brushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
		for (i = 1; i < customGroups + 1; i++) {
			[brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
			[[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
		}
	}
	[[brushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = customGroups + 1; i < [groupNames count]; i++) {
		[brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
		[[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[brushGroupPopUp selectItemAtIndex:[brushGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
    // Determine the currently active brush
    if ([gUserDefaults objectForKey:@"active brush"] == NULL)
        selected = NULL;
    else
        [self setActiveBrushIndex:[gUserDefaults integerForKey:@"active brush"]];

	// Set the window's properties
	[(InfoPanel *)window setPanelStyle:kVerticalPanelStyle];
    [window setDelegate:self];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[self activeBrushIndex] forKey:@"active brush"];
	[gUserDefaults setInteger:activeGroupIndex forKey:@"active brush group"];
}

- (void)update
{
	activeGroupIndex = [[brushGroupPopUp selectedItem] tag];
	if (activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
	[[view documentView] update];
	[view setNeedsDisplay:YES];
}

- (void)windowDidBecomeMain:(NSNotification*)notification
{
    [[view documentView] update];
}

- (void)loadBrushes
{
    brushes = [NSDictionary dictionary];
    [self loadBrushesFromPath:[[gMainBundle resourcePath] stringByAppendingPathComponent:@"/brushes"]];
    [self loadBrushesFromPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Seashore/brushes"]];
    [self createGroups];
}

- (void)loadBrushesFromPath:(NSString*)path
{
    NSArray *files;
    BOOL isDirectory;
    id brush;
    int i;
    
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
    
    // Create a dictionary of all textures
    files = [gFileManager subpathsAtPath:path];
    for (i = 0; i < [files count]; i++) {
        NSString *filepath =[path stringByAppendingPathComponent:files[i]];
        
        [gFileManager fileExistsAtPath:filepath isDirectory:&isDirectory];
        if(isDirectory){
            continue;
        }
        if (![[filepath pathExtension] isEqualToString:@"gbr"]) {
            continue;
        }
        
        brush = [[SeaBrush alloc] initWithContentsOfFile:filepath];
        if (brush) {
            [temp setValue:brush forKey:filepath];
        }
    }
    
    [temp setValuesForKeysWithDictionary:brushes];
    
    brushes = [NSDictionary dictionaryWithDictionary:temp];
}
- (void)createGroups
{
    // Create the all group
    NSArray *array = [[brushes allValues] sortedArrayUsingSelector:@selector(compare:)];
    groups = [NSArray arrayWithObject:array];
    groupNames = [NSArray arrayWithObject:LOCALSTR(@"all group", @"All")];
    
    NSMutableSet *dirs = [[NSMutableSet alloc] init];
    
    for(NSString *filepath in [brushes allKeys]){
        NSArray<NSString *> *comps = [filepath pathComponents];
        // directory is parent component of filename
        NSString *dir = [comps objectAtIndex:([comps count] - 2)];
        [dirs addObject:dir];
    }
    
    NSArray* sorted = [dirs allObjects];
    sorted = [sorted sortedArrayUsingSelector:@selector(compare:)];
    
    for(NSString* dirname in sorted){
        NSArray *groupBrushes = [[NSArray alloc] init];
        for(NSString *filepath in [brushes allKeys]){
            NSArray<NSString *> *comps = [filepath pathComponents];
            // directory is parent component of filename
            NSString *dir = [comps objectAtIndex:([comps count] - 2)];
            if([dirname isEqualToString:dir]){
                groupBrushes = [groupBrushes arrayByAddingObject:[brushes valueForKey:filepath]];
            }
        }
        if([groupBrushes count]>0){
            groupBrushes = [groupBrushes sortedArrayUsingSelector:@selector(compare:)];
            groups = [groups arrayByAddingObject:groupBrushes];
            groupNames = [groupNames arrayByAddingObject:dirname];
        }
    }
}

- (void)addBrushFromPath:(NSString *)path
{
    int i;
    
    SeaBrush *brush = [[SeaBrush alloc] initWithContentsOfFile:path];
    if(!brush){
        return;
    }
    
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithDictionary:brushes];
    [copy setValue:brush forKey:path];
    
    brushes = [NSDictionary dictionaryWithDictionary:copy];
    
    [self createGroups];
    
    // Configure the pop-up menu
    [brushGroupPopUp removeAllItems];
    [brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:0]];
    [[brushGroupPopUp itemAtIndex:0] setTag:0];
    [[brushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
    for (i = 1; i < [groupNames count]; i++) {
        [brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
        [[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
    }
    [brushGroupPopUp selectItemAtIndex:[brushGroupPopUp indexOfItemWithTag:activeGroupIndex]];
    
    // Update utility
    [self setActiveBrushIndex:-1];
}

- (IBAction)changeSpacing:(id)sender
{
	[spacingLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"spacing", @"Spacing: %d%%"), [self spacing]]];
}

- (IBAction)changeGroup:(id)sender
{
	[self update];
}

- (int)spacing
{
    int val = [spacingSlider intValue] / 5 * 5;
    return val == 0 ? 1 : val;
}

- (void)setSpacing:(int)spacing
{
    [spacingSlider setIntValue:spacing];
    [self changeSpacing:spacingSlider];
}

- (id)activeBrush
{
    return selected;
}

- (int)activeBrushIndex
{
    return [[groups objectAtIndex:activeGroupIndex] indexOfObject:selected];
}

- (int)activeGroupIndex
{
    return activeGroupIndex;
}

- (void)setActiveGroupIndex:(int)index
{
    activeGroupIndex = index;
    [brushGroupPopUp selectItemAtIndex:[brushGroupPopUp indexOfItemWithTag:activeGroupIndex]];
}

- (void)setActiveBrushIndex:(int)index
{
    selected = NULL;
    NSArray *brushes = [groups objectAtIndex:activeGroupIndex];
    if (index>=0 && index<[brushes count]) {
        selected = [brushes objectAtIndex:index];
        [brushNameLabel setStringValue:[selected name]];
        [self setSpacing:[selected spacing]];
    } else {
        [brushNameLabel setStringValue:@""];
        [self setSpacing:0];
    }
    [view setNeedsDisplay:YES];
    [[view documentView] update];
}

- (void)setActiveBrush:(SeaBrush *)brush
{
    for(int group=1;group<[groups count];group++) { // don't search in all {
        NSArray *brushes = [groups objectAtIndex:group];
        for(int index=0;index<[brushes count];index++){
            SeaBrush *sb = [brushes objectAtIndex:index];
            if(sb==brush){
                [self setActiveGroupIndex:group];
                [self setActiveBrushIndex:index];
                [[view documentView] update];
                [view setNeedsDisplay:YES];
                return;
            }
        }
    }
}

- (NSArray *)brushes
{
	return [groups objectAtIndex:activeGroupIndex];
}

- (NSArray *)groupNames
{
    return [groupNames subarrayWithRange:NSMakeRange(1, [groupNames count] - 1)];
}

@end

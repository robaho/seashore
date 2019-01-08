#import "SeaPlugins.h"
#import "PluginClass.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "SeaController.h"
#import "SeaTools.h"
#import "EffectTool.h"
#import "ToolboxUtility.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"

@implementation SeaPlugins

NSInteger plugin_sort(PluginClass *obj1,PluginClass *obj2, void *context)
{
    int result;
    
    result = [[obj1 groupName] caseInsensitiveCompare:[obj2 groupName]];
    if (result == NSOrderedSame) {
        result = [[obj1 name] caseInsensitiveCompare:[obj2 name]];
    }
    
    return result;
}

BOOL checkRun(NSString *path, NSString *file)
{
    NSDictionary *infoDict;
    BOOL canRun;
    id value;
    
    // Get dictionary
    canRun = YES;
    infoDict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/Contents/Info.plist", path, file]];
    
    // Check special
    value = [infoDict objectForKey:@"SpecialPlugin"];
    if (value != NULL) {
        if ([value isEqualToString:@"YES"] || [value isEqualToString:@"yes"] || [value isEqualToString:@"1"]) {
            canRun = NO;
        }
    }
    
    // Check system version
    value = [infoDict objectForKey:@"MinSystemVersion"];
    if (value != NULL) {
        switch ((int)floor(NSAppKitVersionNumber)) {
            case NSAppKitVersionNumber10_3:
                canRun = canRun && [value floatValue] <= 10.3;
            break;
            case NSAppKitVersionNumber10_4:
                canRun = canRun && [value floatValue] <= 10.4;
            break;
        }
    }
    
    if(!canRun){
        NSLog(@"Unable to load/run plugin %@ %@",path,file);
    }
    
    return canRun;
}

- (id)init
{
    NSString *pluginsPath;
    NSArray *librarySearchPaths;
    
    // Set the last effect to nothing
    lastEffect = -1;
    
    // Add standard plug-ins
    plugins = [NSArray array];
    pluginsPath = [gMainBundle builtInPlugInsPath];
    
    [self loadPlugins:pluginsPath];
    
    librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
    
    NSString *searchPath;
    
    for(searchPath in librarySearchPaths)
    {
        [self loadPlugins:[searchPath stringByAppendingPathComponent:@"Application Support/Seashore/PlugIns"]];
    }
    
    // Sort and retain plug-ins
    plugins = [plugins sortedArrayUsingFunction:plugin_sort context:NULL];

    return self;
}

- (void)loadPlugins:(NSString*)pluginsPath
{
    NSArray *pre_files;
    NSMutableArray *files;
    NSBundle *bundle;
    id plugin;
    int i, j, found_id;
    BOOL found, can_run;
    NSRange range, next_range;
    NSString *files_name, *pre_files_name;
    
    NSLog(@"Loading plugins from %@",pluginsPath);
    NSError *error;

    pre_files = [gFileManager contentsOfDirectoryAtPath:pluginsPath error:&error];
    if(error!=nil && error.code!=260){
        NSLog(@"unable to read directory %@",error);
    }
    files = [NSMutableArray arrayWithCapacity:[pre_files count]];
    for (i = 0; i < [pre_files count]; i++) {
        pre_files_name = [pre_files objectAtIndex:i];
        if ([pre_files_name hasSuffix:@".bundle"] && ![pre_files_name hasSuffix:@"+.bundle"]) {
            NSLog(@"checking plugin %@",pre_files_name);
            can_run = checkRun(pluginsPath, pre_files_name);
            if (can_run) [files addObject:pre_files_name];
        }
    }
    
    // Add plus plug-ins
    for (i = 0; i < [pre_files count]; i++) {
        pre_files_name = [pre_files objectAtIndex:i];
        if ([pre_files_name hasSuffix:@"+.bundle"]) {
            NSLog(@"checking plugin %@",pre_files_name);
            found = NO;
            range.location = 0;
            range.length = [pre_files_name length] - (sizeof("+.bundle") - 1);
            found_id = -1;
            for (j = 0; j < [files count] && !found; j++) {
                files_name = [files objectAtIndex:j];
                next_range.location = 0;
                next_range.length = [files_name length] - (sizeof(".bundle") - 1);
                if ([[files_name substringWithRange:next_range] isEqualToString:[pre_files_name substringWithRange:range]]) {
                    found = YES;
                    found_id = j;
                }
            }
            can_run = checkRun(pluginsPath, pre_files_name);
            if (can_run) {
                if (found) [files replaceObjectAtIndex:found_id withObject:pre_files_name];
                else [files addObject:pre_files_name];
            }
        }
    }
    
    // Check added plug-ins
    for (i = 0; i < [files count]; i++) {
        bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/%@", pluginsPath, [files objectAtIndex:i]]];
        if (bundle && [bundle principalClass]) {
            plugin = [[bundle principalClass] alloc];
            if (plugin) {
                if ([plugin respondsToSelector:@selector(initWithManager:)]) {
                    plugin = [plugin initWithManager:self];
                    // TODO check for system plugins only
                    //                    if ([plugin respondsToSelector:@selector(sanity)] && [[plugin sanity] isEqualToString:@"Seashore Approved (Bobo)"]) {
                    //                    }
                    if(plugin){
                        plugins = [plugins arrayByAddingObject:plugin];
                    }
                }
            } else {
                NSLog(@"unable to instantiate plugin class %@",[bundle principalClass]);
            }
        } else {
            NSLog(@"unable to open bundle %@",bundle);
        }
    }

}

- (void)awakeFromNib
{
    id menuItem, submenuItem;
    NSMenu *submenu;
    id plugin;
    int i;
    
    // Set up
    pointPlugins = [NSArray array];
    pointPluginsNames = [NSArray array];
        
    // Configure all plug-ins
    for (i = 0; i < [plugins count] && i < 7500; i++) {
        plugin = [plugins objectAtIndex:i];
        
        // If the plug-in is a basic plug-in add it to the effects menu
        if ([(PluginClass *)plugin type] == kBasicPlugin) {
            
            // Add or find group submenu
            submenuItem = [effectMenu itemWithTitle:[plugin groupName]];
            if (submenuItem == NULL) {
                submenuItem = [[NSMenuItem alloc] initWithTitle:[plugin groupName] action:NULL keyEquivalent:@""];
                [effectMenu insertItem:submenuItem atIndex:[effectMenu numberOfItems] - 2];
                submenu = [[NSMenu alloc] initWithTitle:[submenuItem title]];
                [submenuItem setSubmenu:submenu];
            }
            else {
                submenu = [submenuItem submenu];
            }
            
            // Add plug-in to group
            menuItem = [submenu itemWithTitle:[plugin name]];
            if (menuItem == NULL) {
                menuItem = [[NSMenuItem alloc] initWithTitle:[plugin name] action:@selector(run:) keyEquivalent:@""];
                [menuItem setTarget:self];
                [submenu addItem:menuItem];
                [menuItem setTag:i + 10000];
            }
            
        }
        else if ([(PluginClass *)plugin type] == kPointPlugin) {
            pointPluginsNames = [pointPluginsNames arrayByAddingObject:[NSString stringWithFormat:@"%@ / %@", [plugin groupName], [plugin name]]];
            pointPlugins = [pointPlugins arrayByAddingObject:plugin];
        }
        
    }
    
    // Finish off
    
    // Correct effect tool
    [(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:gCurrentDocument] setEffectEnabled:([pointPluginsNames count] != 0)];

    // Register to recieve the terminate message when Seashore quits
    [controller registerForTermination:self];
}

- (void)terminate
{
    EffectOptions *options = (EffectOptions*)[[[SeaController utilitiesManager] optionsUtilityFor:gCurrentDocument] getOptions:kEffectTool];
    [gUserDefaults setInteger:[options selectedRow] forKey:@"effectIndex"];
}

- (id)data
{
    return [gCurrentDocument pluginData];
}

- (IBAction)run:(id)sender
{
    [(PluginClass *)[plugins objectAtIndex:[sender tag] - 10000] run];
    lastEffect = [sender tag] - 10000;
}

- (IBAction)reapplyEffect:(id)sender
{
    [[plugins objectAtIndex:lastEffect] reapply];
}

- (void)cancelReapply
{
    lastEffect = -1;
}

- (BOOL)hasLastEffect
{
    return lastEffect != -1 && [[plugins objectAtIndex:lastEffect] canReapply];
}

- (NSArray *)pointPluginsNames
{
    return pointPluginsNames;
}

- (NSArray *)pointPlugins
{
    return pointPlugins;
}

- (id)activePointEffect
{
    EffectOptions *options = (EffectOptions*)[[[SeaController utilitiesManager] optionsUtilityFor:gCurrentDocument] getOptions: kEffectTool];
    return [pointPlugins objectAtIndex:[options selectedRow] ];
}

- (BOOL)validateMenuItem:(id)menuItem
{
    id document = gCurrentDocument;
    
    // Never when there is no document
    if (document == NULL)
        return NO;
    
    // End the line drawing
    [[document helpers] endLineDrawing];
    
    // Never when the document is locked
    if ([document locked])
        return NO;
    
    // Never if we are told not to
    if ([menuItem tag] >= 10000 && [menuItem tag] < 17500) {
        if (![[plugins objectAtIndex:[menuItem tag] - 10000] validateMenuItem:menuItem])
            return NO;
    }

    return YES;
}

@end

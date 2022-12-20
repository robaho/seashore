#import "SeaPlugins.h"
#import <Plugins/PluginClass.h>
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "SeaController.h"
#import "SeaTools.h"
#import "EffectTool.h"
#import "ToolboxUtility.h"
#import "OptionsUtility.h"

@implementation SeaPlugins

NSInteger plugin_sort(id<PluginClass> obj1,id<PluginClass> obj2, void *context)
{
    int result;
    
    result = [[obj1 groupName] caseInsensitiveCompare:[obj2 groupName]];
    if (result == NSOrderedSame) {
        result = [[obj1 name] caseInsensitiveCompare:[obj2 name]];
    }
    
    return result;
}

- (id)init
{
    NSString *pluginsPath;
    
    // Add standard plug-ins
    plugins = [NSArray array];
    pluginsPath = [gMainBundle builtInPlugInsPath];

    disabled = [NSMutableSet set];
    
    [self loadPlugins:pluginsPath];
    [self loadPlugins:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Seashore/PlugIns"]];

    // Sort and retain plug-ins
    plugins = [plugins sortedArrayUsingFunction:plugin_sort context:NULL];

    return self;
}

- (void)loadPlugins:(NSString*)pluginsPath
{
    NSLog(@"Loading plugins from %@",pluginsPath);
    NSError *error;

    NSArray *files = [gFileManager contentsOfDirectoryAtPath:pluginsPath error:&error];
    if(error!=nil && error.code!=260){
        NSLog(@"unable to read directory %@",error);
    }

    // Check added plug-ins
    for (NSString *filename in files) {
        NSString *path = [NSString stringWithFormat:@"%@/%@", pluginsPath, filename];
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        if (bundle && [bundle principalClass]) {
            Class klass = [bundle principalClass];
            if(![klass conformsToProtocol:@protocol(PluginClass)]) {
                NSLog(@"%@ does not implement PluginClass, ignoring.",path);
                continue;
            }
            id plugin = [klass alloc];
            if (plugin) {
                plugins = [plugins arrayByAddingObject:plugin];
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
    id<PluginClass> plugin;
    int i;

    NSMenu *menu = effectMenu;

    // Configure all plug-ins
    for (i = 0; i < [plugins count] && i < 7500; i++) {
        plugin = [plugins objectAtIndex:i];
        
            // Add or find group submenu
        submenuItem = [menu itemWithTitle:[plugin groupName]];
        if (submenuItem == NULL) {
            submenuItem = [[NSMenuItem alloc] initWithTitle:[plugin groupName] action:NULL keyEquivalent:@""];
            [menu insertItem:submenuItem atIndex:[menu numberOfItems] - 2];
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
    
    // Correct effect tool
    [[gCurrentDocument toolboxUtility] setEffectEnabled:([plugins count] != 0)];

    // Register to recieve the terminate message when Seashore quits
    [controller registerForTermination:self];
}

- (NSMenu*)menu
{
    return effectMenu;
}

- (void)terminate
{
    EffectOptions *options = (EffectOptions*)[[gCurrentDocument optionsUtility] getOptions:kEffectTool];
    [gUserDefaults setObject:[[[options currentPlugin] class] className] forKey:@"effectClass"];
}

- (id)data
{
    return [gCurrentDocument pluginData];
}

- (IBAction)run:(id)sender
{
    int index = (int)([sender tag] - 10000);
    id<PluginClass> base = [plugins objectAtIndex:index];
    id<PluginClass> plugin;
    if (gCurrentDocument.lastPlugin && object_getClass(gCurrentDocument.lastPlugin) == object_getClass(base)){
        plugin = gCurrentDocument.lastPlugin;
    } else {
        plugin = [object_getClass(base) alloc];
    }
    
    if (plugin) {
        [[gCurrentDocument toolboxUtility] changeToolTo:kEffectTool];
        EffectTool *tool = [[gCurrentDocument tools] getTool:kEffectTool];
        [tool selectEffect:plugin];
        gCurrentDocument.lastPlugin = plugin;
    }
}

- (IBAction)reapplyEffect:(id)sender
{
    EffectTool *tool = [[gCurrentDocument tools] getTool:kEffectTool];
    [tool reapply:sender];
}

- (BOOL)hasLastEffect
{
    EffectTool *tool = [[gCurrentDocument tools] getTool:kEffectTool];
    return [tool hasLastEffect];
}

- (BOOL)validateMenuItem:(id)menuItem
{
    id document = gCurrentDocument;
    
    // Never when there is no document
    if (document == NULL)
        return NO;
    
    // Never if we are told not to
    if ([menuItem tag] >= 10000 && [menuItem tag] < 17500) {
        int index = [menuItem tag]-10000;

        if([disabled containsObject:[NSNumber numberWithInt:index]]) {
            return NO;
        }
        if (![[[plugins objectAtIndex:index] class] validatePlugin:[document pluginData]])
            return NO;
    }

    return YES;
}

- (void)disablePlugin:(id<PluginClass>)plugin
{
    Class klass = [plugin class];
    for(int i=0;i<[plugins count];i++) {
        if([klass isEqualTo:[[plugins objectAtIndex:i] class]]) {
            [disabled addObject:[NSNumber numberWithInt:i]];
        }
    }
}

@end

#import "SeaFileChooser.h"

@implementation SeaFileChooser

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    button = [[NSButton alloc] init];
    button.title = @"Choose";
    button.target = self;
    button.action = @selector(buttonPressed:);
    button.cell.controlSize = NSControlSizeMini;
    button.font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]];
    button.bezelStyle = NSRoundedBezelStyle;
    [button setButtonType:NSMomentaryPushInButton];
    label = [Label label];

    [self addSubview:button];
    [self addSubview:label];

    return self;
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(100,20);
}

-(void)buttonPressed:(id)sender
{
    NSOpenPanel *openPanel;

    openPanel = [NSOpenPanel openPanel];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    [openPanel setAllowsMultipleSelection:FALSE];

    int retval = [openPanel runModalForDirectory:directory file:NULL types:fileTypes];
    if (retval == NSOKButton) {
        path = [openPanel filename];
        [self updateLabel];
        [listener componentChanged:self];
    }
}

- (void)updateLabel
{
    if(!path) {
        [label setStringValue:[NSString stringWithFormat:title,@"Default"]];
    } else {
        [label setStringValue:[NSString stringWithFormat:title,[[path lastPathComponent] stringByDeletingPathExtension]]];
    }
}

- (NSString*)path
{
    return path;
}

- (void)layout
{
    NSRect bounds = self.bounds;
    [label setFrame:NSMakeRect(0,0,bounds.size.width-50,bounds.size.height)];
    [button setFrame:NSMakeRect(bounds.size.width-50,0,50,bounds.size.height)];
}

+ (SeaFileChooser*)chooserWithTitle:(NSString*)title types:(NSArray*)fileTypes directory:(NSString*)directory  Listener:(id<Listener>)listener
{
    SeaFileChooser *chooser = [[SeaFileChooser alloc] init];
    chooser->title = title;
    chooser->fileTypes = fileTypes;
    chooser->directory = directory;
    chooser->listener = listener;
    [chooser updateLabel];
    return chooser;
}

@end

#import "SeaFileChooser.h"

@implementation SeaFileChooser

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    button = [SeaButton compactButton:@"Choose" withLabel:@"" target:self action:@selector(buttonPressed:)];

    [self addSubview:button];

    return self;
}

- (NSSize)intrinsicContentSize
{
    return [button intrinsicContentSize];
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
        [button setLabel:[NSString stringWithFormat:title,@"Default"]];
    } else {
        [button setLabel:[NSString stringWithFormat:title,[[path lastPathComponent] stringByDeletingPathExtension]]];
    }
}

- (NSString*)path
{
    return path;
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self layout];
}

- (void)layout
{
    NSRect bounds = self.bounds;
    [button setFrame:NSMakeRect(0,0,bounds.size.width,bounds.size.height)];
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

#import "SeaPopup.h"

@implementation SeaPopup

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    popup = [[NSPopUpButton alloc] init];
    title = [[Label alloc] init];

    checkbox = [[NSButton alloc] init];
    [checkbox setButtonType:NSButtonTypeSwitch];
    [checkbox setHidden:TRUE];
    [checkbox setTarget:self];
    [checkbox setAction:@selector(checkboxChanged:)];

    [popup setTarget:self];
    [popup setAction:@selector(popupChanged:)];

    [self addSubview:popup];
    [self addSubview:title];
    [self addSubview:checkbox];

    return self;
}

- (void)layout
{
    NSRect bounds = self.bounds;

    if(compact) {
        int w = bounds.size.width;
        int h = bounds.size.height;

        [title setFrame:NSMakeRect(0,0,w*.50,h)];
        [popup setFrame:NSMakeRect(w*.50,0,w*.50,h)];

        if(checkable) {
            [checkbox setFrame:NSMakeRect(0,0,w*.50,h)];
        } else {
            [title setFrame:NSMakeRect(0,0,w*.50,h)];
        }
    } else {
        float half = bounds.size.height / 2;
        [title setFrame:NSMakeRect(0,0,bounds.size.width,half)];
        [popup setFrame:NSMakeRect(0,half,bounds.size.width,half)];
    }
}

- (bool)isChecked {
    return [checkbox state] == NSControlStateValueOn;
}

- (void)setChecked:(bool)state {
    if(state) {
        [checkbox setState:NSControlStateValueOn];
        [popup setEnabled:TRUE];
    } else {
        [checkbox setState:NSControlStateValueOff];
        [popup setEnabled:FALSE];
    }
    [self setNeedsDisplay:TRUE];
}

- (NSSize)intrinsicContentSize
{
    if(checkable) {
        return NSMakeSize(100,MAX(checkbox.intrinsicContentSize.height,popup.intrinsicContentSize.height));
    } else {
        return NSMakeSize(100,MAX(title.intrinsicContentSize.height,popup.intrinsicContentSize.height));
    }
}

- (void)checkboxChanged:(id)sender
{
    [popup setEnabled:[self isChecked]];
    if(listener) [listener componentChanged:self];
}

- (void)popupChanged:(id)sender
{
    if(listener) [listener componentChanged:self];
}

- (NSMenuItem*)itemAtIndex:(NSInteger)index
{
    return [popup itemAtIndex:index];
}

- (void)selectItemAtIndex:(NSInteger)index
{
    [popup selectItemAtIndex:index];
}

- (NSInteger)indexOfSelectedItem {
    return [popup indexOfSelectedItem];
}
- (NSMenuItem*)selectedItem {
    return [popup selectedItem];
}
- (NSInteger)indexOfItemWithTag:(NSInteger)tag {
    return [popup indexOfItemWithTag:tag];
}

+ (SeaPopup*)popupWithTitle:(NSString*)title Menu:(NSMenu*)menu Listener:(nullable id<Listener>)listener
{
    SeaPopup *popup = [[SeaPopup alloc] init];
    [popup->title setStringValue:title];
    [popup->popup setMenu:menu];
    popup->listener = listener;
    return popup;
}

+ (SeaPopup*)popupWithCheck:(NSString*)title Menu:(NSMenu*)menu Listener:(nullable id<Listener>)listener
{
    SeaPopup *popup = [SeaPopup compactWithTitle:title Menu:menu Listener:listener];
    popup->checkable=true;
    [popup->checkbox setHidden:FALSE];
    [popup->title setHidden:TRUE];
    [popup->popup setEnabled:false];

    return popup;
}

+ (SeaPopup*)compactWithTitle:(NSString*)title Menu:(NSMenu*)menu Listener:(nullable id<Listener>)listener
{
    SeaPopup *popup = [[SeaPopup alloc] init];
    [popup->popup setMenu:menu];
    popup->compact = true;
    [popup->title setControlSize:NSControlSizeMini];
    [popup->title setTitle:title];
    [popup->title setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]]];
    [popup->popup setControlSize:NSControlSizeMini];
    [popup->popup setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]]];
    [popup->checkbox setControlSize:NSControlSizeMini];
    [popup->checkbox setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]]];
    [popup->checkbox setTitle:title];
    popup->listener = listener;
    return popup;
}


@end

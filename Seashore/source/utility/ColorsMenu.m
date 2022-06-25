#import "ColorsMenu.h"

@implementation ColorsMenu

- (void)awakeFromNib
{
    [self addItem:[[NSMenuItem alloc] initWithTitle:@"Cyan" action:NULL keyEquivalent:@""]];
    [self addItem:[[NSMenuItem alloc] initWithTitle:@"Magenta" action:NULL keyEquivalent:@""]];
    [self addItem:[[NSMenuItem alloc] initWithTitle:@"Yellow" action:NULL keyEquivalent:@""]];
    [self addItem:[[NSMenuItem alloc] initWithTitle:@"Black" action:NULL keyEquivalent:@""]];
    [self addItem:[[NSMenuItem alloc] initWithTitle:@"Gray" action:NULL keyEquivalent:@""]];
    [self addItem:[[NSMenuItem alloc] initWithTitle:@"White" action:NULL keyEquivalent:@""]];
}

@end

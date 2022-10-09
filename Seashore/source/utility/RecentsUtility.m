#import "SeaController.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaHelpers.h"
#import "Units.h"
#import "ToolboxUtility.h"
#import "SeaView.h"
#import "SeaWindowContent.h"

#import "RecentsUtility.h"
#import "BrushUtility.h"
#import "SeaBrush.h"
#import "BrushOptions.h"
#import "SeaTexture.h"
#import "TextureUtility.h"
#import "SeaTools.h"
#import "OptionsUtility.h"
#import "RecentsItem.h"

@interface RememberedBase : NSObject
{
}
@end
@implementation RememberedBase
{
    @public NSColor *foreground,*background;
    @public int opacity;
    @public __weak id document;
}
-(NSColor*)foreground
{
    return foreground;
}
-(NSColor*)background
{
    return background;
}
@end

@interface RememberedBrush : RememberedBase
@end

@implementation RememberedBrush
{
    @public SeaBrush *brush;
    @public int spacing;
}

-(NSString*)memoryAsString
{
    return [brush name];
}
-(void)drawAt:(NSRect)rect
{
    return [brush drawBrushAt:rect];
}
-(void)restore
{
    BrushUtility *brushes = [document brushUtility];
    ToolboxUtility *toolbox = [document toolboxUtility];

    [brushes setActiveBrush:brush];
    [brushes setSpacing:spacing];
    [toolbox setForeground:foreground];
    [toolbox setBackground:background];
    
    [toolbox changeToolTo:kBrushTool];
}
@end

@interface RememberedPencil : RememberedBase
@end

@implementation RememberedPencil
{
@public int pencilSize;
}

-(NSString*)memoryAsString
{
    return @"pencil";
}
-(void)drawAt:(NSRect)rect
{
    NSImage *img = getTinted([NSImage imageNamed:@"pencilLargeTemplate.png"],[NSColor controlTextColor]);
//    [img setFlipped:true];
    
    NSRect imageRect = NSMakeRect(4,8,32,32);
    [img drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:true hints:NULL];

    NSString *size = [NSString stringWithFormat:@"%d",pencilSize];

    NSFont *font = [NSFont systemFontOfSize:9.0];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [NSColor controlTextColor], NSForegroundColorAttributeName, NULL];
    [size drawAtPoint:NSMakePoint(imageRect.origin.x+imageRect.size.width-8,imageRect.origin.y+imageRect.size.height-8) withAttributes:attributes];
}

-(void)restore
{
    ToolboxUtility *toolbox = [document toolboxUtility];
    OptionsUtility *options = [document optionsUtility];
    
    [toolbox setForeground:foreground];
    [toolbox setBackground:background];
    
    [toolbox changeToolTo:kPencilTool];
    PencilOptions *opts = [options getOptions:kPencilTool];
    [opts setPencilSize:pencilSize];
}
@end

@interface RememberedBucket : RememberedBase
@end

@implementation RememberedBucket
{
}

-(NSString*)memoryAsString
{
    return @"bucket";
}
-(void)drawAt:(NSRect)rect
{
    NSImage *img = getTinted([NSImage imageNamed:@"bucketTemplate.png"],[NSColor controlTextColor]);

    NSRect imageRect = NSMakeRect(4,8,32,32);
    [img drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:true hints:NULL];
}

-(void)restore
{
    ToolboxUtility *toolbox = [document toolboxUtility];

    [toolbox setForeground:foreground];
    [toolbox setBackground:background];
    
    [toolbox changeToolTo:kBucketTool];
}
@end


@implementation RecentsUtility

- (id)init
{
    memories = [[NSMutableArray alloc] init];
    return self;
}

- (void)awakeFromNib
{
    [recentsView setItemPrototype:[[RecentsItem alloc] init]];
    [recentsView setMinItemSize:NSMakeSize(kPreviewWidth,kPreviewHeight)];
    [recentsView setMaxItemSize:NSMakeSize(kPreviewWidth,kPreviewHeight)];
    [recentsView setDelegate:self];
}

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object
{
    return [[RecentsItem alloc] init];
}

- (IBAction)show:(id)sender
{
    [[[document window] contentView] setVisibility: YES forRegion: kRecentsHistogram];
    [self update];
}

- (IBAction)hide:(id)sender
{
    [[[document window] contentView] setVisibility: NO forRegion: kRecentsHistogram];
}

- (IBAction)toggle:(id)sender
{
    if([[[document window] contentView] visibilityForRegion: kRecentsHistogram]) {
        [self hide:sender];
    }else{
        [self show:sender];
    }
}

- (void)update
{
    int i;

    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (i=0; i < [self memoryCount]; i++) {
        [items addObject:[self memoryAt:i]];
    }
    [recentsView setContent:items];
    [recentsView setSelectionIndexes:[NSIndexSet new]];
}

- (void)shutdown
{
}

- (BOOL)visible
{
    return [[[document window] contentView] visibilityForRegion: kRecentsHistogram];
}

- (void)rememberBrush:(BrushOptions*)options
{
  
    BrushUtility *brushes = [document brushUtility];
    ToolboxUtility *toolbox = [document toolboxUtility];
    SeaBrush *brush = [brushes activeBrush];
    int spacing = [brushes spacing];
    int opacity = [options opacity];
    NSColor *foreground = [toolbox foreground];
    NSColor *background = [toolbox background];

    for (int i=0;i<[memories count];i++) {
        id entry = [memories objectAtIndex:i];
        if([entry class]!=[RememberedBrush class]) {
            continue;
        }
        RememberedBrush *memory = entry;
        if(memory->brush==brush && memory->spacing==spacing && memory->foreground==foreground && memory->background==background && memory->opacity==opacity) {
            if(i==0) {
                // order not changing, nothing to update
                return;
            }
            [memories removeObject:memory];
            break;
        }
    }
    
    RememberedBrush *memory = [RememberedBrush new];
    memory->document = document;
    memory->brush = brush;
    memory->spacing = spacing;
    memory->foreground = foreground;
    memory->background = background;
    memory->opacity = opacity;

    if ([memories count]==0) {
        [memories addObject:memory];
    } else {
        [memories insertObject:memory atIndex:0];
    }
    
    [self update];
}

- (void)rememberPencil:(PencilOptions*)options
{
    
    ToolboxUtility *toolbox = [document toolboxUtility];
    int pencilSize = [options pencilSize];
    int opacity = [options opacity];
    NSColor *foreground = [toolbox foreground];
    NSColor *background = [toolbox background];
    
    for (int i=0;i<[memories count];i++) {
        id entry = [memories objectAtIndex:i];
        if([entry class]!=[RememberedPencil class]) {
            continue;
        }
        RememberedPencil *memory = entry;
        if(memory->pencilSize==pencilSize && memory->foreground==foreground && memory->background==background && memory->opacity==opacity) {
            if(i==0) {
                // order not changing, nothing to update
                return;
            }
            [memories removeObject:memory];
            break;
        }
    }
    
    RememberedPencil *memory = [RememberedPencil new];
    memory->pencilSize = pencilSize;
    memory->document = document;
    memory->foreground = foreground;
    memory->background = background;
    memory->opacity = opacity;
    
    if ([memories count]==0) {
        [memories addObject:memory];
    } else {
        [memories insertObject:memory atIndex:0];
    }
    
    [self update];
}

- (void)rememberBucket:(BucketOptions*)options
{
    
    ToolboxUtility *toolbox = [document toolboxUtility];
    
    int opacity = [options opacity];
    NSColor *foreground = [toolbox foreground];
    NSColor *background = [toolbox background];
    
    for (int i=0;i<[memories count];i++) {
        id entry = [memories objectAtIndex:i];
        if([entry class]!=[RememberedBucket class]) {
            continue;
        }
        RememberedBucket *memory = entry;
        if(memory->foreground==foreground && memory->background==background && memory->opacity==opacity) {
            if(i==0) {
                // order not changing, nothing to update
                return;
            }
            [memories removeObject:memory];
            break;
        }
    }
    
    RememberedBucket *memory = [RememberedBucket new];
    memory->document = document;
    memory->foreground = foreground;
    memory->background = background;
    memory->opacity = opacity;
    
    if ([memories count]==0) {
        [memories addObject:memory];
    } else {
        [memories insertObject:memory atIndex:0];
    }
    
    [self update];
}



- (int) memoryCount
{
    return (int)[memories count];
}

- (id)memoryAt:(int)index
{
    return [memories objectAtIndex:index];
}

@end

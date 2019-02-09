//
//  RecentsUtility.m
//  Seashore
//
//  Created by robert engels on 2/4/19.
//
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaHelpers.h"
#import "Units.h"
#import "LayerControlView.h"
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

@interface RememberedBase : NSObject
{
}
@end
@implementation RememberedBase
{
    @public SeaTexture *texture;
    @public NSColor *foreground,*background;
    @public int opacity;
    @public id document;
}
-(NSColor*)foreground
{
    return foreground;
}
-(NSColor*)background
{
    return background;
}
-(SeaTexture*)texture
{
    return texture;
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
    BrushUtility *brushes = [[SeaController utilitiesManager] brushUtilityFor:document];
    ToolboxUtility *toolbox = [[SeaController utilitiesManager] toolboxUtilityFor:document];
    TextureUtility *textures =[[SeaController utilitiesManager] textureUtilityFor:document];
    
    [brushes setActiveBrush:brush];
    [brushes setSpacing:spacing];
    [toolbox setForeground:foreground];
    [toolbox setBackground:background];
    
    [textures setActiveTexture:texture];
    [textures setOpacity:opacity];
    
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
    NSImage *img = [NSImage imageNamed:@"pencilLargeTemplate.png"];
    
    NSRect imageRect = NSMakeRect(4,8,32,32);
    [img drawInRect:imageRect];
    
    NSString *size = [NSString stringWithFormat:@"%d",pencilSize];
    
    NSFont *font = [NSFont systemFontOfSize:9.0];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, NULL];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositingOperationDifference];
    [size drawAtPoint:NSMakePoint(imageRect.origin.x+imageRect.size.width-8,imageRect.origin.y+imageRect.size.height-8) withAttributes:attributes];
    [NSGraphicsContext restoreGraphicsState];

}

-(void)restore
{
    ToolboxUtility *toolbox = [[SeaController utilitiesManager] toolboxUtilityFor:document];
    TextureUtility *textures =[[SeaController utilitiesManager] textureUtilityFor:document];
    OptionsUtility *options = [[SeaController utilitiesManager] optionsUtilityFor:document];
    
    [toolbox setForeground:foreground];
    [toolbox setBackground:background];
    
    [textures setActiveTexture:texture];
    [textures setOpacity:opacity];
    
    [toolbox changeToolTo:kPencilTool];
    PencilOptions *opts = [options getOptions:kPencilTool];
    [opts setPencilSize:pencilSize];
    [options update];
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
    NSImage *img = [NSImage imageNamed:@"bucketTemplate.png"];
    
    NSRect imageRect = NSMakeRect(4,8,32,32);
    [img drawInRect:imageRect];
   
}

-(void)restore
{
    ToolboxUtility *toolbox = [[SeaController utilitiesManager] toolboxUtilityFor:document];
    TextureUtility *textures =[[SeaController utilitiesManager] textureUtilityFor:document];
    OptionsUtility *options = [[SeaController utilitiesManager] optionsUtilityFor:document];
    
    [toolbox setForeground:foreground];
    [toolbox setBackground:background];
    
    [textures setActiveTexture:texture];
    [textures setOpacity:opacity];
    
    [toolbox changeToolTo:kBucketTool];
    [options update];
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
    [[SeaController utilitiesManager] setRecentsUtility: self for:document];
}

- (IBAction)show:(id)sender
{
    [[[document window] contentView] setVisibility: YES forRegion: kRecentsBar];
    [self update];
}

- (IBAction)hide:(id)sender
{
    [[[document window] contentView] setVisibility: NO forRegion: kRecentsBar];
}

- (IBAction)toggle:(id)sender
{
    if([[[document window] contentView] visibilityForRegion: kRecentsBar]) {
        [self hide:sender];
    }else{
        [self show:sender];
    }
}
- (void)update
{
}

- (void)shutdown
{
}

- (BOOL)visible
{
    return [[[document window] contentView] visibilityForRegion: kRecentsBar];
}

- (void)rememberBrush:(BrushOptions*)options
{
  
    BrushUtility *brushes = [[SeaController utilitiesManager] brushUtilityFor:document];
    ToolboxUtility *toolbox = [[SeaController utilitiesManager] toolboxUtilityFor:document];
    TextureUtility *textures =[[SeaController utilitiesManager] textureUtilityFor:document];
    SeaBrush *brush = [brushes activeBrush];
    int spacing = [brushes spacing];
    SeaTexture *texture = [textures activeTexture];
    int opacity = [textures opacity];
    NSColor *foreground = [toolbox foreground];
    NSColor *background = [toolbox background];

    for (int i=0;i<[memories count];i++) {
        id entry = [memories objectAtIndex:i];
        if([entry class]!=[RememberedBrush class]) {
            continue;
        }
        RememberedBrush *memory = entry;
        if(memory->brush==brush && memory->spacing==spacing && memory->texture==texture && memory->foreground==foreground && memory->background==background && memory->opacity==opacity) {
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
    memory->texture = texture;
    memory->foreground = foreground;
    memory->background = background;
    memory->opacity = opacity;

    if ([memories count]==0) {
        [memories addObject:memory];
    } else {
        [memories insertObject:memory atIndex:0];
    }
    
    [view update];
}

- (void)rememberPencil:(PencilOptions*)options
{
    
    ToolboxUtility *toolbox = [[SeaController utilitiesManager] toolboxUtilityFor:document];
    TextureUtility *textures =[[SeaController utilitiesManager] textureUtilityFor:document];
    int pencilSize = [options pencilSize];
    SeaTexture *texture = [textures activeTexture];
    int opacity = [textures opacity];
    NSColor *foreground = [toolbox foreground];
    NSColor *background = [toolbox background];
    
    for (int i=0;i<[memories count];i++) {
        id entry = [memories objectAtIndex:i];
        if([entry class]!=[RememberedPencil class]) {
            continue;
        }
        RememberedPencil *memory = entry;
        if(memory->pencilSize==pencilSize && memory->texture==texture && memory->foreground==foreground && memory->background==background && memory->opacity==opacity) {
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
    memory->texture = texture;
    memory->foreground = foreground;
    memory->background = background;
    memory->opacity = opacity;
    
    if ([memories count]==0) {
        [memories addObject:memory];
    } else {
        [memories insertObject:memory atIndex:0];
    }
    
    [view update];
}

- (void)rememberBucket:(BucketOptions*)options
{
    
    ToolboxUtility *toolbox = [[SeaController utilitiesManager] toolboxUtilityFor:document];
    TextureUtility *textures =[[SeaController utilitiesManager] textureUtilityFor:document];
    
    SeaTexture *texture = [textures activeTexture];
    int opacity = [textures opacity];
    NSColor *foreground = [toolbox foreground];
    NSColor *background = [toolbox background];
    
    for (int i=0;i<[memories count];i++) {
        id entry = [memories objectAtIndex:i];
        if([entry class]!=[RememberedBucket class]) {
            continue;
        }
        RememberedBucket *memory = entry;
        if(memory->texture==texture && memory->foreground==foreground && memory->background==background && memory->opacity==opacity) {
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
    memory->texture = texture;
    memory->foreground = foreground;
    memory->background = background;
    memory->opacity = opacity;
    
    if ([memories count]==0) {
        [memories addObject:memory];
    } else {
        [memories insertObject:memory atIndex:0];
    }
    
    [view update];
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

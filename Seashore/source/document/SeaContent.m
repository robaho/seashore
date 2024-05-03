#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaView.h"
#import "SeaHelpers.h"
#import "LayersUtility.h"
#import "SeaLayerUndo.h"
#import "SeaSelection.h"
#import "SeaWhiteboard.h"
#import "CenteringClipView.h"
#import "XCFContent.h"
#import "CocoaContent.h"
#import "XBMContent.h"
#import "SVGContent.h"
#import "WEBPContent.h"
#import "CocoaImporter.h"
#import "WEBPImporter.h"
#import "XCFImporter.h"
#import "XBMImporter.h"
#import "SVGImporter.h"
#import "WEBPImporter.h"
#import "ToolboxUtility.h"
#import "CloneTool.h"
#import "PositionTool.h"
#import "SeaTools.h"
#import "StatusUtility.h"
#import "SeaDocumentController.h"
#import "SeaOperations.h"
#import "SeaAlignment.h"
#import "XCFLayer.h"
#import "XCFTextLayerSupport.h"
#import "SeaTextLayer.h"

static NSString*    FloatAnchorToolbarItemIdentifier = @"Float/Anchor Toolbar Item Identifier";
static NSString*    DuplicateSelectionToolbarItemIdentifier = @"Duplicate Selection Toolbar Item Identifier";

@implementation SeaContent

- (id)initWithDocument:(id)doc
{
    // Set the data members to reasonable values
    xres = yres = 72;
    height = width = type = 0;
    lostprops = NULL; lostprops_len = 0;
    parasites = [[ParasiteData alloc] init];
    exifData = NULL;
    layers = NULL; activeLayerIndex = 0;
    selectedChannel = kAllChannels; trueView = NO;
    document = doc;
    
    return self;
}

- (id)initFromPasteboardWithDocument:(id)doc
{
    id pboard = [NSPasteboard generalPasteboard];
    NSString *imageRepDataType;
    NSData *imageRepData;
    NSBitmapImageRep *imageRep;
    unsigned char *data;
    
    // Get the data from the pasteboard
    imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSTIFFPboardType]];
    if (imageRepDataType != NULL) {
        imageRepData = [pboard dataForType:imageRepDataType];
        imageRep = [[NSBitmapImageRep alloc] initWithData:imageRepData];
    }
    
    // Fill out as many of the properties as possible
    height = (int)[imageRep pixelsHigh];
    width = (int)[imageRep pixelsWide];
    xres = yres = 72;
    lostprops = NULL; lostprops_len = 0;
    parasites = [[ParasiteData alloc] init];
    exifData = NULL;
    selectedChannel = kAllChannels; trueView = NO;
    document = doc;
    
    // Determine the color space of the pasteboard image and the type
    if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace]) {
        type = XCF_GRAY_IMAGE;
    }
    if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace]) {
        type = XCF_GRAY_IMAGE;
    }
    if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]) {
        type = XCF_RGB_IMAGE;
    }
    if ([[imageRep colorSpaceName] isEqualToString:NSDeviceCMYKColorSpace]) {
        type = XCF_RGB_IMAGE;
    }
    
    data = convertRepToARGB(imageRep);
    if (!data) {
        NSLog(@"Required conversion not supported.");
        return NULL;
    }
    
    // Add layer
    SeaLayer *new_layer = [[SeaLayer alloc] initWithDocument:doc rect:IntMakeRect(0, 0, width, height) data:data];
    if(new_layer==NULL){
        NSLog(@"Unable to add layer.");
        return NULL;
    }

    layers = [[NSArray alloc] initWithObjects:new_layer, NULL];
    activeLayerIndex = 0;
    
    return self;
}

- (id)initWithDocument:(id)doc type:(int)dtype width:(int)dwidth height:(int)dheight res:(int)dres opaque:(BOOL)dopaque
{    
    // Call the core initializer
    if (![self initWithDocument:doc])
        return NULL;
    
    // Set the data members to appropriate values
    xres = yres = dres;
    type = dtype;
    height = dheight; width = dwidth;
    
    // Add in a single layer
    layers = [[NSArray alloc] initWithObjects:[[SeaLayer alloc] initWithDocument:doc width:dwidth height:dheight opaque:dopaque], NULL];
    
    return self;
}

- (void)dealloc
{
    if (lostprops) free(lostprops);
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
    id layer;
    int i;

    @synchronized (document.mutex) {
        // Change the width and height of the document
        width += left + right;
        height += top + bottom;

        // Change the layer offsets of the document
        for (i = 0; i < [layers count]; i++) {
            layer = [layers objectAtIndex:i];
            if (left) [layer setOffsets:IntMakePoint([layer xoff] + left, [layer yoff])];
            if (top) [layer setOffsets:IntMakePoint([layer xoff], [layer yoff] + top)];
        }
        [[document selection] adjustOffset:IntMakePoint(left, top)];
    }
}

- (int)type
{
    return type;
}

- (int)xres
{
    return xres;
}

- (int)yres
{
    return yres;
}

- (void)setResolution:(IntResolution)newRes
{
    xres = newRes.x;
    yres = newRes.y;
}

- (int)height
{
    return height;
}

- (int)width
{
    return width;
}

- (IntRect)rect{
    return IntMakeRect(0,0,width,height);
}

- (void)setWidth:(int)newWidth height:(int)newHeight
{
    width = newWidth;
    height = newHeight;
}

- (int)selectedChannel
{
    return selectedChannel;
}

- (void)setSelectedChannel:(int)value;
{
    selectedChannel = value;
}

- (char *)lostprops
{
    return lostprops;
}

- (int)lostprops_len
{
    return lostprops_len;
}


- (BOOL)trueView
{
    return trueView;
}

- (void)setTrueView:(BOOL)value
{
    trueView = value;
}

- (NSColor *)foreground
{
    id foreground;

    foreground = [[document toolboxUtility] foreground];
    if(CGColorGetPattern([foreground CGColor])!=NULL) {
        foreground = [NSColor blackColor];
    }

    if (type == XCF_RGB_IMAGE && selectedChannel != kAlphaChannel)
        return [foreground colorUsingColorSpace:MyRGBCS];
    else if (type == XCF_GRAY_IMAGE)
        return [foreground colorUsingColorSpace:MyGrayCS];
    else
        return [[foreground colorUsingColorSpace:MyGrayCS] colorUsingColorSpace:MyRGBCS];
}

- (NSColor *)background
{
    id background;
    
    background = [[document toolboxUtility] background];
    if(CGColorGetPattern([background CGColor])!=NULL) {
        background = [NSColor whiteColor];
    }

    if (type == XCF_RGB_IMAGE && selectedChannel != kAlphaChannel)
        return [background colorUsingColorSpace:MyRGBCS];
    else if (type == XCF_GRAY_IMAGE)
        return [background colorUsingColorSpace:MyGrayCS];
    else
        return [[background colorUsingColorSpace:MyGrayCS] colorUsingColorSpace:MyRGBCS];
}

- (NSDictionary *)exifData
{
    return exifData;
}

- (NSColorSpace *)fileColorSpace
{
    return fileColorSpace;
}


- (SeaLayer*)layer:(int)index
{
    return [layers objectAtIndex:index];
}

- (int)layerCount
{
    return (int)[layers count];
}

- (SeaLayer*)activeLayer
{
    return (activeLayerIndex < 0 || activeLayerIndex >= [layers count]) ? NULL : [layers objectAtIndex:activeLayerIndex];
}

- (int)activeLayerIndex
{
    return activeLayerIndex;
}

- (void)setActiveLayerIndex:(int)value
{
    if(activeLayerIndex==value)
        return;
    @synchronized (document.mutex) {
        [[document helpers] activeLayerWillChange];
        activeLayerIndex = value;
        [[document helpers] activeLayerChanged:kLayerSwitched];
    }
}

- (void)layerBelow
{
    @synchronized (document.mutex) {
        int newIndex;
        [[document helpers] activeLayerWillChange];
        if(activeLayerIndex + 1 >= [self layerCount])
        {
            newIndex = 0;
        }else {
            newIndex = activeLayerIndex + 1;
        }
        activeLayerIndex = newIndex;
        [[document helpers] activeLayerChanged:kLayerSwitched];
    }
}

- (void)layerAbove
{
    @synchronized (document.mutex) {
        int newIndex;
        [[document helpers] activeLayerWillChange];
        if(activeLayerIndex - 1 < 0)
        {
            newIndex = [self layerCount] - 1;
        }else {
            newIndex = activeLayerIndex - 1;
        }
        activeLayerIndex = newIndex;
        [[document helpers] activeLayerChanged:kLayerSwitched];
    }
}

- (BOOL)canImportLayerFromFile:(NSString *)path
{
    NSString *docType;
    BOOL success = NO;
    
    // Determine which document we have and act appropriately    
    docType = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                (__bridge CFStringRef)[path pathExtension],
                                                                (CFStringRef)@"public.data"));
    
    success = [XCFContent typeIsEditable:docType] ||
        [XBMContent typeIsEditable:docType] ||
        [CocoaContent typeIsViewable:docType forDoc: document] ||
        [SVGContent typeIsViewable:docType];
    
    return success;
}

- (BOOL)importLayerFromFile:(NSString *)path
{
    NSString *docType;
    BOOL success = NO;
    id importer;
    
    docType = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                (__bridge CFStringRef)[path pathExtension],
                                                                (CFStringRef)@"public.data"));

    if ([XCFContent typeIsEditable:docType]) {
        
        // Load GIMP or XCF layers
        importer = [[XCFImporter alloc] init];
        success = [importer addToDocument:document contentsOfFile:path];
        
    } else if ([CocoaContent typeIsViewable:docType forDoc: document]) {
        
        // Load PNG, TIFF, JPEG, GIF and other layers
        importer = [[CocoaImporter alloc] init];
        success = [importer addToDocument:document contentsOfFile:path];
    
    } else if ([XBMContent typeIsEditable:docType]) {
    
        // Load X bitmap layers
        importer = [[XBMImporter alloc] init];
        success = [importer addToDocument:document contentsOfFile:path];
        
    } else if ([SVGContent typeIsViewable:docType]) {
    
        // Load SVG layers
        importer = [[SVGImporter alloc] init];
        success = [importer addToDocument:document contentsOfFile:path];
        
    } else if ([WEBPContent typeIsEditable:docType]) {

        // Load SVG layers
        importer = [[WEBPImporter alloc] init];
        success = [importer addToDocument:document contentsOfFile:path];

    } else {
        
        // Handle an unknown document type
        NSLog(@"Unknown type passed to importLayerFromFile:<%@> docType:<%@>", path, docType);
        success = NO;
    
    }

    // Inform the user of failure
    if (!success){
        [[document warnings] addMessage:LOCALSTR(@"import failure message", @"The file was not able to be imported.") level:kHighImportance];
    }
        
    return success;
}

- (void)importPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSArray *filenames = [panel filenames];
    int i;
    
    if (returnCode == NSOKButton) {
        for (i = 0; i < [filenames count]; i++) {
            [self importLayerFromFile:[filenames objectAtIndex:i]];
        }
    }
}

- (void)importLayer
{
    // Run import dialog
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    NSArray *types = [(SeaDocumentController*)[NSDocumentController sharedDocumentController] readableTypes];
    [openPanel beginSheetForDirectory:NULL file:NULL types:types modalForWindow:[document window] modalDelegate:self didEndSelector:@selector(importPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)addLayer:(int)index
{
    NSArray *tempArray = [NSArray array];
    int i;
    
    if (index == kActiveLayer)
        index = activeLayerIndex;

    SeaLayer *layerToAdd = [[SeaLayer alloc] initWithDocument:document width:width height:height opaque:NO];

    @synchronized (document.mutex) {
        // Inform the helpers we will change the layer
        [[document helpers] activeLayerWillChange];

        // Create a new array with all the existing layers and the one being added
        for (i = 0; i < [layers count] + 1; i++) {
            if (i == index)
                tempArray = [tempArray arrayByAddingObject:layerToAdd];
            else
                tempArray = [tempArray arrayByAddingObject:(i > activeLayerIndex) ? [layers objectAtIndex:i - 1] : [layers objectAtIndex:i]];
        }

        // Now substitute in our new array
        layers = tempArray;

        // Inform document of layer change
        [[document helpers] activeLayerChanged:kLayerAdded];
    }

    // Make action undoable
    [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}

- (void)addLayerObject:(id)layer
{
    [self addLayerObject:layer atIndex:activeLayerIndex];
}

- (void)addLayerObject:(id)layer atIndex:(int)index
{
    @synchronized (document.mutex) {
        [[document helpers] activeLayerWillChange];

        NSMutableArray *temp = [NSMutableArray arrayWithArray:layers];
        [temp insertObject:layer atIndex:index];

        layers = [NSArray arrayWithArray:temp];

        activeLayerIndex = index;

        // Inform document of layer change
        [[document helpers] activeLayerChanged:kLayerAdded];

        // Make action undoable
        [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
    }
}

- (void)copyLayer:(id)layer
{
    SeaLayer *newLayer = [[SeaLayer alloc] initWithDocument:document layer:layer];

    [self addLayerObject:newLayer];
}

- (void)duplicateLayer:(int)index
{
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;

    SeaLayer *layer = [layers objectAtIndex:index];

    Class clazz = [layer class];

    SeaLayer *newLayer = [[clazz alloc] initWithDocument:document layer:[layers objectAtIndex:index]];
    [self addLayerObject:newLayer];
}

- (void)deleteLayer:(int)index
{
    SeaLayer *layer;
    NSArray *tempArray = [NSArray array];
    int i;
    
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;
    layer = [layers objectAtIndex:index];

    @synchronized (document.mutex) {
        // Inform the helpers we will change the layer
        [[document helpers] activeLayerWillChange];

        // Create a new array with all the existing layers except the one being deleted
        for (i = 0; i < [layers count]; i++) {
            if (i != index) {
                tempArray = [tempArray arrayByAddingObject:[layers objectAtIndex:i]];
            }
        }

        layers = tempArray;

        // Change the layer
        if (activeLayerIndex >= [layers count]) activeLayerIndex = [layers count] - 1;

        [[document helpers] activeLayerChanged:kLayerDeleted];
    }
    

    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] restoreLayer:layer atIndex:index];
}

- (void)restoreLayer:(SeaLayer*)layer atIndex:(int)index
{
    NSArray *tempArray;
    int i;

    @synchronized (document.mutex) {
        [[document helpers] activeLayerWillChange];

        // Create a new array with all the existing layers including the one being restored
        tempArray = [NSArray array];
        for (i = 0; i < [layers count] + 1; i++) {
            if (i == index) {
                tempArray = [tempArray arrayByAddingObject:layer];
            }
            else {
                tempArray = [tempArray arrayByAddingObject:[layers objectAtIndex:(i > index) ? i - 1 : i]];
            }
        }

        layers = tempArray;

        activeLayerIndex = index;

        [[document helpers] activeLayerChanged:kLayerAdded];
    }
    [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}

- (void)layerFromSelection:(BOOL)duplicate
{
    BOOL containsNothing;
    unsigned char *data;
    IntRect rect;
    id layer;
    int i;

    // Check the state is valid
    if (![[document selection] active])
        return;

    [[document helpers] endLineDrawing];

    // Save the existing selection
    rect = [[document selection] globalRect];
    data = [[document selection] selectionData];
    
    // Check that the selection contains something
    containsNothing = YES;
    for (i = 0; containsNothing && (i < rect.size.width * rect.size.height); i++) {
        if (data[i*SPP+alphaPos] != 0x00)
            containsNothing = NO;
    }
    if (containsNothing) {
        free(data);
        NSRunAlertPanel(LOCALSTR(@"empty selection title", @"Selection empty"), LOCALSTR(@"empty selection body", @"The layer cannot be created since the selection is empty."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
        return;
    }

    // Remove the old selection if we're not duplicating
    if(!duplicate)
        [[document selection] deleteSelection];

    layer = [[SeaLayer alloc] initWithDocument:document rect:rect data:data];
    [layer trimLayer];

    [self addLayerObject:layer];

    [[document selection] clearSelection];
    [[document toolboxUtility] positionTool];
}

-(IBAction)duplicate:(id)sender
{
    [self layerFromSelection:YES];
}

-(void)floatSelection
{    
    [self layerFromSelection:NO];
}

- (void)layerFromPasteboard:(NSPasteboard*)pboard atIndex:(int)index
{
    NSString *imageRepDataType;
    NSData *imageRepData;
    NSBitmapImageRep *imageRep;
    NSImage *image;
    IntRect rect;
    id layer;
    unsigned char *data;
    int i;
    NSPoint centerPoint;
    IntPoint sel_point;
    IntSize sel_size;
    
    // Ensure that the document is valid
    if(![pboard availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSURLPboardType, NULL]]){
        NSBeep();
        return;
    }
    
    [[document helpers] endLineDrawing];

    NSPasteboardType ptype = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType,NSTIFFPboardType,nil]];
    if([ptype isEqualToString:NSURLPboardType]){
        NSURL *url = [NSURL URLFromPasteboard:pboard];
        if([url isFileURL]) {
            NSString *path = [url path];
            image = [[NSImage alloc] initByReferencingFile:path];
            imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
            if(imageRep==NULL) {
                // maybe another image type, like SVG or Seashore, so try and import the file
                [self importLayerFromFile:path];
                return;
            }
        } else {
            // we'll try the image types below
        }
    }
    
    if(imageRep==NULL){
        // Get the data from the pasteboard
        imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSTIFFPboardType]];
        if (imageRepDataType != NULL) {
            imageRepData = [pboard dataForType:imageRepDataType];
            imageRep = [[NSBitmapImageRep alloc] initWithData:imageRepData];
        }
    }

    if(imageRep==NULL){
        NSBeep();
        return;
    }
    
    // Work out the correct center point
    sel_size = IntMakeSize([imageRep pixelsWide], [imageRep pixelsHigh]);
    if ([[document selection] selectionSizeMatch:sel_size]) {
        sel_point = [[document selection] selectionPoint];
        rect = IntMakeRect(sel_point.x, sel_point.y, sel_size.width, sel_size.height);
    }
    else if ((height > 64 && width > 64 && sel_size.height > height - 12 &&  sel_size.width > width - 12) || (sel_size.height >= height &&  sel_size.width >= width)) { 
        rect = IntMakeRect(width / 2 - sel_size.width / 2, height / 2 - sel_size.height / 2, sel_size.width, sel_size.height);
    }
    else {
        centerPoint = [(CenteringClipView *)[[document docView] superview] centerPoint];
        rect = IntMakeRect(centerPoint.x - sel_size.width / 2, centerPoint.y - sel_size.height / 2, sel_size.width, sel_size.height);
    }
    
    data = convertRepToARGB(imageRep);
    if (!data) {
        NSLog(@"Required conversion not supported.");
        return;
    }
    
    layer = [[SeaLayer alloc] initWithDocument:document rect:rect data:data];

    [layer trimLayer];
    [self addLayerObject:layer atIndex:index];

    [[document toolboxUtility] positionTool];
}

- (BOOL)canRaise:(int)index
{
    if (index == kActiveLayer) index = activeLayerIndex;
    return !(index == 0);
}

- (BOOL)canLower:(int)index
{
    if (index == kActiveLayer) index = activeLayerIndex;
    return !(index == [layers count] - 1);
}

- (void)moveLayer:(id)layer toIndex:(int)index
{
    [self moveLayerOfIndex:[layers indexOfObject:layer] toIndex: index];    
}

- (void)moveLayerOfIndex:(int)source toIndex:(int)dest
{
    NSMutableArray *tempArray;

    // An invalid destination
    if(dest < 0 || dest > [layers count])
        return;
    
    // Correct index
    if (source == kActiveLayer)
        source = activeLayerIndex;
    
    if(source==-1)
        return;
    
    id activeLayer = [layers objectAtIndex:activeLayerIndex];
    
    // Allocate space for a new array
    tempArray = [layers mutableCopy];
    [tempArray removeObjectAtIndex:source];
    
    int actualFinal;
    
    if(dest >= [layers count]){
        actualFinal = [layers count] - 1;
    }else if(dest > source){
        actualFinal = dest - 1;
    }else{
        actualFinal = dest;
    }
    
    [tempArray insertObject:[layers objectAtIndex:source] atIndex:actualFinal];

    @synchronized (document.mutex) {
        // Now substitute in our new array
        layers = [NSArray arrayWithArray:tempArray];

        // Update Seashore with the changes
        activeLayerIndex = [layers indexOfObject:activeLayer];

        [[document helpers] layerLevelChanged:actualFinal];

        // For the undo we need to make sure we get the offset right
        if(source >= dest){
            source++;
        }
    }

    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] moveLayerOfIndex: actualFinal toIndex: source];
}


- (void)raiseLayer:(int)index
{
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;
    
    // Do nothing if we can't do anything
    if (![self canRaise:index])
        return;

    [self moveLayerOfIndex:index toIndex:index-1];
}

- (void)lowerLayer:(int)index
{
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;
    
    // Do nothing if we can't do anything
    if (![self canLower:index])
        return;

    [self moveLayerOfIndex:index toIndex:index+2];
}

- (void)clearAllLinks
{
    [[document helpers] endLineDrawing];

    int i;
    
    // Go through all layers and toggle them back so they are unlinked
    for (i = 0; i < [layers count]; i++) {
        if ([[layers objectAtIndex:i] linked])
            [self setLinked: NO forLayer: i];
    }
}

- (void)setLinked:(BOOL)isLinked forLayer:(int)index
{
    [[document helpers] endLineDrawing];
    
    id layer;
    
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;
    layer = [layers objectAtIndex:index];
    
    // Apply the changes
    [layer setLinked:isLinked];
    [[document layersUtility] update:kLayersUpdateCurrent];
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] setLinked:!isLinked forLayer:index];
}

- (void)setVisible:(BOOL)isVisible forLayer:(int)index
{
    id layer;
    
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;
    layer = [layers objectAtIndex:index];
    
    // Apply the changes
    [layer setVisible:isVisible];
    [[document helpers] layerAttributesChanged:index hold:YES];
    [[document layersUtility] update:kLayersUpdateCurrent];
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] setVisible:!isVisible forLayer:index];
}

- (void)copyMerged
{
    [[document helpers] endLineDrawing];

    id pboard = [NSPasteboard generalPasteboard];

    CGImageRef image = [[document whiteboard] bitmap];

    // Check selection
    if ([[document selection] active]) {
        CGImageRef sub = CGImageCreateWithImageInRect(image,IntRectMakeNSRect([[document selection] maskRect]));
        CGImageRelease(image);
        image = sub;
    }

    // Declare the data being added to the pasteboard
    [pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:NULL];
    
    // Add it to the pasteboard
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:image];
    CGImageRelease(image);
    [pboard setData:[imageRep TIFFRepresentation] forType:NSTIFFPboardType];
}

// copies the layer to the clipboard
- (void)copyLayer
{
    [[document helpers] endLineDrawing];

    SeaLayer *layer = [self activeLayer];

    id pboard = [NSPasteboard generalPasteboard];

    [pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:NULL];
    [pboard setData:[layer TIFFRepresentation] forType:NSTIFFPboardType];
}

- (BOOL)canFlatten
{
    if ([layers count] != 1)
        return YES;

    SeaLayer *layer = [self layer:0];
    
    if ([layer xoff] != 0 || [layer yoff] != 0 || [layer width] != width || [layer height] != height)
        return YES;
    
    return NO;
}

- (void)flatten
{
    [[document helpers] endLineDrawing];

    @synchronized (document.mutex) {
        [self merge:layers withName: LOCALSTR(@"flattened", @"Flattened Layer")];
    }
}

- (void)mergeLinked
{
    [[document helpers] endLineDrawing];

    SeaLayer *layer;
    NSMutableArray *linkedLayers = [NSMutableArray array];
    // Go through noting each linked layer
    NSEnumerator *e = [layers objectEnumerator];
    while(layer = [e nextObject]) {
        if ([layer linked])
            [linkedLayers addObject: layer];
    }
    @synchronized (document.mutex) {
        [self merge:linkedLayers withName: LOCALSTR(@"flattened", @"Flattened Layer")];
    }
}

// merge layer down based on selected channel
- (void)mergeChannelDown
{
    SeaLayer *top = [layers objectAtIndex:activeLayerIndex];
    SeaLayer *bottom = [layers objectAtIndex:activeLayerIndex+1];

    IntRect topRect = [top globalRect],bottomRect = [bottom globalRect];

    IntRect rect = IntConstrainRect(topRect,bottomRect);

    NSArray *copy = [layers copy];
    [[[document undoManager] prepareWithInvocationTarget:self] undoMergeWith:copy];

    int size = [bottom width]*[bottom height]*SPP;
    unsigned char *data = malloc(size);
    memcpy(data,[bottom data],size);

    SeaLayer *new_layer = [[SeaLayer alloc] initWithDocument:document rect:[bottom globalRect] data:data];
    [new_layer setName:[[NSString alloc] initWithString:[bottom name]]];

    NSMutableArray *tempArray = [NSMutableArray array];

    for(SeaLayer* layer in layers) {
        if(layer==top){
            // only need to replace bottom layer
        } else if (layer==bottom) {
            [tempArray addObject:new_layer];
        } else {
            [tempArray addObject:layer];
        }
    }

    for(int y=0;y<rect.size.height;y++){
        int tOffset = ((rect.origin.y - topRect.origin.y + y) * [top width] + rect.origin.x-topRect.origin.x) * SPP;
        int bOffset = ((rect.origin.y - bottomRect.origin.y + y) * [bottom width] + rect.origin.x-bottomRect.origin.x) * SPP;

        unsigned char *td = [top data]+tOffset;
        unsigned char *bd = [new_layer data]+bOffset;

        for(int x=0;x<rect.size.width;x++) {
            if(selectedChannel==kAlphaChannel) {
                bd[alphaPos] = td[alphaPos];
            } else if(selectedChannel==kPrimaryChannels){
                memcpy(bd+CR,td+CR,SPP-1);
            }
            td+=SPP;
            bd+=SPP;
        }
    }

    @synchronized (document.mutex) {
        [[document helpers] documentWillFlatten];

        activeLayerIndex = [tempArray indexOfObject:new_layer];
        layers = tempArray;
        selectedChannel = kAllChannels;

        [[document helpers] documentFlattened];
    }

}


- (void)mergeDown
{
    if(![self canLower:activeLayerIndex])
        return;

    [[document helpers] endLineDrawing];

    NSArray *layersToMerge = [NSArray arrayWithObjects:
                              [layers objectAtIndex:activeLayerIndex],
                              [layers objectAtIndex:activeLayerIndex+1],
                              nil];

    @synchronized (document.mutex) {
        if(selectedChannel == kAllChannels) {
            [self merge:layersToMerge withName: [[layers objectAtIndex:activeLayerIndex + 1] name]];
        } else {
            [self mergeChannelDown];
        }
    }
}

- (void)merge:(NSArray *)mergingLayers withName:(NSString *)newName
{
    // Do nothing if we can't do anything
    if (![self canFlatten])
        return;

    // Inform the helpers we will flatten the document
    [[document helpers] documentWillFlatten];

    NSArray *copy = [layers copy];

    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] undoMergeWith:copy];

    // Create the replacement flat layer

    SeaLayer *layer, *tempLayer = [SeaLayer alloc];

    IntRect rect = IntMakeRect(0,0,0,0);
    NSMutableArray *tempArray = [NSMutableArray array];

    bool found=false;
    for(SeaLayer* layer in layers) {
        if([mergingLayers indexOfObject:layer] != NSNotFound){
            IntRect thisRect = [layer globalRect];
            rect = IntRectIsEmpty(rect) ? thisRect : IntSumRects(rect, thisRect);
            if(!found){
                [tempArray addObject:tempLayer];
                found=true;
            }
        } else {
            [tempArray addObject:layer];
        }
    }

    CGContextRef ctx = CreateImageContext(rect.size);
    CGContextTranslateCTM(ctx,0,rect.size.height);
    CGContextScaleCTM(ctx,1,-1);
    CGContextTranslateCTM(ctx, -rect.origin.x,-rect.origin.y);

    // composite the layers
    NSEnumerator *f = [mergingLayers reverseObjectEnumerator];
    while(layer = [f nextObject]) {
        [layer drawLayer:ctx];
    }

    unpremultiplyBitmap(SPP,ImageContextGetData(ctx),ImageContextGetData(ctx),rect.size.width*rect.size.height);

    layer = [[SeaLayer alloc] initWithDocument:document rect:rect data:ImageContextGetData(ctx)];
    [layer setName:[[NSString alloc] initWithString:newName]];

    CGContextRelease(ctx);

    // Revise layers
    activeLayerIndex = [tempArray indexOfObject:tempLayer];
    [tempArray replaceObjectAtIndex:activeLayerIndex withObject:layer];
    layers = tempArray;
    selectedChannel = kAllChannels;

    [[document helpers] documentFlattened];
}

- (void)undoMergeWith:(NSArray*)oldLayers
{
    NSArray *copy = [layers copy];

    [[[document undoManager] prepareWithInvocationTarget:self] undoMergeWith:copy];

    // Inform the helpers we will unflatten the document
    [[document helpers] documentWillFlatten];

    layers = oldLayers;

    // Inform the helpers we have unflattened the document
    [[document helpers] documentFlattened];
}

- (void)convertToType:(int)newType
{
    NSMutableArray<LayerSnapshot*> *snapshots = [NSMutableArray array];

    SeaLayer *layer;
    int i;
    
    // Do nothing if there is nothing to do
    if (newType == type)
        return;
    
    for (i = 0; i < [layers count]; i++) {
        layer = [layers objectAtIndex:i];
        LayerSnapshot *snapshot = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [layer width], [layer height]) automatic:NO];
        [snapshots addObject:snapshot];
    }

    [[[document undoManager] prepareWithInvocationTarget:self] revertToType:type withRecord:snapshots];

    @synchronized (document.mutex) {
        // Go through and convert all layers to the new given type
        for (i = 0; i < [layers count]; i++)
            [[layers objectAtIndex:i] convertFromType:type to:newType];

        // Then save the new type
        type = newType;

        // Update everything
        [[document helpers] typeChanged];
    }
}

- (void)revertToType:(int)newType withRecord:(NSMutableArray<LayerSnapshot*>*)snapshots
{
    int i;
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] convertToType:type];

    @synchronized (document.mutex) {
        // Go through and convert all layers to the new given type
        for (i = 0; i < [layers count]; i++)
            [[layers objectAtIndex:i] convertFromType:type to:newType];

        // Then save the new type
        type = newType;

        // Restore the layers
        for (i = 0; i < [layers count]; i++)
            [[[layers objectAtIndex:i] seaLayerUndo] restoreSnapshot:[snapshots objectAtIndex:i] automatic:NO];

        // Update everything
        [[document helpers] typeChanged];
    }
}

- (ParasiteData*)parasites{
    return parasites;
}

- (void)fixupLayers
{
    NSMutableArray *layers0 = [NSMutableArray array];

    for(int i=0;i<[layers count];i++) {
        SeaLayer *layer = layers[i];
        if(![layer isKindOfClass:XCFLayer.class]) {
            [layers0 addObject:layer];
            continue;
        }
        XCFLayer *xcf = (XCFLayer*)layer;
        TextProperties* props = [XCFTextLayerSupport properties:xcf];
        if(!props) {
            [layers0 addObject:xcf];
            continue;
        }
        SeaTextLayer *textLayer = [[SeaTextLayer alloc] initWithDocument:document layer:(SeaLayer*)layer properties:props];
        [layers0 addObject:textLayer];
    }
    @synchronized (document.mutex) {
        layers = [NSArray arrayWithArray:layers0];
    }
}

- (BOOL)isRGB
{
    return type == XCF_RGB_IMAGE;
}
- (BOOL)isGrayscale
{
    return type == XCF_GRAY_IMAGE;
}

@end

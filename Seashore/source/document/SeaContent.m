#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaView.h"
#import "SeaHelpers.h"
#import "PegasusUtility.h"
#import "SeaLayerUndo.h"
#import "SeaSelection.h"
#import "SeaWhiteboard.h"
#import "CenteringClipView.h"
#import "Bitmap.h"
#import "SeaWarning.h"
#import "XCFContent.h"
#import "CocoaContent.h"
#import "XBMContent.h"
#import "SVGContent.h"
#import "CocoaImporter.h"
#import "XCFImporter.h"
#import "XBMImporter.h"
#import "SVGImporter.h"
#import "ToolboxUtility.h"
#import "CloneTool.h"
#import "PositionTool.h"
#import "SeaTools.h"
#import "SeaCompositor.h"
#import "StatusUtility.h"
#import "SeaDocumentController.h"

extern IntPoint gScreenResolution;
static NSString*    FloatAnchorToolbarItemIdentifier = @"Float/Anchor Toolbar Item Identifier";
static NSString*    DuplicateSelectionToolbarItemIdentifier = @"Duplicate Selection Toolbar Item Identifier";

@implementation SeaContent

- (id)initWithDocument:(id)doc
{
    // Set the data members to reasonable values
    xres = yres = 72;
    height = width = type = 0;
    lostprops = NULL; lostprops_len = 0;
    parasites = NULL; parasites_count = 0;
    exifData = NULL;
    layers = NULL; activeLayerIndex = 0;
    layersToUndo = [NSMutableArray array];
    layersToRedo = [NSMutableArray array];
    orderings = [NSMutableArray array];
    deletedLayers = [[NSArray alloc] init];
    selectedChannel = kAllChannels; trueView = NO;
    keeper = allocKeeper();
    document = doc;
    
    return self;
}

- (id)initFromPasteboardWithDocument:(id)doc
{
    id pboard = [NSPasteboard generalPasteboard];
    NSString *imageRepDataType;
    NSData *imageRepData;
    NSBitmapImageRep *imageRep;
    NSImage *image;
    int dspp;
    unsigned char *data;
    
    // Get the data from the pasteboard
    imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSTIFFPboardType]];
    if (imageRepDataType == NULL) {
        imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSPICTPboardType]];
        imageRepData = [pboard dataForType:imageRepDataType];
        image = [[NSImage alloc] initWithData:imageRepData];
        imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
    }
    else {
        imageRepData = [pboard dataForType:imageRepDataType];
        imageRep = [[NSBitmapImageRep alloc] initWithData:imageRepData];
    }
    
    // Fill out as many of the properties as possible
    height = [imageRep pixelsHigh];
    width = [imageRep pixelsWide];
    xres = yres = 72;
    lostprops = NULL; lostprops_len = 0;
    parasites = NULL; parasites_count = 0;
    exifData = NULL;
    layersToUndo = [NSMutableArray array];
    layersToRedo = [NSMutableArray array];
    orderings = [NSMutableArray array];
    deletedLayers = [[NSArray alloc] init];
    selectedChannel = kAllChannels; trueView = NO;
    keeper = allocKeeper();
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
    
    // Put it in a nice form
    if (type == XCF_RGB_IMAGE)
        dspp = 4;
    else
        dspp = 2;
    
    data = convertImageRep(imageRep,dspp);
    if (!data) {
        NSLog(@"Required conversion not supported.");
        return NULL;
    }
    
    // Add layer
    SeaLayer *new_layer = [[SeaLayer alloc] initWithDocument:doc rect:IntMakeRect(0, 0, width, height) data:data spp:dspp];
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
    layers = [[NSArray alloc] initWithObjects:[[SeaLayer alloc] initWithDocument:doc width:dwidth height:dheight opaque:dopaque spp:[self spp]], NULL];
    
    return self;
}

- (id)initWithDocument:(id)doc data:(unsigned char *)ddata type:(int)dtype width:(int)dwidth height:(int)dheight res:(int)dres
{
    // Call the core initializer
    if (![self initWithDocument:doc])
        return NULL;
    
    // Set the data members to appropriate values
    xres = yres = dres;
    type = dtype;
    height = dheight; width = dwidth;
    
    // Add in a single layer
    layers = [[NSArray alloc] initWithObjects:[[SeaLayer alloc] initWithDocument:doc rect:IntMakeRect(0, 0, dwidth, dheight) data:ddata spp:(dtype == XCF_RGB_IMAGE) ? 4 : 2], NULL];
    
    return self;
}

- (void)dealloc
{
    int i;
    
    freeKeeper(&keeper);
    if (parasites) {
        for (i = 0; i < parasites_count; i++) {
            free(parasites[i].name);
            free(parasites[i].data);
        }
        free(parasites);
    }
    if (lostprops) free(lostprops);
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
    id layer;
    int i;
    
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

- (int)type
{
    return type;
}

- (int)spp
{
    int result = 0;
    
    switch (type) {
        case XCF_RGB_IMAGE:
            result = 4;
        break;
        case XCF_GRAY_IMAGE:
            result = 2;
        break;
        default:
            NSLog(@"Document type not recognised by spp");
        break;
    }
    
    return result;
}

- (int)xres
{
    return xres;
}

- (int)yres
{
    return yres;
}

- (float)xscale
{
    float xscale = [[document docView] zoom];
    
    if (gScreenResolution.x != 0 && xres != gScreenResolution.x)
        xscale /= ((float)xres / (float)gScreenResolution.x);
    
    return xscale;
}

- (float)yscale
{
    float yscale = [[document docView] zoom];
    
    if (gScreenResolution.y != 0 && yres != gScreenResolution.y)
        yscale /= ((float)yres / (float)gScreenResolution.y);
    
    return yscale;
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

- (ParasiteData *)parasites
{
    return parasites;
}

- (int)parasites_count
{
    return parasites_count;
}

- (ParasiteData *)parasiteWithName:(char *)name
{
    int i;
    
    for (i = 0; i < parasites_count; i++) {
        if (strcmp(name,parasites[i].name)==0)
            return &(parasites[i]);
    }
    
    return NULL;
}

- (void)deleteParasiteWithName:(char *)name
{
    int i, x;
    
    // Find the parasite to delete
    x = -1;
    for (i = 0; i < parasites_count && x == -1; i++) {
        if (strcmp(name,parasites[i].name)==0)
            x = i;
    }
    
    if (x != -1) {
        
        // Destroy it
        free(parasites[x].name);
        free(parasites[x].data);
    
        // Update the parasites list
        parasites_count--;
        if (parasites_count > 0) {
            for (i = x; i < parasites_count; i++) {
                parasites[i] = parasites[i + 1];
            }
            parasites = realloc(parasites, sizeof(ParasiteData) * parasites_count);
        }
        else {
            free(parasites);
            parasites = NULL;
        }
    
    }
}

- (void)addParasite:(ParasiteData)parasite
{
    // Delete existing parasite with the same name (if any)
    [self deleteParasiteWithName:parasite.name];
    
    // Add parasite
    parasites_count++;
    if (parasites_count == 1) parasites = malloc(sizeof(ParasiteData) * parasites_count);
    else parasites = realloc(parasites, sizeof(ParasiteData) * parasites_count);
    parasites[parasites_count - 1] = parasite;
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
    activeLayerIndex = value;
}

- (void)layerBelow
{
    int newIndex;
    [[document helpers] activeLayerWillChange];
    if(activeLayerIndex + 1 >= [self layerCount])
    {
        newIndex = 0;
    }else {
        newIndex = activeLayerIndex + 1;
    }
    [self setActiveLayerIndex: newIndex];
    [[document helpers] activeLayerChanged:kLayerSwitched];
}

- (void)layerAbove
{
    int newIndex;
    [[document helpers] activeLayerWillChange];
    if(activeLayerIndex - 1 < 0)
    {
        newIndex = [self layerCount] - 1;
    }else {
        newIndex = activeLayerIndex - 1;
    }
    [self setActiveLayerIndex: newIndex];
    [[document helpers] activeLayerChanged:kLayerSwitched];
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
        
    } else {
        
        // Handle an unknown document type
        NSLog(@"Unknown type passed to importLayerFromFile:<%@> docType:<%@>", path, docType);
        success = NO;
    
    }

    // Inform the user of failure
    if (!success){
        [[SeaController seaWarning] addMessage:LOCALSTR(@"import failure message", @"The selected file was not able to be successfully imported into this document.") forDocument:document level:kHighImportance];
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

    SeaLayer *layerToAdd;
    
    if([[layers objectAtIndex:index] floating]) {
        SeaLayer *layer = [layers objectAtIndex:index];
        layerToAdd = [[SeaLayer alloc] initWithDocument:document rect:[layer localRect] data:[layer data] spp:[self spp]];

        // Delete the floating layer
        [self deleteLayer:index];
        [[document selection] clearSelection];
    } else {
        layerToAdd = [[SeaLayer alloc] initWithDocument:document width:width height:height opaque:NO spp:[self spp]];
    }

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
    
    // Make action undoable
    [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}

- (void)addLayerObject:(id)layer
{
    NSArray *tempArray = [NSArray array];
    int i, index;
    
    // Inform the helpers we will change the layer
    [[document helpers] activeLayerWillChange];
    
    // Find index
    index = activeLayerIndex;
    
    // Create a new array with all the existing layers and the one being added
    for (i = 0; i < [layers count] + 1; i++) {
        if (i == index)
            tempArray = [tempArray arrayByAddingObject:layer];
        else
            tempArray = [tempArray arrayByAddingObject:(i > index) ? [layers objectAtIndex:i - 1] : [layers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    layers = tempArray;
    
    // Inform document of layer change
    [[document helpers] activeLayerChanged:kLayerAdded];
    
    // Make action undoable
    [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}

- (void)addLayerFromPasteboard:(id)pboard
{
    NSArray *tempArray = [NSArray array];
    NSString *imageRepDataType;
    NSData *imageRepData;
    NSBitmapImageRep *imageRep;
    NSImage *image;
    IntRect rect;
    id layer;
    unsigned char *data;
    int i, spp = [[document contents] spp], dspp;
    NSPoint centerPoint;
    
    // Get the data from the pasteboard
    imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSTIFFPboardType]];
    if (imageRepDataType == NULL) {
        imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSPICTPboardType]];
        imageRepData = [pboard dataForType:imageRepDataType];
        image = [[NSImage alloc] initWithData:imageRepData];
        imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
    }
    else {
        imageRepData = [pboard dataForType:imageRepDataType];
        imageRep = [[NSBitmapImageRep alloc] initWithData:imageRepData];
    }
    
    if(imageRep == NULL) {
        NSLog(@"Unable to load image from pasteboard.");
        return;
    }
    
    // Work out the correct center point
    if (height > 64 && width > 64 && [imageRep pixelsHigh] > height - 12 && [imageRep pixelsWide] > width - 12) { 
        rect = IntMakeRect(width / 2 - [imageRep pixelsWide] / 2, height / 2 - [imageRep pixelsHigh] / 2, [imageRep pixelsWide], [imageRep pixelsHigh]);
    }
    else {
        centerPoint = [(CenteringClipView *)[[document docView] superview] centerPoint];
        centerPoint.x /= [[document docView] zoom];
        centerPoint.y /= [[document docView] zoom];
        rect = IntMakeRect(centerPoint.x - [imageRep pixelsWide] / 2, centerPoint.y - [imageRep pixelsHigh] / 2, [imageRep pixelsWide], [imageRep pixelsHigh]);
    }
    
    dspp = spp;
    
    if (spp == 4 && selectedChannel == kAlphaChannel) {
        dspp = 2;
    }
    
    data = convertImageRep(imageRep,dspp);
    if (!data) {
        NSLog(@"Required conversion not supported.");
        return;
    }
    
    // Inform the helpers we will change the layer
    [[document helpers] activeLayerWillChange];
    
    // Create a new array with all the existing layers and the one being added
    layer = [[SeaLayer alloc] initWithDocument:document rect:rect data:data spp:spp];
    if(layer==NULL){
        NSLog(@"Unable to load create layer.");
        [[document helpers] activeLayerChanged:kLayerSwitched];
        return;
    }
    for (i = 0; i < [layers count] + 1; i++) {
        if (i == activeLayerIndex)
            tempArray = [tempArray arrayByAddingObject:layer];
        else
            tempArray = [tempArray arrayByAddingObject:(i > activeLayerIndex) ? [layers objectAtIndex:i - 1] : [layers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    layers = tempArray;
    
    // Inform document of layer change
    [[document helpers] activeLayerChanged:kLayerAdded];
    
    // Make action undoable
    [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:activeLayerIndex];    
}

- (void)copyLayer:(id)layer
{
    NSArray *tempArray = [NSArray array];
    int i, index;
    
    // Inform the helpers we will change the layer
    [[document helpers] activeLayerWillChange];
    
    // Create a new array with all the existing layers and the one being added
    index = activeLayerIndex;
    for (i = 0; i < [layers count] + 1; i++) {
        if (i == index)
            tempArray = [tempArray arrayByAddingObject:[[SeaLayer alloc] initWithDocument:document layer:layer]];
        else
            tempArray = [tempArray arrayByAddingObject:(i > index) ? [layers objectAtIndex:i - 1] : [layers objectAtIndex:i]];
    }
    
    layers = tempArray;
    
    // Inform document of layer change
    [[document helpers] activeLayerChanged:kLayerAdded];
    
    // Make action undoable
    [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}

- (void)duplicateLayer:(int)index
{
    NSArray *tempArray = [NSArray array];
    IntRect rect;
    int i;
    
    // Inform the helpers we will change the layer
    [[document helpers] activeLayerWillChange];
    
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;
    
    // Create a new array with all the existing layers and the one being added
    for (i = 0; i < [layers count] + 1; i++) {
        if (i == index)
            tempArray = [tempArray arrayByAddingObject:[[SeaLayer alloc] initWithDocument:document layer:[layers objectAtIndex:index]]];
        else
            tempArray = [tempArray arrayByAddingObject:(i > index) ? [layers objectAtIndex:i - 1] : [layers objectAtIndex:i]];
    }
    
    layers = tempArray;
    
    // Inform document of layer change
    rect = IntMakeRect([[layers objectAtIndex:index] xoff], [[layers objectAtIndex:index] yoff], [(SeaLayer *)[layers objectAtIndex:index] width], [(SeaLayer *)[layers objectAtIndex:index] height]);
    [[document helpers] activeLayerChanged:kLayerAdded];
    
    // Make action undoable
    [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}

- (void)deleteLayer:(int)index
{
    id layer;
    NSArray *tempArray = [NSArray array];
    IntRect rect;
    int i;
    
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;
    layer = [layers objectAtIndex:index];
    
    // Inform the helpers we will change the layer
    [[document helpers] activeLayerWillChange];
    
    // Create a new array with all the existing layers except the one being deleted
    for (i = 0; i < [layers count]; i++) {
        if (i != index) {
            tempArray = [tempArray arrayByAddingObject:[layers objectAtIndex:i]];
        }
    }
    
    layers = tempArray;
    
    // Add the layer to the lost layers (compressed)
    deletedLayers = [deletedLayers arrayByAddingObject:layer];
    
    // Change the layer
    if (activeLayerIndex >= [layers count]) activeLayerIndex = [layers count] - 1;
    
    // Update Seashore with the changes
    rect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
    [[document helpers] activeLayerChanged:kLayerDeleted];
    
    // Unset the clone tool
    [[[document tools] getTool:kCloneTool] unset];
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] restoreLayer:index fromLostIndex:[deletedLayers count] - 1];
}

- (void)restoreLayer:(int)index fromLostIndex:(int)lostIndex
{
    SeaLayer *layer = [deletedLayers objectAtIndex:lostIndex];
    NSArray *tempArray;
    IntRect rect;
    int i;
    
    // Inform the helpers we will change the layer
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

    // Create a new array of lost layers with the removed layer replaced with "BLANK"
    tempArray = [NSArray array];
    for (i = 0; i < [deletedLayers count]; i++) {
        if (i == lostIndex)
            tempArray = [tempArray arrayByAddingObject:[[NSString alloc] initWithString:@"BLANK"]];
        else
            tempArray = [tempArray arrayByAddingObject:[deletedLayers objectAtIndex:i]];
    }
    
    deletedLayers = tempArray;
    
    // Update Seashore with the changes
    activeLayerIndex = index;
        
    // Update Seashore with the changes
    rect = IntMakeRect([layer xoff], [layer yoff], [layer width], [layer height]);
    [[document helpers] activeLayerChanged:kLayerAdded];
    
    // Make action undoable
    [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
    
    // Update toolbox
    if ([layer floating]){
        [[document toolboxUtility] floatTool];
        [[document toolboxUtility] update:YES];
    }
}

- (void)makeSelectionFloat:(BOOL)duplicate
{
    NSArray *tempArray = [NSArray array];
    BOOL containsNothing;
    unsigned char *data;
    IntRect rect;
    id layer;
    int i, spp = [[document contents] spp];
    
    // Check the state is valid
    if (![[document selection] active] || [[document selection] floating])
        return;
    
    // Save the existing selection
    rect = [[document selection] globalRect];
    data = [[document selection] selectionData:NO];
    
    // Check that the selection contains something
    containsNothing = YES;
    for (i = 0; containsNothing && (i < rect.size.width * rect.size.height); i++) {
        if (data[(i + 1) * spp - 1] != 0x00)
            containsNothing = NO;
    }
    if (containsNothing) {
        free(data);
        NSRunAlertPanel(LOCALSTR(@"empty selection title", @"Selection empty"), LOCALSTR(@"empty selection body", @"The selection cannot be floated since it is empty."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
        return;
    }

    // Remove the old selection if we're not duplicating
    if(!duplicate)
        [[document selection] deleteSelection];
    
    // Inform the helpers we will change the layer
    [[document helpers] activeLayerWillChange];
    
    // Create a new array with all the existing layers and the one being added
    layer = [[SeaLayer alloc] initFloatingWithDocument:document rect:rect data:data];
    [layer trimLayer];
    for (i = 0; i < [layers count] + 1; i++) {
        if (i == activeLayerIndex)
            tempArray = [tempArray arrayByAddingObject:layer];
        else
            tempArray = [tempArray arrayByAddingObject:(i > activeLayerIndex) ? [layers objectAtIndex:i - 1] : [layers objectAtIndex:i]];
    }
    
    layers = tempArray;
        
    // Wrap selection to the opaque
    [[document selection] selectOpaque];
    
    // Inform document of layer change
    [[document helpers] activeLayerChanged:kLayerAdded];
    
    // Inform the tools of the floating
    [[document toolboxUtility] floatTool];
    
    // Make action undoable
    [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:activeLayerIndex];
}

-(IBAction)duplicate:(id)sender
{
    [self makeSelectionFloat:YES];    
}

-(void)toggleFloatingSelection
{    
    if ([[document selection] floating]) {
        [self anchorLayer];
    }
    else {
        [self makeSelectionFloat:NO];
    }
}

- (void)makePasteboardFloat
{
    NSArray *tempArray = [NSArray array];
    NSString *imageRepDataType;
    NSData *imageRepData;
    NSBitmapImageRep *imageRep;
    NSImage *image;
    IntRect rect;
    id pboard = [NSPasteboard generalPasteboard];
    id layer;
    unsigned char *data;
    int i, spp = [[document contents] spp],dspp;
    NSPoint centerPoint;
    IntPoint sel_point;
    IntSize sel_size;
    
    // Check the state is valid
    if ([[document selection] floating])
        return;
    
    // Ensure that the document is valid
    if(![[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NSURLPboardType, NULL]]){
        NSBeep();
        return;
    }
    
    NSPasteboardType ptype = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType,NSTIFFPboardType,NSPICTPboardType,nil]];
    if([ptype isEqualToString:NSURLPboardType]){
        NSURL *url = [NSURL URLFromPasteboard:pboard];
        if([url isFileURL]) {
            NSString *path = [url path];
            NSString *extension = [path pathExtension];
            image = [[NSImage alloc] initByReferencingFile:path];
            imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
        } else {
            // we'll try the image types below
        }
    }
    
    if(imageRep==NULL){
        // Get the data from the pasteboard
        imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSTIFFPboardType]];
        if (imageRepDataType == NULL) {
            imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSPICTPboardType]];
            imageRepData = [pboard dataForType:imageRepDataType];
            image = [[NSImage alloc] initWithData:imageRepData];
            imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
        }
        else {
            imageRepData = [pboard dataForType:imageRepDataType];
            imageRep = [[NSBitmapImageRep alloc] initWithData:imageRepData];
        }
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
        centerPoint.x /= [[document docView] zoom];
        centerPoint.y /= [[document docView] zoom];
        rect = IntMakeRect(centerPoint.x - sel_size.width / 2, centerPoint.y - sel_size.height / 2, sel_size.width, sel_size.height);
    }
    
    dspp = spp;
    if (spp == 4 && selectedChannel == kAlphaChannel) {
        dspp = 2;
    }

    data = convertImageRep(imageRep,dspp);
    if (!data) {
        NSLog(@"Required conversion not supported.");
        return;
    }
    
    // Handle the special case where a GGGA graphic is wanted
    if (spp == 4 && dspp == 2) {
        unsigned char *tdata = malloc(make_128(rect.size.width * rect.size.height * 4));
        for (i = 0; i < rect.size.width * rect.size.height; i++) {
            tdata[i * 4] = data[i * 2];
            tdata[i * 4 + 1] = data[i * 2];
            tdata[i * 4 + 2] = data[i * 2];
            tdata[i * 4 + 3] = data[i * 2 + 1];
        }
        free(data);
        data = tdata;
    }

    // Inform the helpers we will change the layer
    [[document helpers] activeLayerWillChange];
    
    // Create a new array with all the existing layers and the one being added
    layer = [[SeaLayer alloc] initFloatingWithDocument:document rect:rect data:data];
    [layer trimLayer];
    for (i = 0; i < [layers count] + 1; i++) {
        if (i == activeLayerIndex)
            tempArray = [tempArray arrayByAddingObject:layer];
        else
            tempArray = [tempArray arrayByAddingObject:(i > activeLayerIndex) ? [layers objectAtIndex:i - 1] : [layers objectAtIndex:i]];
    }
    
    layers = tempArray;
    
    // Wrap selection to the opaque
    [[document selection] selectOpaque];
    
    // Inform document of layer change
    [[document helpers] activeLayerChanged:kLayerAdded];
    
    // Inform the tools of the floating
    [[document toolboxUtility] floatTool];
    
    // Make action undoable
    [(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:activeLayerIndex];
}

- (void)anchorLayer
{
    unsigned char *data, *overlay;
    IntRect dataRect, layerRect;
    int i, j, destXPos, destYPos, spp = [self spp];
    
    int floatingLayerIndex = -1;
    int topNonFloatingIndex = -1;
    
    SeaLayer *layer;
    
    // Don't do anything if there's no selection
    if (![[document selection] floating])
        return;
    
    SeaLayer *floating = [[document contents] activeLayer];
    if(!floating) {
        NSLog(@"There were no floating layers!");
        return;
    }
    
    for(i = 0; i < [layers count]; i++){
        if([layers objectAtIndex:i] == floating){
            floatingLayerIndex = i;
            break;
        }
    }
    
    if(floatingLayerIndex == -1){
        NSLog(@"Could not find floating layer!");
        return;
    }
    
    for(i=floatingLayerIndex; i<[layers count];i++) {
        if(![[layers objectAtIndex:i] floating]){
            topNonFloatingIndex = i;
            break;
        }
    }
             
    if(topNonFloatingIndex == -1){
        NSLog(@"Could not find top non-floating layer!");
        return;
    }
    // anchor to top non-floating layer below
    
    layer = floating;
                                  
    dataRect = IntMakeRect([layer xoff], [layer yoff], [layer width], [layer height]);;
    data = malloc(make_128(dataRect.size.width * dataRect.size.height * spp));
    memcpy(data, [layer data], dataRect.size.width * dataRect.size.height * spp);
    
    // Delete the floating layer
    [self deleteLayer:floatingLayerIndex];
    
    // Work out the new layer rectangle
    layer = [layers objectAtIndex:topNonFloatingIndex-1]; // need to subtract 1 because we deleted a layer
    
    [[document helpers] activeLayerWillChange];
    [self setActiveLayerIndex:topNonFloatingIndex-1];
    [[document helpers] activeLayerChanged:kLayerSwitched];

    layerRect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
    
    // Copy the selection to the overlay
    overlay = [[document whiteboard] overlay];
    [[document whiteboard] setOverlayOpacity:255];
    for (j = 0; j < dataRect.size.height; j++) {
        for (i = 0; i < dataRect.size.width; i++) {
            destXPos = dataRect.origin.x - layerRect.origin.x + i;
            destYPos = dataRect.origin.y - layerRect.origin.y + j;
            if (destXPos >= 0 && destXPos < layerRect.size.width && destYPos >= 0 && destYPos < layerRect.size.height) {
                memcpy(&(overlay[(destYPos * layerRect.size.width + destXPos) * spp]), &(data[(j * dataRect.size.width + i) * spp]), spp);
            }
        }
    }
    free(data);
    
    // Clear the selection
    [[document selection] clearSelection];
    // Apply the overlay (only works on active layer)
    [(SeaHelpers *)[document helpers] applyOverlay];
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
    
    // Now substitute in our new array
    layers = [NSArray arrayWithArray:tempArray];
    
    // Update Seashore with the changes
    activeLayerIndex = [layers indexOfObject:activeLayer];
    [[document helpers] layerLevelChanged:activeLayerIndex];
    
    // For the undo we need to make sure we get the offset right
    if(source >= dest){
        source++;
    }
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] moveLayerOfIndex: actualFinal toIndex: source];
}


- (void)raiseLayer:(int)index
{
    NSArray *tempArray;
    int i;
    
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;
    
    // Do nothing if we can't do anything
    if (![self canRaise:index])
        return;
    
    // Allocate space for a new array
    tempArray = [NSArray array];
    
    // Go through and add all existing objects to the new array
    for (i = 0; i < [layers count]; i++) {
        if (i == index - 1) {
            tempArray = [tempArray arrayByAddingObject:[layers objectAtIndex:i + 1]];
            tempArray = [tempArray arrayByAddingObject:[layers objectAtIndex:i]];
            i++;
        }
        else
            tempArray = [tempArray arrayByAddingObject:[layers objectAtIndex:i]];
    }
    
    layers = tempArray;
    
    // Update Seashore with the changes
    activeLayerIndex = index - 1;
    [[document helpers] layerLevelChanged:activeLayerIndex];
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] lowerLayer:index - 1];
}

- (void)lowerLayer:(int)index
{
    NSArray *tempArray;
    int i;
    
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;
    
    // Do nothing if we can't do anything
    if (![self canLower:index])
        return;
    
    // Allocate space for a new array
    tempArray = [NSArray array];
    
    // Go through and add all existing objects to the new array
    for (i = 0; i < [layers count]; i++) {
        if (i == index) {
            tempArray = [tempArray arrayByAddingObject:[layers objectAtIndex:i + 1]];
            tempArray = [tempArray arrayByAddingObject:[layers objectAtIndex:i]];
            i++;
        }
        else
            tempArray = [tempArray arrayByAddingObject:[layers objectAtIndex:i]];
    }
    
    layers = tempArray;
    
    // Update Seashore with the changes
    activeLayerIndex = index + 1;
    [[document helpers] layerLevelChanged:activeLayerIndex];
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] raiseLayer:index + 1];
}

- (void)clearAllLinks
{
    int i;
    
    // Go through all layers and toggle them back so they are unlinked
    for (i = 0; i < [layers count]; i++) {
        if ([[layers objectAtIndex:i] linked])
            [self setLinked: NO forLayer: i];
    }
}

- (void)setLinked:(BOOL)isLinked forLayer:(int)index
{
    id layer;
    
    // Correct index
    if (index == kActiveLayer) index = activeLayerIndex;
    layer = [layers objectAtIndex:index];
    
    // Apply the changes
    [layer setLinked:isLinked];
    [[document pegasusUtility] update:kPegasusUpdateLayerView];
    
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
    [[document pegasusUtility] update:kPegasusUpdateLayerView];
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] setVisible:!isVisible forLayer:index];
}

- (void)copyMerged
{
    id pboard = [NSPasteboard generalPasteboard];
    int spp = [[document contents] spp], i , j, k, t1;
    NSBitmapImageRep *imageRep;
    IntRect globalRect;
    unsigned char *data = [(SeaWhiteboard *)[document whiteboard] data];
    unsigned char *ndata = NULL;
    unsigned char *mask;

    // Check selection
    if ([[document selection] active]) {
        mask = [(SeaSelection*)[(SeaDocument*)document selection] mask];
        globalRect = IntConstrainRect(IntMakeRect(0,0,width,height),[[document selection] globalRect]);
        ndata = malloc(make_128(globalRect.size.width * globalRect.size.height * spp));
        if (mask) {
            for (j = globalRect.origin.y; j < globalRect.origin.y + globalRect.size.height; j++) {
                for (i = globalRect.origin.x; i < globalRect.origin.x + globalRect.size.width; i++) {
                    for (k = 0; k < spp; k++) {
                        ndata[((j - globalRect.origin.y) * globalRect.size.width + (i - globalRect.origin.x)) * spp + k] =  int_mult(data[(j * width + i) * spp + k], mask[(j - globalRect.origin.y) * globalRect.size.width + (i - globalRect.origin.x)], t1);
                    }
                }
            }
        }
        else {
            for (j = globalRect.origin.y; j < globalRect.origin.y + globalRect.size.height; j++) {
                for (i = globalRect.origin.x; i < globalRect.origin.x + globalRect.size.width; i++) {
                    for (k = 0; k < spp; k++) {
                        ndata[((j - globalRect.origin.y) * globalRect.size.width + (i - globalRect.origin.x)) * spp + k] =  data[(j * width + i) * spp + k];
                    }
                }
            }
        }
    }
    else {
        ndata = data;
        globalRect.origin.x = globalRect.origin.y = 0;
        globalRect.size.width = width;
        globalRect.size.height = height;
    }

    // Declare the data being added to the pasteboard
    [pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:NULL];
    
    // Add it to the pasteboard
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&ndata pixelsWide:globalRect.size.width pixelsHigh:globalRect.size.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:globalRect.size.width * spp bitsPerPixel:8 * spp];
    [pboard setData:[imageRep TIFFRepresentation] forType:NSTIFFPboardType]; 
    
    // Clean out the remains
    if (ndata != data) {
        free(ndata);
    }
}

- (BOOL)canFlatten
{
    // Yes, if there are one or more layers
    if ([layers count] != 1)
        return YES;
    
    // Yes, if single layer is out of place
    if ([[layers objectAtIndex:0] xoff] != 0 || [[layers objectAtIndex:0] yoff] != 0
            || [(SeaLayer *)[layers objectAtIndex:0] width] != width || [(SeaLayer *)[layers objectAtIndex:0] height] != height)
        return YES;
    
    return NO;
}

- (void)flatten
{
    [self merge:layers useRepresentation: YES withName: LOCALSTR(@"flattened", @"Flattened Layer")];
}

- (void)mergeLinked
{
    SeaLayer *layer;
    NSMutableArray *linkedLayers = [NSMutableArray array];
    // Go through noting each linked layer
    NSEnumerator *e = [layers objectEnumerator];
    while(layer = [e nextObject]) {
        if ([layer linked])
            [linkedLayers addObject: layer];
    }
    // Preform the merge
    [self merge:linkedLayers useRepresentation: NO withName: LOCALSTR(@"flattened", @"Flattened Layer")];
}

- (void)mergeDown
{
    // Make sure there is a layer to merge into
    if([self canLower:activeLayerIndex]){
        NSArray *twoLayers = [NSArray arrayWithObject:[layers  objectAtIndex:activeLayerIndex]];
        // Add the layer we're going into
        twoLayers = [twoLayers arrayByAddingObject:[layers  objectAtIndex:activeLayerIndex + 1]];
        [self merge: twoLayers useRepresentation: NO withName: [[layers  objectAtIndex:activeLayerIndex + 1] name]];
    }
}

- (void)merge:(NSArray *)mergingLayers useRepresentation: (BOOL)useRepresenation withName:(NSString *)newName
{
    CompositorOptions options;
    unsigned char *data;
    SeaLayer *layer, *lostLayer, *tempLayer = [SeaLayer alloc];
    int spp = [self spp];
    BOOL indexFound = NO;
    NSMutableArray *tempArray = [NSMutableArray array];
    IntRect rect = IntMakeRect(0,0,0,0);
    // The ordering dictionary is needed because layers which are linked are not
    // nessisarily contiguous -- thus just keeping a stack in the undo history
    // would not totally restore their state
    NSMutableDictionary *ordering = [NSMutableDictionary dictionaryWithCapacity:[layers count]];
    
    // Do nothing if we can't do anything
    if (![self canFlatten])
        return;
    
    // Inform the helpers we will flatten the document
    [[document helpers] documentWillFlatten];
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] undoMergeWith:[layers count] andOrdering: ordering];
    [orderings addObject:ordering];
    // Create the replacement flat layer
    
    // Use representation is used when we want to use the pre-made image
    // representation of the image. Basicially, just when flattening the whole
    // file.
    if(useRepresenation){
        rect.size.width = width;
        rect.size.height = height;
        data = malloc(make_128(rect.size.width * rect.size.height * spp));
        memcpy(data, [[document whiteboard] data], rect.size.width * rect.size.height * spp);
        NSEnumerator *e = [layers objectEnumerator];
        while(layer = [e nextObject]){
            [ordering setValue: [NSNumber numberWithInt:[layers indexOfObject: layer]] forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
        }
        [tempArray addObject:tempLayer];
    }else{
        NSEnumerator *e = [layers objectEnumerator];
        // Here we find out the dimensions of the new layer, plus keep track of
        // which layers are not going to be merged (tempArray).
        while(layer = [e nextObject]) {
            [ordering setValue: [NSNumber numberWithInt:[layers indexOfObject: layer]] forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
            if([mergingLayers indexOfObject:layer] != NSNotFound){
                IntRect thisRect = IntMakeRect([layer xoff], [layer yoff], [layer width], [layer height]);
                rect = IntSumRects(rect, thisRect);
                if(!indexFound)
                    [tempArray addObject:tempLayer];
            }else{
                [tempArray addObject:layer];
            }
        }
        data = malloc(make_128(rect.size.width * rect.size.height * spp));
        memset(data, 0, rect.size.width * rect.size.height * spp);
        // Set the composting options
        options.forceNormal = 0;
        options.rect = rect;
        options.destRect = rect;
        options.insertOverlay = NO;
        options.useSelection = NO;
        options.overlayOpacity = 255;
        options.overlayBehaviour = kNormalBehaviour;
        options.spp = spp;

        // Composite the linked layers
        NSEnumerator *f = [mergingLayers reverseObjectEnumerator];
        while(layer = [f nextObject])
            [[[document whiteboard] compositor] compositeLayer:layer withOptions:options andData: data];
    }
    unpremultiplyBitmap(spp, data, data, rect.size.width * rect.size.height);
    layer = [[SeaLayer alloc] initWithDocument:document rect:rect data:data spp:spp];
    [layer setName:[[NSString alloc] initWithString:newName]];

    // Get rid of all the other layers
    NSEnumerator *g = [mergingLayers objectEnumerator];
    while(lostLayer = [g nextObject])
        [layersToUndo addObject: lostLayer];
    
    // Revise layers
    activeLayerIndex = [tempArray indexOfObject:tempLayer];
    [tempArray replaceObjectAtIndex:activeLayerIndex withObject:layer];
    [tempArray removeObject:tempLayer];
    layers = tempArray;
    selectedChannel = 0;
    
    // Unset the clone tool
    [[[document tools] getTool:kCloneTool] unset];
    
    // Inform the helpers we have flattened the document
    [[document helpers] documentFlattened];
}

- (void)undoMergeWith:(int)oldNoLayers andOrdering: (NSMutableDictionary *)ordering
{
    NSMutableArray *oldLayers = [NSMutableArray arrayWithCapacity:oldNoLayers];
    NSMutableDictionary *newOrdering = [NSMutableDictionary dictionaryWithCapacity:[layers count]];
    int i;
    SeaLayer *layer;
    
    // Inform the helpers we will unflatten the document
    [[document helpers] documentWillFlatten];

    // Get the current orderings for the undo history
    NSEnumerator *e = [layers objectEnumerator];
    while(layer = [e nextObject])
        [newOrdering setValue: [NSNumber numberWithInt:[layers indexOfObject: layer]] forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] redoMergeWith:[layers count] andOrdering: newOrdering];

    // This is just to make the dimensions of the array correct
    while([oldLayers count] < oldNoLayers)
        [oldLayers addObject: [layers lastObject]];

    // Store the previous layers to their correct location in the array
    for(i = 0; i < oldNoLayers - [layers count] + 1; i++){
        SeaLayer *oldLayer = [layersToUndo lastObject];
        [layersToUndo removeLastObject];
        int replInd = [[ordering objectForKey:[NSString stringWithFormat:@"%d", [oldLayer uniqueLayerID]]] intValue];        
        [oldLayers replaceObjectAtIndex:replInd withObject:oldLayer];
    }
    
    for(i = 0; i < [layers count]; i++){
        SeaLayer *oldLayer = [layers objectAtIndex:i];
        NSNumber *oldIndex = [ordering objectForKey:[NSString stringWithFormat:@"%d", [oldLayer uniqueLayerID]]];
        // We also will need to store the merged layer for redo
        if(oldIndex != nil)
            [oldLayers replaceObjectAtIndex: [oldIndex intValue] withObject:oldLayer];
        else
            [layersToRedo addObject:oldLayer];
    }
    
    layers = oldLayers;
    
    // Unset the clone tool
    [[[document tools] getTool:kCloneTool] unset];
    
    // Inform the helpers we have unflattened the document
    [[document helpers] documentFlattened];
    
    [orderings removeObject: ordering];
    [orderings addObject:newOrdering];
}

- (unsigned char *)bitmapUnderneath:(IntRect)rect
{
    CompositorOptions options;
    unsigned char *data;
    SeaLayer *layer;
    int i, spp = [self spp];
    
    // Create the replacement flat layer
    data = malloc(make_128(rect.size.width * rect.size.height * spp));
    memset(data, 0, rect.size.width * rect.size.height * spp);

    // Set the composting options
    options.forceNormal = 0;
    options.rect = rect;
    options.destRect = rect;
    options.insertOverlay = NO;
    options.useSelection = NO;
    options.overlayOpacity = 255;
    options.overlayBehaviour = kNormalBehaviour;
    options.spp = spp;

    // Composite the layers underneath
    for (i = [layers count] - 1; i >= activeLayerIndex; i--) {
        layer = [layers objectAtIndex:i];
        if ([layer visible]) {
            [[[document whiteboard] compositor] compositeLayer:layer withOptions:options andData:data];
        }
    }
    
    return data;
}

- (void)redoMergeWith:(int)oldNoLayers andOrdering:(NSMutableDictionary *)ordering
{
    NSMutableArray *newLayers = [NSMutableArray arrayWithCapacity:oldNoLayers];
    NSMutableDictionary *oldOrdering = [NSMutableDictionary dictionaryWithCapacity:[layers count]];
    int i;
    SeaLayer *layer;
    
    // Inform the helpers we will flatten the document
    [[document helpers] documentWillFlatten];
    
    // Store the orderings
    NSEnumerator *e = [layers objectEnumerator];
    while(layer = [e nextObject])
        [oldOrdering setValue: [NSNumber numberWithInt:[layers indexOfObject: layer]] forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];

    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] undoMergeWith:[layers count] andOrdering:oldOrdering];

    // Populate the array
    while([newLayers count] < oldNoLayers)
        [newLayers addObject: [layers lastObject]];
    
    SeaLayer *newLayer = [layersToRedo lastObject];
    [layersToRedo removeLastObject];
    [newLayers replaceObjectAtIndex:[[ordering objectForKey:[NSString stringWithFormat:@"%d", [newLayer uniqueLayerID]]] intValue] withObject:newLayer];

    // Go through and insert the layers at the appropriate places
    for(i = 0; i < [layers count]; i++){
        SeaLayer *newLayer = [layers objectAtIndex:i];
        NSNumber *newIndex = [ordering objectForKey:[NSString stringWithFormat:@"%d", [newLayer uniqueLayerID]]];
        if(newIndex != nil)
            [newLayers replaceObjectAtIndex: [newIndex intValue] withObject:newLayer];
        else
            [layersToUndo addObject:newLayer];
    }
    
    layers = newLayers;

    // Unset the clone tool
    [[[document tools] getTool:kCloneTool] unset];
    
    // Inform the helpers we have flattened the document
    [[document helpers] documentFlattened];

    [orderings removeObject:ordering];
    [orderings addObject:oldOrdering];
}

- (void)convertToType:(int)newType
{
    IndiciesRecord record;
    id layer;
    int i;
    
    // Do nothing if there is nothing to do
    if (newType == type)
        return;
    
    // Make action undoable
    record.length = [layers count];
    record.indicies = malloc([layers count] * sizeof(int));
    for (i = 0; i < [layers count]; i++) {
        layer = [layers objectAtIndex:i]; 
        record.indicies[i] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [(SeaLayer *)layer width], [(SeaLayer *)layer height]) automatic:NO];
    }
    addToKeeper(&keeper, record);
    
    [[[document undoManager] prepareWithInvocationTarget:self] revertToType:type withRecord:record];
    
    // Go through and convert all layers to the new given type
    for (i = 0; i < [layers count]; i++)
        [[layers objectAtIndex:i] convertFromType:type to:newType];
        
    // Then save the new type
    type = newType;
    
    // Update everything
    [[document helpers] typeChanged]; 
}

- (void)revertToType:(int)newType withRecord:(IndiciesRecord)record
{
    int i;
    
    // Make action undoable
    [[[document undoManager] prepareWithInvocationTarget:self] convertToType:type];
    
    // Go through and convert all layers to the new given type
    for (i = 0; i < [layers count]; i++)
        [[layers objectAtIndex:i] convertFromType:type to:newType];

    // Then save the new type
    type = newType;
    
    // Restore the layers
    for (i = 0; i < [layers count]; i++)
        [[[layers objectAtIndex:i] seaLayerUndo] restoreSnapshot:record.indicies[i] automatic:NO];
    
    // Update everything
    [[document helpers] typeChanged]; 
}

@end

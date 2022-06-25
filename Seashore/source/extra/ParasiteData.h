//
//  ParasiteData.h
//  Seashore
//
//  Created by robert engels on 1/23/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @struct        Parasite
 @discussion    A record containing arbitrary data that will be saved with the
 image using the XCF file format.
 @field        name
 The null terminated name of the parasite.
 @field        flags
 Any flags associated with the parasite.
 @field        size
 The size of the parasite's data.
 @field        data
 The parasite's data.
 */

typedef struct {
    char *name;
    unsigned int flags;
    unsigned int size;
    unsigned char *data;
} Parasite;

@interface ParasiteData : NSObject
{
    Parasite *parasites;
    int parasites_count;
}

/*!
 @method        parasites
 @discussion    Returns the parasistes of the document. Parasites are arbitrary
 pieces of data that are saved by the GIMP and Seashore in XCF
 documents.
 @result        Returns an array of ParasiteData records of length given by the
 parasites_count method.
 */
- (Parasite *)parasites;

/*!
 @method        parasites_count
 @discussion    Returns the number of parasites in the document's parasite
 array.
 @result        Returns an integer representing the number of parasites in the
 document's parasite array.
 */
- (int)parasites_count;

/*!
 @method        parasiteWithName:
 @discussion    Returns a pointer to the parasite with the given name.
 @param        name
 The name of the parasite.
 @result        Returns a pointer to the ParasiteData record with the requested
 name or NULL if no parasites match.
 */
- (Parasite *)parasiteWithName:(char *)name;

/*!
 @method        deleteParasiteWithName:
 @discussion    Deletes the parasite with the given name.
 @param        name
 The name of the parasite to delete.
 */
- (void)deleteParasiteWithName:(char *)name;

/*!
 @method        addParasite:
 @discussion    Adds a parasite (replacing an existing one with the same name if
 it exists).
 @param        parasite
 The ParasiteData record to add (no copying is done, the record
 is inserted directly into the parasites array so don't use free
 afterwards).
 */
- (void)addParasite:(Parasite)parasite;

@end

NS_ASSUME_NONNULL_END

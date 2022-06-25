//
//  ParasiteData.m
//  Seashore
//
//  Created by robert engels on 1/23/22.
//

#import "ParasiteData.h"

@implementation ParasiteData

- (Parasite *)parasites
{
    return parasites;
}

- (int)parasites_count
{
    return parasites_count;
}

- (Parasite *)parasiteWithName:(char *)name
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
            parasites = realloc(parasites, sizeof(Parasite) * parasites_count);
        }
        else {
            free(parasites);
            parasites = NULL;
        }

    }
}

- (void)addParasite:(Parasite)parasite
{
    // Delete existing parasite with the same name (if any)
    [self deleteParasiteWithName:parasite.name];

    // Add parasite
    parasites_count++;
    if (parasites_count == 1) parasites = malloc(sizeof(Parasite) * parasites_count);
    else parasites = realloc(parasites, sizeof(Parasite) * parasites_count);
    parasites[parasites_count - 1] = parasite;
}

- (void)dealloc
{
    if (parasites) {
        for (int i = 0; i < parasites_count; i++) {
            free(parasites[i].name);
            free(parasites[i].data);
        }
        free(parasites);
    }
}

@end

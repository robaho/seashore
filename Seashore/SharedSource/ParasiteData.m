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

NSString* parseEscaped(NSString* s){
    NSMutableString *ms = [NSMutableString string];
    int len = [s length];
    unichar buffer[len+1];
    [s getCharacters:buffer range:NSMakeRange(0,len)];

    bool escape = false;

    for(int i=0;i<len;i++) {
        switch(buffer[i]) {
            case '\\':
                if(escape) {
                    [ms appendString:@"\\"]; escape=FALSE;
                } else {
                    escape=TRUE;
                }
                continue;
            default:
                if(!escape) {
                    [ms appendString:[NSString stringWithCharacters:(buffer+i) length:1]];
                } else {
                    escape=false;
                    switch(buffer[i]) {
                        case '\\':
                            [ms appendString:@"\\"]; break;
                        case '"':
                            [ms appendString:@"\""]; break;
                        case 'n':
                            [ms appendString:@"\n"]; break;
                        default:
                            [ms appendString:[NSString stringWithCharacters:(buffer+i) length:1]];
                    }
                }
        }
    }
    return ms;
}

+ (NSDictionary*)parseParasite:(Parasite*)p
{
    NSString *s = [NSString stringWithCString:p->data encoding:NSUTF8StringEncoding];
    return [ParasiteData parseString:s];
}

+ (NSDictionary*)parseString:(NSString*)s
{
    NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:@"\\([^)]+\\s.+\\)" options:0 error:nil];
    NSRegularExpression *exp2 = [NSRegularExpression regularExpressionWithPattern:@"\\(([^\\s]+)\\s(.+)\\)" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    NSArray *matches = [exp matchesInString:s options:0 range:NSMakeRange(0,[s length])];
    for (NSTextCheckingResult *match in matches) {
        NSString *ms = [s substringWithRange:[match range]];

        NSArray<NSTextCheckingResult*> *kvMatches = [exp2 matchesInString:ms options:0 range:NSMakeRange(0,[ms length])];

        if(kvMatches.count!=1 || kvMatches[0].numberOfRanges!=3)
            continue;

        NSString *key = [ms substringWithRange:[kvMatches[0] rangeAtIndex:1]];
        NSString *value = [ms substringWithRange:[kvMatches[0] rangeAtIndex:2]];

        if([value hasPrefix:@"\""]) {
            // remove quotes
            value = [value substringWithRange:NSMakeRange(1,[value length]-2)];
            value = parseEscaped(value);
        }
        dict[key]=value;
//        NSLog(@"%@|%@ %@ %@", key,value,NSStringFromRange([match rangeAtIndex:1]),NSStringFromRange([match rangeAtIndex:2]));
    }
    return dict;
}

+ (void)parseFloats:(NSString*)s floats:(float[_Nonnull])floats
{
    NSArray<NSString*> *strings = [s componentsSeparatedByString:@" "];
    for(int i=0;i<[strings count];i++) {
        floats[i] = [strings[i] floatValue];
    }
}


@end

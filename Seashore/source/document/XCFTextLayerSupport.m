//
//  XCFTextLayerSupport.m
//  Seashore
//
//  Created by robert engels on 7/30/22.
//

#import "XCFTextLayerSupport.h"
#import "NSBezierPath_Extensions.h"

@implementation XCFTextLayerSupport

NSString* parseMarkup(NSString *s) {
    NSMutableString *ms = [NSMutableString string];
    int len = [s length];
    unichar buffer[len+1];
    [s getCharacters:buffer range:NSMakeRange(0,len)];

    bool inTag=false;
    for(int i=0;i<len;i++) {
        if(buffer[i]=='<') {
            inTag=TRUE;
            continue;
        }
        if(inTag) {
            if(buffer[i]=='>')
                inTag=FALSE;
        } else {
            [ms appendString:[NSString stringWithCharacters:(buffer+i) length:1]];
        }
    }
    return ms;
}

+ (TextProperties*)properties:(XCFLayer*)layer
{
    Parasite* p = [[layer parasites] parasiteWithName:"gimp-text-layer"];
    if(!p)
        return NULL;

    NSDictionary *dict = [ParasiteData parseParasite:p];

    TextProperties* props = [[TextProperties alloc] init];
    NSString *rtf = dict[@"rtf"];
    if(rtf != NULL) {
        props.text = [[NSAttributedString alloc] initWithRTF:[rtf dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL];
    } else {
        NSString *s = dict[@"text"];
        if(s==NULL) {
            s = parseMarkup(dict[@"markup"]);
        }
        props.text = [[NSAttributedString alloc] initWithString:s];
    }

    float fontSize = [(NSString*)dict[@"font-size"] floatValue];
    NSString *fontSizeUnit = dict[@"font-size-unit"];
    if(fontSizeUnit) {
        if([fontSizeUnit isEqual:@"pixels"]) {
            // pixels are broken in Gimp
            fontSize = fontSize * 72.0 / [[[layer document] contents] xres];
        } else if([fontSizeUnit isEqualToString:@"points"]) {
            // fontSize = fontSize;
        } else if([fontSizeUnit isEqualToString:@"mm"]) {
            fontSize = fontSize * 2.83465;
        } else if([fontSizeUnit isEqualToString:@"in"]) {
            fontSize = 72 * fontSize;
        } else {
            NSLog(@"unknown unit type %@",fontSizeUnit);
        }
    }

    NSString *fontName = dict[@"font"];
    if(fontName) {
        fontName = [fontName stringByReplacingOccurrencesOfString:@"Sans-serif" withString:@"Helvetica"];

        NSFont *font = [NSFont fontWithName:fontName size:fontSize];
        props.font = font;
    }

    NSString *justify = dict[@"justify"];
    if(justify) {
        if([justify isEqualToString:@"left"]) {
            props.alignment = NSTextAlignmentLeft;
        } else if([justify isEqualToString:@"right"]) {
            props.alignment = NSTextAlignmentRight;
        } else if([justify isEqualToString:@"center"]) {
            props.alignment = NSTextAlignmentCenter;
        } else {
            NSLog(@"unknown justify type %@",justify);
        }
    }

    NSString *colorS = dict[@"color"];
    if(colorS) {
        NSDictionary *colorDict = [ParasiteData parseString:colorS];
        if(colorDict[@"color-rgb"]) {
            colorS = colorDict[@"color-rgb"];
            float rgb[3];
            [ParasiteData parseFloats:colorS floats:rgb];
            props.color = [NSColor colorWithRed:rgb[0] green:rgb[1] blue:rgb[2] alpha:1.0];
        }
    }

    NSString *lineSpacingS = dict[@"line-spacing"];
    if(lineSpacingS) {
        props.lineSpacing = [lineSpacingS floatValue];
    }

    NSString *verticalMarginS = dict[@"vertical-margin"];
    if(verticalMarginS) {
        props.verticalMargin = [verticalMarginS floatValue];
    }

    NSString *outlineS = dict[@"outline-thickness"];
    if(outlineS) {
        props.outline = [outlineS floatValue];
    }

    NSString *textPathS = dict[@"text-path"];
    if(textPathS) {
        props.textPath = [NSBezierPath fromString:textPathS];
    }

    return props;
}

static NSString* escapeString(NSString* s) {
    NSMutableString *ms = [NSMutableString string];
    for(int i=0;i<s.length;i++) {
        unichar c = [s characterAtIndex:i];
        switch(c) {
            case '\\':
                [ms appendString:@"\\\\"]; break;
            case '\n':
                [ms appendString:@"\\n"]; break;
            case '"':
                [ms appendString:@"\\\""]; break;
            default:
                [ms appendString:[NSString stringWithCharacters:&c length:1]];
        }
    }
    return ms;
}

+ (Parasite)toParasite:(SeaTextLayer*)layer properties:(TextProperties*)properties
{
    Parasite p;
    p.name = strdup("gimp-text-layer");

    NSAttributedString *text = properties.text;

    NSDictionary *documentAttributes = @{NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType};
    NSData *rtfData = [text dataFromRange:NSMakeRange(0, text.length) documentAttributes:documentAttributes error:NULL];
    NSString *rtfString = [[NSString alloc] initWithData:rtfData encoding:NSUTF8StringEncoding];

    NSMutableString *ms = [NSMutableString string];
    [ms appendString:[NSString stringWithFormat:@"(rtf \"%@\")\n",escapeString(rtfString)]];
    [ms appendString:[NSString stringWithFormat:@"(text \"%@\")\n",escapeString([properties.text string])]];
    [ms appendString:[NSString stringWithFormat:@"(font-size %f)\n",[properties.font pointSize]]];
    [ms appendString:[NSString stringWithFormat:@"(font-size-unit %@)\n",@"points"]];
    [ms appendString:[NSString stringWithFormat:@"(font \"%@\")\n",escapeString([properties.font displayName])]];

    NSString *justify=@"left";
    switch(properties.alignment) {
        case NSTextAlignmentLeft:
            justify= @"left"; break;
        case NSTextAlignmentCenter:
            justify = @"center"; break;
        case NSTextAlignmentRight:
            justify = @"right"; break;
    }

    [ms appendString:[NSString stringWithFormat:@"(justify %@)\n",justify]];
    [ms appendString:[NSString stringWithFormat:@"(box-mode %@)\n",@"fixed"]];
    [ms appendString:[NSString stringWithFormat:@"(box-width %d)\n",[layer width]]];
    [ms appendString:[NSString stringWithFormat:@"(box-height %d)\n",[layer height]]];
    [ms appendString:[NSString stringWithFormat:@"(box-unit %@)\n",@"pixels"]];
    [ms appendString:[NSString stringWithFormat:@"(line-spacing %f)\n",properties.lineSpacing]];
    [ms appendString:[NSString stringWithFormat:@"(vertical-margin %f)\n",properties.verticalMargin]];
    [ms appendString:[NSString stringWithFormat:@"(outline-thickness %d)\n",properties.outline]];
    if(properties.textPath) {
        [ms appendString:[NSString stringWithFormat:@"(text-path %@)\n",[properties.textPath toString]]];
    }
    double red,green,blue;
    [properties.color getRed:&red green:&green blue:&blue alpha:nil];
    [ms appendString:[NSString stringWithFormat:@"(color (color-rgb %f %f %f))\n",red,green,blue]];

    p.data = (void*)strdup([ms cStringUsingEncoding:NSUTF8StringEncoding]);
    p.size = (int)strlen((char *)p.data)+1;
    return p;
}

@end

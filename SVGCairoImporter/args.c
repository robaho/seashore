/* args.c - Parse command-line argument for svg2png using getopt
 *
 * Copyright © 2002 USC/Information Sciences Institute
 *
 * Permission to use, copy, modify, distribute, and sell this software
 * and its documentation for any purpose is hereby granted without
 * fee, provided that the above copyright notice appear in all copies
 * and that both that copyright notice and this permission notice
 * appear in supporting documentation, and that the name of
 * Information Sciences Institute not be used in advertising or
 * publicity pertaining to distribution of the software without
 * specific, written prior permission.  Information Sciences Institute
 * makes no representations about the suitability of this software for
 * any purpose.  It is provided "as is" without express or implied
 * warranty.
 *
 * INFORMATION SCIENCES INSTITUTE DISCLAIMS ALL WARRANTIES WITH REGARD
 * TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL INFORMATION SCIENCES
 * INSTITUTE BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA
 * OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 * TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 *
 * Author: Carl Worth <cworth@isi.edu>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libgen.h>
#include <getopt.h>

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include "args.h"

#define VERSION "0.1.3"

static const char ARGS_PROGRAM_VERSION[] = VERSION;
static const char ARGS_PROGRAM_DESCRIPTION[] = "svg2png - Render an SVG image to a PNG image";
static const char ARGS_PROGRAM_BUG_ADDRESS[] = "<cworth@isi.edu>";

static const char ARGS_PROGRAM_ARGDOC[] = "[<SVG_file> [<PNG_file>]]";

enum {
    ARGS_VAL_HELP = 256,
    ARGS_VAL_FLIPX,
    ARGS_VAL_FLIPY
};

static const char args_optstring[] = "h:s:w:xyV";
static struct option args_options[] = {
    /* name,		has_arg,	flag,	val */
    {"height",		1,		0,	'h'},
    {"scale",		1,		0,	's'},
    {"width",		1,		0,	'w'},
    {"flipx",		0,		0,	ARGS_VAL_FLIPX},
    {"flipy",		0,		0,	ARGS_VAL_FLIPY},
    {"help",		0,		0,	ARGS_VAL_HELP},
    {"version",		0,		0,	'V'},
    { 0 }
};

static void
args_help (const char *argv0)
{
    char *argv0_copy = strdup (argv0);
    char *argv0_base = basename (argv0_copy);

    printf ("Usage: %s [OPTIONS] %s\n", argv0_base, ARGS_PROGRAM_ARGDOC);
    printf ("%s - %s\n", argv0_base, ARGS_PROGRAM_DESCRIPTION);
    puts ("");
    printf ("  -w, --width=WIDTH\tWidth of output image in pixels\n");
    printf ("  -h, --height=HEIGHT\tHeight of output image in pixels\n");
    printf ("  -s, --scale=FACTOR\tScale image by FACTOR\n");
    puts ("");
    printf ("  --flipx\t\tFlip X coordinates of image\n");
    printf ("  --flipy\t\tFlip Y coordinates of image\n");
    puts ("");
    printf ("  --help\t\tGive this help list\n");
    printf ("  -V, --version\t\tPrint program version\n");

    free (argv0_copy);
}

static void
args_usage (const char *argv0)
{
    char *argv0_copy = strdup (argv0);
    char *argv0_base = basename (argv0_copy);

    printf ("Usage: %s [OPTION] %s\n", argv0_base, ARGS_PROGRAM_ARGDOC);
    printf ("Try `%s --help' for more information.\n", argv0_base);

    free (argv0_copy);
}

int
args_parse (args_t *args, int argc, char *argv[])
{
    int c;

    args->svg_filename = "-";
    args->png_filename = "-";
    args->scale = 1.0;

    args->width = -1;
    args->height = -1;
    args->flipx = 0;
    args->flipy = 0;

    while (1) {
	c = getopt_long (argc, argv, args_optstring, args_options, NULL);
	if (c == -1)
	    break;

	switch (c) {
	case 'h':
	    args->height = atoi (optarg);
	    break;
	case 's':
	    args->scale = atof (optarg);
	    break;
	case 'w':
	    args->width = atoi (optarg);
	    break;
	case 'V':
	    printf ("%s\n", ARGS_PROGRAM_VERSION);
	    exit (0);
	    break;
	case ARGS_VAL_FLIPX:
	    args->flipx = 1;
	    break;
	case ARGS_VAL_FLIPY:
	    args->flipy = 1;
	    break;
	case ARGS_VAL_HELP:
	    args_help (argv[0]);
	    exit (0);
	    break;
	case '?':
	    args_help (argv[0]);
	    exit (1);
	    break;
	default:
	    fprintf (stderr, "Unhandled option: %d\n", c);
	    exit (1);
	    break;
	}
    }
	
    if (argc - optind >= 1) {
	args->svg_filename = argv[optind++];
	if (argc - optind >= 1) {
	    args->png_filename = argv[optind++];
	    if (argc - optind > 0) {
	    	args_usage (argv[0]);
	    	exit (1);
    	    }
	}
    }

    return 0;
}


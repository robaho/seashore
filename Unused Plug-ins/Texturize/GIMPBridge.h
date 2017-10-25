#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>

typedef unsigned char guchar;
typedef char gchar;
typedef unsigned int guint;
typedef unsigned int guint32;
typedef int gint;
typedef int gint32;
typedef char gboolean;
typedef float gfloat;
typedef double gdouble;
typedef void *gpointer;
typedef unsigned long gulong;

#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define g_warning(...)
#define g_message(...)
#define gimp_progress_init(...)
#define gimp_progress_update(...)
#define CLAMP(x, y, z) ((x) < (y) ? (y) : ((x) > (z) ? (z) : (x)))
#define FALSE 0
#define TRUE 1
#define g_malloc(x) malloc(x)
#define g_free(x) free(x)
#define g_new(x,y) (guchar *)malloc(y * sizeof(x))



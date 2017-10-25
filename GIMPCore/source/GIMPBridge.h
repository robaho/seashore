#include <string.h>
#include <math.h>
#include <stdlib.h>

#ifndef GIMPBRIDGE_H
#define GIMPBRIDGE_H

typedef unsigned char guchar;
typedef char gchar;
typedef unsigned int guint;
typedef unsigned int guint32;
typedef int gint;
typedef char gboolean;
typedef float gfloat;
typedef double gdouble;
typedef void *gpointer;
typedef unsigned long gulong;

#define g_assert_not_reached()
#define g_malloc(x) malloc(x)
#define g_free(x) free(x)
#define g_new(x,y) malloc((y) * sizeof(x))
#define g_new0(x,y) calloc(y, sizeof(x))
#define FALSE 0
#define TRUE 1
#define RINT(x) rint(x)
#define ROUND(x) ((int) ((x) + 0.5))
#define SQR(x) ((x) * (x))
#define ABS(x) (((x) < 0) ? (x * -1) : (x))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define CLAMP(x, y, z) ((x) < (y) ? (y) : ((x) > (z) ? (z) : (x)))
#define g_return_val_if_fail(test, val) if (test) { return val; }
#define g_return_if_fail(test) if (test) { return; }
#define G_PI 3.14159265358979323846
#define G_PI_2  1.57079632679489661923
#define MAX_CHANNELS 4

#endif
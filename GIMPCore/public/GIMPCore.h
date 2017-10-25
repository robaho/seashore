/*
	GIMPCore -- a framework featuring various useful functions of the GIMP
	Copyright (c) 1995 Spencer Kimball and Peter Mattis
	Copyright (c) 2003 Mark Pazolli
	Copyright (c) 2004 Andreas Schiffler
	
	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef GIMPCORE_H
#define GIMPCORE_H

#ifndef INTRECT_T
#define INTRECT_T
typedef struct { int x; int y; } IntPoint;
typedef struct { int width; int height; } IntSize;
typedef struct { IntPoint origin; IntSize size; } IntRect;
#endif /* INTRECT_T */

typedef enum {
  GIMP_INTERPOLATION_NONE, 		/* Specifies no interpolation. */
  GIMP_INTERPOLATION_LINEAR, 	/* Specifies lower-quality but faster linear interpolation. */
  GIMP_INTERPOLATION_CUBIC		/* Specifies high-quality cubic interpolation */
} GimpInterpolationType;

typedef enum {
  GIMP_GRADIENT_LINEAR,                /* Specifies linear gradient */
  GIMP_GRADIENT_BILINEAR,              /* Specifies bi-linear gradient */
  GIMP_GRADIENT_RADIAL,                /* Specifies radial gradient */
  GIMP_GRADIENT_SQUARE,                /* Specifies square gradient */
  GIMP_GRADIENT_CONICAL_SYMMETRIC,     /* Specifies conical (symmetric) gradient */
  GIMP_GRADIENT_CONICAL_ASYMMETRIC,    /* Specifies conical (asymmetric) gradient */
  GIMP_GRADIENT_SHAPEBURST_ANGULAR,    /* Specifies shapeburst (angular) gradient (NYI)*/
  GIMP_GRADIENT_SHAPEBURST_SPHERICAL,  /* Specifies shapeburst (spherical) gradient (NYI) */
  GIMP_GRADIENT_SHAPEBURST_DIMPLED,    /* Specifies shapeburst (dimpled) gradient (NYI) */
  GIMP_GRADIENT_SPIRAL_CLOCKWISE,      /* Specifies spiral (clockwise) gradient */
  GIMP_GRADIENT_SPIRAL_ANTICLOCKWISE   /* Specifies spiral (anticlockwise) gradient */
} GimpGradientType;

typedef enum {
  GIMP_REPEAT_NONE,       /* Specifies no repeat */
  GIMP_REPEAT_SAWTOOTH,   /* Specifies sawtooth repeat wave */
  GIMP_REPEAT_TRIANGULAR  /* Specifies triangular repeat wave */
} GimpRepeatMode;

typedef struct {
	 int gradient_type;					/* Specifies the gradient type */
	 int repeat;						/* Specifies the repeat mode */
	 unsigned int supersample;			/* Specifies whether supersampling should be used */
	 int max_depth;						/* Specifies the maximum depth for use in supersampling */
	 double threshold;					/* Specifies the threshold for use in supersampling */
	 unsigned char start_color[4];		/* Specifies the colour to start with */
	 IntPoint start;					/* Specifies the start co-ordinates */ 
	 unsigned char end_color[4];		/* Specifies the colour to end with */
	 IntPoint end;						/* Specifies the end co-ordinates */ 
} GimpGradientInfo;

typedef struct _GimpVector2 GimpVector2;

struct _GimpVector2
{
  double x, y;
};

typedef void (* ProgressFunction) (int max, int current);

/*
	GCScalePixels()
	
	Scales the pixels of the source bitmap so that they fill the destination
	bitmap using the specified interpolation style (see GCConstants).
*/
void GCScalePixels(unsigned char *dest, int destWidth, int destHeight, unsigned char *src, int srcWidth, int srcHeight, int interpolation, int spp);

/*
	GCDrawEllipse()
	
	Fills the given bitmap with an ellipse of the specified dimensions.
*/
void GCDrawEllipse(unsigned char *dest, int destWidth, int destHeight, IntRect rect, unsigned int antialiased);

/*
	GCFillGradient
	
	Fills a rectangle of the given bitmap with the given gradient.
*/
void GCFillGradient(unsigned char *dest, int destWidth, int destHeight, IntRect rect, int spp, GimpGradientInfo info, ProgressFunction progress_callback);

/*
	GCDrawPolygon
	
	Fills the given bitmap with a polygon using the provided points.
*/
void GCDrawPolygon(unsigned char *dest, int destWidth, int destHeight, GimpVector2 *points, int n, int spp);

/*
	GCRotateImage
	
	Rotates the given bitmap through the specified angle (in radians).
*/
void GCRotateImage(unsigned char **dest, int *destWidth, int *destHeight, int *destX, int *destY, unsigned char *src, int srcWidth, int srcHeight, float angle, int interpolation_type, int spp, ProgressFunction progress_callback);

#endif /* GIMPCORE_H */

#include "GIMPCore.h"
#include "GIMPBridge.h"
#include "gimpmatrix.h"

/*  Actually carry out a transformation  */
/*
TileManager *
transform_core_do (GImage          *gimage,
                   GimpDrawable    *drawable,
                   TileManager     *float_tiles,
                   gboolean         interpolation,
                   GimpMatrix3      matrix,
                   progress_func_t  progress_callback,
                   gpointer         progress_data)
{
 }
*/

/* Note: cubic function no longer clips result */
static gdouble
cubic (gdouble dx,
       gint    jm1,
       gint    j,
       gint    jp1,
       gint    jp2)
{
  gdouble result;

#if 0
  /* Equivalent to Gimp 1.1.1 and earlier - some ringing */
  result = ((( ( - jm1 + j - jp1 + jp2 ) * dx +
               ( jm1 + jm1 - j - j + jp1 - jp2 ) ) * dx +
               ( - jm1 + jp1 ) ) * dx + j );
  /* Recommended by Mitchell and Netravali - too blurred? */
  result = ((( ( - 7 * jm1 + 21 * j - 21 * jp1 + 7 * jp2 ) * dx +
               ( 15 * jm1 - 36 * j + 27 * jp1 - 6 * jp2 ) ) * dx +
               ( - 9 * jm1 + 9 * jp1 ) ) * dx + (jm1 + 16 * j + jp1) ) / 18.0;
#else

  /* Catmull-Rom - not bad */
  result = ((( ( - jm1 + 3 * j - 3 * jp1 + jp2 ) * dx +
               ( 2 * jm1 - 5 * j + 4 * jp1 - jp2 ) ) * dx +
               ( - jm1 + jp1 ) ) * dx + (j + j) ) / 2.0;

#endif

  return result;
}

typedef struct _PixelSurround
{
  guchar      *buff;
  gint         buff_size;
  gint         bpp;
  gint         w;
  gint         h;
  guchar       bg[MAX_CHANNELS];
  gint         row_stride;
} PixelSurround;

static void
pixel_surround_init (PixelSurround *ps,
		     gint           w,
		     gint           h,
			 gint			spp,
		     guchar         bg[MAX_CHANNELS])
{
  gint i;

  for (i = 0; i < MAX_CHANNELS; ++i)
    {
      ps->bg[i] = bg[i];
    }
  ps->bpp = spp;
  ps->w = w;
  ps->h = h;
  /* make sure buffer is big enough */
  ps->buff_size = w * h * spp;
  ps->buff = g_malloc (ps->buff_size);
  ps->row_stride = 0;
}

/* return a pointer to a buffer which contains all the surrounding pixels */
/* strategy: if we are in the middle of a tile, use the tile storage */
/* otherwise just copy into our own malloced buffer and return that */

static guchar *
pixel_surround_lock (PixelSurround *ps,
		     gint           x,
		     gint           y,
			 guchar         *src,
			 gint           srcWidth,
			 gint           srcHeight)
{
  gint    i, j, k;
  guchar *ptr;

  /* copy pixels, one by one */
  /* no, this is not the best way, but it's much better than before */
  ptr = ps->buff;
  for (j = y; j < y+ps->h; ++j)
    {
      for (i = x; i < x+ps->w; ++i)
	{
		if (i >= 0 && i  < srcWidth && j >= 0 && j < srcHeight) {
			for (k = 0; k < ps->bpp; k++) {
				*ptr = src[((j *srcWidth) + i) * ps->bpp + k];
				ptr++;
			}
		}
	}
    }
	
  return ps->buff;
}

static int
pixel_surround_rowstride (PixelSurround *ps)
{
  return ps->row_stride;
}

static void
pixel_surround_release (PixelSurround *ps)
{
}

static void
pixel_surround_clear (PixelSurround *ps)
{
  if (ps->buff)
    {
      g_free (ps->buff);
      ps->buff = 0;
      ps->buff_size = 0;
    }
}

/*!
	@defined	make_128(x)
	@discussion	A macro that ensures its integer argument is greater than its
				original value and divisible by 16. This is useful if the result
				is being used to allocate memory that may be subject to AltiVec
				operations which must operate on  128-bits at a time.
*/
#define make_128(x) (x + 16 - (x % 16))

#define BILINEAR(jk,j1k,jk1,j1k1,dx,dy) \
                ((1-dy) * (jk + dx * (j1k - jk)) + \
		    dy  * (jk1 + dx * (j1k1 - jk1)))

/* access interleaved pixels */
#define CUBIC_ROW(dx, row, step) \
  cubic(dx, (row)[0], (row)[step], (row)[step+step], (row)[step+step+step])
#define CUBIC_SCALED_ROW(dx, row, step, i) \
  cubic(dx, (row)[0] * (row)[i], \
            (row)[step] * (row)[step + i], \
            (row)[step+step]* (row)[step+step + i], \
            (row)[step+step+step] * (row)[step+step+step + i])

#define REF_TILE(i,x,y) \
     tsrc[i] = &(src[(y * srcWidth + x) * spp]);

void GCRotateImage(unsigned char **dest, int *destWidth, int *destHeight, int *destX, int *destY, unsigned char *src, int srcWidth, int srcHeight, float angle, int interpolation_type, int spp, ProgressFunction progress_callback)
{
  GimpMatrix3  m;
#if 0
  GimpMatrix3  im;
#endif
  gint         itx, ity;
  gint         tx1, ty1, tx2, ty2;
  gint         width, height;
  gint         alpha = spp - 1;
  gint         bytes, b;
  gint         x, y;
  gint         sx, sy;
  gint         x1, y1, x2, y2;
  gdouble      xinc, yinc, winc;
  gdouble      tx, ty, tw;
  gdouble      ttx = 0.0, tty = 0.0;
  guchar      *d;
  guchar      *tsrc[16];
  guchar       bg_col[MAX_CHANNELS];
  gint         i;
  gdouble      a_val, a_recip;
  gint         newval;
  GimpMatrix3      matrix;
  gboolean        interpolation = TRUE;
  
  PixelSurround surround;
  
  interpolation_type = GIMP_INTERPOLATION_NONE;

	bg_col[0] = bg_col[1] = 0;
	bg_col[2] = bg_col[3] = 255;

	gimp_matrix3_identity(matrix);
	matrix[0][0] = cos(angle);
	matrix[0][1] = sin(angle);
	matrix[1][0] = -sin(angle);
	matrix[1][1] = cos(angle);

  /*  turn interpolation off for simple transformations (e.g. rot90)  */
  if (gimp_matrix3_is_simple (matrix) ||
      interpolation_type == GIMP_INTERPOLATION_NONE)
    interpolation = FALSE;

#if 0
  if (transform_tool_direction () == TRANSFORM_CORRECTIVE)
    {
      /*  keep the original matrix here, so we dont need to recalculate 
	  the inverse later  */   
      gimp_matrix3_duplicate (matrix, m);
      gimp_matrix3_invert (matrix, im);
      matrix = im;
    }
  else
    {
#endif	
      /*  Find the inverse of the transformation matrix  */
      gimp_matrix3_invert (matrix, m);
#if 0
    }
#endif

  x1 = 0;
  y1 = 0;
  x2 = srcWidth;
  y2 = srcHeight;

  /*  Find the bounding coordinates  */
  {
      gdouble dx1, dy1, dx2, dy2, dx3, dy3, dx4, dy4;

      gimp_matrix3_transform_point (matrix, x1, y1, &dx1, &dy1);
      gimp_matrix3_transform_point (matrix, x2, y1, &dx2, &dy2);
      gimp_matrix3_transform_point (matrix, x1, y2, &dx3, &dy3);
      gimp_matrix3_transform_point (matrix, x2, y2, &dx4, &dy4);

      tx1 = MIN (dx1, dx2);
      tx1 = MIN (tx1, dx3);
      tx1 = MIN (tx1, dx4);
      ty1 = MIN (dy1, dy2);
      ty1 = MIN (ty1, dy3);
      ty1 = MIN (ty1, dy4);
      tx2 = MAX (dx1, dx2);
      tx2 = MAX (tx2, dx3);
      tx2 = MAX (tx2, dx4);
      ty2 = MAX (dy1, dy2);
      ty2 = MAX (ty2, dy3);
      ty2 = MAX (ty2, dy4);
    }

  /*  Get the new temporary buffer for the transformed result  */
  *dest = malloc(make_128((tx2 - tx1)  * (ty2 - ty1) * spp));
  *destWidth = tx2 - tx1;
  *destHeight = ty2 - ty1;
  *destX = tx1;
  *destY = ty1;
  
  /* initialise the pixel_surround accessor */
  if (interpolation)
    {
      if (interpolation_type == GIMP_INTERPOLATION_CUBIC)
	{
	  pixel_surround_init (&surround, 4, 4, spp, bg_col);
	}
      else
	{
	  pixel_surround_init (&surround, 2, 2, spp, bg_col);
	}
    }
  else
    {
      /* not actually useful, keeps the code cleaner */
      pixel_surround_init (&surround, 1, 1, spp, bg_col);
    }

  width  = *destWidth;
  height = *destHeight;
  bytes  = spp;
  
  xinc = m[0][0];
  yinc = m[1][0];
  winc = m[2][0];

  /* these loops could be rearranged, depending on which bit of code
   * you'd most like to write more than once.
   */

  for (y = ty1; y < ty2; y++)
    {
      if (progress_callback)
	(* progress_callback) (y, ABS(ty2 - ty1));

      /* set up inverse transform steps */
      tx = xinc * (tx1 + 0.5) + m[0][1] * (y + 0.5) + m[0][2] - 0.5;
      ty = yinc * (tx1 + 0.5) + m[1][1] * (y + 0.5) + m[1][2] - 0.5;
      tw = winc * (tx1 + 0.5) + m[2][1] * (y + 0.5) + m[2][2];

      d = *dest + width * y * spp;
      for (x = tx1; x < tx2; x++)
	{
	  /*  normalize homogeneous coords  */
	  if (tw == 1.0)
	    {
	      ttx = tx;
	      tty = ty;
	    }
	  else if (tw != 0.0)
	    {
	      ttx = tx / tw;
	      tty = ty / tw;
	    }
	  else
	    {
	     // g_warning ("homogeneous coordinate = 0...\n");
	    }

          /*  Set the destination pixels  */

          if (interpolation)
       	    {
			              if (interpolation_type == GIMP_INTERPOLATION_CUBIC)
       	        {
                  /*  ttx & tty are the subpixel coordinates of the point in
		   *  the original selection's floating buffer.
		   *  We need the four integer pixel coords around them:
		   *  itx to itx + 3, ity to ity + 3
                   */
                  itx = RINT (ttx);
                  ity = RINT (tty);

		  /* check if any part of our region overlaps the buffer */

                  if ((itx + 2) >= x1 && (itx - 1) < x2 &&
                      (ity + 2) >= y1 && (ity - 1) < y2 )
                    {
                      guchar  *data;
                      gint     row;
                      gdouble  dx, dy;
                      guchar  *start;

		      /* lock the pixel surround */
                      data = pixel_surround_lock (&surround,
						  itx - 1 - x1, ity - 1 - y1, src, srcWidth, srcHeight);

                      row = pixel_surround_rowstride (&surround);

                      /* the fractional error */
                      dx = ttx - itx;
                      dy = tty - ity;

		      /* calculate alpha of result */
		      start = &data[alpha];
		      a_val = cubic (dy,
				     CUBIC_ROW (dx, start, bytes),
				     CUBIC_ROW (dx, start + row, bytes),
				     CUBIC_ROW (dx, start + row + row, bytes),
				     CUBIC_ROW (dx, start + row + row + row, bytes));

		      if (a_val <= 0.0)
			{
			  a_recip = 0.0;
			  d[alpha] = 0;
			}
		      else if (a_val > 255.0)
			{
			  a_recip = 1.0 / a_val;
			  d[alpha] = 255;
			}
		      else
			{
			  a_recip = 1.0 / a_val;
			  d[alpha] = RINT(a_val);
			}

		      /*  for colour channels c,
		       *  result = bicubic (c * alpha) / bicubic (alpha)
		       *
		       *  never entered for alpha == 0
		       */
		      for (i = -alpha; i < 0; ++i)
			{
			  start = &data[alpha];
			  newval =
			    RINT (a_recip *
				  cubic (dy,
					 CUBIC_SCALED_ROW (dx, start, bytes, i),
					 CUBIC_SCALED_ROW (dx, start + row, bytes, i),
					 CUBIC_SCALED_ROW (dx, start + row + row, bytes, i),
					 CUBIC_SCALED_ROW (dx, start + row + row + row, bytes, i)));
			  if (newval <= 0)
			    {
			      *d++ = 0;
			    }
			  else if (newval > 255)
			    {
			      *d++ = 255;
			    }
			  else
			    {
			      *d++ = newval;
			    }
			}

		      /*  alpha already done  */
		      d++;

		      pixel_surround_release (&surround);
		    }
                  else /* not in source range */
                    {
                      /*  increment the destination pointers  */
                      for (b = 0; b < bytes; b++)
                        *d++ = bg_col[b];
                    }
                }

       	      else  /*  linear  */
                {
                  itx = RINT (ttx);
                  ity = RINT (tty);

		  /*  expand source area to cover interpolation region
		   *  (which runs from itx to itx + 1, same in y)
		   */
                  if ((itx + 1) >= x1 && itx < x2 &&
                      (ity + 1) >= y1 && ity < y2 )
                    {
                      guchar  *data;
                      gint     row;
                      double   dx, dy;
                      guchar  *chan;

		      /* lock the pixel surround */
                      data = pixel_surround_lock (&surround, itx - x1, ity - y1, src, srcWidth, srcHeight);

                      row = pixel_surround_rowstride (&surround);

                      /* the fractional error */
                      dx = ttx - itx;
                      dy = tty - ity;

		      /* calculate alpha value of result pixel */
		      chan = &data[alpha];
		      a_val = BILINEAR (chan[0], chan[bytes], chan[row],
					chan[row+bytes], dx, dy);
		      if (a_val <= 0.0)
			{
			  a_recip = 0.0;
			  d[alpha] = 0.0;
			}
		      else if (a_val >= 255.0)
			{
			  a_recip = 1.0 / a_val;
			  d[alpha] = 255;
			}
		      else
			{
			  a_recip = 1.0 / a_val;
			  d[alpha] = RINT (a_val);
			}

		      /*  for colour channels c,
		       *  result = bilinear (c * alpha) / bilinear (alpha)
		       *
		       *  never entered for alpha == 0
		       */
		      for (i = -alpha; i < 0; ++i)
			{
			  chan = &data[alpha];
			  newval =
			    RINT (a_recip * 
				  BILINEAR (chan[0] * chan[i],
					    chan[bytes] * chan[bytes+i],
					    chan[row] * chan[row+i],
					    chan[row+bytes] * chan[row+bytes+i],
					    dx, dy));
			  if (newval <= 0)
			    {
			      *d++ = 0;
			    }
			  else if (newval > 255)
			    {
			      *d++ = 255;
			    }
			  else
			    {
			      *d++ = newval;
			    }
			}

		      /*  alpha already done  */
		      d++;

                      pixel_surround_release (&surround);
		    }

                  else /* not in source range */
                    {
                      /*  increment the destination pointers  */
                      for (b = 0; b < bytes; b++)
                        *d++ = bg_col[b];
                    }
		}
	    }
          else  /*  no interpolation  */
            {
              itx = RINT (ttx);
              ity = RINT (tty);

              if (itx >= x1 && itx < x2 &&
                  ity >= y1 && ity < y2 )
                {
                  /*  x, y coordinates into source tiles  */
                  sx = itx - x1;
                  sy = ity - y1;

                  REF_TILE (0, sx, sy);
                  for (b = 0; b < bytes; b++)
                    *d++ = tsrc[0][b];

#if 0
                  tile_release (tile[0], FALSE);
#endif
		}
              else /* not in source range */
                {
                  /*  increment the destination pointers  */
                  for (b = 0; b < bytes; b++)
                    *d++ = bg_col[b];
                }
	    }
	  /*  increment the transformed coordinates  */
	  tx += xinc;
	  ty += yinc;
	  tw += winc;
	}

      /*  set the pixel region row  */
     // pixel_region_set_row (&destPR, 0, (y - ty1), width, dest);
    }

  pixel_surround_clear (&surround);
}


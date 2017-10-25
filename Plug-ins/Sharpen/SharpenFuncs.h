/*!
	@header		SharpenFuncs
	@abstract	Functions copied directly from sharpen.c in the GIMP.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli and
				Copyright (c) 1997-1998 Michael Sweet
*/

typedef int intneg;
typedef int intpos;

intneg neg_lut[256];   /* Negative coefficient LUT */
intpos pos_lut[256];   /* Positive coefficient LUT */

int extent;

#define CLAMP0255(x) ((x) > 255 ? 255 : ((x) < 0 ? 0 : (x)))
#define guchar unsigned char

static inline void
compute_luts (int extent)
{
  int i;       /* Looping var */
  int fact;    /* 1 - sharpness */

  fact = 100 - extent;
  if (fact < 1)
    fact = 1;

  for (i = 0; i < 256; i ++)
    {
      pos_lut[i] = 800 * i / fact;
      neg_lut[i] = (4 + pos_lut[i] - (i << 3)) >> 3;
    }
}

void
graya_filter (int   width,     /* I - Width of line in pixels */
              guchar *src,      /* I - Source line */
              guchar *dst,      /* O - Destination line */
              intneg *neg0,     /* I - Top negative coefficient line */
              intneg *neg1,     /* I - Middle negative coefficient line */
              intneg *neg2)     /* I - Bottom negative coefficient line */
{
  intpos pixel;         /* New pixel value */

  *dst++ = *src++;
  *dst++ = *src++;
  width -= 2;

  while (width > 0)
    {
      pixel = (pos_lut[*src++] - neg0[-2] - neg0[0] - neg0[2] -
               neg1[-2] - neg1[2] -
               neg2[-2] - neg2[0] - neg2[2]);
      pixel = (pixel + 4) >> 3;
      *dst++ = CLAMP0255 (pixel);

      *dst++ = *src++;
      neg0 += 2;
      neg1 += 2;
      neg2 += 2;
      width --;
    }

  *dst++ = *src++;
  *dst++ = *src++;
}

void
rgba_filter (int   width,      /* I - Width of line in pixels */
             guchar *src,       /* I - Source line */
             guchar *dst,       /* O - Destination line */
             intneg *neg0,      /* I - Top negative coefficient line */
             intneg *neg1,      /* I - Middle negative coefficient line */
             intneg *neg2)      /* I - Bottom negative coefficient line */
{
  intpos pixel;         /* New pixel value */

  *dst++ = *src++;
  *dst++ = *src++;
  *dst++ = *src++;
  *dst++ = *src++;
  width -= 2;

  while (width > 0)
    {
      pixel = (pos_lut[*src++] - neg0[-4] - neg0[0] - neg0[4] -
               neg1[-4] - neg1[4] -
               neg2[-4] - neg2[0] - neg2[4]);
      pixel = (pixel + 4) >> 3;
      *dst++ = CLAMP0255 (pixel);

      pixel = (pos_lut[*src++] - neg0[-3] - neg0[1] - neg0[5] -
               neg1[-3] - neg1[5] -
               neg2[-3] - neg2[1] - neg2[5]);
      pixel = (pixel + 4) >> 3;
      *dst++ = CLAMP0255 (pixel);

      pixel = (pos_lut[*src++] - neg0[-2] - neg0[2] - neg0[6] -
               neg1[-2] - neg1[6] -
               neg2[-2] - neg2[2] - neg2[6]);
      pixel = (pixel + 4) >> 3;
      *dst++ = CLAMP0255 (pixel);

      *dst++ = *src++;

      neg0 += 4;
      neg1 += 4;
      neg2 += 4;
      width --;
    }

  *dst++ = *src++;
  *dst++ = *src++;
  *dst++ = *src++;
  *dst++ = *src++;
}



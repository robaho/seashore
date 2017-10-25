/*!
	@header		GaussianFuncs
	@abstract	Functions copied directly from gauss.c in the GIMP.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#define G_PI 3.14159265358979323846

typedef enum
{
  BLUR_IIR,
  BLUR_RLE
} BlurMethod;

static inline void
find_constants (double n_p[],
                double n_m[],
                double d_p[],
                double d_m[],
                double bd_p[],
                double bd_m[],
                double std_dev)
{
  int    i;
  double constants [8];
  double div;

  /*  The constants used in the implemenation of a casual sequence
   *  using a 4th order approximation of the gaussian operator
   */

  div = sqrt(2 * G_PI) * std_dev;
  constants [0] = -1.783 / std_dev;
  constants [1] = -1.723 / std_dev;
  constants [2] = 0.6318 / std_dev;
  constants [3] = 1.997  / std_dev;
  constants [4] = 1.6803 / div;
  constants [5] = 3.735 / div;
  constants [6] = -0.6803 / div;
  constants [7] = -0.2598 / div;

  n_p [0] = constants[4] + constants[6];
  n_p [1] = exp (constants[1]) *
    (constants[7] * sin (constants[3]) -
     (constants[6] + 2 * constants[4]) * cos (constants[3])) +
       exp (constants[0]) *
         (constants[5] * sin (constants[2]) -
          (2 * constants[6] + constants[4]) * cos (constants[2]));
  n_p [2] = 2 * exp (constants[0] + constants[1]) *
    ((constants[4] + constants[6]) * cos (constants[3]) * cos (constants[2]) -
     constants[5] * cos (constants[3]) * sin (constants[2]) -
     constants[7] * cos (constants[2]) * sin (constants[3])) +
       constants[6] * exp (2 * constants[0]) +
         constants[4] * exp (2 * constants[1]);
  n_p [3] = exp (constants[1] + 2 * constants[0]) *
    (constants[7] * sin (constants[3]) - constants[6] * cos (constants[3])) +
      exp (constants[0] + 2 * constants[1]) *
        (constants[5] * sin (constants[2]) - constants[4] * cos (constants[2]));
  n_p [4] = 0.0;

  d_p [0] = 0.0;
  d_p [1] = -2 * exp (constants[1]) * cos (constants[3]) -
    2 * exp (constants[0]) * cos (constants[2]);
  d_p [2] = 4 * cos (constants[3]) * cos (constants[2]) * exp (constants[0] + constants[1]) +
    exp (2 * constants[1]) + exp (2 * constants[0]);
  d_p [3] = -2 * cos (constants[2]) * exp (constants[0] + 2 * constants[1]) -
    2 * cos (constants[3]) * exp (constants[1] + 2 * constants[0]);
  d_p [4] = exp (2 * constants[0] + 2 * constants[1]);

  for (i = 0; i <= 4; i++)
    d_m [i] = d_p [i];

  n_m[0] = 0.0;
  for (i = 1; i <= 4; i++)
    n_m [i] = n_p[i] - d_p[i] * n_p[0];

  {
    double sum_n_p, sum_n_m, sum_d;
    double a, b;

    sum_n_p = 0.0;
    sum_n_m = 0.0;
    sum_d = 0.0;
    for (i = 0; i <= 4; i++)
      {
        sum_n_p += n_p[i];
        sum_n_m += n_m[i];
        sum_d += d_p[i];
      }

    a = sum_n_p / (1.0 + sum_d);
    b = sum_n_m / (1.0 + sum_d);

    for (i = 0; i <= 4; i++)
      {
        bd_p[i] = d_p[i] * a;
        bd_m[i] = d_m[i] * b;
      }
  }
}

static inline int *
make_curve (double  sigma,
            int    *length)
{
  int    *curve;
  double  sigma2;
  double  l;
  int     temp;
  int     i, n;

  sigma2 = 2 * sigma * sigma;
  l = sqrt (-sigma2 * log (1.0 / 255.0));

  n = ceil (l) * 2;
  if ((n % 2) == 0)
    n += 1;

  curve = malloc (sizeof(int) * n);

  *length = n / 2;
  curve += *length;
  curve[0] = 255;

  for (i = 1; i <= *length; i++)
    {
      temp = (int) (exp (- (i * i) / sigma2) * 255);
      curve[-i] = temp;
      curve[i] = temp;
    }

  return curve;
}

static inline void
run_length_encode (unsigned char *src,
                   int   *dest,
                   int    bytes,
                   int    width)
{
  int   start;
  int   i;
  int   j;
  unsigned char last;

  last = *src;
  src += bytes;
  start = 0;

  for (i = 1; i < width; i++)
    {
      if (*src != last)
        {
          for (j = start; j < i; j++)
            {
              *dest++ = (i - j);
              *dest++ = last;
            }
          start = i;
          last = *src;
        }
      src += bytes;
    }

  for (j = start; j < i; j++)
    {
      *dest++ = (i - j);
      *dest++ = last;
    }
}

static inline void
transfer_pixels (double *src1,
                 double *src2,
                 unsigned char  *dest,
                 int     bytes,
                 int     width)
{
  int    b;
  int    bend = bytes * width;
  double sum;

  for(b = 0; b < bend; b++)
    {
      sum = *src1++ + *src2++;
      if (sum > 255) sum = 255;
      else if(sum < 0) sum = 0;

      *dest++ = (unsigned char) sum;
    }
}

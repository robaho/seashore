#import "SeaBrush.h"

#define KERNEL_HEIGHT 3
#define KERNEL_WIDTH 3

static const int subsample[5][5][9] =
{
  {
    {  64,  64,   0,  64,  64,   0,   0,   0,   0, },
    {  25, 102,   0,  25, 102,   0,   0,   0,   0, },
    {   0, 128,   0,   0, 128,   0,   0,   0,   0, },
    {   0, 102,  25,   0, 102,  25,   0,   0,   0, },
    {   0,  64,  64,   0,  64,  64,   0,   0,   0, } 
  },
  {
    {  25,  25,   0, 102, 102,   0,   0,   0,   0, },
    {   6,  43,   0,  43, 162,   0,   0,   0,   0, },
    {   0,  50,   0,   0, 205,   0,   0,   0,   0, },
    {   0,  43,   6,   0, 162,  43,   0,   0,   0, },
    {   0,  25,  25,   0, 102, 102,   0,   0,   0, } 
  },
  {
    {   0,   0,   0, 128, 128,   0,   0,   0,   0, },
    {   0,   0,   0,  50, 205,   0,   0,   0,   0, },
    {   0,   0,   0,   0, 256,   0,   0,   0,   0, },
    {   0,   0,   0,   0, 205,  50,   0,   0,   0, },
    {   0,   0,   0,   0, 128, 128,   0,   0,   0, } 
  },
  {
    {   0,   0,   0, 102, 102,   0,  25,  25,   0, },
    {   0,   0,   0,  43, 162,   0,   6,  43,   0, },
    {   0,   0,   0,   0, 205,   0,   0,  50,   0, },
    {   0,   0,   0,   0, 162,  43,   0,  43,   6, },
    {   0,   0,   0,   0, 102, 102,   0,  25,  25, } 
  },
  {
    {   0,   0,   0,  64,  64,   0,  64,  64,   0, },
    {   0,   0,   0,  25, 102,   0,  25, 102,   0, },
    {   0,   0,   0,   0, 128,   0,   0, 128,   0, },
    {   0,   0,   0,   0, 102,  25,   0, 102,  25, },
    {   0,   0,   0,   0,  64,  64,   0,  64,  64, } 
  } 
};

void determineBrushMask(unsigned char *input, unsigned char *output, int width, int height, int index1, int index2)
{
	const int *kernel;
	unsigned char *m = input;
	unsigned char *d = output;
	const int *k;
	int new_val, i, j, r, s;

	// Clear the output
	memset(output, 0, (width + 2) * (height + 2));
	
	// Determine the kernel
	kernel = subsample[index2][index1];
	
	// Work out the brush mask
	for (j = 0; j < height; j++) {
		for (i = 0; i < width; i++) {
			k = kernel;
			for (r = 0; r < KERNEL_HEIGHT; r++) {
				d = output + (j+r) * (width + 2) + i;
				s = KERNEL_WIDTH;
				while (s--) {
					new_val = *d + ((*m * *k++ + 128) >> 8);
					*d++ = MIN (new_val, 255);
				}
			}
			m++;
		}
	}
}

void arrangePixels(unsigned char *dest, int destWidth, int destHeight, unsigned char *src, int srcWidth, int srcHeight)
{
	int i, j, xoff, yoff;
	
	memset(dest, 0, destWidth * destHeight);
	xoff = (destWidth / 2) - (srcWidth / 2);
	yoff = (destHeight / 2) - (srcHeight / 2);
	for (j = 0; j < srcHeight; j++) {
		for (i = 0; i < srcWidth; i++) {
			dest[(j + yoff) * destWidth + (i + xoff)] = src[j * srcWidth + i];
		}
	}
}


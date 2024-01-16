/*
round - round file to size

MIT License

Copyright (c) 2023 Bernd Boeckmann

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFFERSIZE 8192

unsigned char buffer[BUFFERSIZE];

int main( int argc, char *argv[] )
{
   FILE *inf, *outf;
   int result = EXIT_SUCCESS;
   int boundary = 0, blocksize;
   unsigned long processed = 0;

   if ( argc != 4 ) {
      puts( "Usage: round input.bin output.sys boundary");
      result = EXIT_FAILURE;
      goto ret0;
   }

   /* parse boundary first, must be nonzero, positive, and a power of 2 */
   boundary = atoi(argv[3]);
   if (boundary == 0 || boundary < 0 || (boundary & (boundary - 1)) != 0) {
      puts( "error in specified boundary!" );
      result = EXIT_FAILURE;
      goto ret0;
   }

   /* open input and output files */
   inf = fopen( argv[1], "rb" );
   if ( !inf ) {
      puts( "error opening file to read!" );
      result = EXIT_FAILURE;
      goto ret0;

   }
   outf = fopen( argv[2], "wb" );
   if ( !outf ) {
      puts( "error opening file to write!" );
      result = EXIT_FAILURE;
      goto ret1;
   }

   /* copy all data from input file */
   while ( !feof( inf ) ) {
      blocksize = fread( buffer, 1, BUFFERSIZE, inf );
      if ( fwrite( buffer, 1, blocksize, outf ) != blocksize ) {
         puts( "error writing to file!" );
         result = EXIT_FAILURE;
         goto ret2;
      }
      /* keep track of file size */
      processed += blocksize;
      if ( processed < blocksize ) {
         puts( "file size overflow!" );
         result = EXIT_FAILURE;
         goto ret2;
      }
   }

   /* fill buffer with zeroes */
   for ( blocksize = 0; blocksize < BUFFERSIZE; ++ blocksize ) {
      buffer[blocksize] = 0;
   }

   /* align processed to boundary */
   processed &= (boundary - 1);		/* mod */
   processed = boundary - processed;
   processed &= (boundary - 1);		/* mod */

   while ( processed ) {
      /* set size to write next */
      blocksize = processed;
      if ( blocksize > BUFFERSIZE ) {
         blocksize = BUFFERSIZE;
      }
      /* write padding */
      if ( fwrite( buffer, 1, blocksize, outf ) != blocksize ) {
         puts( "error writing to file!" );
         result = EXIT_FAILURE;
         goto ret2;
      }
      /* keep track of how much padding still to write */
      processed -= blocksize;
   }

   ret2:
   fclose( outf );
   ret1:
   fclose( inf );
   ret0:
   return result;
}

/*
COMPBDOS - a re-implementation of COMPBDOS.EXE of EDR-DOS LTOOLS

MIT License

Copyright (c) 2024 Bernd Boeckmann

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


/*
The uncompressed DRDOS.SYS starts with a padding area consisting of zeroes.
The first word of the file specifies the size of this area. The padding
area is followed by a header (defined in DRDOS\HEADER.A86), containing
information if the DOS is compressed and the size of the code area etc..

First job of COMPBDOS is to strip the padding area. It then copies the code
area uncompressed, after determine its size from the header.

After copying the uncompressed code area, the data area is zero-compressed.

The original COMPBDOS appends copyright info to the DRDOS.SYS. This
re-implementation does not do this.

This is how the zero-compression works:

COMPBDOS encodes regions of zero as a 16-bit count with the highest bit set
to one. So, if 16 zeroes are encoded this becomes 0x8010. Data regions that
are to be copied literally are preceeded by the 16-bit byte count, with
the highest bit cleared. So 32 bytes to be copied are encoded as 0x0020
followed by the actual bytes. The end of the compressed region is encoded by
0x0000.

The DRDOS.SYS decompression is implemented in dos_reloc in DRBIO\BIOSINIT.ASM.
*/


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#ifdef __FAR
 #include <libi86/malloc.h>
 #define farkeyword __far
 #define farmemcpy _fmemcpy
 #define farfree _ffree
#else
 #define farkeyword
 #define farmemcpy memcpy
 #define farfree free
#endif

#include "zerocomp.h"

#define CODE_SIZE_OFFSET 0x1e  /* location in input file holding the start
                                of the BDOS data area to be compressed,
                                without padding! */
#define COMP_FLAG_OFFSET 0x1c



int main( int argc, char *argv[] )
{
   farkeyword char *in_data, *in_ptr;
   char *out_data, *out_ptr;
   size_t in_size, out_size;
   uint16_t padding;
   uint16_t comp_start;

   if ( argc != 3 ) {
      puts( "Usage: COMPBDOS.EXE in-file out-file" );
      return 1;
   }

   in_data = in_ptr = read_file( argv[1], &in_size );
   if ( !in_data ) {
      puts( "error: can not read input file" );
      return 1;
   }

   /* number of padding bytes to be skipped */
   padding = *(farkeyword uint16_t*)in_data;
   in_ptr += padding;
   in_size -= padding;

   /* get offset of data area to be compressed */
   comp_start = *(farkeyword uint16_t*)(in_ptr + CODE_SIZE_OFFSET);
   /*printf( "start compressing at %04x\n", comp_start );*/

   /* mark file as compressed */
   in_ptr[COMP_FLAG_OFFSET] = 1; 

   out_data = out_ptr = malloc( in_size );
   if ( !out_data ) {
      puts( "allocation error" );
      return 1;
   }

   /* copy uncompressed part of file */
   farmemcpy( out_ptr, in_ptr, comp_start );

   /* zero-compress file... */
   in_ptr += comp_start;
   out_ptr += comp_start;
   zerocomp( in_ptr, in_size - comp_start, out_ptr, &out_size, 1 );
   /*printf( "in-size: %zu, out-size: %zu\n ", in_size - comp_start, out_size );*/
   
   /* ...and write everything to output file */
   if ( !write_file( argv[2], out_data, comp_start + out_size ) ) {
      puts( "error: could not write output file" );
      free( out_data );
      farfree( in_data );
      return 1;
   }

   free( out_data );
   farfree( in_data );
   return 0;
}


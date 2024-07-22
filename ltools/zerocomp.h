#ifndef ZEROCOMP_H
#define ZEROCOMP_H

void zerocomp( farkeyword char *data, size_t data_len, char *out, size_t *out_len, int terminate );
farkeyword char * read_file( const char *fn, size_t *size );
int write_file( const char *fn, const char *data, size_t size );
int write_file_multiple( const char *fn, const char **data, size_t *size, int num );

#define ZERO_THRESHOLD 5

/* encodes a single block of either non-zero data or zeroes. Up to 
   ZERO_THRESHOLD consecutive zeroes are allowed in non-zero data blocks.
   Block size is restricted to 0x7fff bytes. */
static void zerocomp_block( farkeyword char **in, farkeyword char *eof, char **out )
{
   farkeyword char *data = *in;
   size_t len;
   uint16_t count = 0, zero_count = 0;
   farkeyword char *last_non_zero = NULL;
   char *outp = *out;

   if ( data >= eof ) return;

   while ( data < eof && count <= 0x7fff ) {
      if ( *data ) {
         if ( zero_count >= ZERO_THRESHOLD ) {
            break;
         }
         last_non_zero = data;
         zero_count = 0;

      }
      else {
         /* zero encountered */
         zero_count++;
         if ( zero_count >= ZERO_THRESHOLD && last_non_zero ) {
            data = last_non_zero + 1;
            break;
         }
      }
      data++;
      count++;
   }

   len = data - *in;

   if ( last_non_zero ) {
      /*printf( "NON-ZERO: %04tX\n", len );*/
      *(uint16_t*)outp = len;
      outp += 2;
      farmemcpy( outp, *in, len);
      outp += len;
   }
   else {
      /*printf( "ZERO    : %04tX\n", 0x8000 | len );*/
      *(uint16_t*)outp = 0x8000 | len;
      outp+=2;
   }

   *out = outp;
   *in = data;
}


void zerocomp( farkeyword char *data, size_t data_len, char *out, size_t *out_len, int terminate )
{
   farkeyword char *eof = data + data_len;
   farkeyword char *end = eof;
   char *outp = out;

   /* Optimization: scan for trailing zeroes. Three or four trailing zeroes
      may be encoded more efficiently as RLE compared to when included in
      the last non-zero block

      Not actually useful for DRBIOS, but for the future...
   */
   while ( ( --end >= data ) && !*end );
   end++;
   if ( eof - end < 3 ) end = eof;

   /* compress blocks of either zero or non-zero data */
   while ( data < end ) {
      zerocomp_block( &data, end, &outp );
   }
   zerocomp_block( &end, eof, &outp );

   /* terminate with 0x0000 to indicate no further data */
   if ( terminate ) {
      *outp++ = 0;
      *outp++ = 0;
   }

   *out_len = outp - out;
}


farkeyword char * read_file( const char *fn, size_t *size )
{
   FILE *f;
   char *nearbuf;
#ifdef __FAR
   farkeyword char *farbuf;
#endif

   f = fopen( fn, "rb" );
   if ( !f ) {
      return NULL;
   }

   fseek( f, 0, SEEK_END );
   *size = ftell( f );
   nearbuf = malloc( *size );
   if ( !nearbuf ) {
      fclose( f );
      return NULL;
   }
#ifdef __FAR
   farbuf = _fmalloc( *size );
   if ( !farbuf ) {
      free( nearbuf );
      fclose( f );
      return NULL;
   }
#endif
   fseek( f, 0, SEEK_SET );

   if ( fread( nearbuf, 1, *size, f ) != *size ) {
      free( nearbuf );
#ifdef __FAR
      farfree( farbuf );
#endif
      fclose( f );
      return NULL;
   }

#ifdef __FAR
   farmemcpy( farbuf, nearbuf, *size );
   free( nearbuf );
#endif

   fclose( f );
#ifdef __FAR
   return farbuf;
#else
   return nearbuf;
#endif
}


int write_file( const char *fn, const char *data, size_t size )
{
   FILE *f;

   f = fopen( fn, "wb" );
   if ( !f ) {
      return 0;
   }

   if ( fwrite( data, 1, size, f ) != size ) {
      fclose( f );
      return 0;
   }

   fclose( f );
   return 1;
}


/* writes multiple buffers given by **data and *size to output file */
int write_file_multiple( const char *fn, const char **data, size_t *size, int num )
{
   FILE *f;

   f = fopen( fn, "wb" );
   if ( !f ) {
      return 0;
   }

   while ( num-- ) {
      if ( fwrite( *data, 1, *size, f ) != *size ) {
         fclose( f );
         return 0;
      }
      data++;
      size++;
   }

   fclose( f );
   return 1;
}

#endif /* ZEROCOMP_H */

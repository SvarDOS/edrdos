#ifndef ZEROCOMP_H
#define ZEROCOMP_H

void zerocomp( char *data, size_t data_len, char *out, size_t *out_len );
char * read_file( const char *fn, size_t *size );
int write_file( const char *fn, const char *data, size_t size );

#define ZERO_THRESHOLD 5

/* encodes a single block of either non-zero data or zeroes. Up to 
   ZERO_THRESHOLD consecutive zeroes are allowed in non-zero data blocks.
   Block size is restricted to 0x7fff bytes. */
static void zerocomp_block( char **in, char *eof, char **out )
{
   char *data = *in;
   size_t len;
   uint16_t count = 0, zero_count = 0;
   char *last_non_zero = NULL;
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
      memcpy( outp, *in, len);
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


void zerocomp( char *data, size_t data_len, char *out, size_t *out_len )
{
   char *eof = data + data_len;
   char *end = eof;
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
   *outp++ = 0;
   *outp++ = 0;

   *out_len = outp - out;
}


char * read_file( const char *fn, size_t *size )
{
   FILE *f;
   char *buf;

   f = fopen( fn, "rb" );
   if ( !f ) {
      return NULL;
   }

   fseek( f, 0, SEEK_END );
   *size = ftell( f );
   buf = malloc( *size );
   if ( !buf ) {
      fclose( f );
      return NULL;
   }
   fseek( f, 0, SEEK_SET );

   if ( fread( buf, 1, *size, f ) != *size ) {
      free( buf );
      fclose( f );
      return NULL;
   }

   fclose( f );
   return buf;
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


#endif /* ZEROCOMP_H */


typedef struct {
   unsigned long long dword[2];
} work_t __attribute__ ((aligned (16) ));

// ===================
//  DLM-based data-structures
// ===================

//work_t dlm_st_byte_work[8] =
//       {
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA }
//       };
//
//work_t dlm_st_byte_exp[8] =
//       {    // dword0              dword1
//          { 0xAAAAAAAAAAAAAA00, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAA42AA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAA55AAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAA7FAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAFFAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAD3AAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAA96AAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0x81AAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA }
//       };
//
//work_t dlm_st_hword_work[8] =
//       {
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA }
//       };
//
//work_t dlm_st_hword_exp[8] =
//       {
//          { 0xAAAAAAAAAAAA7FFF, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAA77F0AA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAA6FE1AAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAA67D2AAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAA8000AAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAA880FAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0x901EAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0x2DAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAA98 }
//       };
//
//work_t dlm_st_word_work[8] =
//       {
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA }
//       };
//
//work_t dlm_st_word_exp[8] =
//       {
//          { 0xAAAAAAAA89ABCDEF, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAA89ABCDEFAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAA89ABCDEFAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAA89ABCDEFAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0x01234567AAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0x234567AAAAAAAAAA, 0xAAAAAAAAAAAAAA01 },
//          { 0x4567AAAAAAAAAAAA, 0xAAAAAAAAAAAA0123 },
//          { 0x67AAAAAAAAAAAAAA, 0xAAAAAAAAAA012345 }
//       };
//
//work_t dlm_st_dword_work[8] =
//       {
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
//          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA }
//       };
//
//work_t dlm_st_dword_exp[8] =
//       {
//          { 0x08192A3B4C5D6E7F, 0xAAAAAAAAAAAAAAAA },
//          { 0x192A3B4C5D6E7FAA, 0xAAAAAAAAAAAAAA08 },
//          { 0x2A3B4C5D6E7FAAAA, 0xAAAAAAAAAAAA0819 },
//          { 0x3B4C5D6E7FAAAAAA, 0xAAAAAAAAAA08192A },
//          { 0x4C5D6E7FAAAAAAAA, 0xAAAAAAAA08192A3B },
//          { 0x5D6E7FAAAAAAAAAA, 0xAAAAAA08192A3B4C },
//          { 0x6E7FAAAAAAAAAAAA, 0xAAAA08192A3B4C5D },
//          { 0x7FAAAAAAAAAAAAAA, 0xAA08192A3B4C5D6E }
//       };

// ===================
//  AXIM-based data-structures
// ===================

__attribute__ ((section (".axim_data") ))
work_t axim_st_byte_work[8] =
       {
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA }
       };

__attribute__ ((section (".axim_data") ))
work_t axim_st_byte_exp[8] =
       {    // dword0              dword1
          { 0xAAAAAAAAAAAAAA00, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAA42AA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAA55AAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAA7FAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAFFAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAD3AAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAA96AAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0x81AAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA }
       };

__attribute__ ((section (".axim_data") ))
work_t axim_st_hword_work[8] =
       {
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA }
       };

__attribute__ ((section (".axim_data") ))
work_t axim_st_hword_exp[8] =
       {
          { 0xAAAAAAAAAAAA7FFF, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAA77F0AA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAA6FE1AAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAA67D2AAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAA8000AAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAA880FAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0x901EAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0x2DAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAA98 }
       };

__attribute__ ((section (".axim_data") ))
work_t axim_st_word_work[8] =
       {
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA }
       };

__attribute__ ((section (".axim_data") ))
work_t axim_st_word_exp[8] =
       {
          { 0xAAAAAAAA89ABCDEF, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAA89ABCDEFAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAA89ABCDEFAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAA89ABCDEFAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0x01234567AAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0x234567AAAAAAAAAA, 0xAAAAAAAAAAAAAA01 },
          { 0x4567AAAAAAAAAAAA, 0xAAAAAAAAAAAA0123 },
          { 0x67AAAAAAAAAAAAAA, 0xAAAAAAAAAA012345 }
       };

__attribute__ ((section (".axim_data") ))
work_t axim_st_dword_work[8] =
       {
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA },
          { 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA }
       };

__attribute__ ((section (".axim_data") ))
work_t axim_st_dword_exp[8] =
       {
          { 0x08192A3B4C5D6E7F, 0xAAAAAAAAAAAAAAAA },
          { 0x192A3B4C5D6E7FAA, 0xAAAAAAAAAAAAAA08 },
          { 0x2A3B4C5D6E7FAAAA, 0xAAAAAAAAAAAA0819 },
          { 0x3B4C5D6E7FAAAAAA, 0xAAAAAAAAAA08192A },
          { 0x4C5D6E7FAAAAAAAA, 0xAAAAAAAA08192A3B },
          { 0x5D6E7FAAAAAAAAAA, 0xAAAAAA08192A3B4C },
          { 0x6E7FAAAAAAAAAAAA, 0xAAAA08192A3B4C5D },
          { 0x7FAAAAAAAAAAAAAA, 0xAA08192A3B4C5D6E }
       };

// ===================
//  ILM-based functions
// ===================

/*

__attribute__ ((noinline))
int ilm_test_store_byte ( work_t work_area[], work_t exp_area[]) {

   bool mismatch;
   volatile unsigned char *pb;

   // eight store bytes: 00, 42, 55, 7f, 0xFF, 0xD3, 96, 0x81

   // Store bytes at 8 different alignments
   //pb = (unsigned char *) work_area[0].dword[0];
   pb = (unsigned char *) work_area;

   *pb = (unsigned char) 0x00;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0x42;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0x55;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0x7F;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0xFF;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0xD3;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0x96;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0x81;

   // check mem written by byte stores
   mismatch = false;
   for ( int i=0; i < 8; i++ ) {
      if ( work_area[i].dword[0] != exp_area[i].dword[0] ||
           work_area[i].dword[1] != exp_area[i].dword[1]    ) {
         mismatch = true;
      }
   }

   return (int) mismatch;

} // ilm_test_store_byte

__attribute__ ((noinline))
int ilm_test_store_hword ( work_t work_area[], work_t exp_area[]) {

   bool mismatch;
   volatile unsigned short *phw;
   unsigned short uhw;

   // eight store hwords: 7fff, 77f0, 6fe1, 67d2, 8000, 880f, 901E, 982D

   // Store hwords at 8 different alignments
   uhw = 0x7fff;

   //phw = (unsigned short *) &work_area[0].dword[0];
   phw = (unsigned short *) work_area;

   for ( int i=0; i < 4; i++ ) {
      *phw = uhw;
      phw  = (unsigned short *) ((unsigned char *)phw + 16 + 1);
      uhw  = uhw - 0x80f;
   }

   uhw = 0x8000;

   for ( int i=0; i < 4; i++ ) {
      *phw = uhw;
      phw  = (unsigned short *) ((unsigned char *)phw + 16 + 1);
      uhw  = uhw + 0x80f;
   }

   // check mem written by hword stores
   mismatch = false;
   for ( int i=0; i < 8; i++ ) {
      if ( work_area[i].dword[0] != exp_area[i].dword[0] ||
           work_area[i].dword[1] != exp_area[i].dword[1]    ) {
         mismatch = true;
      }
   }

   return (int) mismatch;

} // ilm_test_store_hword

__attribute__ ((noinline))
int ilm_test_store_word ( work_t work_area[], work_t exp_area[]) {

   bool mismatch;
   volatile unsigned int *pw;
   unsigned int uw;

   // Store words at 8 different alignments
   uw = 0x89ABCDEF;

   //pw = (unsigned int *) &work_area[0].dword[0];
   pw = (unsigned int *) work_area;

   for ( int i=0; i < 4; i++ ) {
      *pw = uw;
      pw  = (unsigned int *) ((unsigned char *)pw + 16 + 1);
   }

   uw = 0x01234567;

   for ( int i=0; i < 4; i++ ) {
      *pw = uw;
      pw  = (unsigned int *) ((unsigned char *)pw + 16 + 1);
   }

   // check mem written by word stores
   mismatch = false;
   for ( int i=0; i < 8; i++ ) {
      if ( work_area[i].dword[0] != exp_area[i].dword[0] ||
           work_area[i].dword[1] != exp_area[i].dword[1]    ) {
         mismatch = true;
      }
   }

   return (int) mismatch;

} // ilm_test_store_word

__attribute__ ((noinline))
int ilm_test_store_dword ( work_t work_area[], work_t exp_area[]) {

   bool mismatch;
   volatile unsigned long long *pdw;
   unsigned long long udw;

   // Store dwords at 8 different alignments
   udw = 0x08192A3B4C5D6E7F;

   //pdw = (unsigned long long *) &work_area[0].dword[0];
   pdw = (unsigned long long *) work_area;

   for ( int i=0; i < 8; i++ ) {
      *pdw = udw;
      pdw  = (unsigned long long *) ((unsigned char *)pdw + 16 + 1);
   }

   // check mem written by word stores
   mismatch = false;
   for ( int i=0; i < 8; i++ ) {
      if ( work_area[i].dword[0] != exp_area[i].dword[0] ||
           work_area[i].dword[1] != exp_area[i].dword[1]    ) {
         mismatch = true;
      }
   }

   return (int) mismatch;

} // ilm_test_store_dword

*/

// ===================
//  AXIM-based functions
// ===================

__attribute__ ((section (".axim_text") ))
__attribute__ ((noinline))
int axim_test_store_byte ( work_t work_area[], work_t exp_area[]) {

   bool mismatch;
   volatile unsigned char *pb;

   // eight store bytes: 00, 42, 55, 7f, 0xFF, 0xD3, 96, 0x81

   // Store bytes at 8 different alignments
   //pb = (unsigned char *) work_area[0].dword[0];
   pb = (unsigned char *) work_area;

   *pb = (unsigned char) 0x00;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0x42;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0x55;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0x7F;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0xFF;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0xD3;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0x96;
   pb = pb + 16 + 1;
   *pb = (unsigned char) 0x81;

   // check mem written by byte stores
   mismatch = false;
   for ( int i=0; i < 8; i++ ) {
      if ( work_area[i].dword[0] != exp_area[i].dword[0] ||
           work_area[i].dword[1] != exp_area[i].dword[1]    ) {
         mismatch = true;
      }
   }

   return (int) mismatch;

} // axim_test_store_byte

__attribute__ ((section (".axim_text") ))
__attribute__ ((noinline))
int axim_test_store_hword ( work_t work_area[], work_t exp_area[]) {

   bool mismatch;
   volatile unsigned short *phw;
   unsigned short uhw;

   // eight store hwords: 7fff, 77f0, 6fe1, 67d2, 8000, 880f, 901E, 982D

   // Store hwords at 8 different alignments
   uhw = 0x7fff;

   //phw = (unsigned short *) &work_area[0].dword[0];
   phw = (unsigned short *) work_area;

   for ( int i=0; i < 4; i++ ) {
      *phw = uhw;
      phw  = (unsigned short *) ((unsigned char *)phw + 16 + 1);
      uhw  = uhw - 0x80f;
   }

   uhw = 0x8000;

   for ( int i=0; i < 4; i++ ) {
      *phw = uhw;
      phw  = (unsigned short *) ((unsigned char *)phw + 16 + 1);
      uhw  = uhw + 0x80f;
   }

   // check mem written by hword stores
   mismatch = false;
   for ( int i=0; i < 8; i++ ) {
      if ( work_area[i].dword[0] != exp_area[i].dword[0] ||
           work_area[i].dword[1] != exp_area[i].dword[1]    ) {
         mismatch = true;
      }
   }

   return (int) mismatch;

} // axim_test_store_hword

__attribute__ ((section (".axim_text") ))
__attribute__ ((noinline))
int axim_test_store_word ( work_t work_area[], work_t exp_area[]) {

   bool mismatch;
   volatile unsigned int *pw;
   unsigned int uw;

   // Store words at 8 different alignments
   uw = 0x89ABCDEF;

   //pw = (unsigned int *) &work_area[0].dword[0];
   pw = (unsigned int *) work_area;

   for ( int i=0; i < 4; i++ ) {
      *pw = uw;
      pw  = (unsigned int *) ((unsigned char *)pw + 16 + 1);
   }

   uw = 0x01234567;

   for ( int i=0; i < 4; i++ ) {
      *pw = uw;
      pw  = (unsigned int *) ((unsigned char *)pw + 16 + 1);
   }

   // check mem written by word stores
   mismatch = false;
   for ( int i=0; i < 8; i++ ) {
      if ( work_area[i].dword[0] != exp_area[i].dword[0] ||
           work_area[i].dword[1] != exp_area[i].dword[1]    ) {
         mismatch = true;
      }
   }

   return (int) mismatch;

} // axim_test_store_word

__attribute__ ((section (".axim_text") ))
__attribute__ ((noinline))
int axim_test_store_dword ( work_t work_area[], work_t exp_area[]) {

   bool mismatch;
   volatile unsigned long long *pdw;
   unsigned long long udw;

   // Store dwords at 8 different alignments
   udw = 0x08192A3B4C5D6E7F;

   //pdw = (unsigned long long *) &work_area[0].dword[0];
   pdw = (unsigned long long *) work_area;

   for ( int i=0; i < 8; i++ ) {
      *pdw = udw;
      pdw  = (unsigned long long *) ((unsigned char *)pdw + 16 + 1);
   }

   // check mem written by word stores
   mismatch = false;
   for ( int i=0; i < 8; i++ ) {
      if ( work_area[i].dword[0] != exp_area[i].dword[0] ||
           work_area[i].dword[1] != exp_area[i].dword[1]    ) {
         mismatch = true;
      }
   }

   return (int) mismatch;

} // axim_test_store_dword

// ===================
// 
// ===================

// tbd: return failed test number

int main() {

   int mismatch;

   mismatch = 0;

   //mismatch  = ilm_test_store_byte   ( dlm_st_byte_work,   dlm_st_byte_exp  );
   //mismatch |= ilm_test_store_hword  ( dlm_st_hword_work,  dlm_st_hword_exp );
   //mismatch |= ilm_test_store_word   ( dlm_st_word_work,   dlm_st_word_exp  );
   //mismatch |= ilm_test_store_dword  ( dlm_st_dword_work,  dlm_st_dword_exp );

   //if ( mismatch != 0 ) return mismatch;

   //mismatch  = ilm_test_store_byte   ( axim_st_byte_work,  axim_st_byte_exp  );
   //mismatch |= ilm_test_store_hword  ( axim_st_hword_work, axim_st_hword_exp );
   //mismatch |= ilm_test_store_word   ( axim_st_word_work,  axim_st_word_exp  );
   //mismatch |= ilm_test_store_dword  ( axim_st_dword_work, axim_st_dword_exp );

   //if ( mismatch != 0 ) return mismatch;

   //mismatch  = axim_test_store_byte  ( dlm_st_byte_work,   dlm_st_byte_exp   );
   //mismatch |= axim_test_store_hword ( dlm_st_hword_work,  dlm_st_hword_exp  );
   //mismatch |= axim_test_store_word  ( dlm_st_word_work,   dlm_st_word_exp   );
   //mismatch |= axim_test_store_dword ( dlm_st_dword_work,  dlm_st_dword_exp  );

   //if ( mismatch != 0 ) return mismatch;

   mismatch  = axim_test_store_byte  ( axim_st_byte_work,  axim_st_byte_exp  );
   mismatch |= axim_test_store_hword ( axim_st_hword_work, axim_st_hword_exp );
   mismatch |= axim_test_store_word  ( axim_st_word_work,  axim_st_word_exp  );
   mismatch |= axim_test_store_dword ( axim_st_dword_work, axim_st_dword_exp );

   return mismatch;

} // main

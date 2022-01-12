#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define DEFAULT_LOAD_ADDR 0x6000
#define OUTPUT_FN "WORDS.BIN"

uint16_t word_lut[26][26];

int main(int argc, char **argv) {
   uint16_t addr;
   int first_letter;
   int second_letter;
   inc count;
   int letter;
   int i;
   uint8_t word_str[5];
   FILE *fpin;
   FILE *fpout;

   if (argc < 2) {
      printf("Usage: %s [input file] [load address]\n",argv[0]);
      return -1;
   }

   fpin = fopen(argv[1],"r");
   if (fpin == NULL) {
      printf("Error opening %s\n",argv[1]);
      return -1;
   }

   fpout = fopen(OUTPUT_FN,"w");
   if (fpout == NULL) {
      printf("Error opening %s\n",OUTPUT_FN);
      fclose(fpin);
      return -1;
   }

   if (argc >= 3) {
      addr = (uint16_t) atoi(argv[2]);
   } else {
      addr = DEFAULT_LOAD_ADDR;
   }

   word_str[0] = (uint8_t) (addr & 0xFF);
   word_str[1] = (uint8_t) ((addr & 0xFF00) >> 8);

   fwrite(word_str,1,2,fpout);

   for (first_letter = 0; first_letter < 26; first_letter++) {
      for (second_letter = 0; second_letter < 26; second_letter++) {
         word_lut[first_letter][second_letter] = 0;
      }
   }

   fwrite(word_lut,2,26*26,fpout);

   first_letter = -1;
   second_letter = -1;

   count = 0;
   while (!feof(fpin))) {
      if (fread(word_str,1,5,fpin) == 5) {
         for (i = 0; i < 5; i++) {
            letter = (int) (word_str[i] - 'a');
            if ((letter < 0) || (letter > 25)) {
               printf("Invalid word: %s\n",word_str);
               fclose(fpin);
               fclose(fpout);
               return -1;
            }
            if ((i == 0) && (first_letter != letter)) {
               first_letter = letter;
               second_letter = -1;
            }
            if ((i == 1) && (second_letter != letter)) {
               second_letter = letter;
               word_lut[first_letter][second_letter] = addr + 26*26*2 + (uint16_t)count*5;
            }
         }
         count++;
         fwrite(word_str,1,5,fpout);
      }
   }

   fclose(fpin);

   fseek(fpout,2,SEEK_SET);
   i = 1;
   if (*(char *)&i == 0) {
      /* convert big-endian addresses to little-endian */
      for (first_letter = 0; first_letter < 26; first_letter++) {
         for (second_letter = 0; second_letter < 26; second_letter++) {
            addr = word_lut[first_letter][second_letter];
            addr = ((addr & 0x00FF) << 8) | ((addr & 0xFF00) >> 8);
            word_lut[first_letter][second_letter] = addr;
         }
      }
   }
   fwrite(word_lut,2,26*26,fpout);
   fclose(fpout);

   return 0;
}

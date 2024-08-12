#include "obf.h"

#define LOWER_HALFBYTE(x) ((x) & 0xF)
#define UPPER_HALFBYTE(x) (((x) >> 4) & 0xF)

void deobfuscate_str(char *str, uint64_t hashValue) {
  auto *byteString = reinterpret_cast<uint8_t *>(str);
  auto *hash = reinterpret_cast<uint8_t *>(&hashValue);
  int i = 0;

  while (*byteString != 0) {
    int pos = i / 2;
    bool bottom = (i % 2) == 0;
    uint8_t *ch = byteString;
    uint8_t xr = bottom ? LOWER_HALFBYTE(hash[pos]) : UPPER_HALFBYTE(hash[pos]);

    *ch ^= xr;

    if (++i == sizeof(uint64_t) * 2) {
      i = 0;
    }

    byteString++;
  }
}

#include <cpp11.hpp>
#include <string.h>
#include <stdint.h> // uint64_t


[[cpp11::register]]
std::string cpp_base62(uint64_t value, uint64_t hundredth, int bytes) {
  
  std::string result = "";
  
  if (hundredth) {
    value = (value * 100) + hundredth;
  }
  
  for (int i = 0; i < bytes; i++) {
    char ch = value % 62;
    if      (ch < 26) { ch = ch + 97;      } // a - z
    else if (ch < 52) { ch = ch + 65 - 26; } // A - Z
    else              { ch = ch + 48 - 52; } // 0 - 9
    result = ch + result;
    value = value / 62;
  }
  
  return result;
}


[[cpp11::register]]
std::string cpp_hash(std::string str) {
  std::hash<std::string> hash_string;
  return cpp_base62(hash_string(str), 0, 11);
}

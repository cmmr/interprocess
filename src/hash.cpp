// [[Rcpp::depends(BH)]]

#include <Rcpp.h>
#include <string.h>


// [[Rcpp::export]]
std::size_t rcpp_hash(std::string str) {
  return std::hash<std::string>{}(str);
}

// [[Rcpp::depends(BH)]]

#include <Rcpp.h>
#include <boost/interprocess/sync/named_sharable_mutex.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>

using namespace boost::interprocess;
namespace pt = boost::posix_time;


/*-------------------*/
/*  CREATE / REMOVE  */
/*-------------------*/

// [[Rcpp::export]]
void rcpp_mutex_create_only(std::string name) {
  named_sharable_mutex mut(create_only_t(), name.c_str());
}

// [[Rcpp::export]]
void rcpp_mutex_open_only(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
}

// [[Rcpp::export]]
void rcpp_mutex_open_create(std::string name) {
  named_sharable_mutex mut(open_or_create_t(), name.c_str());
}


// [[Rcpp::export]]
bool rcpp_mutex_remove(std::string name) {
  return named_sharable_mutex::remove(name.c_str());
}




/*-------------------*/
/*  EXCLUSIVE LOCKS  */
/*-------------------*/

// [[Rcpp::export]]
bool rcpp_mutex_lock(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  mut.lock();
  return true;
}


// [[Rcpp::export]]
bool rcpp_mutex_try_lock(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  return mut.try_lock();
}


// [[Rcpp::export]]
bool rcpp_mutex_timed_lock(std::string name, long timeout_ms) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  pt::ptime timeout = pt::microsec_clock::universal_time() + pt::milliseconds(timeout_ms);
  return mut.timed_lock(timeout);
}


// [[Rcpp::export]]
bool rcpp_mutex_unlock(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  mut.unlock();
  return true;
}




/*-------------------*/
/*  SHARED LOCKS     */
/*-------------------*/

// [[Rcpp::export]]
bool rcpp_mutex_lock_sharable(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  mut.lock_sharable();
  return true;
}


// [[Rcpp::export]]
bool rcpp_mutex_try_lock_sharable(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  return mut.try_lock_sharable();
}


// [[Rcpp::export]]
bool rcpp_mutex_timed_lock_sharable(std::string name, long timeout_ms) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  pt::ptime timeout = pt::microsec_clock::universal_time() + pt::milliseconds(timeout_ms);
  return mut.timed_lock_sharable(timeout);
}


// [[Rcpp::export]]
bool rcpp_mutex_unlock_sharable(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  mut.unlock_sharable();
  return true;
}

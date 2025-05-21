#include <cpp11.hpp>
#include <boost/interprocess/sync/named_sharable_mutex.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>

using namespace boost::interprocess;
namespace pt = boost::posix_time;


/*-------------------*/
/*  CREATE / REMOVE  */
/*-------------------*/

[[cpp11::register]]
void cpp_mutex_create_only(std::string name) {
  named_sharable_mutex mut(create_only_t(), name.c_str());
}

[[cpp11::register]]
void cpp_mutex_open_only(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
}

[[cpp11::register]]
void cpp_mutex_open_create(std::string name) {
  named_sharable_mutex mut(open_or_create_t(), name.c_str());
}


[[cpp11::register]]
bool cpp_mutex_remove(std::string name) {
  return named_sharable_mutex::remove(name.c_str());
}




/*-------------------*/
/*  EXCLUSIVE LOCKS  */
/*-------------------*/

[[cpp11::register]]
bool cpp_mutex_lock(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  mut.lock();
  return true;
}


[[cpp11::register]]
bool cpp_mutex_try_lock(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  return mut.try_lock();
}


[[cpp11::register]]
bool cpp_mutex_timed_lock(std::string name, long timeout_ms) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  pt::ptime timeout = pt::microsec_clock::universal_time() + pt::milliseconds(timeout_ms);
  return mut.timed_lock(timeout);
}


[[cpp11::register]]
bool cpp_mutex_unlock(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  mut.unlock();
  return true;
}




/*-------------------*/
/*  SHARED LOCKS     */
/*-------------------*/

[[cpp11::register]]
bool cpp_mutex_lock_sharable(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  mut.lock_sharable();
  return true;
}


[[cpp11::register]]
bool cpp_mutex_try_lock_sharable(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  return mut.try_lock_sharable();
}


[[cpp11::register]]
bool cpp_mutex_timed_lock_sharable(std::string name, long timeout_ms) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  pt::ptime timeout = pt::microsec_clock::universal_time() + pt::milliseconds(timeout_ms);
  return mut.timed_lock_sharable(timeout);
}


[[cpp11::register]]
bool cpp_mutex_unlock_sharable(std::string name) {
  named_sharable_mutex mut(open_only_t(), name.c_str());
  mut.unlock_sharable();
  return true;
}

#include <cpp11.hpp>
#include <boost/interprocess/ipc/message_queue.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>

using namespace boost::interprocess;
namespace pt = boost::posix_time;


/*------------------*/
/*  CREATE A QUEUE  */
/*------------------*/

[[cpp11::register]]
void cpp_mq_create_only(std::string name, size_t max_num_msg, size_t max_msg_size) {
  message_queue(create_only_t(), name.c_str(), max_num_msg, max_msg_size);
}

[[cpp11::register]]
void cpp_mq_open_only(std::string name) {
  message_queue(open_only_t(), name.c_str());
}

[[cpp11::register]]
void cpp_mq_open_create(std::string name, size_t max_num_msg, size_t max_msg_size) {
  message_queue(open_or_create_t(), name.c_str(), max_num_msg, max_msg_size);
}



/*---------------------------*/
/*  ADD MESSAGES TO A QUEUE  */
/*---------------------------*/

[[cpp11::register]]
bool cpp_mq_send(std::string name, std::string msg, unsigned int priority) {
  message_queue mq(open_only_t(), name.c_str());
  mq.send(msg.data(), msg.size(), priority);
  return true;
}

[[cpp11::register]]
bool cpp_mq_try_send(std::string name, std::string msg, unsigned int priority) {
  message_queue mq(open_only_t(), name.c_str());
  return mq.try_send(msg.data(), msg.size(), priority);
}

[[cpp11::register]]
bool cpp_mq_timed_send(std::string name, std::string msg, unsigned int priority, long timeout_ms) {
  message_queue mq(open_only_t(), name.c_str());
  pt::ptime timeout = pt::microsec_clock::universal_time() + pt::milliseconds(timeout_ms);
  return mq.timed_send(msg.data(), msg.size(), priority, timeout);
}



/*--------------------------------*/
/*  REMOVE MESSAGES FROM A QUEUE  */
/*--------------------------------*/

[[cpp11::register]]
std::string cpp_mq_receive(std::string name) {
  
  message_queue mq(open_only_t(), name.c_str());
  
  unsigned int max_msg_size = mq.get_max_msg_size();
  std::string  msg (max_msg_size, 0);
  
  message_queue::size_type recvd_size;
  unsigned int             priority;
  
  mq.receive(&msg[0], max_msg_size, recvd_size, priority);
  msg.resize(recvd_size);
  
  return msg;
}


[[cpp11::register]]
SEXP cpp_mq_try_receive(std::string name) {
  
  message_queue mq(open_only_t(), name.c_str());
  
  unsigned int max_msg_size = mq.get_max_msg_size();
  std::string  msg (max_msg_size, 0);
  
  message_queue::size_type recvd_size;
  unsigned int             priority;
  
  if (mq.try_receive(&msg[0], max_msg_size, recvd_size, priority)) {
    msg.resize(recvd_size);
    return cpp11::as_sexp(msg);
  }
  
  return R_NilValue;
}


[[cpp11::register]]
SEXP cpp_mq_timed_receive(std::string name, long timeout_ms) {
  
  message_queue mq(open_only_t(), name.c_str());
  
  unsigned int max_msg_size = mq.get_max_msg_size();
  std::string  msg (max_msg_size, 0);
  pt::ptime    timeout = pt::microsec_clock::universal_time() + pt::milliseconds(timeout_ms);
  
  message_queue::size_type recvd_size;
  unsigned int             priority;
  
  if (mq.timed_receive(&msg[0], max_msg_size, recvd_size, priority, timeout)) {
    msg.resize(recvd_size);
    return cpp11::as_sexp(msg);
  }
  
  return R_NilValue;
}




/*---------------------*/
/*  QUEUE INFORMATION  */
/*---------------------*/

[[cpp11::register]]
std::size_t cpp_mq_get_max_msg(std::string name) {
  message_queue mq(open_only_t(), name.c_str());
  return mq.get_max_msg();
}

[[cpp11::register]]
std::size_t cpp_mq_get_max_msg_size(std::string name) {
  message_queue mq(open_only_t(), name.c_str());
  return mq.get_max_msg_size();
}

[[cpp11::register]]
std::size_t cpp_mq_get_num_msg(std::string name) {
  message_queue mq(open_only_t(), name.c_str());
  return mq.get_num_msg();
}




/*------------------*/
/*  DELETE A QUEUE  */
/*------------------*/

[[cpp11::register]]
bool cpp_mq_remove(std::string name) {
  return message_queue::remove(name.c_str());
}

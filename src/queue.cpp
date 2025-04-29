// [[Rcpp::depends(BH)]]

#include <Rcpp.h>
#include <boost/interprocess/ipc/message_queue.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>

using namespace boost::interprocess;
namespace pt = boost::posix_time;


/*------------------*/
/*  CREATE A QUEUE  */
/*------------------*/

// [[Rcpp::export]]
void rcpp_queue_create_only(std::string name, size_t max_num_msg, size_t max_msg_size) {
  message_queue(create_only_t(), name.c_str(), max_num_msg, max_msg_size);
}

// [[Rcpp::export]]
void rcpp_queue_open_only(std::string name) {
  message_queue(open_only_t(), name.c_str());
}

// [[Rcpp::export]]
void rcpp_queue_open_create(std::string name, size_t max_num_msg, size_t max_msg_size) {
  message_queue(open_or_create_t(), name.c_str(), max_num_msg, max_msg_size);
}



/*---------------------------*/
/*  ADD MESSAGES TO A QUEUE  */
/*---------------------------*/

// [[Rcpp::export]]
bool rcpp_queue_send(std::string name, std::string msg, unsigned int priority) {
  message_queue mq(open_only_t(), name.c_str());
  mq.send(msg.data(), msg.size(), priority);
  return true;
}

// [[Rcpp::export]]
bool rcpp_queue_try_send(std::string name, std::string msg, unsigned int priority) {
  message_queue mq(open_only_t(), name.c_str());
  return mq.try_send(msg.data(), msg.size(), priority);
}

// [[Rcpp::export]]
bool rcpp_queue_timed_send(std::string name, std::string msg, unsigned int priority, long timeout_ms) {
  message_queue mq(open_only_t(), name.c_str());
  pt::ptime timeout = pt::microsec_clock::universal_time() + pt::milliseconds(timeout_ms);
  return mq.timed_send(msg.data(), msg.size(), priority, timeout);
}



/*--------------------------------*/
/*  REMOVE MESSAGES FROM A QUEUE  */
/*--------------------------------*/

// [[Rcpp::export]]
Rcpp::String rcpp_queue_receive(std::string name) {
  
  message_queue mq(open_only_t(), name.c_str());
  
  unsigned int max_msg_size = mq.get_max_msg_size();
  std::string  msg (max_msg_size, 0);
  
  message_queue::size_type recvd_size;
  unsigned int             priority;
  
  mq.receive(&msg[0], max_msg_size, recvd_size, priority);
  msg.resize(recvd_size);
  
  return msg;
}


// [[Rcpp::export]]
Rcpp::String rcpp_queue_try_receive(std::string name) {
  
  message_queue mq(open_only_t(), name.c_str());
  
  unsigned int max_msg_size = mq.get_max_msg_size();
  std::string  msg (max_msg_size, 0);
  
  message_queue::size_type recvd_size;
  unsigned int             priority;
  
  if (mq.try_receive(&msg[0], max_msg_size, recvd_size, priority)) {
    msg.resize(recvd_size);
    return msg;
  }
  
  return NA_STRING;
}


// [[Rcpp::export]]
Rcpp::String rcpp_queue_timed_receive(std::string name, long timeout_ms) {
  
  message_queue mq(open_only_t(), name.c_str());
  
  unsigned int max_msg_size = mq.get_max_msg_size();
  std::string  msg (max_msg_size, 0);
  pt::ptime    timeout = pt::microsec_clock::universal_time() + pt::milliseconds(timeout_ms);
  
  message_queue::size_type recvd_size;
  unsigned int             priority;
  
  if (mq.timed_receive(&msg[0], max_msg_size, recvd_size, priority, timeout)) {
    msg.resize(recvd_size);
    return msg;
  }
  
  return NA_STRING;
}




/*---------------------*/
/*  QUEUE INFORMATION  */
/*---------------------*/

// [[Rcpp::export]]
std::size_t rcpp_queue_get_max_msg(std::string name) {
  message_queue mq(open_only_t(), name.c_str());
  return mq.get_max_msg();
}

// [[Rcpp::export]]
std::size_t rcpp_queue_get_max_msg_size(std::string name) {
  message_queue mq(open_only_t(), name.c_str());
  return mq.get_max_msg_size();
}

// [[Rcpp::export]]
std::size_t rcpp_queue_get_num_msg(std::string name) {
  message_queue mq(open_only_t(), name.c_str());
  return mq.get_num_msg();
}




/*------------------*/
/*  DELETE A QUEUE  */
/*------------------*/

// [[Rcpp::export]]
bool rcpp_queue_remove(std::string name) {
  return message_queue::remove(name.c_str());
}

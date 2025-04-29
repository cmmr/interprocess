

test_that("queue", {
  
  expect_error(queue(name = 'abc123', file = tempfile()))
  
  x <- expect_silent(queue(max_count = 2, cleanup = TRUE))
  y <- expect_silent(queue(assert = 'create', max_nchar = 1, file = tempfile()))
  z <- expect_silent(queue(name = y$name, assert = 'exists'))
  
  expect_identical(x$max_count(), 2L)
  expect_identical(y$max_nchar(), 1L)
  expect_error(y$send('abc'))
  
  expect_true(x$send('abc', timeout_ms = Inf, priority = 0))
  expect_true(x$send('def', timeout_ms = 100, priority = 1))
  expect_false(x$send('ghi', timeout_ms = 0))
  expect_identical(x$count(), 2L)
  
  expect_identical(x$receive(timeout_ms = Inf),       'def')
  expect_identical(with(x, expr = ., timeout_ms = 0), 'abc')
  expect_null(     with(x, expr = ., timeout_ms = 0))
  expect_null(     with(x, expr = ., timeout_ms = 10))
  
  expect_false(exists(x = '.', inherits = FALSE))
  assign(x = '.', TRUE)
  expect_true(x$send('abc'))
  expect_identical(with(x, expr = invisible(.), timeout_ms = 10), 'abc')
  expect_true(get(x = '.', inherits = FALSE))
  
  expect_true(x$remove())
  expect_true(y$remove())
  expect_false(z$remove())
  
  
  skip_on_cran()
  skip_on_covr()
  
  mq <- expect_silent(queue(max_count = 1))
  f <- function (nm) {
    q <- interprocess::queue(name = nm)
    return (q$receive(timeout_ms = 0))
  }
  expect_true(mq$send('abc'))
  expect_identical(callr::r(f, list(nm = mq$name)), 'abc')
  expect_null(     callr::r(f, list(nm = mq$name)))
  
  expect_true(mq$remove())
})




test_that("semaphore", {
  
  expect_error(semaphore(name = 'abc123', file = tempfile()))
  
  x <- expect_silent(semaphore(value = 2, cleanup = TRUE))
  y <- expect_no_error(semaphore(assert = 'create', file = tempfile()))
  z <- expect_silent(semaphore(name = y$name, assert = 'exists'))
  
  expect_true(x$post())
  expect_true( x$wait(timeout_ms = Inf))
  expect_true( x$wait(timeout_ms = 100))
  expect_true( x$wait(timeout_ms = 0))
  expect_false(x$wait(timeout_ms = 0))
  expect_false(x$wait(timeout_ms = 10))
  
  expect_true(x$post())
  expect_true( with(x, expr = invisible(TRUE), alt_expr = FALSE, timeout_ms = 0))
  expect_false(with(x, expr = invisible(TRUE), alt_expr = FALSE, timeout_ms = 0))
  
  expect_true(x$remove())
  expect_true(y$remove())
  expect_false(z$remove())
  
  
  skip_on_cran()
  skip_on_covr()
  
  sem <- expect_silent(semaphore(value = 1))
  f <- function (nm) {
    s <- interprocess::semaphore(name = nm)
    return (s$wait(timeout_ms = 0))
  }
  expect_true( callr::r(f, list(nm = sem$name)))
  expect_false(callr::r(f, list(nm = sem$name)))
  
  expect_true(sem$remove())
  
  
  # cleanup works
  nm  <- callr::r(function () interprocess::semaphore(cleanup = TRUE)$name)
  sem <- expect_silent(interprocess::semaphore(name = nm, assert = 'create'))
  expect_true(sem$remove())
  
  # persistence works
  nm  <- callr::r(function () interprocess::semaphore(cleanup = FALSE)$name)
  sem <- expect_silent(interprocess::semaphore(name = nm, assert = 'exists'))
  expect_true(sem$remove())
  
})


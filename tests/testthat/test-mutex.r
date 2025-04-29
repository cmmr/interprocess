

test_that("mutex", {
  
  expect_error(mutex(name = 'abc123', file = tempfile()))
  
  x <- expect_silent(mutex(cleanup = TRUE))
  y <- expect_silent(mutex(assert = 'create', file = tempfile()))
  z <- expect_silent(mutex(name = y$name, assert = 'exists'))
  
  expect_true(with(x, invisible(TRUE)))
  
  expect_true(with(x, TRUE, FALSE, timeout_ms = Inf))
  expect_true(with(x, TRUE, FALSE, timeout_ms = 100))
  expect_true(with(x, TRUE, FALSE, timeout_ms = 0))
  expect_true(with(x, TRUE, FALSE, timeout_ms = Inf, shared = TRUE))
  expect_true(with(x, TRUE, FALSE, timeout_ms = 100, shared = TRUE))
  expect_true(with(x, TRUE, FALSE, timeout_ms = 0,   shared = TRUE))
  
  expect_true(x$lock())
  expect_error(x$lock())
  expect_true(x$unlock())
  expect_warning(x$unlock(warn = TRUE))
  expect_false(x$unlock(warn = FALSE))
  
  expect_true(x$remove())
  expect_true(y$remove())
  expect_false(z$remove())
  
  
  skip_on_cran()
  skip_on_covr()
  
  mut <- expect_silent(mutex())
  f <- function (nm, shr) {
    m <- interprocess::mutex(name = nm)
    return (with(m, TRUE, FALSE, shared = shr, timeout_ms = 0))
  }
  
  expect_true(callr::r(f, list(nm = mut$name, shr = TRUE)))
  expect_true(callr::r(f, list(nm = mut$name, shr = FALSE)))
  
  with(mut, shared = TRUE, {
    expect_true( callr::r(f, list(nm = mut$name, shr = TRUE)))
    expect_false(callr::r(f, list(nm = mut$name, shr = FALSE)))
  })
  
  with(mut, shared = FALSE, {
    expect_false(callr::r(f, list(nm = mut$name, shr = TRUE)))
    expect_false(callr::r(f, list(nm = mut$name, shr = FALSE)))
  })
  
  expect_true(mut$remove())
  
})


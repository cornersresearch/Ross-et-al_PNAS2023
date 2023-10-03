mode <-
  function(x) {
    #' compute mode
    unique(x)[which.max(tabulate(match(x, unique(x))))]
  }
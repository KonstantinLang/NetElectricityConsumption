#' Calculate AUC with trapezoidal rule
#'
#' @param x numeric, vector with x values
#' @param y numeric, vector with y values
#'
#' @returns AUC of curve described by x and y values
auc <- \(x, y) {
  n <- length(x)
  a <- 0.5 * (y[1:(n-1)] + y[2:n]) * (x[2:n] - x[1:(n-1)])
  sum(as.numeric(a), na.rm = TRUE)
}

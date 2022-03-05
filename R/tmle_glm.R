tmle_glm <- function(a, w, x, y, offset, a.vals, trt.var, trim = 0.01){

  # set up evaluation points & matrices for predictions
  n <- nrow(x)
  id <- which(colnames(w) == trt.var)

  # estimate nuisance outcome model with splines
  fmla <- formula(paste0( "y ~ ns(a, 4) ", paste0(colnames(w[,-id]), collapse = "+")))
  mumod <- glm(fmla, data = data.frame(w, a = w[,id]), offset = offset, family = poisson(link = "log"))
  muhat <- exp(log(mumod$fitted.values) - offset)

  # estimate nuisance GPS parameters with lm
  pimod <- lm(a ~ 0 + ., data = data.frame(x))
  pimod.vals <- c(pimod$fitted.values, predict(pimod, newdata = data.frame(w)))
  pi2mod.vals <- sigma(pimod)^2

  # parametric density
  # pihat <- dnorm(a, pimod.vals, sqrt(pi2mod.vals))
  # pihat.mat <- sapply(a.vals, function(a.tmp, ...) {
  #   dnorm(a, pimod.vals, sqrt(pi2mod.vals))
  # })
  # phat <- predict(smooth.spline(a.vals, colMeans(pihat.mat, na.rm = T)), x = a)$y
  # phat[phat<0] <- 1e-4

  # nonparametric denisty
  a.std <- c(c(a, w[,id]) - pimod.vals) / sqrt(pi2mod.vals)
  dens <- density(a.std[1:n])
  pihat <- approx(x = dens$x, y = dens$y, xout = a.std)$y / sqrt(pi2mod.vals)

  pihat.mat <- sapply(a.vals, function(a.tmp, ...) {
    std <- c(a.tmp - pimod.vals) / sqrt(pi2mod.vals)
    approx(x = dens$x, y = dens$y, xout = std)$y / sqrt(pi2mod.vals)
  })

  phat <- predict(smooth.spline(a.vals, colMeans(pihat.mat[1:n,], na.rm = T)), x = c(a, w[,id]))$y
  phat[phat<0] <- 1e-4

  # TMLE update
  nsa <- ns(a, df = 4, intercept = TRUE)
  weights <- phat/pihat
  trim0 <- quantile(weights[1:n], trim)
  trim1 <- quantile(weights[1:n], 1 - trim)
  weights[weights < trim0] <- trim0
  weights[weights > trim1] <- trim1
  base <- predict(nsa, newx = w[,id])*weights[-(1:n)]
  new_mod <- glm(y ~ 0 + base, offset = log(muhat) + offset,
                 family = poisson(link = "log"))
  param <- coef(new_mod)

  # predict spline basis and impute
  estimate <- sapply(1:length(a.vals), function(k, ...) {
    print(k)
    w$a <- a.vals[k]
    muhat.tmp <- predict(mumod, newdata = data.frame(w))
    pihat.tmp <- pihat.mat[,k]
    a.tmp <- a.vals[k]
    wts <- c(mean(pihat.tmp[1:n], na.rm = TRUE)/pihat.tmp[-(1:n)])
    wts[wts < trim0] <- trim0
    wts[wts > trim1] <- trim1
    mat <- predict(nsa, newx = rep(a.tmp, length(wts)))*wts
    return(weighted.mean(exp(log(muhat.tmp) + c(mat%*%param)), w = exp(offset), na.rm = TRUE))
  })

  return(list(estimate = estimate, weights = weights[-(1:n)]))

}

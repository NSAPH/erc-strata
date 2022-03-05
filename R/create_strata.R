create_strata <- function(data, dual = c(0,1,2), race = c("all", "white", "black")) {

  zip_cov <- c("pm25", "mean_bmi", "smoke_rate", "hispanic", "pct_blk", "medhouseholdincome", "medianhousevalue", "poverty", "education",
               "popdensity", "pct_owner_occ", "summer_tmmx", "winter_tmmx", "summer_rmax", "winter_rmax", "region")

  if (dual == 0) {
    dual0 <- 0
  } else if (dual == 1) {
    dual0 <- 1
  } else {
    dual0 <- c(0,1)
  }

  if (race == "white") {
    race0 <- 1
  } else if (race == "black") {
    race0 <- 2
  } else {
    race0 <- c(1,2,3,4,5)
  }

  sub_data <- data %>% filter(data$race %in% race0 & data$dual %in% dual0)

  # Covariates and Outcomes
  w <- data.table(zip = sub_data$zip, year = sub_data$year, race = sub_data$race,
                  sex = sub_data$sex, dual = sub_data$dual, age_break = sub_data$age_break,
                  dead = sub_data$dead, time_count = sub_data$time_count)[
                    ,lapply(.SD, sum), by = c("zip", "year", "race", "sex", "dual", "age_break")]

  x <- data.table(zip = sub_data$zip, year = sub_data$year,
                  model.matrix(~ ., data = sub_data[,zip_cov])[,-1])[
                    ,lapply(.SD, min), by = c("zip", "year")]

  return(list(w = w, x = x))

}

##       author: Naeem Khoshnevis
##      created: March 2022
##      purpose: Profiling the CausalGPS package with the study data.

# See Misc/env_setup.md for setting up environment.

## Load libraries --------------------------------------------------------------

library(CausalGPS)
library(data.table)
library(dplyr)

## Load input data -------------------------------------------------------------

dir_data_qd <- '/nfs/nsaph_ci3/ci3_analysis/pdez_measurementerror/Data/balance_qd/covariates_white_male_qd.RData'
dir_out <- '/nfs/home/N/nak443/shared_space/ci3_analysis/nkhoshenvis_wd/code_test/Kevin/erc-strata/output'

load("/nfs/nsaph_ci3/ci3_analysis/pdez_measurementerror/Data/aggregate_data_qd.RData")
load(dir_data_qd)


print(paste0("Length of data:  ", nrow(covariates_white_male_qd)))

## Pre-processing ---------------------------------------------------------------


covariates_white_male_qd$year<-as.factor(covariates_white_male_qd$year)
covariates_white_male_qd$region<-as.factor(covariates_white_male_qd$region)
white_male_qd<-aggregate_data_qd %>% filter(aggregate_data_qd$race==1 & aggregate_data_qd$sex==1)
a.vals <- seq(min(white_male_qd$pm25_ensemble), max(white_male_qd$pm25_ensemble), length.out = 50)
delta_n <- (a.vals[2] - a.vals[1])

print(paste0("delta_n: ", delta_n))

## Run Parameters --------------------------------------------------------------

trim = 0.05

## Generate Pseudo Population --------------------------------------------------

set_logger(logger_level="DEBUG")

s_t <- proc.time()

set.seed(892)
match_pop <- generate_pseudo_pop(Y = covariates_white_male_qd$zip,
                                 w = covariates_white_male_qd$pm25_ensemble,
                                 c = covariates_white_male_qd[, c(4:19)],
                                 ci_appr = "matching",
                                 pred_model = "sl",
                                 gps_model = "parametric",
                                 use_cov_transform = TRUE,
                                 transformers = list("pow2", "pow3"),
                                 sl_lib = c("m_xgboost"),
                                 params = list(xgb_nrounds = seq(10,100)),
                                 nthread = 24,
                                 covar_bl_method = "absolute",
                                 covar_bl_trs = 0.1,
                                 covar_bl_trs_type = "maximal",
                                 trim_quantiles = c(trim, 1 - trim),
                                 optimized_compile = TRUE,
                                 max_attempt = 10,
                                 matching_fun = "matching_l1",
                                 delta_n = delta_n,
                                 scale = 1.0)

e_t <- proc.time()


pseudo_pop <- match_pop$pseudo_pop
print(paste0("Length of pseudopop: ", nrow(pseudo_pop)))
# Time for processing one iteration is about 5 min.
#[1] "Time for generating pseudo pop: 256.718000000001 seconds."

##  Save results on disk
png(paste0(dir_out,"/","plot.png"))
plot(match_pop)
dev.off()

##       author: Naeem Khoshnevis
##      created: March 2022
##      purpose: Profiling the CausalGPS package with the study data.

# See Misc/env_setup.md for setting up environment.

## Load libraries --------------------------------------------------------------

library(CausalGPS)

## Load input data -------------------------------------------------------------

dir_data_qd <- '/nfs/nsaph_ci3/ci3_analysis/josey_erc_strata/Data/qd'
dir_out <- '/nfs/home/N/nak443/shared_space/ci3_analysis/nkhoshenvis_wd/code_test/Kevin/erc-strata/output'

load(paste0(dir_data_qd,"2_all_qd.RData"))

data <- new_data$x

# output data is located under new_data$w

confs_name <- c("zip", "year", "mean_bmi", "smoke_rate", "hispanic", "pct_blk",
                "medhouseholdincome", "medianhousevalue", "poverty", "education",
                "popdensity", "pct_owner_occ", "summer_tmmx", "winter_tmmx",
                "summer_rmax", "winter_rmax", "regionNORTHEAST", "regionSOUTH",
                "regionWEST")

conf_data <- data[confs_name]
exp_data <- data[c("pm25")]
outcome <- new_data$w

print(paste0("Length of confunding data:  ", length(conf_data)))
print(paste0("Length of exposure data: ", length(exp_data)))
print(paste0("Length of outcome: ", length(outcome)))

## Pre-processing ---------------------------------------------------------------

conf_data$zip <- factor(conf_data$zip)
conf_data$year <- factor(conf_data$year)
conf_data$sex <- factor(conf_data$sex)
conf_data$region <- factor(conf_data$region)

## Run Parameters --------------------------------------------------------------

trim = 0.05

## Generate Pseudo Population --------------------------------------------------

set.seed(892)
match_pop <- generate_pseudo_pop(Y = outcome,
                                 w = exp_data,
                                 c = conf_data,
                                 ci_appr = "matching",
                                 pred_model = "sl",
                                 gps_model = "parametric",
                                 use_cov_transform = TRUE,
                                 transformers = list("pow2", "pow3"),
                                 sl_lib = c("m_xgboost"),
                                 params = list(xgb_nrounds = c(50)),
                                 nthread = 12,
                                 covar_bl_method = "absolute",
                                 covar_bl_trs = 0.1,
                                 covar_bl_trs_type = "mean",
                                 trim_quantiles = c(trim, 1 - trim),
                                 optimized_compile = TRUE,
                                 max_attempt = 5,
                                 matching_fun = "matching_l1",
                                 delta_n = 0.2,
                                 scale = 1.0)


pseudo_pop <- match_pop$pseudo_pop
print(paste0("Length of pseudopop: ", length(pseudo_pop)))

png(paste0(dir_out,"/","plot.png"))
plot(pseudo_pop)
dev.off()

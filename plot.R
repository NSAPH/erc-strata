library(data.table)
library(tidyr)
library(dplyr)
library(stringr)
library(splines)
library(ggplot2)
library(ggpubr)
library(cowplot)
library(cobalt)

source('/nfs/nsaph_ci3/ci3_analysis/josey_erc_strata/Code/dr_fun.R')

# scenarios
scenarios <- expand.grid(sex = c("male", "female"), race = c("white", "black", "hispanic", "asian"))
scenarios$sex <- as.character(scenarios$sex)
scenarios$race <- as.character(scenarios$race)
scenarios <- rbind(c(sex = "both", race = "all"), scenarios)
a.vals <- seq(3, 18, length.out = 151)
n.boot <- 1000

# Data Directories
dir_out_qd = '/nfs/nsaph_ci3/ci3_analysis/josey_erc_strata/Output/DR_qd/'
dir_out_rm = '/nfs/nsaph_ci3/ci3_analysis/josey_erc_strata/Output/DR_rm/'

dat_qd <- data.frame()
dat_rm <- data.frame()
contr <- data.frame()

idx5 <- which(a.vals == 5)
idx8 <- which(a.vals == 8)
idx10 <- which(a.vals == 10)
idx12 <- which(a.vals == 12)

# Race or Sex Plot
for (i in 1:nrow(scenarios)){
  
  # QD
  scenario <- scenarios[i,]
  load(paste0(dir_out_qd, scenario$sex, "_", scenario$race, "_qd.RData"))
  adj <- sqrt(1/log(n.zip))
  dat_qd_tmp <- data.frame(a.vals = boot_out$a.vals, estimate = boot_out$estimate,
                           lower = sapply(1:nrow(boot_out), function(j,...) boot_out[j,2] - 1.96*sd(boot_out[j,3:(n.boot + 2)])*adj),
                           upper = sapply(1:nrow(boot_out), function(j,...) boot_out[j,2] + 1.96*sd(boot_out[j,3:(n.boot + 2)])*adj),
                           exposure = rep("QD", nrow(boot_out)),
                           race = rep(scenario$race, nrow(boot_out)),
                           sex = rep(scenario$sex, nrow(boot_out)))
  dat_qd <- rbind(dat_qd, dat_qd_tmp)
  
  qd_tmp_1 <- 100*as.vector(t(boot_out[idx10,2:(n.boot + 2)]) - t(boot_out[idx5,2:(n.boot + 2)]))/as.vector(t(boot_out[idx5,2:(n.boot + 2)]))
  qd_tmp_2 <- 100*as.vector(t(boot_out[idx12,2:(n.boot + 2)]) - t(boot_out[idx8,2:(n.boot + 2)]))/as.vector(t(boot_out[idx8,2:(n.boot + 2)]))
  
  contr_qd_tmp <- data.frame(estimate = c(qd_tmp_1[1], qd_tmp_2[1]),
                             lower = c(qd_tmp_1[1] - 1.96*sd(qd_tmp_1[2:n.boot + 1])*adj,
                                       qd_tmp_2[1] - 1.96*sd(qd_tmp_2[2:n.boot + 1])*adj),
                             upper = c(qd_tmp_1[1] + 1.96*sd(qd_tmp_1[2:n.boot + 1])*adj, 
                                       qd_tmp_2[1] + 1.96*sd(qd_tmp_2[2:n.boot + 1])*adj),
                             pm0 = c(5, 8),
                             pm1 = c(10, 12),
                             exposure = c("QD"),
                             race = scenario$race,
                             sex = scenario$sex)
  
  # RM
  load(paste0(dir_out_rm, scenario$sex, "_", scenario$race, "_rm.RData"))
  adj <- sqrt(1/log(n.zip))
  dat_rm_tmp <- data.frame(a.vals = boot_out$a.vals, 
                           estimate = boot_out$estimate,
                           lower = sapply(1:nrow(boot_out), function(j,...) boot_out[j,2] - 1.96*sd(boot_out[j,3:(n.boot + 2)])*adj),
                           upper = sapply(1:nrow(boot_out), function(j,...) boot_out[j,2] + 1.96*sd(boot_out[j,3:(n.boot + 2)])*adj),
                           exposure = rep("RM", nrow(boot_out)),
                           race = rep(scenario$race, nrow(boot_out)),
                           sex = rep(scenario$sex, nrow(boot_out)))
  dat_rm <- rbind(dat_rm, dat_rm_tmp)
  
  rm_tmp_1 <- 100*as.vector(t(boot_out[idx10,2:(n.boot + 2)]) - t(boot_out[idx5,2:(n.boot + 2)]))/as.vector(t(boot_out[idx5,2:(n.boot + 2)]))
  rm_tmp_2 <- 100*as.vector(t(boot_out[idx12,2:(n.boot + 2)]) - t(boot_out[idx8,2:(n.boot + 2)]))/as.vector(t(boot_out[idx8,2:(n.boot + 2)]))
  
  contr_rm_tmp <- data.frame(estimate = c(rm_tmp_1[1], rm_tmp_2[1]),
                             lower = c(rm_tmp_1[1] - 1.96*sd(rm_tmp_1[2:n.boot + 1])*adj, 
                                       rm_tmp_2[1] - 1.96*sd(rm_tmp_2[2:n.boot + 1])*adj),
                             upper = c(rm_tmp_1[1] + 1.96*sd(rm_tmp_1[2:n.boot + 1])*adj, 
                                       rm_tmp_2[1] + 1.96*sd(rm_tmp_2[2:n.boot + 1])*adj),
                             pm0 = c(5, 8),
                             pm1 = c(10, 12),
                             exposure = c("RM"),
                             race = scenario$race,
                             sex = scenario$sex)
  
  contr <- rbind(contr, contr_qd_tmp, contr_rm_tmp)
  
}

### Main Plot

# QD
i <- 1
scenario <- scenarios[i,]
load(paste0(dir_out_qd, scenario$sex, "_", scenario$race, "_qd.RData"))
dat_qd_tmp <- subset(dat_qd, sex == scenario$sex & race == scenario$race)
a_dat <- data.frame(a = out_data$a, exposure = "QD")

# RM
load(paste0(dir_out_rm, scenario$sex, "_", scenario$race, "_rm.RData"))
dat_rm_tmp <- subset(dat_rm, sex == scenario$sex & race == scenario$race)
a_dat <- rbind(a_dat, data.frame(a = out_data$a, exposure = "RM"))

# combine
dat_tmp <- rbind(dat_qd_tmp, dat_rm_tmp)

erf_plot <- dat_tmp %>% 
  ggplot(aes(x = a.vals, y = estimate, color = exposure)) + 
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, linetype = "dotted") +
  geom_line(size = 1) +
  coord_cartesian(xlim = c(3,18)) +
  labs(x = "Annual Average PM2.5", y = "All-cause Mortality Rate",
       color = "Exposure Model") + 
  theme(legend.position = c(0.02, 0.9),
        legend.background = element_rect(colour = "black"),
        panel.grid=element_blank())

a_dat <- subset(a_dat, a >= 3 & a <= 18)

a_hist <- ggplot(a_dat, mapping = aes(x = a, fill = exposure)) + 
  geom_histogram(aes(y = ..density..), bins = 30, alpha = 0.25)+
  coord_cartesian(xlim = c(3,18)) +
  labs(x = "Annual Average PM2.5", y = "Exposure Density") + 
  theme(panel.grid=element_blank()) +
  scale_y_continuous(position = "right") +
  guides(fill="none") +
  theme_cowplot()

align <- align_plots(a_hist, erf_plot, align = "hv", axis = "tblr")
big_bad_plot <- ggdraw(align[[1]]) + draw_plot(align[[2]])

pdf(file = "/nfs/nsaph_ci3/ci3_analysis/josey_erc_strata/Output/erc_plot.pdf", width = 8, height = 8)
big_bad_plot
dev.off()

### Plot by Race

plot_list <- list()
situations <- expand.grid(exposure = c("QD", "RM"), sex = c("male", "female"))

for (i in 1:nrow(situations)){
  
  situation <- situations[i,]
  
  if (situation$exposure == "QD"){
    main <- paste("QD", str_to_title(situation$sex))
    dat_tmp <- subset(dat_qd, sex == as.character(situation$sex))
  } else {
    main <- paste("RM", str_to_title(situation$sex))
    dat_tmp <- subset(dat_rm, sex == as.character(situation$sex))
  }
  
  dat_tmp$race <- str_to_title(dat_tmp$race)
  
  # dat_tmp$race <- str_to_title(dat_tmp$race)
  
  erf_strata_plot <- dat_tmp %>% 
    ggplot(aes(x = a.vals, y = estimate, color = race)) + 
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, linetype = "dotted") +
    geom_line(size = 1) +
    coord_cartesian(xlim = c(3,18), ylim = c(0.03, 0.07)) +
    labs(x = "Annual Average PM2.5", y = "All-cause Mortality Rate", 
         color = "Race Strata", title = main) + 
    theme(legend.position = c(0.02, 0.9),
          legend.background = element_rect(colour = "black"),
          panel.grid=element_blank())
  
  plot_list[[i]] <- erf_strata_plot
  
}


strata_plot <- ggarrange(plotlist = plot_list, ncol = 2, nrow = 2, legend = "bottom", common.legend = TRUE)

pdf(file = "/nfs/nsaph_ci3/ci3_analysis/josey_erc_strata/Output/strata_plot.pdf", width = 10, height = 10)
strata_plot
dev.off()

### Contrast Plot

contr$race_sex <- str_to_title(paste(contr$race, contr$sex))
contr$race_sex <- ifelse(contr$race_sex == "All Both", "All", contr$race_sex)
contr$race_sex <- factor(contr$race_sex, levels = c("All", "White Male", "White Female",
                                                    "Black Male", "Black Female",
                                                    "Hispanic Male", "Hispanic Female",
                                                    "Asian Male", "Asian Female"))
contr_1 <- subset(contr, pm0 == 5) 
contr_2 <- subset(contr, pm0 == 8) 

contrast_plot_1 <- contr_1 %>% 
  ggplot(aes(x = race_sex, y = estimate, color = exposure)) + 
  geom_pointrange(aes(ymin = lower, ymax = upper), position = position_dodge(width = 0.25)) +
  labs(x = "Strata", y = "Relative Risk Increase (%)", color = "Exposure Model",
       title = "Changing PM2.5 from 5 mcg/m3 to 10 mcg/m3") + 
  theme(legend.background = element_rect(colour = "black"),
        panel.grid=element_blank()) +
  grids(linetype = "dashed") +
  geom_hline(yintercept = 0, lty = 3) 

contrast_plot_2 <- contr_2 %>% 
  ggplot(aes(x = race_sex, y = estimate, color = exposure)) + 
  geom_pointrange(aes(ymin = lower, ymax = upper), position = position_dodge(width = 0.25)) +
  labs(x = "Strata", y = "Relative Risk Increase (%)", color = "Exposure Model",
       title = "Changing PM2.5 from 8 mcg/m3 to 12 mcg/m3") + 
  theme(legend.background = element_rect(colour = "black"),
        panel.grid=element_blank())+
  grids(linetype = "dashed") +
  geom_hline(yintercept = 0, lty = 3)

contrast_plot <- ggarrange(contrast_plot_1 + theme(legend.position="none"), 
                           contrast_plot_2 + theme(legend.position="none"),
                           ncol = 1, nrow = 2, 
                           legend = "bottom", common.legend = TRUE)

pdf(file = "/nfs/nsaph_ci3/ci3_analysis/josey_erc_strata/Output/contrast_plot.pdf", width = 12, height = 6)
contrast_plot
dev.off()

### Balance Plot

bal_plot <- function(a, x, weights, main = "All QD"){
  
  val <- bal.tab(x, treat = a, weights = weights, method = "weighting")
  bal_df <- val$Balance[order(abs(val$Balance$Corr.Un), decreasing = TRUE),]
  labs <- rep(rownames(bal_df), 2)
  vals <- c(bal_df$Corr.Un, bal_df$Corr.Adj)
  adjust <- rep(c("Unadjusted", "Adjusted"), each = nrow(bal_df))
  df <- data.frame(labs = labs, vals = abs(vals), adjust = adjust)
  df$labs <- factor(df$labs, levels = rev(rownames(bal_df)))
  
  fp <- ggplot(data = df, aes(x = labs, y = vals, color = adjust)) +
    geom_point(pch = 21, size = 2) +
    geom_line(aes(group = adjust)) + 
    geom_hline(yintercept = 0, lty = 1) +
    geom_hline(yintercept = 0.1, lty = 3, colour = "black") +
    coord_flip() +  # flip coordinates (puts labels on y axis)
    xlab("Covariates") + ylab("Absolute Pearson Correlation") +
    ylim(0, 0.35) +
    guides(color = guide_legend(title = "GPS Adjusting")) +
    theme_bw() + # use a white background
    ggtitle(main)
  
  return(fp)
  
}

i <- 1
scenario <- scenarios[i,]

load(paste0(dir_out_qd, scenario$sex, "_", scenario$race, "_qd.RData"))
bplot_1 <- bal_plot(a = out_data$a, x = out_data[,3:20], weights = out_data$weights, main = "QD")

load(paste0(dir_out_rm, scenario$sex, "_", scenario$race, "_rm.RData"))
bplot_2 <- bal_plot(a = out_data$a, x = out_data[,3:20], weights = out_data$weights, main = "RM")

balance_plot <- ggarrange(bplot_1 + theme(legend.position="none"), 
                          bplot_2 + theme(legend.position="none"),
                          ncol = 2, nrow = 1, 
                          legend = "bottom", common.legend = TRUE)

pdf(file = "/nfs/nsaph_ci3/ci3_analysis/josey_erc_strata/Output/balance_plot.pdf", width = 8, height = 8)
balance_plot
dev.off()

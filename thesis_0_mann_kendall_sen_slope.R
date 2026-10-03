# Master's thesis, University of Passau (2025) - Camila Aguirre Diaz
# Mann-Kendall trend test and Sen's slope for precipitation series.
# Set the working directory to the project folder; input data (not included) go in data/.
# install.packages(c("Kendall", "trend", "lmtest", "haven", "dplyr"))

# packages
library(Kendall)
library(dplyr)
library(trend)
library(haven)
library(lmtest)

dir.create("output", showWarnings = FALSE)

# TENDENCY ANALYSYS FOR PRECIPITATION 1981-2024 =44 OBSERVATIONES /village level 


climate_data_1 <- read_dta(file.path("data", "precipitation_mandall_kendal_wide.dta"))
# View(climate_data_1)

aldeas <- grep("^precip", names(climate_data_1), value = TRUE)
resultados <- data.frame()

t_full <- seq_len(nrow(climate_data_1))

for (aldea in aldeas) {
  y <- as.numeric(climate_data_1[[aldea]])
  ok <- !is.na(y)
  y_nna <- y[ok]
  t_nna <- t_full[ok]
  
  # Default values NA
  tau <- Z_MK <- p_MK <- sen_slope <- conf_low <- conf_high <- R2 <- CV <- DW_stat <- DW_p <- NA_real_
  
  # Only if there is sufficient data
  n <- length(y_nna)
  
  # Mann–Kendall y Sen's slope (required ≥3)
  if (n >= 3) {
    # tau (Kendall)
    tau <- tryCatch(Kendall::MannKendall(y_nna)$tau, error = function(e) NA_real_)
    
    # mk.test (Z y p)
    mkz <- tryCatch(trend::mk.test(y_nna), error = function(e) NULL)
    if (!is.null(mkz)) {
      # Some packages use p.value, others use sl
      Z_MK <- suppressWarnings(as.numeric(mkz$statistic))
      p_MK <- if (!is.null(mkz$p.value)) mkz$p.value else if (!is.null(mkz$sl)) mkz$sl else NA_real_
    }
    
    # Sen's slope
    sen <- tryCatch(trend::sens.slope(y_nna), error = function(e) NULL)
    if (!is.null(sen)) {
      sen_slope <- suppressWarnings(as.numeric(sen$estimates))
      if (!is.null(sen$conf.int) && length(sen$conf.int) == 2) {
        conf_low  <- as.numeric(sen$conf.int[1])
        conf_high <- as.numeric(sen$conf.int[2])
      }
    }
  }
  
  # Linear regression and Durbin–Watson (requires ≥2)
  if (n >= 2) {
    modelo <- tryCatch(lm(y_nna ~ t_nna), error = function(e) NULL)
    if (!is.null(modelo)) {
      R2 <- tryCatch(summary(modelo)$r.squared, error = function(e) NA_real_)
      # Durbin–Watson
      dw <- tryCatch(dwtest(modelo), error = function(e) NULL)
      if (!is.null(dw)) {
        DW_stat <- suppressWarnings(as.numeric(dw$statistic[[1]]))
        DW_p    <- suppressWarnings(as.numeric(dw$p.value))
      }
    }
  }
  
  # Coefficient of variation (%)
  if (n >= 1) {
    m <- mean(y_nna, na.rm = TRUE)
    s <- sd(y_nna, na.rm = TRUE)
    CV <- if (!is.na(m) && !is.na(s) && m != 0 && s > 0) (s / abs(m)) * 100 else NA_real_
  }
  
  # Assemble ONE row (all columns length 1 or NA) 
  fila <- data.frame(
    aldea = aldea,
    n_obs = n,
    tau = tau,
    Z_MK = Z_MK,
    p_value = p_MK,
    sen_slope = sen_slope,
    conf_low = conf_low,
    conf_high = conf_high,
    R2 = R2,
    CV = CV,
    DW_stat = DW_stat,
    DW_p_value = DW_p,
    stringsAsFactors = FALSE
  )
  
  resultados <- rbind(resultados, fila)
}

print(resultados)
write_dta(resultados, file.path("output", "resultados_mk_sen.dta"))

  
#  SENEGAL DATA WORLD BANK PRECIPITATION AGREGATED ANUAL  // national level 

wb_data <- read_dta(file.path("data", "world_bank.dta"))
# View(wb_data )

# Time series vector
y <- wb_data$PRECIPITATION

# Test de Mann-Kendall
mk <- MannKendall(y)

#  Sen SLOPE
sen <- sens.slope(y)

# RESULTS SHOW
cat("Mann-Kendall Test:\n")
cat("  tau =", mk$tau, "\n")
cat("  p-value =", mk$sl, "\n\n")

cat("Sen's Slope Estimate:\n")
cat("  slope =", sen$estimates, "\n")
cat("  95% CI = [", sen$conf.int[1], ",", sen$conf.int[2], "]\n")

# Create a table with the results in data frame format.
resultados_nacional <- data.frame(
  escala = "Senegal_nacional",
  tau = mk$tau,
  p_value = mk$sl,
  sen_slope = sen$estimates,
  conf_low = sen$conf.int[1],
  conf_high = sen$conf.int[2]
)

print(resultados_nacional)

write_dta(resultados_nacional, file.path("output", "resultados_mk_sen_nacional.dta"))



# TENDENCY ANALYSIS FOR PRECIPITATION 1950-2024 : world data bank


climate_data_r <- read_dta(file.path("data", "precipitation_mandall_kendall_region.dta"))
# View(climate_data_r)

aldeas <- grep("^precip", names(climate_data_r), value = TRUE)
resultados <- data.frame()

t_full <- seq_len(nrow(climate_data_r))

for (aldea in aldeas) {
  y <- as.numeric(climate_data_r[[aldea]])
  ok <- !is.na(y)
  y_nna <- y[ok]
  t_nna <- t_full[ok]
  
  # Default values NA
  tau <- Z_MK <- p_MK <- sen_slope <- conf_low <- conf_high <- R2 <- CV <- DW_stat <- DW_p <- NA_real_
  
  # Only if there is sufficient data
  n <- length(y_nna)
  
  # Mann–Kendall y Sen's slope (requiere ≥3)
  if (n >= 3) {
    # tau (Kendall)
    tau <- tryCatch(Kendall::MannKendall(y_nna)$tau, error = function(e) NA_real_)
    
    # mk.test (Z y p)
    mkz <- tryCatch(trend::mk.test(y_nna), error = function(e) NULL)
    if (!is.null(mkz)) {
      # Some packages use p.value, others use sl
      Z_MK <- suppressWarnings(as.numeric(mkz$statistic))
      p_MK <- if (!is.null(mkz$p.value)) mkz$p.value else if (!is.null(mkz$sl)) mkz$sl else NA_real_
    }
    
    # Sen's slope
    sen <- tryCatch(trend::sens.slope(y_nna), error = function(e) NULL)
    if (!is.null(sen)) {
      sen_slope <- suppressWarnings(as.numeric(sen$estimates))
      if (!is.null(sen$conf.int) && length(sen$conf.int) == 2) {
        conf_low  <- as.numeric(sen$conf.int[1])
        conf_high <- as.numeric(sen$conf.int[2])
      }
    }
  }
  
  # Linear and Durbin–Watson regression (requires ≥2)
  if (n >= 2) {
    modelo <- tryCatch(lm(y_nna ~ t_nna), error = function(e) NULL)
    if (!is.null(modelo)) {
      R2 <- tryCatch(summary(modelo)$r.squared, error = function(e) NA_real_)
      # Durbin–Watson
      dw <- tryCatch(dwtest(modelo), error = function(e) NULL)
      if (!is.null(dw)) {
        DW_stat <- suppressWarnings(as.numeric(dw$statistic[[1]]))
        DW_p    <- suppressWarnings(as.numeric(dw$p.value))
      }
    }
  }
  
  # Coefficient of variation (%)
  if (n >= 1) {
    m <- mean(y_nna, na.rm = TRUE)
    s <- sd(y_nna, na.rm = TRUE)
    CV <- if (!is.na(m) && !is.na(s) && m != 0 && s > 0) (s / abs(m)) * 100 else NA_real_
  }
  
  # Assemble ONE row (all columns length 1 or NA)
  fila <- data.frame(
    aldea = aldea,
    n_obs = n,
    tau = tau,
    Z_MK = Z_MK,
    p_value = p_MK,
    sen_slope = sen_slope,
    conf_low = conf_low,
    conf_high = conf_high,
    R2 = R2,
    CV = CV,
    DW_stat = DW_stat,
    DW_p_value = DW_p,
    stringsAsFactors = FALSE
  )
  
  resultados <- rbind(resultados, fila)
}

print(resultados)
write_dta(resultados, file.path("output", "resultados_mk_sen_region.dta"))







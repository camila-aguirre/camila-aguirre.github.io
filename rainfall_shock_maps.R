# ==============================================================================
# SENEGAL RAINFALL SHOCK MAPS (2021-2023)
# Project: Climate migration and mediators
# Variable: % Deviation from Long-Term Mean (Post-Onset 30 Days)
# ==============================================================================

# Author: Camila Aguirre Diaz
#
# All paths are relative to the project folder (open the .Rproj or set the
# working directory to this folder before running).

# Load necessary libraries
library('readr')
library('terra')
library('tidyverse')
library('haven')

# --- 1. Load Spatial and Base Data ---

# Shapefile for Senegal borders
shp_path <- file.path("data", "AEZ_shapefile", "AEZ_SEN.shp")
senegal  <- vect(shp_path)


# Prepare region labels: remove accents and ensure coordinate system matches GPS
# senegal$clean_name <- iconv(senegal$name, to='ASCII//TRANSLIT')
senegal <- project(senegal, "EPSG:4326")

# Village coordinates
villages_gps <- read.csv(file.path("data", "villages_jittered_only.csv"), sep = ";")


# Main treatment data (processed in Stata to include rain_pct_deviation, DS30)
treat_data_path <- file.path("data", "Building_Treatment_map_2010_2024.dta")
treat_data <- read_dta(treat_data_path)


# --- 2. Global Plotting Settings ---

# We fix the scale at +/- 80% across all years to ensure they are comparable.
# This ensures a specific shade of brown always represents the same % deficit.
rain_limit <- 80 
rain_range <- c(-rain_limit, rain_limit)

# Output directory
out_dir <- "output"
dir.create(out_dir, showWarnings = FALSE)

# --- 3. Loop Through Years to Generate Maps ---

years_to_map <- c(2021, 2022, 2023)

for (yr in years_to_map) {
  
  # A. Filter and Join Data for the specific year
  rain_data_yr <- treat_data %>%
    filter(year == yr) %>%
    select(ea_id, rain_pct_deviation_tamsat, DS30_tamsat) %>% 
    left_join(villages_gps, by = "ea_id") %>%
    drop_na(rain_pct_deviation_tamsat, longitude_jit, latitude_jit, DS30_tamsat)%>%
    # FIX: Clamp the values so they don't fall outside the map range
    mutate(
      rain_pct_deviation_tamsat = pmin(pmax(rain_pct_deviation_tamsat, -rain_limit), rain_limit)
    )
  
  # B. Convert to spatial points (SpatVector)
  rain_spat <- vect(rain_data_yr, 
                    geom = c("longitude_jit", "latitude_jit"), 
                    crs = "EPSG:4326")
  
  rain_spat_control <- rain_spat[rain_spat$DS30_tamsat == 0, ]
  rain_spat_treated <- rain_spat[rain_spat$DS30_tamsat == 1, ]
  
  # C. Set File Path for this year
  file_name <- paste0("rainfall_pct_deviation_AEZ_tamsat", yr, ".png")
  full_out_path <- file.path(out_dir, file_name)
  
  # D. Start Graphics Device
  png(filename = full_out_path, width = 3000, height = 2000, res = 300)
  
  # --- Update Margins and Device ---
  # Increase top margin (3rd value) to 5 or 6 to clear the legend
  par(mar = c(2, 2, 4, 12), xpd = NA) 
  
  # --- Layer 1: Base Map ---
  plot(senegal, 
       col = "grey95", 
       border = "grey40", 
       lwd = 0.6, 
       axes = FALSE,
       main = paste("Post-Onset Rainfall Anomaly (30 Days),", yr))
  
  # Define palette once
  cols_full <- hcl.colors(50, "BrBG", rev = FALSE)
  
  # Remove the very light middle part
  cols <- cols_full[c(1:20, 31:50)]
  
  # --- Controls (circles WITH legend) ---
  plot(rain_spat_control, "rain_pct_deviation_tamsat",
       col = cols,
       pch = 16,
       cex = 1.2,
       add = TRUE,
       type = "continuous",
       range = rain_range,
       plg = list(
         x = -12.1,
         y = 16.1,
         title = "Mean Deviation (%)\n ",
         title.cex = 0.8,
         title.font = 2,
         title.x = -12.1,
         title.y = 16.1,
         at = c(80, 40, 0, -40, -80),
         labels = c("+80%", "+40%", "Normal", "-40%", "-80%"),
         inset = c(-0.15, 0.1),
         shrink = 0.6
       ))
  
  # --- Treated (squares, NO legend) ---
  plot(rain_spat_treated, "rain_pct_deviation_tamsat",
       col = cols,
       pch = 15,
       cex = 1.4,
       add = TRUE,
       type = "continuous",
       range = rain_range,
       legend = FALSE)
  
  # --- Treatment legend ---
  legend(legend = c("Control", "Treated"),
         x = -12.2,
         y = 15.3,
         pch = c(1, 0),
         pt.cex = c(1.2, 1.4),
         bty = "n")
  
  # G. Layer 3: Region Labels
  others <- senegal[senegal$AEZ != "Senegal River Valley", ]
  text(centroids(others), "AEZ", cex = 0.6, col = "black", family = "sans", font = 3)
  
  # 2. Plot the Senegal River Valley at a specific coordinate of your choice
  text(x = -13.9, y = 16.4, labels = "Senegal River Valley", 
       cex = 0.6, col = "black", family = "sans", font = 3)
  
  
  # Close and save
  dev.off()
  
  # Print progress to console
  message(paste("Successfully generated map for:", yr))
}

# ==============================================================================
# SCRIPT COMPLETE
# ==============================================================================
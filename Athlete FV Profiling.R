#----Introductory Notes----

# This script calculates the Vertical Force-Velocity profile (Samozino Method) for athletes based on vertical jump data (loaded and unloaded).
# It can work for both Squat Jumps and Countermovement Jumps; you need to ensure you are controlling for height, as it is a major component to the calculation.
# I stripped it from the free Excel/Google sheet from their website: https://jbmorin.net/2017/12/13/a-spreadsheet-for-sprint-acceleration-force-velocity-power-profiling/
# The issue is that Excel and Google Sheets handle large exponents, so with the assistance of AI, I was able to convert the calculations to R for more consistent and faster calculations.

# The code is expecting an export file from the VALD ForceDecks web app with the following columns:
# Name, BW [KG], Additional Load [kg], Jump Height (Imp-Mom) [cm], Countermovement Depth [cm]
# To use this with any data set, I recommend renaming the columns to match these exactly, or if you're brave, to modify the code (Ctrl+F and have fun!).

# 0) Libraries & constants
library(dplyr)
library(readr)
library(tibble)
library(ggplot2)

g <- 9.81        # gravitational acceleration (m/s^2)
show_plots <- TRUE  # set FALSE to not show plots

# 1) Load data (expects ForceDecks export column names)
#    Name, BW [KG], Additional Load [kg], Jump Height (Imp-Mom) [cm], Countermovement Depth [cm]
path <- file.choose()  # choose your .csv
raw <- read_csv(path, show_col_types = FALSE)

# 2) Select/clean columns, convert to meters, filter bad rows
df <- raw %>%
  transmute(
    athlete_id = Name,
    mass = `BW [KG]`,
    load = `Additional Load [kg]`,
    jump_height = `Jump Height (Imp-Mom) [cm]` / 100,       # convert to m
    depth = abs(`Countermovement Depth [cm]` / 100)         # convert to m
  ) %>%
  filter(is.finite(jump_height), jump_height > 0,
         is.finite(depth), depth > 0,
         is.finite(mass), is.finite(load))

if (nrow(df) == 0) stop("No valid rows after filtering. Check column names/units and data quality.")

# 3) Split by athlete for individual analysis
by_athlete <- split(df, df$athlete_id)

results_list <- list()
plot_list <- list()

for (nm in names(by_athlete)) {
  data <- by_athlete[[nm]]
  
  # 3a) Use athlete-specific median push-off distance (depth) across their trials
  s_med <- median(data$depth, na.rm = TRUE)
  data$depth <- s_med
  
  # 3b) Kinematics & mean force (Samozino method)
  data <- data %>%
    mutate(
      m_total = mass + load,                  # total system mass Bw + load (kg)
      v_to = sqrt(2 * g * jump_height),       # take-off velocity (m/s)
      v_mean = v_to / 2,                      # mean concentric velocity (m/s)
      a_mean = v_to^2 / (2 * depth),          # mean concentric acceleration (m/s^2)
      force = m_total * (g + a_mean)          # mean concentric force (N)
    ) %>%
    filter(is.finite(v_mean), is.finite(force))
  
  if (nrow(data) < 2) {
    warning(paste0("Athlete '", nm, "' has <2 valid trials. Skipping model fit.")) # athletes need at least 2 trials
    next
  }
  
  # 3c) Linear F–V model
  model <- lm(force ~ v_mean, data = data)
  coefs <- coef(model)
  if (!all(is.finite(coefs))) {
    warning(paste0("Non-finite coefficients for athlete '", nm, "'. Skipping."))
    next
  }
  
  force_at_zero <- unname(coefs[1])                     # F0 (N) at v=0
  slope_actual  <- unname(coefs[2])                     # slope (N·s·m^-1); should be negative
  velocity_at_zero <- -force_at_zero / slope_actual     # V0 (m/s) at F=0
  max_power <- (force_at_zero * velocity_at_zero) / 4   # max power
  r_squared <- summary(model)$r.squared                 # goodness of fit - ideally >0.8
  
  # 3d) Per-kg quantities (using body weight)
  mass_min <- min(data$mass, na.rm = TRUE)              # Body weight of athlete (kg)
  if (!is.finite(mass_min) || mass_min <= 0) {
    warning(paste0("Invalid mass for athlete '", nm, "'. Skipping."))
    next
  }
  
  slope_per_kg <- slope_actual / mass_min
  p_max_per_kg <- max_power / mass_min
  
  # 3e) optimal slope per kg (Samozino method)
  if (is.finite(s_med) && s_med > 0 && is.finite(p_max_per_kg) && p_max_per_kg > 0) {
    term1 <- -(g^6 * s_med^6)
    term2 <- -18 * g^3 * s_med^5 * p_max_per_kg^2
    term3 <- -54 * s_med^4 * p_max_per_kg^4
    radical_inner <- 2 * g^3 * s_med^9 * p_max_per_kg^6 + 27 * s_med^8 * p_max_per_kg^8
    radical <- 6 * sqrt(3) * sqrt(radical_inner)
    x_input <- term1 + term2 + term3 + radical
    x <- -sign(x_input) * abs(x_input)^(1/3)
    
    slope_opt_per_kg <- {
      tmp <- -(g^2) / (3 * p_max_per_kg) -
        (-g^4 * s_med^4 - 12 * g * s_med^3 * p_max_per_kg^2) / (3 * s_med^2 * p_max_per_kg * x) +
        x / (3 * s_med^2 * p_max_per_kg)
      -abs(tmp)  # ensure negative orientation
    }
  } else {
    slope_opt_per_kg <- NA_real_
  }
  
  # 3f) F–V imbalance (% of optimal) and qualitative label (inline case_when)
  fvi_percent <- if (is.finite(slope_opt_per_kg) && slope_opt_per_kg != 0) {
    abs(slope_per_kg / slope_opt_per_kg) * 100
  } else {
    NA_real_
  }
  
  recommendation <- dplyr::case_when(
    is.na(fvi_percent)            ~ "Insufficient Data",
    fvi_percent < 60              ~ "High Force Deficit",
    fvi_percent < 90              ~ "Low Force Deficit",
    fvi_percent <= 110            ~ "Well Balanced",
    fvi_percent <= 140            ~ "Low Velocity Deficit",
    TRUE                          ~ "High Velocity Deficit"
  )
  
  # 3g) Plot (optional)
  if (isTRUE(show_plots)) {
    plot_title <- paste0("F–V Profile: ", nm, "   |   R² = ", round(r_squared, 3))
    plot_subtitle <- paste0("Body mass = ", round(mean(data$mass, na.rm = TRUE), 1), " kg",
                            " | Depth = ", round(s_med * 100, 1), " cm")
    p <- ggplot(data, aes(x = v_mean, y = force)) +
      geom_point(size = 3) +
      geom_smooth(method = "lm", se = FALSE) +
      geom_text(aes(label = paste0(load, " kg")), vjust = -1, size = 3) +  # label each point
      labs(
        title    = plot_title,
        subtitle = plot_subtitle,
        x        = "Mean Velocity (m/s)",
        y        = "Force (N)") +
      coord_cartesian(clip = "off") +  # allow labels outside plot bounds
      expand_limits(y = max(data$force) * 1.02) +  # 2% padding above top point
      theme_minimal() +
      theme(plot.margin = margin(10, 20, 10, 20))  # extra margin on right
    print(p)
    plot_list[[nm]] <- p
  }
  
  # 3h) Collect results row
  results_list[[nm]] <- tibble(
    athlete_id = nm,
    body_mass_kg = round(mean(data$mass, na.rm = TRUE), 1),   # athlete’s body weight
    depth_med_m = round(s_med, 3),                           # countermovement depth (m)
    force_at_zero = round(force_at_zero, 1),
    velocity_at_zero = round(velocity_at_zero, 2),
    max_power = round(max_power, 1),
    slope_actual = round(slope_actual, 1),
    slope_per_kg = round(slope_per_kg, 2),
    slope_opt_per_kg = round(slope_opt_per_kg, 2),
    fvi_percent = round(fvi_percent, 1),
    r_squared = round(r_squared, 3),
    recommendation = recommendation
  )
}

# 4) Final table
results <- bind_rows(results_list)
print(results, n = Inf)

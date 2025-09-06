R script for athlete-level Force–Velocity profiling from ForceDecks exports. Implements Samozino’s method, dynamic slope optimization, and athlete-specific feedback. Includes regression plots, FVI classification, and batch analysis across multiple athletes.

# Force–Velocity Profile Generator (ForceDecks)

This R script processes athlete jump data from ForceDecks exports to generate individualized Force–Velocity (F-V) profiles. It applies Samozino’s method with dynamically calculated optimal slopes to evaluate performance and classify force–velocity imbalances.

---

## Features

- Automatic import of `.csv` ForceDecks exports via `file.choose()`
- Handles multiple athletes and trials
- Applies Samozino’s method with precise optimization logic
- Calculates:
  - F₀ (Max Force)
  - V₀ (Max Velocity)
  - Pmax (Power)
  - F-V Slope
  - Optimal slope per athlete
  - Force–Velocity Imbalance (% optimal)
- Classifies athletes into training needs:
  - High Force Deficit
  - Low Force Deficit
  - Well Balanced
  - Low Velocity Deficit
  - High Velocity Deficit
- Automatically generates F–V regression plots per athlete with R²

---

## Input Format

CSV file exported from ForceDecks containing (minimally) the following columns:

| Column                       | Description                  |
|-----------------------------|------------------------------|
| `Name`                      | Athlete identifier           |
| `BW [KG]`                   | Body mass in kilograms       |
| `Additional Load [kg]`      | Load used for that trial     |
| `Jump Height (Imp-Mom) [cm]`| Jump height in centimeters   |
| `Countermovement Depth [cm]`| Push-off distance in cm      |

---

## How It Works

1. Launch script: `source("fv_profile_runner.R")`
2. Choose your CSV file when prompted
3. Script processes each athlete’s jumps:
   - Applies median push-off distance
   - Filters invalid jumps (depth/jump height > 0)
   - Runs F–V regression per athlete
   - Computes individualized optimal slope
   - Classifies imbalance
   - Plots and prints summary

---

## Example Output
| athlete_id |   F0 (N) | V₀ (m/s) | Pmax (W) | slope_per_kg | slope_opt_per_kg | FVI (%) | R²   | Recommendation       |
|------------|----------|----------|----------|---------------|-------------------|---------|------|-----------------------|
| athlete_1  |   2491   |   3.26   |   2029   |     -11.3     |       -12.5       |   90.2  | 0.94 | Low Force Deficit     |
| athlete_2  |   3395   |   3.58   |   3036   |     -11.7     |       -14.2       |   82.3  | 0.96 | Low Force Deficit     |
| athlete_3  |   3096   |   3.61   |   2796   |     -10.8     |       -13.6       |   79.6  | 0.91 | Low Force Deficit     |



Each athlete also gets a Force vs Velocity regression plot with R² value.

---

## Interpretation Key
| Imbalance (%) | Category                | Training Focus                   |
|---------------|-------------------------|----------------------------------|
| < 60%         | High Force Deficit      | Max strength                     |
| 60–89%        | Low Force Deficit       | Mixed strength work              |
| 90–110%       | Well Balanced           | Maintain current program         |
| 111–140%      | Low Velocity Deficit    | Speed–strength, power training   |
| > 140%        | High Velocity Deficit   | Ballistic & velocity-based work  |

---

## Dependencies
- `dplyr`
- `readr`
- `tibble`
- `ggplot2`

Install with:
```r
install.packages(c(\"dplyr\", \"readr\", \"tibble\", \"ggplot2\"))
```

---

## Author
Created and maintained by **Troy Wilson**; developed with the assistance of OpenAI’s ChatGPT for code structure, documentation, and logic verification

---

## References
This tool is based on the F–V profiling method developed by Samozino and Morin. It draws from the original scientific literature, spreadsheet tools, and optimization logic used in their applied sport science work.

### Primary Methodological Papers
1. **Samozino, P., Rejc, E., Di Prampero, P. E., Belli, A., & Morin, J. B.** (2012).  
   *Optimal force–velocity profile in ballistic movements—altius: citius or fortius?*  
   Medicine & Science in Sports & Exercise, 44(2), 313–322.  
   https://doi.org/10.1249/MSS.0b013e31822d757a

2. **Samozino, P., Morin, J. B., Hintzy, F., & Belli, A.** (2008).  
   *A simple method for measuring force, velocity and power output during squat jump.*  
   Journal of Biomechanics, 41(14), 2940–2945.  
   https://doi.org/10.1016/j.jbiomech.2008.07.028

3. **Morin, J. B., Samozino, P., Zameziati, K., & Belli, A.** (2010).  
   *Direct measurement of power during one single sprint on treadmill.*  
   Journal of Biomechanics, 43(10), 1970–1975.  
   https://doi.org/10.1016/j.jbiomech.2010.03.031

---

### Public Spreadsheets and Online Tools
4. **Samozino, P.** (2017).  
   *Free Excel spreadsheet for calculating F–V and P–V profiles from jump testing.*  
   [https://jbmorin.net/2017/12/13/a-spreadsheet-for-sprint-acceleration-force-velocity-power-profiling/](https://jbmorin.net/2017/12/13/a-spreadsheet-for-sprint-acceleration-force-velocity-power-profiling/)  
   (Includes downloadable `.xls` files used as the basis for the slope optimization and profile logic in this repo.)

5. **Samozino, P., & Morin, J.-B.**  
   *Force–velocity profiling for jumping and sprinting: practical guide.*  
   Shared in workshops, conferences, and performance labs across Europe and North America. Used in national team support programs and validated in elite sport settings.

---

### Additional Reading (for applied coaches)
6. **Morin, J.-B., & Samozino, P.** (2016).  
   *Interpreting power-force-velocity profiles for individualized and specific training.*  
   *International Journal of Sports Physiology and Performance, 11(2), 267–272.*  
   https://doi.org/10.1123/ijspp.2015-0638

7. **Morin, J.-B., & Samozino, P.** (2017).  
   *Practical guide to analyzing the sprint acceleration force–velocity profile.*  
   *Published online by Science for Sport.*  
   [https://www.scienceforsport.com/force-velocity-profiling/](https://www.scienceforsport.com/force-velocity-profiling/)

---

### Spreadsheet Credits
This project was inspired by the original Excel-based tools created by Pierre Samozino and Jean-Benoît Morin. Their work laid the foundation for integrating theoretical mechanics with applied performance analysis in jumping and sprinting.

---

## Citation Suggestion

If you use this tool in research, please cite the 2012 Samozino et al. paper and reference this repository in your methods section.

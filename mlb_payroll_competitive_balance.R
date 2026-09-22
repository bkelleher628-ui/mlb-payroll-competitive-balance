# MLB Payroll & Competitive Balance Analysis
# Brandon Kelleher
# Advanced portfolio version
#
# Research question:
#   How strongly does MLB payroll explain team wins, and how would different
#   payroll compression rules affect predicted competitive balance?
#
# Dataset expected:
#   mlb_payrolls.csv
#
# Dataset structure used by this script:
#   Team, Team Name, Year, Average Age, Total Payroll Allocations,
#   Active 26-Man, Injured, Retained, Buried, Wins, Losses, Postseason
#
# Notes:
#   - The 2020 season was shortened, so the script uses wins scaled to a
#     162-game season: Wins_162 = Win_Pct * 162.
#   - Payroll is evaluated both in dollar terms and relative to each season's
#     median payroll so the model is not driven only by payroll inflation.
#   - Policy simulations are counterfactual: they show what the fitted model
#     predicts if payrolls were compressed. They do not model real roster
#     behavior under a new collective bargaining agreement.

# ----------------------------
# 1. Setup
# ----------------------------

required_packages <- c("readr", "dplyr", "ggplot2", "tidyr", "scales")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop(
    paste0(
      "Missing packages: ", paste(missing_packages, collapse = ", "),
      "\nInstall them with: install.packages(c('",
      paste(missing_packages, collapse = "', '"), "'))"
    )
  )
}

library(readr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(scales)

set.seed(42)

output_dir <- "outputs"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# If the exact file name is not present, use the first matching MLB payroll CSV.
data_file <- "mlb_payrolls.csv"

if (!file.exists(data_file)) {
  possible_files <- list.files(pattern = "^mlb_payrolls.*\\.csv$", ignore.case = TRUE)

  if (length(possible_files) == 0) {
    stop("Could not find mlb_payrolls.csv. Place the dataset in the working directory.")
  }

  data_file <- possible_files[1]
  message("Using data file: ", data_file)
}

# ----------------------------
# 2. Load and clean data
# ----------------------------

parse_money <- function(x) {
  x <- gsub("[$,]", "", x)
  x[x == "" | x == "-"] <- "0"
  as.numeric(x)
}

gini <- function(x) {
  x <- x[!is.na(x)]
  n <- length(x)
  mu <- mean(x)

  if (n == 0 || mu == 0) {
    return(NA_real_)
  }

  sum(abs(outer(x, x, "-"))) / (2 * n^2 * mu)
}

rmse <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2, na.rm = TRUE))
}

model_metrics <- function(model, data, label) {
  predicted <- predict(model, newdata = data)

  data.frame(
    Model = label,
    R2 = summary(model)$r.squared,
    Adj_R2 = summary(model)$adj.r.squared,
    RMSE = rmse(data$Wins_162, predicted),
    stringsAsFactors = FALSE
  )
}

mlb_raw <- read_csv(data_file, show_col_types = FALSE)

mlb <- mlb_raw %>%
  mutate(
    Year = as.integer(Year),
    Average_Age = as.numeric(`Average Age`),
    Payroll = parse_money(`Total Payroll Allocations`),
    Active_26 = parse_money(`Active 26-Man`),
    Injured = parse_money(Injured),
    Retained = parse_money(Retained),
    Buried = parse_money(Buried),
    Wins = as.numeric(Wins),
    Losses = as.numeric(Losses),
    Games = Wins + Losses,
    Win_Pct = Wins / Games,
    Wins_162 = Win_Pct * 162,
    Playoff = ifelse(Postseason == "No Playoffs", 0, 1),
    Payroll_M = Payroll / 1000000,
    Active_Share = Active_26 / Payroll,
    Injured_Share = Injured / Payroll,
    Retained_Share = Retained / Payroll,
    Buried_Share = Buried / Payroll
  ) %>%
  group_by(Year) %>%
  mutate(
    Median_Payroll = median(Payroll, na.rm = TRUE),
    Relative_Payroll = Payroll / Median_Payroll,
    Log_Payroll = log(Payroll),
    Log_Relative_Payroll = log(Relative_Payroll)
  ) %>%
  ungroup()

# ----------------------------
# 3. Exploratory summaries
# ----------------------------

project_summary <- data.frame(
  Metric = c(
    "Team-seasons",
    "Teams",
    "Seasons",
    "Average 162-game wins",
    "SD of 162-game wins",
    "Gini of 162-game wins"
  ),
  Value = c(
    nrow(mlb),
    length(unique(mlb$Team)),
    paste0(min(mlb$Year), "-", max(mlb$Year)),
    round(mean(mlb$Wins_162), 2),
    round(sd(mlb$Wins_162), 2),
    round(gini(mlb$Wins_162), 4)
  )
)

write_csv(project_summary, file.path(output_dir, "project_summary.csv"))

payroll_by_year <- mlb %>%
  group_by(Year) %>%
  summarize(
    Min_Payroll_M = min(Payroll_M, na.rm = TRUE),
    Median_Payroll_M = median(Payroll_M, na.rm = TRUE),
    Max_Payroll_M = max(Payroll_M, na.rm = TRUE),
    Payroll_Gini = gini(Payroll),
    .groups = "drop"
  )

write_csv(payroll_by_year, file.path(output_dir, "payroll_by_year.csv"))

payroll_quartiles <- mlb %>%
  mutate(
    Payroll_Quartile = ntile(Relative_Payroll, 4)
  ) %>%
  group_by(Payroll_Quartile) %>%
  summarize(
    Avg_Relative_Payroll = mean(Relative_Payroll, na.rm = TRUE),
    Avg_Wins_162 = mean(Wins_162, na.rm = TRUE),
    Playoff_Rate = mean(Playoff, na.rm = TRUE),
    Team_Seasons = n(),
    .groups = "drop"
  )

write_csv(payroll_quartiles, file.path(output_dir, "payroll_quartiles.csv"))

# ----------------------------
# 4. Regression models
# ----------------------------

model_payroll_linear <- lm(Wins_162 ~ Payroll_M, data = mlb)
model_log_payroll <- lm(Wins_162 ~ Log_Payroll, data = mlb)
model_relative_payroll <- lm(Wins_162 ~ Log_Relative_Payroll, data = mlb)
model_relative_age <- lm(Wins_162 ~ Log_Relative_Payroll + Average_Age, data = mlb)

model_roster_structure <- lm(
  Wins_162 ~ Log_Relative_Payroll + Average_Age + Active_Share + Injured_Share + Retained_Share,
  data = mlb
)

model_policy <- lm(
  Wins_162 ~ Log_Payroll + factor(Year),
  data = mlb
)

model_full_year <- lm(
  Wins_162 ~ Log_Payroll + Average_Age + Active_Share + Injured_Share + Retained_Share + factor(Year),
  data = mlb
)

model_comparison <- bind_rows(
  model_metrics(model_payroll_linear, mlb, "Payroll only"),
  model_metrics(model_log_payroll, mlb, "Log payroll"),
  model_metrics(model_relative_payroll, mlb, "Relative payroll"),
  model_metrics(model_relative_age, mlb, "Relative payroll + age"),
  model_metrics(model_roster_structure, mlb, "Roster structure model"),
  model_metrics(model_full_year, mlb, "Full model + year effects")
)

write_csv(model_comparison, file.path(output_dir, "model_comparison.csv"))

# Interpretation helper for log-relative payroll.
log_relative_beta <- coef(model_relative_payroll)["Log_Relative_Payroll"]
ten_pct_payroll_effect <- log_relative_beta * log(1.10)

cat("\nEstimated effect of 10% higher relative payroll:", round(ten_pct_payroll_effect, 2), "wins\n")

# ----------------------------
# 5. Efficiency table
# ----------------------------

mlb <- mlb %>%
  mutate(
    Predicted_Wins_Policy_Model = predict(model_policy, newdata = mlb),
    Payroll_Residual = Wins_162 - Predicted_Wins_Policy_Model
  )

efficiency_table <- mlb %>%
  select(
    Year,
    Team,
    `Team Name`,
    Payroll_M,
    Relative_Payroll,
    Wins_162,
    Predicted_Wins_Policy_Model,
    Payroll_Residual,
    Postseason
  ) %>%
  arrange(desc(Payroll_Residual))

write_csv(efficiency_table, file.path(output_dir, "team_efficiency_table.csv"))

# ----------------------------
# 6. Salary cap and floor simulation
# ----------------------------

simulate_policy <- function(data, label, floor_multiple = NA_real_, cap_multiple = NA_real_) {
  sim_data <- data %>%
    group_by(Year) %>%
    mutate(
      Payroll_Simulated = Payroll,
      Floor_Level = ifelse(is.na(floor_multiple), NA_real_, floor_multiple * Median_Payroll),
      Cap_Level = ifelse(is.na(cap_multiple), NA_real_, cap_multiple * Median_Payroll),
      Payroll_Simulated = ifelse(!is.na(floor_multiple) & Payroll_Simulated < Floor_Level, Floor_Level, Payroll_Simulated),
      Payroll_Simulated = ifelse(!is.na(cap_multiple) & Payroll_Simulated > Cap_Level, Cap_Level, Payroll_Simulated),
      Log_Payroll = log(Payroll_Simulated),
      Was_Floored = !is.na(floor_multiple) & Payroll < Floor_Level,
      Was_Capped = !is.na(cap_multiple) & Payroll > Cap_Level,
      Was_Affected = Was_Floored | Was_Capped
    ) %>%
    ungroup()

  predicted_before <- predict(model_policy, newdata = data)
  predicted_after <- predict(model_policy, newdata = sim_data)

  data.frame(
    Scenario = label,
    SD_Before = sd(predicted_before, na.rm = TRUE),
    SD_After = sd(predicted_after, na.rm = TRUE),
    SD_Reduction_Pct = 100 * (sd(predicted_before, na.rm = TRUE) - sd(predicted_after, na.rm = TRUE)) / sd(predicted_before, na.rm = TRUE),
    Gini_Before = gini(predicted_before),
    Gini_After = gini(predicted_after),
    Gini_Reduction_Pct = 100 * (gini(predicted_before) - gini(predicted_after)) / gini(predicted_before),
    Team_Seasons_Affected = sum(sim_data$Was_Affected, na.rm = TRUE),
    Team_Seasons_Capped = sum(sim_data$Was_Capped, na.rm = TRUE),
    Team_Seasons_Floored = sum(sim_data$Was_Floored, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

policy_results <- bind_rows(
  simulate_policy(mlb, "Cap 1.10x median", cap_multiple = 1.10),
  simulate_policy(mlb, "Cap 1.25x median", cap_multiple = 1.25),
  simulate_policy(mlb, "Cap 1.50x median", cap_multiple = 1.50),
  simulate_policy(mlb, "Floor 0.75x median", floor_multiple = 0.75),
  simulate_policy(mlb, "Band 0.75x-1.25x", floor_multiple = 0.75, cap_multiple = 1.25),
  simulate_policy(mlb, "Band 0.85x-1.15x", floor_multiple = 0.85, cap_multiple = 1.15)
)

write_csv(policy_results, file.path(output_dir, "policy_simulation_results.csv"))

print(policy_results)

# ----------------------------
# 7. Pittsburgh Pirates context table
# ----------------------------

pirates_context <- mlb %>%
  group_by(Year) %>%
  mutate(
    Payroll_Rank = rank(-Payroll, ties.method = "first"),
    Wins_Rank = rank(-Wins_162, ties.method = "first")
  ) %>%
  ungroup() %>%
  filter(Team == "PIT") %>%
  select(
    Year,
    Payroll_M,
    Payroll_Rank,
    Relative_Payroll,
    Wins_162,
    Wins_Rank,
    Predicted_Wins_Policy_Model,
    Payroll_Residual,
    Postseason
  )

write_csv(pirates_context, file.path(output_dir, "pirates_context.csv"))

# ----------------------------
# 8. Visualizations
# ----------------------------

p1 <- ggplot(mlb, aes(x = Relative_Payroll, y = Wins_162)) +
  geom_point(alpha = 0.65) +
  geom_smooth(method = "lm", se = FALSE) +
  scale_x_continuous(labels = label_number(accuracy = 0.1)) +
  labs(
    title = "Relative Payroll and 162-Game Wins",
    subtitle = "Payroll is expressed as a multiple of each season's median payroll",
    x = "Relative payroll",
    y = "Wins scaled to 162 games"
  ) +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "01_relative_payroll_vs_wins.png"), p1, width = 9, height = 6, dpi = 300)

p2 <- model_comparison %>%
  mutate(Model = factor(Model, levels = Model)) %>%
  ggplot(aes(x = Model, y = R2)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Model Comparison",
    subtitle = "Explained variation in 162-game wins",
    x = NULL,
    y = "R-squared"
  ) +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "02_model_comparison.png"), p2, width = 9, height = 6, dpi = 300)

p3 <- policy_results %>%
  mutate(Scenario = factor(Scenario, levels = Scenario)) %>%
  ggplot(aes(x = Scenario, y = SD_Reduction_Pct)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Predicted Competitive Balance Improvement",
    subtitle = "Reduction in standard deviation of predicted wins",
    x = NULL,
    y = "SD reduction (%)"
  ) +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "03_policy_sd_reduction.png"), p3, width = 9, height = 6, dpi = 300)

p4 <- payroll_quartiles %>%
  mutate(Payroll_Quartile = paste0("Q", Payroll_Quartile)) %>%
  ggplot(aes(x = Payroll_Quartile, y = Avg_Wins_162)) +
  geom_col() +
  labs(
    title = "Average Wins by Relative Payroll Quartile",
    x = "Relative payroll quartile",
    y = "Average 162-game wins"
  ) +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "04_payroll_quartile_wins.png"), p4, width = 9, height = 6, dpi = 300)

p5 <- efficiency_table %>%
  slice_head(n = 10) %>%
  mutate(Label = paste0(Year, " ", Team)) %>%
  ggplot(aes(x = reorder(Label, Payroll_Residual), y = Payroll_Residual)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top Overperformers vs Payroll-Based Prediction",
    x = NULL,
    y = "Wins above prediction"
  ) +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "05_efficiency_residuals.png"), p5, width = 9, height = 6, dpi = 300)

p6 <- pirates_context %>%
  filter(Year >= 2018) %>%
  ggplot(aes(x = Year)) +
  geom_line(aes(y = Wins_162), linewidth = 1) +
  geom_point(aes(y = Wins_162), size = 2) +
  geom_line(aes(y = Predicted_Wins_Policy_Model), linetype = "dashed", linewidth = 1) +
  geom_point(aes(y = Predicted_Wins_Policy_Model), size = 2) +
  labs(
    title = "Pittsburgh Pirates: Actual vs Payroll-Based Predicted Wins",
    subtitle = "Dashed line is predicted wins from the policy model",
    x = NULL,
    y = "Wins scaled to 162 games"
  ) +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "06_pirates_context.png"), p6, width = 9, height = 6, dpi = 300)

# ----------------------------
# 9. Console summary
# ----------------------------

cat("\nProject summary\n")
print(project_summary)

cat("\nModel comparison\n")
print(model_comparison)

cat("\nPolicy simulation results\n")
print(policy_results)

cat("\nKey interpretation\n")
cat("A 10% increase in relative payroll is associated with about ",
    round(ten_pct_payroll_effect, 2),
    " additional 162-game wins in the relative-payroll model.\n", sep = "")

cat("\nFiles written to the outputs/ folder.\n")

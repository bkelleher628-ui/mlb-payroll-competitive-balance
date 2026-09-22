# MLB Payroll & Competitive Balance

An R-based baseball analytics project examining MLB payroll, team performance, spending efficiency, and hypothetical salary-cap / salary-floor policies from 2011–2024.

## Project Overview

Major League Baseball does not use a traditional hard salary cap, which creates large payroll differences across the league.

This project analyzes how much payroll explains winning, whether spending has diminishing returns, which teams outperform their payroll-based expectations, and how different payroll policy structures could affect competitive balance.

The project uses 420 MLB team-season observations from 2011 through 2024 and applies regression modeling, feature engineering, residual analysis, and counterfactual simulation in R.

## Research Questions

1. How strongly is payroll associated with regular-season wins?
2. Does payroll spending show diminishing returns?
3. Does roster structure improve the model beyond payroll alone?
4. Which teams outperform or underperform their payroll-based expectations?
5. How would hypothetical salary caps, salary floors, or cap-floor systems affect predicted competitive balance?

## Data

The dataset contains MLB team-level payroll and performance data from 2011–2024.

The analysis uses variables such as team, season, payroll, roster payroll allocation, wins, losses, average age, and postseason result.

The raw dataset is not redistributed in this repository. To reproduce the analysis, download the original dataset and save it as:

`mlb_payrolls.csv`

Dataset source:

https://www.kaggle.com/datasets/christophertreasure/mlb-team-payrolls-2011-2024

## Data Preparation

The 2020 season was adjusted to a 162-game basis because it was shortened.

Instead of only using raw payroll dollars, the project also calculates each team's payroll relative to that season's median payroll.

This allows teams from different seasons to be compared more fairly.

Key engineered variables include:

- 162-game adjusted wins
- Relative payroll
- Log payroll
- Active roster payroll share
- Injured-list payroll share
- Retained payroll share
- Buried payroll share
- Payroll efficiency residuals

## Modeling Approach

Several regression models were compared:

- Raw payroll model
- Log payroll model
- Relative payroll model
- Relative payroll plus age model
- Roster structure model
- Full model with season effects

The goal was not only to ask whether money matters, but also to understand how much of team performance payroll actually explains.

## Key Model Results

| Model | R² | Approx. RMSE |
|---|---:|---:|
| Raw Payroll | 11.4% | 11.9 wins |
| Log Payroll | 10.3% | 12.0 wins |
| Relative Payroll | 14.0% | 11.7 wins |
| Relative Payroll + Age | 31.7% | 10.5 wins |
| Roster Structure Model | 39.9% | 9.8 wins |
| Full Model + Season Effects | 43.8% | 9.5 wins |

Payroll is associated with winning, but payroll alone does not fully explain team success.

The fuller model performs better because it includes roster structure and season context.

## Main Findings

A 10% increase in payroll relative to the league median is associated with approximately 1.1 additional wins over a 162-game season.

Higher-payroll teams win more on average, but the relationship is not automatic.

The highest payroll quartile averaged about 87.6 wins, while the lowest payroll quartile averaged about 76.4 wins.

That gap is meaningful, but there is still substantial variation within each payroll group.

This suggests that financial resources matter, but player development, roster construction, injuries, scouting, coaching, and front-office decision making also play major roles.

## Payroll Efficiency

The project calculates a payroll efficiency residual for each team-season:

Residual = Actual Wins - Payroll-Based Predicted Wins

A positive residual means a team won more games than expected based on payroll.

A negative residual means a team won fewer games than expected based on payroll.

This helps identify teams that overperformed or underperformed their financial position.

## Competitive Balance Simulation

The project simulates several hypothetical payroll policy scenarios.

Competitive balance is measured using:

- Standard deviation of predicted wins
- Gini coefficient of predicted wins

Lower values indicate a more compressed and balanced distribution of predicted wins.

## Policy Scenarios Tested

The simulation tested:

- 1.10× median payroll cap
- 1.25× median payroll cap
- 1.50× median payroll cap
- 0.75× median payroll floor
- 0.75× to 1.25× median payroll band
- 0.85× to 1.15× median payroll band

## Policy Results

The 1.25× median payroll cap affected 109 team-seasons.

It reduced predicted win dispersion by about 17.5% and reduced predicted Gini inequality by about 19.3%.

The 0.75× to 1.25× cap-floor band had a larger effect.

It affected 224 team-seasons and reduced predicted win dispersion by about 46.1%.

This suggests that a cap-only system compresses the top of the payroll distribution, while a cap-floor system changes both the top and bottom.

## Pittsburgh Pirates Case Study

The project includes a Pirates-specific section that compares actual wins to payroll-model expected wins.

This creates a useful framework for evaluating a smaller-payroll organization.

The question becomes:

When payroll is limited, what allows a team to generate wins above its financial expectation?

This is the part of the project most connected to baseball operations and front-office analytics.

## Repository Files

- `mlb_payroll_competitive_balance.R` — complete R script for cleaning, modeling, simulations, residual analysis, and visualizations
- `MLB_Payroll_Competitive_Balance_Advanced_Portfolio.pptx` — professional presentation summarizing the project
- `README.md` — project overview and documentation

## Tools Used

- R
- RStudio
- readr
- dplyr
- tidyr
- ggplot2
- scales

## Skills Demonstrated

- Data cleaning
- Feature engineering
- Regression modeling
- Model comparison
- RMSE and R² interpretation
- Log transformations
- Residual analysis
- Gini coefficient
- Counterfactual simulation
- Data visualization
- Baseball analytics
- Technical communication

## Limitations

This project is descriptive, not causal.

The model estimates historical relationships, but it does not prove that increasing payroll directly causes a specific number of additional wins.

The salary-cap and salary-floor simulations are simplified. Real teams, players, agents, and front offices would likely change behavior under a different payroll system.

The model also does not include several important baseball variables, such as WAR, run differential, injury days, player projections, contract efficiency, farm-system strength, or player development outcomes.

## Future Work

Future versions of this project could improve the model by adding:

- Player WAR
- Run differential
- Injury data
- Contract value
- Player projections
- Farm-system rankings
- Homegrown player production
- Free-agent spending
- Multi-year roster strategy

The next step would be moving from:

"How much does a team spend?"

to:

"How efficiently does a team convert payroll and player-development resources into wins?"

## Author

Brandon Kelleher

B.S. Mathematics  
Data Science / Baseball Analytics

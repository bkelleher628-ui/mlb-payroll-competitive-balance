# MLB Payroll & Competitive Balance

### An R-based analysis of MLB payroll, team performance, diminishing returns, and hypothetical salary-cap scenarios from 2011–2024.

## Project Overview

Major League Baseball does not use a traditional hard salary cap, which allows significant differences in team payrolls across the league.

This project examines a simple but important baseball analytics question:

**How much does payroll actually influence winning, and would limiting payroll improve competitive balance?**

Using MLB team-season data from 2011 through 2024, I analyzed the relationship between team payroll and regular-season wins using regression modeling in R. I then created hypothetical salary-cap scenarios and measured how those changes affected the predicted distribution of wins across the league.

## Research Questions

The project focused on three main questions:

1. Does higher team payroll lead to more regular-season wins?
2. Are there diminishing returns as teams continue increasing payroll?
3. Would a salary cap meaningfully improve competitive balance in MLB?

## Methods

The analysis was completed in **R** and included:

- Data cleaning and transformation
- Exploratory data analysis
- Linear regression
- Log-linear regression
- Correlation analysis
- Salary-cap simulations
- Gini coefficient calculations
- Standard deviation comparisons
- Data visualization with `ggplot2`

Two primary regression models were compared:

```text
Wins = β0 + β1(Payroll) + ε
and
Wins = β0 + β1 log(Payroll) + ε

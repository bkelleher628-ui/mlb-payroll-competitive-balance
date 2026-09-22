# mlb-payroll-competitive-balance
This project analyzes the relationship between Major League Baseball team payroll and regular-season wins from 2011–2024.

Using R, I built linear and log-linear regression models to examine whether higher payroll is associated with more wins and whether diminishing returns exist at higher spending levels. I also simulated salary-cap scenarios based on each season's median payroll and measured changes in competitive balance using the standard deviation of predicted wins and the Gini coefficient.

Project Question

Does money buy wins in Major League Baseball, and would a salary cap meaningfully improve competitive balance?

Methods

Cleaned MLB team payroll data in R

Modeled wins using linear regression

Modeled wins using log-payroll regression to capture diminishing returns

Simulated salary-cap scenarios at:

1.10x yearly median payroll

1.25x yearly median payroll

1.50x yearly median payroll

Compared competitive balance before and after the cap simulations

Key Findings

Payroll has a statistically significant positive relationship with wins.

The log-payroll model suggests diminishing returns to additional spending.

Payroll explains part of team success, but not all of it.

Salary-cap simulations improve predicted competitive balance, but the effect is moderate rather than dramatic.

Files

mlb_payroll_competitive_balance.R — main R script for cleaning, modeling, simulation, and visualization

MLB_Payroll_Competitive_Balance_Presentation.pptx — portfolio presentation summarizing the project

Tools Used

R

dplyr

ggplot2

Regression modeling

Simulation

Data visualization

Notes

The project is intended as a baseball analytics portfolio piece. It frames a real MLB policy question as a reproducible data science workflow: clean the data, build models, simulate a rule change, and communicate the results clearly.

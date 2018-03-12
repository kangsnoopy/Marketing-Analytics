# Marketing-Analytics

Charity Campaign Project

GOAL:
The goal is to identify the donners who are most likely to make donnations in one particular charity campaign, using all the donation histories of donners and campaign information from the charity side.

SQL:
The total volume of the database is immense, so the first step is to have access to the data is to use MySQL Workbench to create the database. Several tables were created to store different information:

actions table the action history of the charity
acts table contains the donnation history for every donner who has entry to the database
channels table contains campaign channel labels
contacts table contains detail information of every donner
payment_method table stores the payment method labels
prefixes table contains prefix labels
assignment2 table contains the donner information for the particular campaingn for which we want to predict

R:
Fist step is to extract relevant features. The main idea is to extract amount, frequency, recency features according to different periods (e.g. last 2,5,10 years,) and different payment methods (PA, DO), channel, etc. and profil information for the donnors like prefix.

In th modeling part, two methods were used. Scoring and random forest.

Scoring model
Scoring contains a logit model to predict the likelihood for each donner to response to this campaign, and a regression model (normal linear regression or ridge regression) to predict the amount of donnation for each person if he/she is about to donate. Then we multiply the probability and the amount to get the extimated amount. If this amount is larger than 2 which is the cost of solicitation, the charity will solicit this person, otherwise no. 
This model worked well and we got a net marfin of around 213000 euros with a cost of around 74000 euro.

Random Forest
The second model is random forest. we use all the features. Result was not applaudable. Dataset is notably largr so the trees have overfit. Further step is to try reducing the max depth of the tree or increasing minimum information gain. 





# load necessary libraries
library(tidyverse)
library(VIM)


#load full dataframe

covidfull.df <- read.csv('https://raw.githubusercontent.com/jotsap/DS6373/master/data/all-states-history.csv', header = T)
str(covidfull.df)
head(covidfull.df)
glimpse(covidfull.df)

# convert date from factor to date type
#base::as.Date( covidfull.df$date, "%y-%m-%d") -> covidfull.df$date
base::as.Date( covidfull.df$date) -> covidfull.df$date

# add rowId for easier tracking
covidfull.df$rowId <- 1:length(covidfull.df$totalTestResults)

# Missing Values: from VIM package
aggr(covidfull.df, 
     prop = FALSE, 
     combined = TRUE, 
     numbers = TRUE, 
     sortVars = TRUE, 
     sortCombs = TRUE)



### Variable Count

#positiveTestsPeopleAntigen           13514
#totalTestsPeopleAntigen              13396
#positiveTestsAntigen                 13308
#negativeTestsPeopleAntibody          13139
#positiveTestsPeopleAntibody          13139
#totalTestsAntigen                    13082
#negativeTestsAntibody                12979
#onVentilatorCumulative               12969
#totalTestsPeopleAntibody             12748
#positiveTestsAntibody                11954
#inIcuCumulative                      11450
#totalTestsAntibody                   11287
#negativeTestsViral                   10868
#totalTestEncountersViral             10599
#positiveTestsViral                   9587
#deathProbable                        9563
#onVentilatorCurrently                8586
#totalTestsPeopleViral                8088
#deathConfirmed                       8015
#inIcuCurrently                       7469
#hospitalized                         5815
#hospitalizedCumulative               5815
#totalTestsViral                      5308
#recovered                            4061
#positiveCasesViral                   3172
#hospitalizedCurrently                3010
#death                                818
#negative                             306
#positive                             133
#totalTestResults                     35
#date                                 0
#state                                0
#dataQualityGrade                     0
#deathIncrease                        0
#hospitalizedIncrease                 0
#negativeIncrease                     0
#positiveIncrease                     0
#positiveScore                        0
#totalTestEncountersViralIncrease     0
#totalTestResultsIncrease             0
#totalTestsPeopleViralIncrease        0
#totalTestsViralIncrease              0




### all POSITIVE columns
head(covidfull.df[,21:29])
# list rows with missing values
# most have NA across all the same colums
covidfull.df[is.na(covidfull.df[,21:29]),21:29 ]


### all NEGATIVE columns
head(covidfull.df[,14:18])
# list rows with missing values
# most have NA across all the same colums
covidfull.df[is.na(covidfull.df[,14:18]),14:18 ]


# remove fields with more than 6% missing
#c(positiveTestsPeopleAntigen, totalTestsPeopleAntigen, positiveTestsAntigen, negativeTestsPeopleAntibody, positiveTestsPeopleAntibody, totalTestsAntigen, negativeTestsAntibody, onVentilatorCumulative, totalTestsPeopleAntibody, positiveTestsAntibody, inIcuCumulative, totalTestsAntibody, negativeTestsViral, totalTestEncountersViral, positiveTestsViral, deathProbable, onVentilatorCurrently, totalTestsPeopleViral, deathConfirmed, inIcuCurrently, hospitalized, hospitalizedCumulative, totalTestsViral, recovered, positiveCasesViral, hospitalizedCurrently)

covidfull.df %>% dplyr::select(-c(positiveTestsPeopleAntigen, totalTestsPeopleAntigen, positiveTestsAntigen, negativeTestsPeopleAntibody, positiveTestsPeopleAntibody, totalTestsAntigen, negativeTestsAntibody, onVentilatorCumulative, totalTestsPeopleAntibody, positiveTestsAntibody, inIcuCumulative, totalTestsAntibody, negativeTestsViral, totalTestEncountersViral, positiveTestsViral, deathProbable, onVentilatorCurrently, totalTestsPeopleViral, deathConfirmed, inIcuCurrently, hospitalized, hospitalizedCumulative, totalTestsViral, recovered, positiveCasesViral, hospitalizedCurrently) )  -> covidclean.df
# alternate code: covidfull.df$positiveTestsPeopleAntigen <- NULL

## PROBLEM: TOTAL TEST DISCREPANCY - SEE DETAILS BELOW
glimpse(covidclean.df)

# Missing Values
aggr(covidclean.df, 
     prop = FALSE, 
     combined = TRUE, 
     numbers = TRUE, 
     sortVars = TRUE, 
     sortCombs = TRUE)




### looking at death, negative, positive columns
# 'death' has more than 3x the amount of missing data
covidclean.df[ is.na(covidclean.df[,c('death','negative','positive', "totalTestResults" )] ), c('date' ,'death','negative','positive',"totalTestResults" ) ]
# death
covidclean.df[ is.na(covidclean.df$death ), c('date','death','negative','positive',"totalTestResults" ) ]
# negative
covidclean.df[ is.na(covidclean.df$negative ), c('date','death','negative','positive',"totalTestResults" ) ]
# positive
covidclean.df[ is.na(covidclean.df$positive ), c('date','death','negative','positive',"totalTestResults" ) ]
# totalTestResults
covidclean.df[ is.na(covidclean.df$totalTestResults ), c('date','death','negative','positive',"totalTestResults" ) ]




###### DISCREPANCIES IN TEST COUNT ######


## POSITIVITY RATE
covidclean.df$positive / covidclean.df$totalTestResults
## NEGATIVITY RATE
covidclean.df$negative / covidclean.df$totalTestResults
## VALIDATE NEGATIVE + POSITIVE VS TOTAL
(covidclean.df$positive + covidclean.df$negative) / covidclean.df$totalTestResults


### make testDiscrepancy column
# total_results - (negative + positive)
covidclean.df$testDiscrepancy <- covidclean.df$totalTestResults - (covidclean.df$positive + covidclean.df$negative) 


### SHOW TEST DISCREPANCY ### 
# Total tests VS (Negative + Popsitive)

# all rows
covidclean.df[ , c("rowId", 'date', 'totalTestResults', 'positive', 'negative','testDiscrepancy') ]
# only discrepancy rows
covidclean.df[ ( (covidclean.df$positive + covidclean.df$negative) / covidclean.df$totalTestResults ) != 1, c("rowId",'date', 'totalTestResults', 'positive', 'negative','testDiscrepancy') ]



# define rows where total negative + postive  does NOT equal the total_tests
covidrows <- covidclean.df[covidclean.df$testDiscrepancy != 0, "rowId" ]
# ALTERNATE W/O USING ROWID
# as.numeric(row.names( covidclean.df[covidclean.df$testDiscrepancy != 0, ]  )) 

sort(covidrows, decreasing = T)

covidclean.df[covidrows, c('date', 'totalTestResults', 'positive', 'negative', 'testDiscrepancy' ) ]



# create absolute value of TestDiscrepancy for aggregate analysis
abs(covidclean.df$testDiscrepancy) -> covidclean.df$absTestDiscrepancy

### WHICH STATES HAD HIGHEST AGGREGATE TEST DISCREPANCY
covidclean.df %>% 
  dplyr::select( c(state, date, death, absTestDiscrepancy , negative, positive, totalTestResults) ) %>% 
  group_by(state) %>% 
  tally(absTestDiscrepancy)


### WHICH DATES HAD HIGHEST AGGREGATE TEST DISCREPANCY
covidclean.df %>% 
  dplyr::select( c(state, date, death, absTestDiscrepancy , negative, positive, totalTestResults) ) %>% 
  group_by(date) %>% 
  tally(absTestDiscrepancy) %>% as.data.frame()
  .[[2]] %>% plot.ts()


plotts.wge(covidclean.df$testDiscrepancy)

covidclean.df$testDiscrepancy



####### DATA EXPLORATION & VISUALIZATION


# create positive test %
#### PROBLEM: TOTAL TEST DISCREPANCY 

covidclean.df$positive / covidclean.df$totalTestResults




# TOTAL DEATH: GROUP BY STATE
covidclean.df %>% 
  dplyr::select( c(state, death, negative, positive, totalTestResults) ) %>% 
  group_by(state) %>%  tally( death )

barplot(
  covidclean.df %>% dplyr::select( c(state, death) ) %>% group_by(state) %>% tally(death) %>% .[[2]]/1000,
  col = covidclean.df %>% dplyr::select( c(state, death) ) %>% group_by(state) %>% tally(death) %>% .[[1]],
  legend.text = covidclean.df %>% dplyr::select( c(state, death) ) %>% group_by(state) %>% tally(death) %>% .[[1]],
  horiz = T,
  main = 'Death By State',
  xlab = 'Number of Deaths in Thousands'
) 


# TOTAL TESTS: GROUP BY STATE
covidclean.df %>% 
  dplyr::select( c(state, death, negative, positive, totalTestResults) ) %>% 
  group_by(state) %>%  tally( totalTestResults ) 

barplot(
  covidclean.df %>% dplyr::select( c(state, totalTestResults) ) %>% group_by(state) %>% tally(totalTestResults) %>% .[[2]]/1000000,
  col = covidclean.df %>% dplyr::select( c(state, totalTestResults) ) %>% group_by(state) %>% tally(totalTestResults) %>% .[[1]],
  legend.text = covidclean.df %>% dplyr::select( c(state, totalTestResults) ) %>% group_by(state) %>% tally(totalTestResults) %>% .[[1]],
  horiz = T,
  main = 'Tests By State',
  xlab = 'Number of Tests in Millions'
) 


# TOTAL POSITIVE: GROUP BY STATE
covidclean.df %>% 
  dplyr::select( c(state, death, negative, positive, totalTestResults) ) %>% 
  group_by(state) %>%  tally( positive ) 

barplot(
  covidclean.df %>% dplyr::select( c(state, positive) ) %>% group_by(state) %>% tally(positive) %>% .[[2]]/1000000,
  col = covidclean.df %>% dplyr::select( c(state, positive) ) %>% group_by(state) %>% tally(positive) %>% .[[1]],
  legend.text = covidclean.df %>% dplyr::select( c(state, positive) ) %>% group_by(state) %>% tally(positive) %>% .[[1]],
  horiz = T,
  main = 'Positive Results By State',
  xlab = 'Number of Results in Millions'
) 


# TOTAL NEGATIVE: GROUP BY STATE
covidclean.df %>% 
  dplyr::select( c(state, death, negative, positive, totalTestResults) ) %>% 
  group_by(state) %>%  tally( negative ) 

barplot(
  covidclean.df %>% dplyr::select( c(state, negative) ) %>% group_by(state) %>% tally(negative) %>% .[[2]]/1000000,
  col = covidclean.df %>% dplyr::select( c(state, negative) ) %>% group_by(state) %>% tally(negative) %>% .[[1]],
  legend.text = covidclean.df %>% dplyr::select( c(state, negative) ) %>% group_by(state) %>% tally(negative) %>% .[[1]],
  horiz = T,
  main = 'Negative Results By State',
  xlab = 'Number of Results in Millions'
) 











######  CA data ######
covidfull.df[covidfull.df$state == 'CA', ] -> covid_ca.df

# Missing Values: from VIM package
aggr(covid_ca.df, 
     prop = FALSE, 
     combined = TRUE, 
     numbers = TRUE, 
     sortVars = TRUE, 
     sortCombs = TRUE)


#deathConfirmed   245
#deathProbable   245
#hospitalized   245
#hospitalizedCumulative   245
#inIcuCumulative   245
#negativeTestsAntibody   245
#negativeTestsPeopleAntibody   245
#negativeTestsViral   245
#onVentilatorCumulative   245
#onVentilatorCurrently   245
#positiveTestsAntibody   245
#positiveTestsAntigen   245
#positiveTestsPeopleAntibody   245
#positiveTestsPeopleAntigen   245
#positiveTestsViral   245
#recovered   245
#totalTestEncountersViral   245
#totalTestsAntibody   245
#totalTestsAntigen   245
#totalTestsPeopleAntibody   245
#totalTestsPeopleAntigen   245
#totalTestsPeopleViral   245
#positiveCasesViral    56
#hospitalizedCurrently    23
#inIcuCurrently    23
#death     8
#date     0
#state     0
#dataQualityGrade     0
#deathIncrease     0
#hospitalizedIncrease     0
#negative     0
#negativeIncrease     0
#positive     0
#positiveIncrease     0
#positiveScore     0
#totalTestEncountersViralIncrease     0
#totalTestResults     0
#totalTestResultsIncrease     0
#totalTestsPeopleViralIncrease     0
#totalTestsViral     0
#totalTestsViralIncrease     0



### all POSITIVE columns
head(covid_ca.df[,21:29])
# list rows with missing values
# in general 'positive' is the best column to use
covid_ca.df[is.na(covid_ca.df$negativeTestsViral), 21:29 ]


### all NEGATIVE columns
head(covid_ca.df[,14:18])
# list rows with missing values
# in general 'negative' is the best column to use
covid_ca.df[is.na(covid_ca.df$negativeTestsViral),14:18 ]



# remove fields with more than 6% missing
#c(deathConfirmed, deathProbable, hospitalized, hospitalizedCumulative, inIcuCumulative, negativeTestsAntibody, negativeTestsPeopleAntibody, negativeTestsViral, onVentilatorCumulative, onVentilatorCurrently, positiveTestsAntibody, positiveTestsAntigen, positiveTestsPeopleAntibody, positiveTestsPeopleAntigen, positiveTestsViral, recovered, totalTestEncountersViral, totalTestsAntibody, totalTestsAntigen, totalTestsPeopleAntibody, totalTestsPeopleAntigen, totalTestsPeopleViral, positiveCasesViral, hospitalizedCurrently, inIcuCurrently)

covid_ca.df %>% dplyr::select(-c(deathConfirmed, deathProbable, hospitalized, hospitalizedCumulative, inIcuCumulative, negativeTestsAntibody, negativeTestsPeopleAntibody, negativeTestsViral, onVentilatorCumulative, onVentilatorCurrently, positiveTestsAntibody, positiveTestsAntigen, positiveTestsPeopleAntibody, positiveTestsPeopleAntigen, positiveTestsViral, recovered, totalTestEncountersViral, totalTestsAntibody, totalTestsAntigen, totalTestsPeopleAntibody, totalTestsPeopleAntigen, totalTestsPeopleViral, positiveCasesViral, hospitalizedCurrently, inIcuCurrently) )  -> covidclean_ca.df
# alternate code: covidfull.df$positiveTestsPeopleAntigen <- NULL

# recheck missing values
aggr(covidclean_ca.df, 
     prop = FALSE, 
     combined = TRUE, 
     numbers = TRUE, 
     sortVars = TRUE, 
     sortCombs = TRUE)




### looking at death, negative, positive columns
# 'death' has only 8 missing values
covidclean_ca.df[ is.na(covidclean_ca.df[,c('death','negative','positive' )] ), c('death','negative','positive' ) ]
covidclean_ca.df[ is.na(covidclean_ca.df$death ), c('death','negative','positive' ) ]


## POSITIVITY RATE
covidclean_ca.df$positive / covidclean_ca.df$totalTestResults
## NEGATIVITY RATE
covidclean_ca.df$negative / covidclean_ca.df$totalTestResults
## VALIDATE NEGATIVE + POSITIVE VS TOTAL
(covidclean_ca.df$positive + covidclean_ca.df$negative) / covidclean_ca.df$totalTestResults

covidclean_ca.df[ ((covidclean_ca.df$positive + covidclean_ca.df$negative) / covidclean_ca.df$totalTestResults) != 1, ]

## row 10366 has a total negative + postive that does NOT equal the total tests
covidclean_ca.df[as.numeric( row.names( covidclean_ca.df) ) == 10366, c('date', 'totalTestResults', 'positive', 'negative' )]

#       date          totalTestResults  positive  negative
#10366  2020-05-02    685048            52197     634606
685048 - (52197 + 634606)
# discrepency of 1755 tests






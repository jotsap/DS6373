## Data Files
  
### Variable Count

* positiveTestsPeopleAntigen           13514
* totalTestsPeopleAntigen              13396
* positiveTestsAntigen                 13308
* negativeTestsPeopleAntibody          13139
* positiveTestsPeopleAntibody          13139
* totalTestsAntigen                    13082
* negativeTestsAntibody                12979
* onVentilatorCumulative               12969
* totalTestsPeopleAntibody             12748
* positiveTestsAntibody                11954
* inIcuCumulative                      11450
* totalTestsAntibody                   11287
* negativeTestsViral                   10868
* totalTestEncountersViral             10599
* positiveTestsViral                   9587
* deathProbable                        9563
* onVentilatorCurrently                8586
* totalTestsPeopleViral                8088
* deathConfirmed                       8015
* inIcuCurrently                       7469
* hospitalized                         5815
* hospitalizedCumulative               5815
* totalTestsViral                      5308
* recovered                            4061
* positiveCasesViral                   3172
* hospitalizedCurrently                3010
* death                                818
* negative                             306
* positive                             133
* totalTestResults                     35
* date                                 0
* state                                0
* dataQualityGrade                     0
* deathIncrease                        0
* hospitalizedIncrease                 0
* negativeIncrease                     0
* positiveIncrease                     0
* positiveScore                        0
* totalTestEncountersViralIncrease     0
* totalTestResultsIncrease             0
* totalTestsPeopleViralIncrease        0
* totalTestsViralIncrease              0
  
Covid Tracking Project  
https://covidtracking.com/data    

https://covidtracking.com/data/download  

API: https://covidtracking.com/data/api  
https://api.covidtracking.com/v1/states/daily.csv  

NOTE: These REST API calls SHOULD work but unfortunately dont 
# filter to just CA  
https://api.covidtracking.com/v1/states/daily.json?q={"state":"CA"}  
# filter out non-states / US territories  
https://api.covidtracking.com/v1/states/daily.json?q={"state" : {"$not" : [AS,GU,MP,PR,VI] }}  

**Alternate Data Sources**  
Hopkins Positivity Rate  
https://coronavirus.jhu.edu/testing/individual-states  
  
**7-Day Averages** The CRC calculates the rolling 7-day average separately for daily cases and daily tests, and then for each day calculate the percentage over the rolling averages. Some states may be calculating the positivity percentage for each day, and then doing the rolling 7-day average. The reason why we use our approach is because testing capacity issues and uneven reporting cadences create a lot of misleading peaks and valleys in the data. Since we want to give a 7-day average, it is more fair to average the raw data and then calculate the ratios. Otherwise, days when a large number of negative tests are released all at once—and positivity is going to be very low—will have the same weight as days when data was steadily released, and the overall result is going to be lower. Our approach is applied to all our testing data to correct for these uneven data release patterns.
  
CDC Deaths by State  
https://covid.cdc.gov/covid-data-tracker/#cases_totalcases

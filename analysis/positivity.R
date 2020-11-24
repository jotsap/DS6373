#Filter out territories
#Only start at March 9, end at November 9th


#Project
covidfull.df = read.csv('https://api.covidtracking.com/v1/states/daily.csv', header = T)
head(covidfull.df)
dim(covidfull.df) #13775 records, 43 columns

# load necessary libraries
library(tidyverse)
#library(VIM)

#look at structure
str(covidfull.df)
#better version of str from dplyr library
glimpse(covidfull.df)

#date currently saved as factor
typeof(covidfull.df$date)
covidfull.df$date = base::as.Date(covidfull.df$date) 
base::as.Date( as.factor(covidfull.df$date), "%Y%m%d" )-> covidfull.df$date
glimpse(covidfull.df)

# add rowId for easier tracking
covidfull.df$rowId <- 1:length(covidfull.df$totalTestResults)

# Missing Values: from VIM package
#number null for single column 
sum(is.na(covidfull.df$positiveTestsPeopleAntibody))

#create function to find nulls
find_nulls = function(col){
  num_nulls = sum(is.na(col))
  return(num_nulls)
}


#find num nulls
vec_null = apply(X=covidfull.df,FUN=find_nulls, MARGIN = 2)
sort(vec_null, decreasing = T)

#find percentage null
find_perc_nulls = function(col){
  num_nulls = sum(is.na(col))
  tot_nulls = length(col)
  perc_nulls = num_nulls/tot_nulls
  return(perc_nulls)
}

vec_perc_null = apply(X=covidfull.df,FUN=find_perc_nulls, MARGIN = 2)
sort(vec_perc_null, decreasing = T)

### There are multiple "positive columns"
head(covidfull.df[,21:29])
colnames(covidfull.df[,21:29])

#Look at percentage null positive columns
vec_perc_null = apply(X=covidfull.df[,21:29],FUN=find_perc_nulls, MARGIN = 2)
sort(vec_perc_null, decreasing = T)
#USE POSITIVE COLUMN


#There are multiple negative columns
vec_perc_null = apply(X=covidfull.df[,14:18],FUN=find_perc_nulls, MARGIN = 2)
sort(vec_perc_null, decreasing = T)
#USE NEGATIVE

#There are multiple total columns
vec_perc_null = apply(X=covidfull.df[,31:42],FUN=find_perc_nulls, MARGIN = 2)
sort(vec_perc_null, decreasing = T)
##Use totalTestResults

COVID_totals = covidfull.df[,c("date", 'state',"positive","negative", "totalTestResults", "death")]
head(COVID_totals)
max(COVID_totals$date)  "2020-11-20"

#Put date in ascending order
COVID_totals = COVID_totals[order(COVID_totals$date),]
head(COVID_totals)

#Replace NAs
COVID_totals[is.na(COVID_totals$positive),'positive'] = 0
COVID_totals[is.na(COVID_totals$negative),'negative'] = 0
COVID_totals[is.na(COVID_totals$death),'death'] = 0
#COVID_totals$MyTotal = COVID_totals$positive + COVID_totals$negative
#head(COVID_totals)


#setwd('/Users/spencerfogelman/Desktop/SMU_TimeSeries/Project')
#tiff("test.tiff", units="in", width=5, height=6, res=300)
#ggplot(my_df, aes(y=state, x=TotDiscrepancy2)) +
#geom_bar(stat="identity", color='black', fill='steelblue')+ xlim(0,300)+
#geom_text(aes(label=TotDiscrepancy2),size=2.5,hjust=0,nudge_x = 4,
#color='#8E1E29')+
#labs(title='Discrepancy by State', x='Total Discrepancy in Millions of Cases',
#y='State')
#dev.off()


str(COVID_totals)

COVID_totals = COVID_totals %>%
  filter(!state %in% c('AS','GU','MP','PR','VI')) %>%
  filter(date > '2020-03-08')
head(COVID_totals)

library(dplyr)
COVID_totals_final <- COVID_totals %>%
  dplyr::select(date, positive, negative, death) %>% 
  group_by(date) %>% 
  summarize(pos_sum = sum(positive), neg_sum = sum(negative), 
            death_sum=sum(death)) %>% ungroup() %>%
  mutate(new_pos = c(pos_sum[1], diff(pos_sum, 1)), 
         new_neg = c(neg_sum[1], diff(neg_sum, 1)), 
         new_death = c(death_sum[1], diff(death_sum, 1))) %>%
  mutate(totals = new_pos + new_neg) %>% 
  mutate(perc_pos = new_pos/totals)

#change NAN to inf from division by 0
COVID_totals_final[is.na(COVID_totals_final$perc_pos), 'perc_pos'] = 0

#Plot daily US perc_positive
#Removed data with all zeros before March
COVID_totals_final %>% filter(perc_pos>0) %>%
  ggplot( aes(x=date, y=perc_pos)) + geom_point() +
  geom_line() + labs(title='Daily Positive Percentage in US', x='Date', y='Percent Positive')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=c(seq(0,0.25,.05)))+
  theme(axis.text.x = element_text(angle=45, hjust=1))

#Plot daily US death
COVID_totals_final %>% 
  ggplot( aes(x=date, y=new_death)) + geom_point() +
  geom_line() + labs(title='Daily Death in US', x='Date', y='Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,3000, 300))+
  theme(axis.text.x = element_text(angle=45, hjust=1))

#Plot total positive US
COVID_totals_final %>% 
  ggplot( aes(x=date, y=new_pos)) + geom_point() +
  geom_line() + labs(title='Daily Positive Cases in US', x='Date', y='Number Positive Cases')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,200000, 20000))+
  theme(axis.text.x = element_text(angle=45, hjust=1))


##################################################################
#################CALIFORNIA ONLY
#filter for only CA
covid_ca.df = covidfull.df[covidfull.df$state == 'CA',]

#reorder dates in ascheding order
covid_ca.df = covid_ca.df[order(covid_ca.df$date),]

practice_df_CA = covid_ca.df[,c("date", "positive","negative", "totalTestResults", "death")]
head(practice_df_CA)

#Where does death have NA values?
practice_df_CA[is.na(practice_df_CA$death),]
#only starting reporting death March 12th
practice_df_CA = practice_df_CA %>% drop_na(any_of("death"))
sum(is.na(practice_df_CA$death)) #0

#Where does positive and negative have NA values?
sum(is.na(practice_df_CA$positive)) #0
sum(is.na(practice_df_CA$negative)) #0

#Create Total Column
practice_df_CA$MyTotal = practice_df_CA$positive + practice_df_CA$negative

COVID_CA = practice_df_CA
#only one date where reported totals doesn't match up -> index '2020-05-02'

#Visualize
library(tswge)
head(COVID_CA[,c('date', 'positive')],20)
#we can see positive cases are reported as cumulative total


#Look at positive tests (Cumulative)
glimpse(COVID_CA)
ggplot(data=COVID_CA, aes(x=date, y=positive)) + geom_point() +
  geom_line() + labs(title='Positive Tests by CA', x='Date', y='Number Positive Tests')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,1000000, by = 100000))+
  theme(axis.text.x = element_text(angle=45, hjust=1))

#Create new columns for new positives, new negatives, new total, and
#death
new_positive = c(COVID_CA$positive[1], diff(COVID_CA$positive, 1))
COVID_CA$new_positive = new_positive
head(COVID_CA)

#Create new negative
new_negative = c(COVID_CA$negative[1], diff(COVID_CA$negative, 1))
COVID_CA$new_negative = new_negative
head(COVID_CA)

#Create new total
new_total = c(COVID_CA$MyTotal[1], diff(COVID_CA$MyTotal, 1))
COVID_CA$new_total = new_total
head(COVID_CA)

#Create new death
new_death = c(COVID_CA$death[1], diff(COVID_CA$death, 1))
COVID_CA$new_death = new_death
head(COVID_CA)

#Create percent positive column
COVID_CA$perc_positive = COVID_CA$positive/COVID_CA$new_total
head(COVID_CA)

#replace infinity values with 0
COVID_CA[is.infinite(COVID_CA$perc_positive), 'perc_positive'] = 0
sum(is.infinite(COVID_CA$perc_positive)) #0

#Graph daily perc_positive
ggplot(data=COVID_CA, aes(x=date, y=perc_positive)) + geom_point() +
  geom_line() + labs(title='Percentage Positive Tests in CA', x='Date', y='Daily Percent Positive Tests')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  theme(axis.text.x = element_text(angle=45, hjust=1))

#Graph new daily deaths
ggplot(data=COVID_CA, aes(x=date, y=new_death)) + geom_point() +
  geom_line() + labs(title='Daily Death in CA', x='Date', y='Daily Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  theme(axis.text.x = element_text(angle=45, hjust=1))

#Graph new daily positives
ggplot(data=COVID_CA, aes(x=date, y=new_positive)) + geom_point() +
  geom_line() + labs(title='Daily COVID Cases in CA', x='Date', y='Daily Cases')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks = seq(from = 0, to = 15000, by = 1500))+
  theme(axis.text.x = element_text(angle=45, hjust=1)) 





########################################################################
######  Model Daily Positive Perc in CA
colnames(COVID_CA)
#visualize
ggplot(data=COVID_CA, aes(x=date, y=perc_positive)) + geom_point() +
  geom_line() + labs(title='Daily Percentage Positive for COVID-19 in CA', x='Date', y='Daily Positives Percentage')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  theme(axis.text.x = element_text(angle=45, hjust=1))

ggplot(data=COVID_CA, aes(x=date, y=new_positive)) + geom_point() +
  geom_line() + labs(title='Daily Percentage Positive for COVID-19 in CA', x='Date', y='Daily Positives Percentage')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  theme(axis.text.x = element_text(angle=45, hjust=1))


#variance seems to be lower before April 1st-> leave out this data
#for modeling purposes =
pos_perc = COVID_CA %>% filter(date > '2020-08-01') 


ggplot(data=pos_perc, aes(x=date, y=perc_positive)) +
  geom_line()+geom_point() 

plotts.sample.wge(pos_perc$perc_positive)
#clear seasonality of 7 (1/7=.14)
#also see wanderung behavior

#overfit table
est.ar.wge(pos_perc$perc_positive, p=12)
#strong frequencies at 0, .14, .28

#Check s=7
factor.wge(c(rep(0,6), 1))
#strong frequencies at 0, .28, .14, .43
#Factors in (1-B^7):        Match in overfit table?
#1-1.0000B                  Yes (freq = 0)
#1+0.4450B+1.0000B^2        Yes (freq=.28)
#1-1.2470B+1.0000B^2        Yes (freq=.14)
#1+1.8019B+1.0000B^2        No



difs7 = artrans.wge(pos_perc$perc_positive, c(rep(0,6), 1))
plotts.sample.wge(difs7, arlimits = T)
#seems to have overdone it a bit due to large negative peak at lag7

#try .7 instead of 1
difs.6 = artrans.wge(pos_perc$perc_positive, c(rep(0,6), .6))

aic5.wge(difs.6, p=0:15, q=0:0) #picks AR(10)
aic5.wge(difs.6, p=0:12, q=0:0, type='bic') #picks AR(1)

difs.6_ests = est.ar.wge(difs.6, p=10)
AR10 = artrans.wge(difs.6, difs.6_ests$phi)
#looks like white noise

var(AR10) # 1.977389
mean(pos_perc$perc_positive) # 6.789022

ljung.wge(AR10) #FTR
ljung.wge(AR10, K=48) #FTR

#(1-.7B^7)
fore.aruma.wge(x = pos_perc$perc_positive, n.ahead = 7, lambda=c(rep(0,6), .6),
               phi=difs.6_ests$phi)

#Forecasts

#Short term forecasts
length(pos_perc$perc_positive) #111
f_short = fore.aruma.wge(x = pos_perc$perc_positive, n.ahead = 7,lambda=c(rep(0,6), .6),
                         phi=difs.6_ests$phi)

dates = seq(as.Date(pos_perc$date[111]), by='day', length.out=8)[c(-1)]

forecasts = data.frame(preds = f_short$f, upper = f_short$ul,
                       lower = f_short$ll, date=dates)


#Visualize
ggplot(data=pos_perc, aes(x=date, y=perc_positive)) +
  geom_line()+geom_point() + ggtitle('Short Term Positive Percentage Forecasts in CA')+
  xlab(NULL)+ylab('Number Cases')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')

#Short term ASE
#deaths_small = deaths$new_death[1:209] #(216-7)
f_short = fore.aruma.wge(x = pos_perc$perc_positive, limits=F, n.ahead = 7, lastn=T,
                         lambda=c(rep(0,6), .6), phi=difs.6_ests$phi)

dates = seq(as.Date(pos_perc$date[105]), by='day', length.out=7)

forecasts = data.frame(preds = f_short$f, upper = f_short$ul,
                       lower = f_short$ll, date=dates)


#Visualize
p = ggplot(pos_perc, aes(x=date, y=perc_positive)) +
  geom_line()+geom_point() + ggtitle('Short Term Positive Percentage Forecasts in CA')+
  xlab(NULL)+ylab('Number Cases')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')

ASE_small_d = mean((pos_perc$perc_positive[105:111] - f_short$f)**2)
ASE_small_d  #973.1014 -> overpredicting deaths

labels = data.frame(x=c(zoo::as.Date('2020-08-20')), y=c(14), label=c(paste('ASE:', base::round(ASE_small_d,2))))
labels

p + geom_label(data=labels, aes(x=x, y=y, label=label),
               color='white', fill='black', fontface='bold')

#Short term rolling window ASE
Rolling_Window_ASE = function(series, trainingSize, horizon = 1, s = 0, d = 0, phis = 0, thetas = 0, lambdas=0)
{
  trainingSize = 70
  horizon = 12
  ASEHolder = numeric()
  s = 10
  d = 0
  phis = phis
  thetas = thetas
  lambdas = lambdas
  
  
  
  for( i in 1:(length(series)-(trainingSize + horizon) + 1))
  {
    
    forecasts = fore.aruma.wge(series[i:(i+(trainingSize-1))],phi = phis, theta = thetas, s = s, d = d, lambda = lambdas, n.ahead = horizon, plot=F)
    
    ASE = mean((series[(trainingSize+i):(trainingSize+ i + (horizon) - 1)] - forecasts$f)^2)
    
    ASEHolder[i] = ASE
    
  }
  
  WindowedASE = mean(ASEHolder)
  
  print("The Summary Statistics for the Rolling Window ASE Are:")
  print(summary(ASEHolder))
  print(paste("The Rolling Window ASE is: ",WindowedASE))
  return(WindowedASE)
}

Rolling_Window_ASE(pos_perc$perc_positive, trainingSize = 20, horizon=7, 
                   phi=difs.6_ests$phi,lambdas=c(rep(0,6), .6))
length(pos_perc$perc_positive) #111

# 2.618646

#Long term forecast
f_long = fore.aruma.wge(x=pos_perc$perc_positive, n.ahead=93, 
                        lambda=c(rep(0,6), .6), phi=difs.6_ests$phi)


dates = seq(as.Date(pos_perc$date[111]), by='day', length.out=94)[c(-1)]

forecasts = data.frame(preds = f_long$f, upper = f_long$ul,
                       lower = f_long$ll, date=dates)

#Visualize
ggplot(data=pos_perc, aes(x=date, y=perc_positive)) +
  geom_line()+geom_point() + ggtitle('Long Term Positive Percentage Forecasts in CA')+
  xlab(NULL)+ylab('Number Cases')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')

#Long term ASE
#216-93 = 123
f_long = fore.aruma.wge(x = pos_perc$perc_positive, limits=F, n.ahead = 93,
                        lambda=c(rep(0,6), .6), phi=difs.6_ests$phi, lastn=T)


ASE_long_d = mean((pos_perc$perc_positive[19:111] - f_long$f)**2)
ASE_long_d # 1401.118 -> overpredicting deaths

dates = seq(as.Date(pos_perc$date[19]), by='day', length.out=93)

forecasts = data.frame(preds = f_long$f, upper = f_long$ul,
                       lower = f_long$ll, date=dates)


#Visualize
p = ggplot(data=pos_perc, aes(x=date, y=perc_positive)) +
  geom_line()+geom_point() + ggtitle('Long Term Positive Percentage Forecasts in CA')+
  xlab(NULL)+ylab('Number Cases')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')


ASE_long_d = mean((pos_perc$perc_positive[19:111] - f_long$f)**2)
ASE_long_d #1401.118-> overpredicting deaths

labels = data.frame(x=c(zoo::as.Date('2020-08-18')), y=c(12.5), label=c(paste('ASE:', base::round(ASE_long_d,2))))
labels

p + geom_label(data=labels, aes(x=x, y=y, label=label),
               color='white', fill='black', fontface='bold')




#####################################################################
###MODEL PERCENT POSITIVE IN US
colnames(COVID_totals_final)
COVID_totals_final %>% 
  ggplot( aes(x=date, y=perc_pos)) + geom_point() +
  geom_line() + labs(title='Daily Death in US', x='Date', y='Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,3000, 300))+
  theme(axis.text.x = element_text(angle=45, hjust=1))

#Filter data for after April 10th so that variance is similar
pos_perc_us = COVID_totals_final %>% filter(date>'2020-05-01')
dim(pos_perc_us) #203

plotts.sample.wge(pos_perc_us$perc_pos)
#clear weakly frequency

est.ar.wge(deaths_us$new_death, p=12)
#strong frequencies at .14, 0, .28 and wandering

factor.wge(c(rep(0,6),1))
#strong frequencies at 0, .28, .14, .42
#Factors in (1-B^7):        Match in overfit table?
#1-1.0000B                   Yes (freq = 0)
#1+0.4450B+1.0000B^2         Yes (freq=.28)
#1-1.2470B+1.0000B^2         Yes (freq=.14)
#1+1.8019B+1.0000B^2         No

dif1 = artrans.wge(pos_perc_us$perc_pos, 1)
dif1.7 = artrans.wge(dif1, c(rep(0,6), .2))

aic5.wge(dif1.7, p=0:10, q=0:0) #picks AR(9)
aic5.wge(dif1.7, p=0:10, q=0:0, type='bic') #picks AR(5)

my_ests = est.ar.wge(dif1.7, p=5)
AR5 = artrans.wge(dif1.7, my_ests$phi) #looks like white noise
var(AR5) #7.670331e-05
mean(pos_perc_us$perc_pos) # 0.06933989
ljung.wge(AR5) #FTR
ljung.wge(AR5, K=48) #barely rejects


######################Short term forecasts
fore.aruma.wge(pos_perc_us$perc_pos, phi=my_ests$phi, lambda = c(rep(0,6), .2),d=1,
               n.ahead=7, limits=F)

#Short term forecasts
length(deaths_us$new_death)#229
f_short = fore.aruma.wge(x = pos_perc_us$perc_pos, n.ahead = 7,d=1,
                         phi=my_ests$phi, lambda=c(rep(0,6), .2), limits=F)

dates = seq(as.Date(pos_perc_us$date[203]), by='day', length.out=8)[c(-1)]

forecasts = data.frame(preds = f_short$f, upper = f_short$ul,
                       lower = f_short$ll, date=dates)


#Visualize
ggplot(data=pos_perc_us, aes(x=date, y=perc_pos)) +
  geom_line()+geom_point() + ggtitle('Short Term Positive Percentage Forecasts in US')+
  xlab(NULL)+ylab('Number Cases')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,.13,0.01))+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')



#######################short term ASE
short_f = fore.aruma.wge(pos_perc_us$perc_pos, phi=my_ests$phi,d=1,
                         n.ahead=7, limits=F, lastn=T, lambda = c(rep(0,6), .2))

ASE_short = mean((pos_perc_us$perc_pos[197:203] - short_f$f)**2)
ASE_short # 165388.1` `


dates = seq(as.Date(pos_perc_us$date[197]), by='day', length.out=7)

forecasts = data.frame(preds = f_short$f, upper = f_short$ul,
                       lower = f_short$ll, date=dates)


#Visualize
p = ggplot(data=pos_perc_us, aes(x=date, y=perc_pos)) +
  geom_line()+geom_point() + ggtitle('Short Term Positive Percentage Forecasts in US')+
  xlab(NULL)+ylab('Number Cases')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,.13,0.01))+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')


labels = data.frame(x=c(as.Date('2020-06-1')), y=c(.10), label=c(paste('ASE:', base::round(ASE_short,6))))

p + geom_label(data=labels, aes(x=x, y=y, label=label),
               color='white', fill='black', fontface='bold')

#Rolling window ASE
Rolling_Window_ASE(pos_perc_us$perc_pos, trainingSize = 20, horizon=7,phi=my_ests$phi,d=1,
                   lambdas = c(rep(0,6), .2))
#  0.0004029462


############################Long term forecasts
fore.aruma.wge(pos_perc_us$perc_pos, phi=my_ests$phi,lambda=c(rep(0,6), .2),d=1,
               n.ahead=93, limits=F)

f_long = fore.aruma.wge(x = pos_perc_us$perc_pos,lambda=c(rep(0,6), .2), n.ahead = 93,d=1,
                        phi=my_ests$phi)

dates = seq(as.Date(pos_perc_us$date[203]), by='day', length.out=94)[c(-1)]

forecasts = data.frame(preds = f_long$f, upper = f_long$ul,
                       lower = f_long$ll, date=dates)


#Visualize
ggplot(data=pos_perc_us, aes(x=date, y=perc_pos)) +
  geom_line()+geom_point() + ggtitle('Long Term Positive Percentage Forecasts in US')+
  xlab(NULL)+ylab('Number Cases')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,.13,0.01))+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')

#########################################
#Long term ASE
f_long = fore.aruma.wge(x = pos_perc_us$perc_pos, limits=F, n.ahead = 93,d=1,
                        phi=my_ests$phi, lastn=T, lambda=c(rep(0,6), .2))


ASE_long_d = mean((pos_perc_us$perc_pos[111:203] - f_long$f)**2)
ASE_long_d #126604.5 -> overpredicting deaths

dates = seq(as.Date(pos_perc_us$date[111]), by='day', length.out=93)

forecasts = data.frame(preds = f_long$f, upper = f_long$ul,
                       lower = f_long$ll, date=dates)


#Visualize
p = ggplot(data=pos_perc_us, aes(x=date, y=perc_pos)) +
  geom_line()+geom_point() + ggtitle('Long Term Positive Percentage Forecasts in US')+
  xlab(NULL)+ylab('Number Cases')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,.13,0.01))+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')


labels = data.frame(x=c(as.Date('2020-06-1')), y=c(.10), label=c(paste('ASE:', base::round(ASE_long_d,6))))
labels

p + geom_label(data=labels, aes(x=x, y=y, label=label),
               color='white', fill='black', fontface='bold')

#Filter out territories
#Only start at March 9, end at November 9th


#Project
covidfull.df = read.csv('/Users/spencerfogelman/Desktop/SMU_TimeSeries/Project/all-states-history.csv')
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
  select(date, positive, negative, death) %>% 
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
######  Model Daily Death in CA

#visualize
ggplot(data=COVID_CA, aes(x=date, y=new_death)) + geom_point() +
  geom_line() + labs(title='Daily Death in CA', x='Date', y='Daily Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  theme(axis.text.x = element_text(angle=45, hjust=1))

#variance seems to be lower before April 1st-> leave out this data
#for modeling purposes
deaths = COVID_CA %>% filter(date > '2020-04-01') 


ggplot(data=deaths, aes(x=date, y=new_death)) +
  geom_line()+geom_point() 

plotts.sample.wge(deaths$new_death)
#clear seasonality of 7 (1/7=.14)
#also see wanderung behavior

#overfit table
est.ar.wge(deaths$new_death, p=12)
#strong frequencies at 0, .14, .28

#Check s=7
factor.wge(c(rep(0,6), 1))
#strong frequencies at 0, .28, .14, .43
#Factors in (1-B^7):        Match in overfit table?
#1-1.0000B                  Yes (freq = 0)
#1+0.4450B+1.0000B^2        Yes (freq=.28)
#1-1.2470B+1.0000B^2        Yes (freq=.14)
#1+1.8019B+1.0000B^2        No



difs7 = artrans.wge(deaths$new_death, c(rep(0,6), 1))
plotts.sample.wge(difs7, arlimits = T)
#seems to have overdone it a bit due to large negative peak at lag7

#try .7 instead of 1
difs.7 = artrans.wge(deaths$new_death, c(rep(0,6), .7))

aic5.wge(difs.7, p=0:12, q=0:0) #picks AR(8)
aic5.wge(difs.7, p=0:12, q=0:0, type='bic') #picks AR(8)

difs.7_ests = est.ar.wge(difs.7, p=8)
AR8 = artrans.wge(difs.7, difs.7_ests$phi)
#looks like white noise

var(AR8) #659.2513
mean(deaths$new_death) #81.08796

ljung.wge(AR8) #FTR
ljung.wge(AR8, K=48) #barely rejects

fore.aruma.wge(x = deaths$new_death, n.ahead = 7, lambda=c(rep(0,6), .7),
               phi=difs.7_ests$phi)

#Forecasts

#Short term forecasts
length(deaths$new_death) #216
f_short = fore.aruma.wge(x = deaths$new_death, n.ahead = 7,lambda=c(rep(0,6), .7),
                         phi=difs.7_ests$phi)

dates = seq(as.Date(deaths$date[216]), by='day', length.out=8)[c(-1)]

forecasts = data.frame(preds = f_short$f, upper = f_short$ul,
                       lower = f_short$ll, date=dates)

                         
#Visualize
ggplot(data=deaths, aes(x=date, y=new_death)) +
  geom_line()+geom_point() + ggtitle('Short Term Death Forecasts in CA')+
  xlab(NULL)+ylab('Number Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')

#Short term ASE
#deaths_small = deaths$new_death[1:209] #(216-7)
f_short = fore.aruma.wge(x = deaths$new_death, limits=F, n.ahead = 7, lastn=T,
                         lambda=c(rep(0,6), .7), phi=difs.7_ests$phi)

dates = seq(as.Date(deaths$date[210]), by='day', length.out=7)

forecasts = data.frame(preds = f_short$f, upper = f_short$ul,
                       lower = f_short$ll, date=dates)


#Visualize
p = ggplot(data=deaths, aes(x=date, y=new_death)) +
  geom_line()+geom_point() + ggtitle('Short Term Death Forecasts in CA')+
  xlab(NULL)+ylab('Number Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')
  
ASE_small_d = mean((deaths$new_death[210:216] - f_short$f)**2)
ASE_small_d #1110.792 -> overpredicting deaths

labels = data.frame(x=c(as.Date('2020-05-1')), y=c(200), label=c(paste('ASE:', base::round(ASE_small_d,2))))
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

Rolling_Window_ASE(deaths$new_death, trainingSize = 20, horizon=7, 
                   phi=difs.7_ests$phi,lambdas=c(rep(0,6), .7))

#2017.954

#Long term forecast
f_long = fore.aruma.wge(x=deaths$new_death, n.ahead=93, 
                        lambda=c(rep(0,6), .7), phi=difs.7_ests$phi)


dates = seq(as.Date(deaths$date[216]), by='day', length.out=94)[c(-1)]

forecasts = data.frame(preds = f_long$f, upper = f_long$ul,
                       lower = f_long$ll, date=dates)

#Visualize
ggplot(data=deaths, aes(x=date, y=new_death)) +
  geom_line()+geom_point() + ggtitle('Long Term Death Forecasts in CA')+
  xlab(NULL)+ylab('Number Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')

#Long term ASE
#216-93 = 123
f_long = fore.aruma.wge(x = deaths$new_death, limits=F, n.ahead = 93,
                        lambda=c(rep(0,6), .7), phi=difs.7_ests$phi, lastn=T)


ASE_long_d = mean((deaths$new_death[124:216] - f_long$f)**2)
ASE_long_d #1637.169 -> overpredicting deaths

dates = seq(as.Date(deaths$date[124]), by='day', length.out=93)

forecasts = data.frame(preds = f_long$f, upper = f_long$ul,
                       lower = f_long$ll, date=dates)


#Visualize
p = ggplot(data=deaths, aes(x=date, y=new_death)) +
  geom_line()+geom_point() + ggtitle('Long Term Death Forecasts in CA')+
  xlab(NULL)+ylab('Number Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')


ASE_long_d = mean((deaths$new_death[124:216] - f_long$f)**2)
ASE_long_d #1637.169-> overpredicting deaths

labels = data.frame(x=c(as.Date('2020-05-1')), y=c(200), label=c(paste('ASE:', base::round(ASE_long_d,2))))
labels

p + geom_label(data=labels, aes(x=x, y=y, label=label),
               color='white', fill='black', fontface='bold')

###################################################################
#Stationary Model for deaths in CA
plotts.sample.wge(deaths$new_death)
aic5.wge(deaths$new_death, p=0:14, q=0:2, type='bic')
#ARMA(6,2)
my_ests = est.arma.wge(deaths$new_death, p=6, q=2)

f = fore.arma.wge(deaths$new_death, phi=my_ests$phi, theta=my_ests$theta, n.ahead=7)
f = fore.arma.wge(deaths$new_death, phi=my_ests$phi, theta=my_ests$theta, n.ahead=7, lastn=T)

length(deaths$new_death) #216

#short term
ASE = mean((deaths$new_death[210:216] - f$f)**2)
ASE #1159.376

#long term
f_l = fore.arma.wge(deaths$new_death, phi=my_ests$phi, theta=my_ests$theta, n.ahead=93)
f_l = fore.arma.wge(deaths$new_death, phi=my_ests$phi, theta=my_ests$theta, n.ahead=93, lastn=T)
ASE = mean((deaths$new_death[124:216] - f_l$f)**2)
ASE #1201.155

#####################################################################
###MODEL DAILY DEATH IN US
COVID_totals_final %>% 
  ggplot( aes(x=date, y=new_death)) + geom_point() +
  geom_line() + labs(title='Daily Death in US', x='Date', y='Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,3000, 300))+
  theme(axis.text.x = element_text(angle=45, hjust=1))

#Filter data for after April 10th so that variance is similar
deaths_us = COVID_totals_final %>% filter(date>'2020-04-05')
dim(deaths_us) #212

plotts.sample.wge(deaths_us$new_death)
#clear weakly frequency

est.ar.wge(deaths_us$new_death, p=12)
#strong frequencies at .14, 0, .28

factor.wge(c(rep(0,6),1))
#strong frequencies at 0, .28, .14, .42
#Factors in (1-B^7):        Match in overfit table?
#1-1.0000B                   Yes (freq = 0)
#1+0.4450B+1.0000B^2         Yes (freq=.28)
#1-1.2470B+1.0000B^2         Yes (freq=.14)
#1+1.8019B+1.0000B^2         No


difs7 = artrans.wge(deaths_us$new_death, phi.tr = c(rep(0,6), 1))
plotts.sample.wge(difs7, arlimits = T)

difs.9 = artrans.wge(deaths_us$new_death, phi.tr = c(rep(0,6), .8))
plotts.sample.wge(difs.9, arlimits = T)

aic5.wge(difs.9, p=0:12, q=0:0) #picks AR(8)
aic5.wge(difs.9, p=0:12, q=0:0, type='bic') #picks AR(8)

my_ests = est.ar.wge(difs.9, p=8)
AR8 = artrans.wge(difs.9, my_ests$phi) #looks like white noise
var(AR8) #34032.61
mean(deaths_us$new_death) #1003.495
ljung.wge(AR8) #FTR
ljung.wge(AR8, K=48) #FTR


######################Short term forecasts
fore.aruma.wge(deaths_us$new_death, phi=my_ests$phi, lambda = c(rep(0,6), .8),
               n.ahead=7, limits=F)

#Short term forecasts
length(deaths_us$new_death)#212
f_short = fore.aruma.wge(x = deaths_us$new_death, n.ahead = 7,
                         phi=my_ests$phi, lambda=c(rep(0,6), .8), limits=F)

dates = seq(as.Date(deaths_us$date[212]), by='day', length.out=8)[c(-1)]

forecasts = data.frame(preds = f_short$f, upper = f_short$ul,
                       lower = f_short$ll, date=dates)


#Visualize
ggplot(data=deaths_us, aes(x=date, y=new_death)) +
  geom_line()+geom_point() + ggtitle('Short Term Death Forecasts in US')+
  xlab(NULL)+ylab('Number Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,3000, 300))+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')



#######################short term ASE
short_f = fore.aruma.wge(deaths_us$new_death, phi=my_ests$phi,
               n.ahead=7, limits=F, lastn=T, lambda = c(rep(0,6), .8))

ASE_short = mean((deaths_us$new_death[206:212] - short_f$f)**2)
ASE_short #11018.46


dates = seq(as.Date(deaths_us$date[206]), by='day', length.out=7)

forecasts = data.frame(preds = f_short$f, upper = f_short$ul,
                       lower = f_short$ll, date=dates)


#Visualize
p = ggplot(data=deaths_us, aes(x=date, y=new_death)) +
  geom_line()+geom_point() + ggtitle('Short Term Death Forecasts in US')+
  xlab(NULL)+ylab('Number Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,3000, 300))+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')


labels = data.frame(x=c(as.Date('2020-10-1')), y=c(2000), label=c(paste('ASE:', base::round(ASE_short,2))))

p + geom_label(data=labels, aes(x=x, y=y, label=label),
               color='white', fill='black', fontface='bold')

#Rolling window ASE
Rolling_Window_ASE(deaths_us$new_death, trainingSize = 20, horizon=7,phi=my_ests$phi,
                   lambdas = c(rep(0,6), .8))
#68271.52


############################Long term forecasts
fore.aruma.wge(deaths_us$new_death, phi=my_ests$phi,lambda=c(rep(0,6), .8),
               n.ahead=93, limits=F)

f_long = fore.aruma.wge(x = deaths_us$new_death,lambda=c(rep(0,6), .8), n.ahead = 93,
                         phi=my_ests$phi)

dates = seq(as.Date(deaths_us$date[212]), by='day', length.out=94)[c(-1)]

forecasts = data.frame(preds = f_long$f, upper = f_long$ul,
                       lower = f_long$ll, date=dates)


#Visualize
ggplot(data=deaths_us, aes(x=date, y=new_death)) +
  geom_line()+geom_point() + ggtitle('Long Term Death Forecasts in US')+
  xlab(NULL)+ylab('Number Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,3000, 300))+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')

#########################################
#Long term ASE
f_long = fore.aruma.wge(x = deaths_us$new_death, limits=F, n.ahead = 93,
                        phi=my_ests$phi, lastn=T, lambda=c(rep(0,6), .8))


ASE_long_d = mean((deaths_us$new_death[120:212] - f_long$f)**2)
ASE_long_d #118513.3 -> overpredicting deaths

dates = seq(as.Date(deaths_us$date[120]), by='day', length.out=93)

forecasts = data.frame(preds = f_long$f, upper = f_long$ul,
                       lower = f_long$ll, date=dates)


#Visualize
p = ggplot(data=deaths_us, aes(x=date, y=new_death)) +
  geom_line()+geom_point() + ggtitle('Long Term Death Forecasts in US')+
  xlab(NULL)+ylab('Number Deaths')+
  scale_x_date(date_labels = "%b/%d", date_breaks = '1 month')+
  scale_y_continuous(breaks=seq(0,3000, 300))+
  geom_line(data=forecasts, aes(x=dates, y=preds), color='red')


labels = data.frame(x=c(as.Date('2020-10-1')), y=c(2000), label=c(paste('ASE:', base::round(ASE_long_d,2))))
labels

p + geom_label(data=labels, aes(x=x, y=y, label=label),
               color='white', fill='black', fontface='bold')


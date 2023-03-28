############################################
############################################
#################  Summary #################
############################################
############################################

############################################
############################################
###########  Libraries & Data ##############
############################################
############################################

library(readxl)
library(dplyr)
library(ggplot2)
library(lubridate)
library(rugarch)

main_path <- "C:/Warwick Final Year/RAE"

data_path <- paste0(main_path,"/Data")

df_Nikkei <- data.frame(read.csv(paste0(data_path,"/^N225.csv"))) %>%
  filter(Adj.Close!="null")

df_DAX    <- data.frame(read.csv(paste0(data_path,"/^GDAXI.csv"))) %>%
  filter(Adj.Close!="null")

df_NASDAQ <- data.frame(read.csv(paste0(data_path,"/^IXIC.csv"))) %>%
  filter(Adj.Close!="null")

Nikkei_log <- data.frame(Date = ymd(df_Nikkei$Date),
                         log_returns = c(NA,diff(log(as.numeric(df_Nikkei$Adj.Close)))))

DAX_log <- data.frame(Date = ymd(df_DAX$Date),
                      log_returns = c(NA,diff(log(as.numeric(df_DAX$Adj.Close)))))

NASDAQ_log <- data.frame(Date = ymd(df_NASDAQ$Date),
                         log_returns = c(NA,diff(log(as.numeric(df_NASDAQ$Adj.Close))))) %>%
  filter(!(is.na(log_returns)))


# Pick series to work with here 

which_series <- "DAX"

if (which_series == "Nikkei"){
  
DATA <- Nikkei_log  
validation_data <- Nikkei_log %>% filter(Date >= "2015-01-01")
training_data   <- Nikkei_log %>% filter(Date <  "2015-01-01")

} else if (which_series == "NASDAQ") {
  DATA <- NASDAQ_log 
  validation_data <- NASDAQ_log %>% filter(Date >= "2015-01-01")
  training_data   <- NASDAQ_log %>% filter(Date <  "2015-01-01")
  
} else if (which_series == "DAX") {
  DATA <- DAX_log
  validation_data <- DAX_log %>% filter(Date >= "2015-01-01")
  training_data   <- DAX_log %>% filter(Date <  "2015-01-01")
  
} else {
  
  stop("That series is not available")
}

##################################################################
##################################################################
############################ Normal ##############################
##################################################################
##################################################################

Normal_ARMA_GARCH <- function(GARCH_ORDER,
                              ARMA_ORDER) {
  
  specif <- ugarchspec(variance.model = list(garchOrder=GARCH_ORDER),
                       mean.model =list(armaOrder=ARMA_ORDER),
                       distribution.model = "norm")
  
  # start from 4 onwards - no idea why but otherwise doesn't converge 
  fitted_GARCH <- ugarchfit(spec=specif,
                            data=DATA$log_returns[4:length(DATA$log_returns)],
                            out.sample = (length(validation_data$log_returns)-1),
                            solver = 'hybrid')
  
  rolling_norm <- ugarchforecast(fitted_GARCH,
                                 n.ahead = 1,
                                 n.roll = (length(validation_data$log_returns)-1))
  
  df <- data.frame(Date = validation_data$Date,
                   mu = c(rolling_norm@forecast$seriesFor),
                   sigma = c(rolling_norm@forecast$sigmaFor))
  
  return(df)

}


##################################################################
##################################################################
############################ Student T ###########################
##################################################################
##################################################################

T_ARMA_GARCH <- function(GARCH_ORDER,
                      ARMA_ORDER) {
  
  specif <- ugarchspec(variance.model = list(garchOrder=GARCH_ORDER),
                       mean.model =list(armaOrder=ARMA_ORDER),
                       distribution.model = "std")
  
  # start from 4 onwards - no idea why but otherwise doesn't converge 
  fitted_GARCH <- ugarchfit(spec=specif,
                            data=DATA$log_returns[4:length(DATA$log_returns)],
                            out.sample = (length(validation_data$log_returns)-1),
                            solver = 'hybrid')
  
  rolling_t <- ugarchforecast(fitted_GARCH,
                              n.ahead = 1,
                              n.roll = (length(validation_data$log_returns)-1))
  
  
  DoF_t <- rep(fitted_GARCH@fit$coef[['shape']],length(rolling_t@forecast$seriesFor))
  
  df <- data.frame(Date = validation_data$Date,
                   mu = c(rolling_t@forecast$seriesFor),
                   sigma = c(rolling_t@forecast$sigmaFor),
                   DoF = DoF_t)
  
  return(df)
}


##################################################################
##################################################################
############################## Laplace ###########################
##################################################################
##################################################################

# used generalised error distribution in rugarch
# GED distribution with shape = 1 is Laplace so fix this 

Laplace_ARMA_GARCH <- function(GARCH_ORDER,
                               ARMA_ORDER) {
  
  specif <- ugarchspec(variance.model = list(garchOrder=GARCH_ORDER),
                       mean.model =list(armaOrder=ARMA_ORDER),
                       distribution.model = "ged",
                       fixed.pars = list(shape = 1))
  
  # start from 4 onwards - no idea why but otherwise doesn't converge 
  fitted_GARCH <- ugarchfit(spec=specif,
                            data=DATA$log_returns[4:length(DATA$log_returns)],
                            out.sample = (length(validation_data$log_returns)-1),
                            solver = 'hybrid')
  
  rolling_lap <- ugarchforecast(fitted_GARCH,
                                n.ahead = 1,
                                n.roll = (length(validation_data$log_returns)-1))
  
  df <- data.frame(Date = validation_data$Date,
                   mu = c(rolling_lap@forecast$seriesFor),
                   sigma = c(rolling_lap@forecast$sigmaFor))
  
  return(df)
  
}


##################################################################
##################################################################
####################### Export to Python #########################
##################################################################
##################################################################

#for (AR in 1:3){
#  for (MA in 1:3) {
#    for (GARCH1 in 1:3){
#      for (GARCH2 in 1:3){


for (i in 1:5) {
        
        df_norm <- Normal_ARMA_GARCH(GARCH_ORDER = c(i,i),
                                     ARMA_ORDER  = c(i,i))
        
        df_t <- T_ARMA_GARCH(GARCH_ORDER = c(i,i),
                                     ARMA_ORDER  = c(i,i))
        
        df_lap <- Laplace_ARMA_GARCH(GARCH_ORDER = c(i,i),
                                     ARMA_ORDER  = c(i,i))
        

        df <- data.frame(Date = validation_data$Date,
                             Norm_mu = c(df_norm$mu),
                             Norm_std = c(df_norm$sigma),
                             T_mu = c(df_t$mu),
                             T_std = c(df_t$sigma),
                             T_shape = c(df_t$DoF),
                             Lap_mu = c(df_lap$mu),
                             Lap_std = c(df_lap$sigma))

        write.csv(df,paste0(main_path,"/Processed Data/",which_series,"/ARMA_GARCH/ARMA_",as.character(i),as.character(i),"_GARCH_",as.character(i),as.character(i),".csv"),row.names=F)
      }
 #   }
#  }
#}


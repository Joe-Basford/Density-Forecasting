
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

df_DAX    <- data.frame(read.csv(paste0(data_path,"/^GDAXI.csv")))

df_NASDAQ <- data.frame(read.csv(paste0(data_path,"/^IXIC.csv")))

Nikkei_log <- data.frame(Date = ymd(df_Nikkei$Date),
                         log_returns = c(NA,diff(log(as.numeric(df_Nikkei$Adj.Close)))))

DAX_log <- data.frame(Date = ymd(df_DAX$Date),
                      log_returns = c(NA,diff(log(as.numeric(df_DAX$Adj.Close)))))

NASDAQ_log <- data.frame(Date = ymd(df_NASDAQ$Date),
                         log_returns = c(NA,diff(log(as.numeric(df_NASDAQ$Adj.Close))))) %>%
  filter(!(is.na(log_returns)))

##################################################################
##################################################################
############################ Normal ##############################
##################################################################
##################################################################


specif <- ugarchspec(variance.model = list(garchOrder=c(5,5)),
                   mean.model =list(armaOrder=c(5,0)),
                                  distribution.model = "norm")

fitted_GARCH <- ugarchfit(spec=specif,
                          data=Nikkei_log$log_returns[2:length(Nikkei_log$log_returns)],
                          out.sample = length(Nikkei_log$log_returns[-(1:12309)]))

rolling_norm <- ugarchforecast(fitted_GARCH,
                          n.ahead = 1,
                          n.roll = length(Nikkei_log$log_returns[-(1:12309)]))

forecast_length = length(rolling_norm@forecast$sigmaFor)

Score = sum(dnorm(tail(Nikkei_log$log_returns,forecast_length),
                  mean = rolling_norm@forecast$seriesFor,
                  sd   = rolling_norm@forecast$sigmaFor,
                  log  = T))/forecast_length

ggplot() +
  geom_line(aes(x=tail(Nikkei_log$Date,forecast_length),tail(Nikkei_log$log_returns,forecast_length),color='real'))+
  geom_line(aes(x=tail(Nikkei_log$Date,forecast_length),y=rolling_norm@forecast$seriesFor,color='forecast')) +
  geom_ribbon(aes(x=tail(Nikkei_log$Date,forecast_length), 
                  ymin=qnorm(0.025,mean=rolling_norm@forecast$seriesFor,sd=rolling_norm@forecast$sigmaFor),
                  ymax=qnorm(0.975,mean=rolling_norm@forecast$seriesFor,sd=rolling_norm@forecast$sigmaFor),fill="band"),color="green",alpha=0.4) +
  ylab("log-returns")  +
  xlab("Date") +
  ggtitle("ARMA(5,0)-GARCH(5,5) Normal") + 
  scale_color_manual(values = c("real"="blue","forecast"="red")) + 
  scale_fill_manual(values = c("band" = "black")) +
  labs(color='', fill='') +
  annotate("text",x=ymd("2022-01-01"),y=-0.075,label=paste0("Score = ",as.character(round(Score,4))),color='red') +
  theme_bw()+
  theme(plot.title = element_text(hjust = 0.5))



ggsave(paste0(main_path,"/Graphs/AR5GARCH55_Nikkei225_Normal.pdf"))


##################################################################
##################################################################
############################ Student T ###########################
##################################################################
##################################################################


specif <- ugarchspec(variance.model = list(garchOrder=c(5,5)),
                     mean.model =list(armaOrder=c(5,0)),
                     distribution.model = "std")

fitted_GARCH <- ugarchfit(spec=specif,
                          data=Nikkei_log$log_returns[2:length(Nikkei_log$log_returns)],
                          out.sample = length(Nikkei_log$log_returns[-(1:12309)]))

rolling_t <- ugarchforecast(fitted_GARCH,
                          n.ahead = 1,
                          n.roll = length(Nikkei_log$log_returns[-(1:12309)]))

forecast_length = length(rolling_t@forecast$sigmaFor)

DoF_t <- fitted_GARCH@fit$coef[['shape']]

Score = sum(dt(tail(Nikkei_log$log_returns,forecast_length),
                  ncp = rolling_t@forecast$seriesFor,
                  df  = rolling_t@forecast$sigmaFor,
                  log = T))/forecast_length

ggplot() +
  geom_line(aes(x=tail(Nikkei_log$Date,forecast_length),tail(Nikkei_log$log_returns,forecast_length),color='real'))+
  geom_line(aes(x=tail(Nikkei_log$Date,forecast_length),y=rolling_t@forecast$seriesFor,color='forecast')) +
  geom_ribbon(aes(x=tail(Nikkei_log$Date,forecast_length), 
                  ymin=-rolling_t@forecast$sigmaFor,
                  ymax=rolling_t@forecast$sigmaFor,fill="band"),color="green",alpha=0.4) +
  ylab("log-returns")  +
  xlab("Date") +
  ggtitle("ARMA(5,0)-GARCH(5,5) Student_T") + 
  scale_color_manual(values = c("real"="blue","forecast"="red")) + 
  scale_fill_manual(values = c("band" = "black")) +
  labs(color='', fill='') +
  annotate("text",x=ymd("2022-01-01"),y=-0.075,label=paste0("Score = ",as.character(round(Score,4))),color='red') +
  theme_bw()+
  theme(plot.title = element_text(hjust = 0.5))


ggsave(paste0(main_path,"/Graphs/AR5GARCH55_Nikkei225_StudentT.pdf"))

##################################################################
##################################################################
############################## Laplace ###########################
##################################################################
##################################################################

# no capability of rugarch to do laplace - need to make myself


log_dlaplace <- function(x,mu_lap,var_lap) {
  b <- sqrt(var_lap/2)
  dlap <- (1/(2*b))*exp(-(abs(x-mu_lap)/b))
  return(log(dlap))
}

loglik_Lap <- function(param) {
  
  # We first initialize the values
  
  loglik <- 0
  sigma2_lap <- rep(var(win),10)
  # First we define the AR(5) parameters
  
  rho_0 <- param[1] ; rho_1 <- param[2] ; rho_2 <- param[3]
  rho_3 <- param[4] ; rho_4 <- param[5] ; rho_5 <- param[6]
  
  # Now we define the GARCH(5,5) parameters
  
  omega <- exp(param[7]) ; alpha_1 <- exp(param[8])
  alpha_2 <- exp(param[9]) ; alpha_3 <- exp(param[10])
  alpha_4 <- exp(param[11]) ; alpha_5 <- exp(param[12])
  beta_1  <- exp(param[13]) ;  beta_2 <- exp(param[14])
  beta_3 <- exp(param[15])  ; beta_4 <- exp(param[16])
  beta_5 <- exp(param[17])
  
  
  for (i in (10:forecast_length)) {
    
    sigma2_lap[i] <- omega + alpha_1*((1-rho_1)*win[i-1]
                                 -rho_0
                                 -rho_2*win[i-2]
                                 -rho_3*win[i-3]
                                 -rho_4*win[i-4]
                                 -rho_5*win[i-5])^2 +
      alpha_2*((1-rho_1)*win[i-2]
               -rho_0
               -rho_2*win[i-3]
               -rho_3*win[i-4]
               -rho_4*win[i-5]
               -rho_5*win[i-6])^2 +
      alpha_3*((1-rho_1)*win[i-3]
               -rho_0
               -rho_2*win[i-4]
               -rho_3*win[i-5]
               -rho_4*win[i-6]
               -rho_5*win[i-7])^2 +
      alpha_4*((1-rho_1)*win[i-4]
               -rho_0
               -rho_2*win[i-5]
               -rho_3*win[i-6]
               -rho_4*win[i-7]
               -rho_5*win[i-8])^2 +
      alpha_5*((1-rho_1)*win[i-5]
               -rho_0
               -rho_2*win[i-6]
               -rho_3*win[i-7]
               -rho_4*win[i-8]
               -rho_5*win[i-9])^2 +
      beta_1*sigma2_lap[i-5]
    +beta_2*sigma2_lap[i-4] + beta_3*sigma2_lap[i-3]+ beta_4*sigma2_lap[i-2] +
      beta_5*sigma2_lap[i-1]
    
    mu <- rho_0 + rho_1*win[i-1] + rho_2*win[i-2] + rho_3*win[i-3] + rho_4*win[i-4]+rho_5*win[i-5]
    
  
    loglik <- loglik + log_dlaplace(win[i],mu,sigma2_lap[i])
  }
  
  # Take a negative to allow for minimising instead of maximising
  return(-loglik)
}

# Now that we have defined the two log-likelihood functions, we create
# estimate them over the first m=500 observations and use the resulting
# model to create the rolling window forecasts
win <- Nikkei_log$log_returns[2:12309]
oo_lap <- optim(c(rep(0.1,17)),loglik_Lap,method='BFGS')

param_lap <- oo_lap$par


rho_0 <- param_lap[1] ; rho_1 <- param_lap[2] ; rho_2 <- param_lap[3]
rho_3 <- param_lap[4] ; rho_4 <- param_lap[5] ; rho_5 <- param_lap[6]


omega <- exp(param_lap[7]) ; alpha_1 <- exp(param_lap[8])
alpha_2 <- exp(param_lap[9]) ; alpha_3 <- exp(param_lap[10])
alpha_4 <- exp(param_lap[11]) ; alpha_5 <- exp(param_lap[12])
beta_1  <- exp(param_lap[13]) ;  beta_2 <- exp(param_lap[14])
beta_3 <- exp(param_lap[15])  ; beta_4 <- exp(param_lap[16])
beta_5 <- exp(param_lap[17])

var_lap <- rep(var(win),5)

Nikkei_forecasting <- Nikkei_log$log_returns

mus <- c()
vars_lap <- c()
length(Nikkei_forecasting)
for (i in 12309:length(Nikkei_forecasting)) {
  
  var_lap[i-12303] <- omega + alpha_1*((1-rho_1)*Nikkei_forecasting[i-1]
                                    -rho_0
                                    -rho_2*Nikkei_forecasting[i-2]
                                    -rho_3*Nikkei_forecasting[i-3]
                                    -rho_4*Nikkei_forecasting[i-4]
                                    -rho_5*Nikkei_forecasting[i-5])^2 +
    alpha_2*((1-rho_1)*Nikkei_forecasting[i-2]
             -rho_0
             -rho_2*Nikkei_forecasting[i-3]
             -rho_3*Nikkei_forecasting[i-4]
             -rho_4*Nikkei_forecasting[i-5]
             -rho_5*Nikkei_forecasting[i-6])^2 +
    alpha_3*((1-rho_1)*Nikkei_forecasting[i-3]
             -rho_0
             -rho_2*Nikkei_forecasting[i-4]
             -rho_3*Nikkei_forecasting[i-5]
             -rho_4*Nikkei_forecasting[i-6]
             -rho_5*Nikkei_forecasting[i-7])^2 +
    alpha_4*((1-rho_1)*Nikkei_forecasting[i-4]
             -rho_0
             -rho_2*Nikkei_forecasting[i-5]
             -rho_3*Nikkei_forecasting[i-6]
             -rho_4*Nikkei_forecasting[i-7]
             -rho_5*Nikkei_forecasting[i-8])^2 +
    alpha_5*((1-rho_1)*Nikkei_forecasting[i-5]
             -rho_0
             -rho_2*Nikkei_forecasting[i-6]
             -rho_3*Nikkei_forecasting[i-7]
             -rho_4*Nikkei_forecasting[i-8]
             -rho_5*Nikkei_forecasting[i-9])^2 +
    beta_1*var_lap[i-12308]
  +beta_2*var_lap[i-12307] + beta_3*var_lap[i-12306]+ beta_4*var_lap[i-12305] +
    beta_5*var_lap[i-12304]
  
  mus <- c(mus,rho_0 + rho_1*Nikkei_forecasting[i-1] + rho_2*Nikkei_forecasting[i-2] + rho_3*Nikkei_forecasting[i-3] + rho_4*Nikkei_forecasting[i-4]+rho_5*Nikkei_forecasting[i-5])
  
  vars_lap <- c(vars_lap,sqrt(var_lap[i-12303]))
  
}


##################################################################
##################################################################
####################### Export to Python #########################
##################################################################
##################################################################


df <- data.frame(Date = Nikkei_log$Date[12309:length(Nikkei_log$Date)],
                 Norm_mu = c(rolling_norm@forecast$seriesFor),
                 Norm_std = c(rolling_norm@forecast$sigmaFor),
                 T_mu = c(rolling_t@forecast$seriesFor),
                 T_std = c(rolling_t@forecast$sigmaFor),
                 Lap_mu = mus,
                 Lap_std = vars_lap)

write.csv(df,paste0(main_path,"/Processed Data/ARMAGARCH.csv"),row.names=F)

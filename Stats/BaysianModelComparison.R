### Model Comparison ###
## Kostas Lagogiannis 2019
### Model Evidence - Using a Baysian Factor #comparison## 
## The Prior is  very imporrtant 
## Compare Likelyhoods between models for undershooting (linear slope fit)  
## Establish if LF fit model is separate to  DF And NF, while NF and DF are actually from the same  underlying process - 
## Thus show for which prior assumptions we can take NF and DF to be the same while LF fish behave differently
## 
## This was shown to me by  by Giovanni 16-18 jan 2019, based on model evidence formula (see wikipedia Bayesian linear regression 
## https://en.wikipedia.org/wiki/Bayesian_linear_regression)

## Needs Packages  ##
## install.packages("invgamma")
## install.packages("mvtnorm") for the multivariate gaussian
library(invgamma)
library(mvtnorm)

##Load Data (See stat_LinRegression_TurnVsBearing)
lFirstBoutPoints <- readRDS(paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData",".rds",sep="") ) #Processed Registry on which we add )

## Get Event Counts Within Range ##
datTurnVsPreyLL <- cbind(lFirstBoutPoints$LL[,"OnSetAngleToPrey"] , as.numeric(lFirstBoutPoints$LL[,"Turn"]),lFirstBoutPoints$LL[,"RegistarIdx"] )
datTurnVsPreyLL <- datTurnVsPreyLL[!is.na(datTurnVsPreyLL[,1]),]
datTurnVsPreyNL <- cbind(lFirstBoutPoints$NL[,"OnSetAngleToPrey"] , as.numeric(lFirstBoutPoints$NL[,"Turn"]),lFirstBoutPoints$NL[,"RegistarIdx"] )
datTurnVsPreyNL <- datTurnVsPreyNL[!is.na(datTurnVsPreyNL[,1]),]
datTurnVsPreyDL <- cbind(lFirstBoutPoints$DL[,"OnSetAngleToPrey"] , as.numeric(lFirstBoutPoints$DL[,"Turn"]),lFirstBoutPoints$DL[,"RegistarIdx"] )
datTurnVsPreyDL <- datTurnVsPreyDL[!is.na(datTurnVsPreyDL[,1]),]
nDatLL <- NROW(datTurnVsPreyLL)
nDatNL <- NROW(datTurnVsPreyNL)
nDatDL <- NROW(datTurnVsPreyDL)

dataLL=list(turn=datTurnVsPreyLL[,2],bearing=datTurnVsPreyLL[,1],N=nDatLL);
dataNL=list(turn=datTurnVsPreyNL[,2],bearing=datTurnVsPreyNL[,1],N=nDatNL);
dataDL=list(turn=datTurnVsPreyDL[,2],bearing=datTurnVsPreyDL[,1],N=nDatDL);

###

getParams <- function(data,a0=1,b0=1,Lambda0=lambda0){
  n=nrow(data)
  y=data[,2]
  X=cbind(1,data[,1])
  Lambda  = t(X)%*%X+Lambda0
  beta_hat = solve(t(X)%*%X)%*%t(X)%*%y
  mu0 = c(1,0)
  mu  = solve(t(X)%*%X+Lambda0)%*%(t(X)%*%X%*%beta_hat+Lambda0%*%mu0)
  a=a0+n/2
  b=b0+0.5*(t(y)%*%y+t(mu0)%*%Lambda0%*%mu0-t(mu)%*%Lambda%*%mu)
  
  return(list(n=n,a0=a0,b0=b0,lambda0=Lambda0,a=a,b=b,mu=mu,lambda=Lambda))
}

logML <- function(par){
  res=-par$n/2*log(2*pi)+0.5*log(det( par$lambda)/det(par$lambda0)) + par$a0*log(par$b0) - par$a*log(par$b) + lgamma(par$a) - lgamma(par$a0)
  return(res)
}

DrawPostParams<- function(par){
  s2=rinvgamma(1,par$a,par$b)
  beta=rmvnorm(n=1,mean=par$mu,sigma=s2*solve(par$lambda))
  return(list(s2,beta))
}

genManyPar <- function(par,n=100){
  x=seq(-70,70,.2)
  #plot(NA,xlim=range(x),ylim=range(x),type='n')
  for(i in 1:n){
    l=DrawPostParams(par)
    lines(x,l[[2]][1]+x*l[[2]][2])
  }
}

a0=10
b0=1300
sigma0 = 100;
##This is inverse Variance
lambda0 = matrix(c(sigma0*10000,0,0,sigma0),2,2)


##Synthetic - TEst Data
x=seq(-65,65,3)
c11=0.5
c12=0.99
c13=14 ##SD
c21=0.5
c22=0.60
c23=14 ##SED

test_data1=cbind(x,c11+c12*x+rnorm(length(x),sd=c13))
test_data2=cbind(x,c21+c22*x+rnorm(length(x),sd=c23))
test_data3=rbind(test_data1,test_data2)


plot(test_data1,ylim=c(-70,70),xlim=c(-70,70) )
points(test_data2,col="red")
#plot(cbind(dataLL$turn,dataLL$bearing),ylim=c(-70,70),xlim=c(-70,70) )


## Example ##
p1=getParams(test_data1); lML1=logML(p1)
p2=getParams(test_data2); lML2=logML(p2)
p3=getParams(test_data3); lML3=logML(p3)


genManyPar(p1)
genManyPar(p2)
genManyPar(p3)


## +ve means they are from separate Sources
## -ve is interpreted as common model best describes these
logR=(lML1+lML2)-lML3
#######################

##On to the **REAL** Data - PRIORS Are very important 
## in managing to separate te 2 cases where a common source exists and 
## Priors plot(r,dinvgamma(r, 15, 1290))

a0=10 
b0=1025
sigma0 = 1000;
##This is inverse Variance prior
#lambda0 = matrix(c(sigma0*10000,0,0,sigma0),2,2)
lambda0 = matrix(c(sigma0*1,0,0,sigma0),2,2)

## Plot Prior Variance 
r <- seq(0,300,1) 
plot(r,dinvgamma(r, a0, b0),main="Prior for variance (Inverse Gamma)",type="l")

##DATA Combinations ##
datLL <- cbind(dataLL$turn,dataLL$bearing)
datDL <- cbind(dataDL$turn,dataDL$bearing)
datNL <- cbind(dataNL$turn,dataNL$bearing)
dataNLDL <- rbind(cbind(dataNL$turn,dataNL$bearing),cbind(dataDL$turn,dataDL$bearing))
dataDLLL <- rbind(cbind(dataDL$turn,dataDL$bearing),cbind(dataLL$turn,dataLL$bearing))
dataLLNL <- rbind(cbind(dataNL$turn,dataNL$bearing),cbind(dataLL$turn,dataLL$bearing))

MLparamsLL <- getParams( datLL,a0,b0,lambda0 )
MLparamsDL <- getParams( datDL,a0,b0,lambda0 )
MLparamsNL <- getParams( datNL,a0,b0,lambda0 )
MLparamsNLDL <- getParams( dataNLDL,a0,b0 )
MLparamsDLLL <- getParams( dataDLLL,a0,b0 )
MLparamsLLNL <- getParams( dataLLNL,a0,b0 )


## Calcilate Probability of Model Given Data
logML_LL <- logML(MLparamsLL)
logML_DL <- logML(MLparamsDL)
logML_NL <- logML(MLparamsNL)
logML_NLDL <- logML(MLparamsNLDL)
logML_DLLL <- logML(MLparamsDLLL)
logML_LLNL <- logML(MLparamsLLNL)


## Compare Models On Log Likehoods
## +ve means they are from separate Sources
## -ve is interpreted as common model best describes these
logR_DLNL=(logML_DL+logML_NL)-logML_NLDL
logR_LLDL=(logML_DL+logML_LL)-logML_DLLL
logR_LLNL=(logML_NL+logML_LL)-logML_LLNL

strComparisonTxt <- (paste("k-factor comparison\n LL Vs DL:", prettyNum(logR_LLDL ),ifelse(logR_LLDL < 0," Common ","Separate"),
                           "\n LL vs NL:",prettyNum(logR_LLNL),ifelse(logR_LLNL < 0," Common ","Separate") ,
                           " \n DL vs NL:",prettyNum(logR_DLNL), ifelse(logR_DLNL < 0," Common ","Separate") )  )



message(paste("a0:",a0,"b0:",b0,"sigma0:",sigma0))
message(strComparisonTxt)
###Plot Lines

## Plot The LL Fit ##
pdf(file= paste(strPlotExportPath,"/stat/BaysianModelComparison-kfactor-",".pdf",sep="")) 

plot(datLL,col="green",
     main="Baysian Model  comparison",
     sub="",
     xlab="\n \n \n Bearing To Prey prior to Bout",
     ylab="First Turn To Prey",xlim=c(-80,80))
par(col="green")
genManyPar(MLparamsLL)
points(datNL,col="red")
par(col="red")
genManyPar(MLparamsNL)
points(datDL,col="blue")
par(col="blue")
genManyPar(MLparamsDL)
legend("topleft",
       legend=c(
         paste("DL M.LogP:", prettyNum(logML_DL,digits=5) ) ,
         paste("LL M.LogP:", prettyNum(logML_LL,digits=5) ) ,
         paste("NL M.LogP:",prettyNum(logML_NL,digits=5))  ) , fill=colourL )
text(40,-50,strComparisonTxt)

## Variance Prior
plot(r,dinvgamma(r, a0, b0),main="Prior for variance (Inverse Gamma)",type="l")

dev.off()

### Plot Undershoot Raw Data
hist(dataLL$turn/dataLL$bearing)
hist(dataNL$turn/dataNL$bearing)
hist(dataDL$turn/dataDL$bearing)
















####### OLD ###
getParams_old <- function(data,a0=1,b0=1,sigma0=1){
  n=nrow(data)
  y=data[,2]
  X=cbind(1,data[,1])
  Lambda0 = diag(sigma0,2)
  Lambda  = t(X)%*%X+Lambda0 
  beta_hat = solve(t(X)%*%X) %*%t(X)%*%y
  mu0 = c(1,0)               
  mu  = solve(t(X)%*%X+Lambda0)%*%(t(X)%*%X%*%beta_hat+Lambda0%*%mu0)
  a=a0+n/2                           
  b=b0+0.5*(t(y)%*%y+t(mu0)%*%Lambda0%*%mu0-t(mu)%*%Lambda%*%mu)
  
  return(list(n=n,a=a,b=b,mu=mu,lambda=Lambda))  
}

##Marginal Likelyhood 
MarginalLikelihood <- function(MLParams,a0,b0)
{
  return (1/(2*pi)^(MLParams$n/2))* sqrt( det(diag(sigma0,2))/det( MLParams$lambda))*((b0^a0)/(MLParams$b^MLParams$a)) *(gamma(MLParams$a)/gamma(a))
}


b0=1
a0=1
MLparamsLL <- getParams( cbind(dataLL$turn,dataLL$bearing),a0,b0 )
MLparamsDL <- getParams( cbind(dataDL$turn,dataDL$bearing),a0,b0 )
MLparamsNL <- getParams( cbind(dataNL$turn,dataNL$bearing),a0,b0 )

dataNLDL <- rbind(cbind(dataNL$turn,dataNL$bearing),cbind(dataDL$turn,dataDL$bearing))
MLparamsNLDL <- getParams( dataNLDL,a0,b0 )

dataDLLL <- rbind(cbind(dataDL$turn,dataDL$bearing),cbind(dataLL$turn,dataLL$bearing))
MLparamsDLLL <- getParams( dataDLLL,a0,b0 )

## Calcilate Probability of Model Given Data
ML_LL <- MarginalLikelihood(MLparamsLL,a0,b0)
ML_DL <- MarginalLikelihood(MLparamsDL,a0,b0)
ML_NL <- MarginalLikelihood(MLparamsNL,a0,b0)
ML_NLDL <- MarginalLikelihood(MLparamsNLDL,a0,b0)
ML_DLLL <- MarginalLikelihood(MLparamsDLLL,a0,b0)

##Now Compare ##
# A value of K > 1 means that M1 is more strongly supported by the data under consideration than M2.
ML_DL*ML_NL/(ML_NLDL) ## This is equal to 1 
ML_NL/(ML_NLDL)
ML_DL/(ML_NLDL)

## Check For COmparing DL LL 
ML_DL*ML_LL/(ML_DLLL)
ML_LL/(ML_DLLL)
ML_DL/(ML_DLLL)

mean(dataDL$turn/dataDL$bearing)
mean(dataNL$turn/dataNL$bearing)



cov0=matrix(c(1,0,0,1),2,2);
mynorm <- function(x,y,cov) { 
  return(exp(-0.5/100.*(x*(cov[1,1]*x+cov[1,2]*y)+y*(cov[2,1]*x+cov[2,2]*y))))
}

x0=seq(-10,10,0.2);
y0=seq(-10,10,0.2);
u=outer(x0,y0,mynorm,cov=matrix(c(2,1,1,2)*10,2,2));
plot(x0,u[50,],type='l')


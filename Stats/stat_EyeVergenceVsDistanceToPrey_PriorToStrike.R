### Kostas Lagogiannis 2019-04-17 
## Discovered relationship between the last bout speed - ie Capture speed and the undershoot ratio -
## higher undershoot predicts higher capture speeds, while undershoot also seems to predict higher distance from prey 
##  suggesting that LF stays further away from prey, so it does stronger capture bouts and it is undershoot that allows it to do it.
## Their ability to judge distance is also revealed in the the eye vergence prior to capture, where there is a relationship between EyeV and distance to prey   is shown 
## Stohoi:
## S1 Establish whether undershoot covaries with capture speed
## S2 Compare cap.Speed vs UNdershoot models between groups - Do they also covary in all groups?
## S3 compare accuracy of capture speed vs distance to prey between groups (use covariance distributions)
## Aitiology :
## 
## A: Does undershoot explain capture speed and distance to prey accuracy?

### Stat Model on Capture speed vs undershoot
library(rjags)
library(runjags)


source("DataLabelling/labelHuntEvents_lib.r") ##for convertToScoreLabel
source("TrackerDataFilesImport_lib.r")
### Hunting Episode Analysis ####
source("HuntingEventAnalysis_lib.r")

strmodel_capspeedVsDistance <- "
model {
##Draw capt speed from 2d gaussian
for (i in 1:N)
{
  c[i,1:2] ~ dmnorm(mu[],prec[ , ])
}


##Covariance matrix and its inverse -> the precision matrix
prec[1:2,1:2] <- inverse(cov[,])
cov[1,1] <- sigma[1]*sigma[1]
cov[1,2] <- sigma[1]*sigma[2]*rho
cov[2,1] <- sigma[1]*sigma[2]*rho
cov[2,2] <- sigma[2]*sigma[2]

## Priors 
sigma[1] ~ dunif(0,1) ##dist prey - Keep it broad within the expected limits 
sigma[2] ~ dunif(0,100)  ##the EyeV sigma 
rho ~ dunif(-1,1) ##The covar coefficient
mu[1] ~ dnorm(1,0.001) ##Distance prey
mu[2] ~ dnorm(40,0.001) ##Eye V 

## Synthesize data from the distribution
x_rand ~ dmnorm(mu[],prec[,])

} "

strModelPDFFileName <- "/stat/UndershootAnalysis/stat_modelDistToPreyVsEyeV_Valid.pdf"
strDataPDFFileName <- "/stat/UndershootAnalysis/DistanceToPreyVsEyeVergence_scatter_Valid.pdf"

datTrackedEventsRegister <- readRDS( paste(strDataExportDir,"/setn_huntEventsTrackAnalysis_Register_ToValidate.rds",sep="") ) ## THis is the Processed Register File On 
#lMotionBoutDat <- readRDS(paste(strDataExportDir,"/huntEpisodeAnalysis_MotionBoutData_SetC.rds",sep="") ) #Processed Registry on which we add )
#lEyeMotionDat <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_EyeMotionData_SetC",".rds",sep="")) #
lFirstBoutPoints <-readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_Validated",".rds",sep="")) 

datDistanceToPreyVsEyeV_NL <- data.frame( cbind(DistanceToPrey=lFirstBoutPoints$NL[,"DistanceToPrey"],EyeV=lFirstBoutPoints$NL[,"CaptureStrikeEyeVergence"]),Validated= lFirstBoutPoints$NL[,"Validated"] )
datDistanceToPreyVsEyeV_LL <- data.frame( cbind(DistanceToPrey=lFirstBoutPoints$LL[,"DistanceToPrey"],EyeV=lFirstBoutPoints$LL[,"CaptureStrikeEyeVergence"]),Validated= lFirstBoutPoints$LL[,"Validated"] )
datDistanceToPreyVsEyeV_DL <- data.frame( cbind(DistanceToPrey=lFirstBoutPoints$DL[,"DistanceToPrey"],EyeV=lFirstBoutPoints$DL[,"CaptureStrikeEyeVergence"]),Validated= lFirstBoutPoints$DL[,"Validated"] )


###Validated Only
datDistanceToPreyVsEyeV_NL <- datDistanceToPreyVsEyeV_NL[!is.na(datDistanceToPreyVsEyeV_NL$Validated), ]
datDistanceToPreyVsEyeV_LL <- datDistanceToPreyVsEyeV_LL[!is.na(datDistanceToPreyVsEyeV_LL$Validated), ]
datDistanceToPreyVsEyeV_DL <- datDistanceToPreyVsEyeV_DL[!is.na(datDistanceToPreyVsEyeV_DL$Validated), ]


##
steps <- 5000
str_vars <- c("mu","rho","sigma","x_rand")
ldata_LF <- list(c=datDistanceToPreyVsEyeV_LL,N=NROW(datDistanceToPreyVsEyeV_LL)) ##Live fed
ldata_NF <- list(c=datDistanceToPreyVsEyeV_NL,N=NROW(datDistanceToPreyVsEyeV_NL)) ##Not fed
ldata_DF <- list(c=datDistanceToPreyVsEyeV_DL,N=NROW(datDistanceToPreyVsEyeV_DL)) ##Dry fed

jags_model_LF <- jags.model(textConnection(strmodel_capspeedVsDistance), data = ldata_LF, 
                            n.adapt = 500, n.chains = 3, quiet = F)
update(jags_model_LF, 500)
draw_LF=jags.samples(jags_model_LF,steps,thin=2,variable.names=str_vars)

##Not Fed
jags_model_NF <- jags.model(textConnection(strmodel_capspeedVsDistance), data = ldata_NF, 
                            n.adapt = 500, n.chains = 3, quiet = F)
update(jags_model_NF)
draw_NF=jags.samples(jags_model_NF,steps,thin=2,variable.names=str_vars)

##Not Fed
jags_model_DF <- jags.model(textConnection(strmodel_capspeedVsDistance), data = ldata_DF, 
                            n.adapt = 500, n.chains = 3, quiet = F)
update(jags_model_DF, 500)
draw_DF=jags.samples(jags_model_DF,steps,thin=2,variable.names=str_vars)

### Estimate  densities  ###
nContours <- 5
ntail <-1000
pBw   <- 0.1 

zLL <- kde2d(c(tail(draw_LF$mu[1,,1],ntail)), c(tail(draw_LF$mu[2,,1],ntail)),n=80)
zNL <- kde2d(c(tail(draw_NF$mu[1,,1],ntail)), c(tail(draw_NF$mu[2,,1],ntail)),n=80)
zDL <- kde2d(c(tail(draw_DF$mu[1,,1],ntail)), c(tail(draw_DF$mu[2,,1],ntail)),n=80)

## Check out the covar coeffient , compare estimated densities
dLLb_rho<-density(tail(draw_LF$rho[,,1],ntail),kernel="gaussian",bw=pBw)
dNLb_rho<-density(tail(draw_NF$rho[,,1],ntail),kernel="gaussian",bw=pBw)
dDLb_rho<-density(tail(draw_DF$rho[,,1],ntail),kernel="gaussian",bw=pBw)


## Check out the dist to prey variance  , compare estimated densities
dLLb_sigmaD<-density(tail(draw_LF$sigma[1,,1],ntail),kernel="gaussian",bw=pBw)
dNLb_sigmaD<-density(tail(draw_NF$sigma[1,,1],ntail),kernel="gaussian",bw=pBw)
dDLb_sigmaD<-density(tail(draw_DF$sigma[1,,1],ntail),kernel="gaussian",bw=pBw)

dLLb_sigmaE<-density(tail(draw_LF$sigma[2,,1],ntail),kernel="gaussian",bw=pBw)
dNLb_sigmaE<-density(tail(draw_NF$sigma[2,,1],ntail),kernel="gaussian",bw=pBw)
dDLb_sigmaE<-density(tail(draw_DF$sigma[2,,1],ntail),kernel="gaussian",bw=pBw)



##Get the synthesized data:
plot(tail((draw_NF$x_rand[1,,1]) , ntail),tail((draw_NF$x_rand[2,,1]) , ntail),col=colourH[1])
points(tail((draw_LF$x_rand[1,,1]) , ntail),tail((draw_LF$x_rand[2,,1]) , ntail),col=colourH[2])
points(tail((draw_DF$x_rand[1,,1]) , ntail),tail((draw_DF$x_rand[2,,1]) , ntail),col=colourH[3])

####################################
## PLot Model / Means and covariance ##
## Open Output PDF 

pdf(file= paste(strPlotExportPath,strModelPDFFileName,sep=""),width=14,height=7,
    title="A statistical model for EyeVergence vs Distance to prey  before capture bout ")

outer = FALSE
line = 1 ## SubFig Label Params
cex = 1.1
adj  = 3.5
padj <- -23.0
las <- 1

layout(matrix(c(1,2,3,4),2,2, byrow = TRUE))
##Margin: (Bottom,Left,Top,Right )
par(mar = c(3.9,4.3,1,1))

## Plot the mean of the 2D Models ##
ntail <- 1000
plot(tail(draw_NF$mu[1,,1],ntail),tail(draw_NF$mu[2,,1],ntail),col=colourH[1],pch=pchL[1], xlim=c(0,0.8),ylim=c(40,80),ylab=NA,xlab=NA )
points(tail(draw_LF$mu[1,,1],ntail),tail(draw_LF$mu[2,,1],ntail),col=colourH[2],pch=pchL[2])
points(tail(draw_DF$mu[1,,1],ntail),tail(draw_DF$mu[2,,1],ntail),col=colourH[3],pch=pchL[1])
mtext(side = 1,cex=0.8, line = 2.2, expression("Distance to Prey (mm) "~(delta) ))
mtext(side = 2,cex=0.8, line = 2.2, expression("Eye Vergence ("~degrees~")" ))

contour(zDL, drawlabels=FALSE, nlevels=nContours,add=TRUE)
contour(zLL, drawlabels=FALSE, nlevels=nContours,add=TRUE)
contour(zNL, drawlabels=FALSE, nlevels=nContours,add=TRUE)


legend("topleft",
       legend=c(  expression (),
                  bquote(NF["e"] ~ '#' ~ .(ldata_NF$N)  ),
                  bquote(LF["e"] ~ '#' ~ .(ldata_LF$N)  ),
                  bquote(DF["e"] ~ '#' ~ .(ldata_DF$N)  )  ), #paste(c("DL n=","LL n=","NL n="),c(NROW(lFirstBoutPoints[["DL"]][,1]),NROW(lFirstBoutPoints[["LL"]][,1]) ,NROW(lFirstBoutPoints[["NL"]][,1] ) ) )
       pch=pchL, col=colourLegL)
mtext("A",at="topleft",outer=outer,side=2,col="black",font=2,las=las,line=line,padj=padj,adj=adj,cex.main=cex)

## Plot the covariance ##
plot(dNLb_rho,col=colourLegL[1],xlim=c(-1.0,1),lwd=3,lty=1,ylim=c(0,3),
     main=NA, #"Density Inference of Turn-To-Prey Slope ",
     xlab=NA,ylab=NA) #expression(paste("slope ",gamma) ) )
lines(dLLb_rho,col=colourLegL[2],lwd=3,lty=2)
lines(dDLb_rho,col=colourLegL[3],lwd=3,lty=3)
legend("topright",
       legend=c(  expression (),
                  bquote(NF["e"] ~ '#' ~ .(ldata_NF$N)  ),
                  bquote(LF["e"] ~ '#' ~ .(ldata_LF$N)  ),
                  bquote(DF["e"] ~ '#' ~ .(ldata_DF$N)  )  ), ##paste(c("DL n=","LL n=","NL n="),c(NROW(lFirstBoutPoints[["DL"]][,1]),NROW(lFirstBoutPoints[["LL"]][,1]) ,NROW(lFirstBoutPoints[["NL"]][,1] ) ) )
       col=colourLegL,lty=c(1,2,3),lwd=3)
mtext(side = 1,cex=0.8, line = 2.2, expression(paste("Cov. Eye Vergence to Prey Distance  ",rho) ))
mtext(side = 2,cex=0.8, line = 2.2, expression("Density ") )
mtext("B",at="topleft",outer=outer,side=2,col="black",font=2,las=las,line=line,padj=padj,adj=adj,cex.main=cex)

### aDDD DISTANCE TO PREY VARIANCE COMPARISON

plot(dNLb_sigmaD,col=colourLegL[1],xlim=c(0.0,1),lwd=3,lty=1,ylim=c(0,5),
     main=NA, #"Density Inference of Turn-To-Prey Slope ",
     xlab=NA,ylab=NA) #expression(paste("slope ",gamma) ) )
lines(dLLb_sigmaD,col=colourLegL[2],lwd=3,lty=2)
lines(dDLb_sigmaD,col=colourLegL[3],lwd=3,lty=3)
mtext(side = 1,cex=0.8, line = 2.2, expression(paste("Variance Prey Distance  ",delta) ))
mtext(side = 2,cex=0.8, line = 2.2, expression("Density ") )

### PloT CAPT SPEED VARIANCE 

plot(dNLb_sigmaE,col=colourLegL[1],xlim=c(0.0,20),lwd=3,lty=1,ylim=c(0,1),
     main=NA, #"Density Inference of Turn-To-Prey Slope ",
     xlab=NA,ylab=NA) #expression(paste("slope ",gamma) ) )
lines(dLLb_sigmaE,col=colourLegL[2],lwd=3,lty=2)
lines(dDLb_sigmaE,col=colourLegL[3],lwd=3,lty=3)
mtext(side = 1,cex=0.8, line = 2.2, expression(paste("Variance Eye Vergence  ") ))
mtext(side = 2,cex=0.8, line = 2.2, expression("Density ") )


dev.off()

#mcmc_samples <- coda.samples(jags_model, c("mu", "rho", "sigma", "x_rand"),                             n.iter = 5000)

### PLOT EMPIRICAL 
####
########################################################
###        Distance vs EyeV               ###

############### Distance to prey vs Eye V at the onset of capture bout #### 


pdf(file= paste(strPlotExportPath,strDataPDFFileName,sep=""))

layout(matrix(c(1,2,3),3,1, byrow = FALSE))
##Margin: (Bottom,Left,Top,Right )
par(mar = c(3.9,4.3,1,1))
plot(datDistanceToPreyVsEyeV_NL$DistanceToPrey,datDistanceToPreyVsEyeV_NL$EyeV,xlim=c(0,1.0),ylim=c(0,100),col=colourH[1],xlab="Distance to prey (mm)",ylab="Eye Vergence")
legend("topright",
       legend=paste("NF cov:",prettyNum(digits=3, cov(datDistanceToPreyVsEyeV_NL$DistanceToPrey, datDistanceToPreyVsEyeV_NL$EyeV) ) ) ) 

plot(datDistanceToPreyVsEyeV_LL$DistanceToPrey,datDistanceToPreyVsEyeV_LL$EyeV,xlim=c(0,1.0),ylim=c(0,100),col=colourH[2],xlab="Distance to prey (mm)",ylab="Eye Vergence")
legend("topright",
       legend=paste("LF cov:",prettyNum(digits=3, cov(datDistanceToPreyVsEyeV_LL$DistanceToPrey, datDistanceToPreyVsEyeV_LL$EyeV) ) )) 

plot(datDistanceToPreyVsEyeV_DL$DistanceToPrey,datDistanceToPreyVsEyeV_DL$EyeV,xlim=c(0,1.0),ylim=c(0,100),col=colourH[3] ,xlab="Distance to prey (mm)",ylab="Eye Vergence")
legend("topright",
       legend=paste("DF cov:",prettyNum(digits=3, cov(datDistanceToPreyVsEyeV_DL$DistanceToPrey, datDistanceToPreyVsEyeV_DL$EyeV) ) ) ) 

dev.off()


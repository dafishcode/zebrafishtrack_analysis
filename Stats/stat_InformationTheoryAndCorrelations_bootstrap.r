## Calculate Mutual Information Between turn ratio and Distance to Prey
## What is the relationship between correlation Pearson and Mutual Information?
# what do these measures do? 
# In Cov(X,Y) they create a weighted sum of the product of the two random variables. 
# In I(X,Y) they create a weighted sum of their joint probabilities.
#So with Cov(X,Y) we look at what non-independence does to their product, while in I(X,Y) we look at what non-independence does to their joint probability distribution. 
#So the two are not antagonistic—they are complementary, describing different aspects of the association between two random variables. One could comment that Mutual Information "is not concerned" whether the association is linear or not, while Covariance may be zero and the variables may still be stochastically dependent. On the other hand, Covariance can be calculated directly from a data sample without the need to actually know the probability distributions involved (since it is an expression involving moments of the distribution), while Mutual Information requires knowledge of the distributions

###Spearman's rank correlation coefficient or Spearman's rho, is a nonparametric measure of rank correlation (statistical dependence between the rankings of two variables).
# It assesses how well the relationship between two variables can be described using a monotonic function.
## The Spearman correlation between two variables is equal to the Pearson correlation between the rank values of those two variables; 
# while Pearson's correlation assesses linear relationships, Spearman's correlation assesses monotonic relationships (whether linear or not). If there are no repeated data values, a perfect Spearman correlation of +1 or −1 occurs when each of the variables is a perfect monotone function of the other

library(tools)
library(RColorBrewer);


source("config_lib.R")
source("Stats/stat_InformationTheoryAndCorrelations_bootstrap_lib.r")

#lEyeMotionDat <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_EyeMotionData_SetC",".rds",sep="")) #
lFirstBoutPoints <-readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_Validated",".rds",sep="")) 


#### Load  hunting stats- Generated in main_GenerateMSFigures.r - now including the cluster classification -
#datCapture_NL <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_NL_clustered",".rds",sep="")) 
#datCapture_LL <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_LL_clustered",".rds",sep="")) 
#datCapture_DL <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_DL_clustered",".rds",sep="")) 


#### LOAD Capture First-Last Bout hunting that include the cluster classification - (made in stat_CaptureSpeedVsDistanceToPrey)
##22/10/19- Updated with Time To get To prey INfo 
datCapture_NL <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_wCapFrame_NL_clustered.rds",sep="")) 
datCapture_LL <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_wCapFrame_LL_clustered.rds",sep="")) 
datCapture_DL <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_wCapFrame_DL_clustered.rds",sep="")) 


#datCapture_NL <- datCapture_NL[datCapture_NL$Cluster == "fast",]
#datCapture_LL <- datCapture_LL[datCapture_LL$Cluster == "fast",]
#datCapture_DL <- datCapture_DL[datCapture_DL$Cluster == "fast",]

### Capture Speed vs Distance to prey ###
#datCapture_NL <- data.frame( cbind(DistanceToPrey=lFirstBoutPoints$NL[,"DistanceToPrey"],CaptureSpeed=lFirstBoutPoints$NL[,"CaptureSpeed"],Undershoot=lFirstBoutPoints$NL[,"Turn"]/lFirstBoutPoints$NL[,"OnSetAngleToPrey"],RegistarIdx=lFirstBoutPoints$NL[,"RegistarIdx"],Validated= lFirstBoutPoints$NL[,"Validated"] ) )
#datCapture_LL <- data.frame( cbind(DistanceToPrey=lFirstBoutPoints$LL[,"DistanceToPrey"],CaptureSpeed=lFirstBoutPoints$LL[,"CaptureSpeed"]),Undershoot=lFirstBoutPoints$LL[,"Turn"]/lFirstBoutPoints$LL[,"OnSetAngleToPrey"],RegistarIdx=lFirstBoutPoints$LL[,"RegistarIdx"],Validated= lFirstBoutPoints$LL[,"Validated"] )
#datCapture_DL <- data.frame( cbind(DistanceToPrey=lFirstBoutPoints$DL[,"DistanceToPrey"],CaptureSpeed=lFirstBoutPoints$DL[,"CaptureSpeed"]),Undershoot=lFirstBoutPoints$DL[,"Turn"]/lFirstBoutPoints$DL[,"OnSetAngleToPrey"],RegistarIdx=lFirstBoutPoints$DL[,"RegistarIdx"],Validated= lFirstBoutPoints$DL[,"Validated"] )
##Select Validated Only
#datCapture_NL <- datCapture_NL[datCapture_NL$Validated == 1, ]
#datCapture_LL <- datCapture_LL[datCapture_LL$Validated == 1, ]
#datCapture_DL <- datCapture_DL[datCapture_DL$Validated == 1, ]

# XRange_NL  <- range(datCapture_NL$Undershoot) #seq(0,2,0.2)
# YRange_NL <- range(datCapture_NL$CaptureSpeed) ##We limit The information Obtained To Reasonable Ranges Of Phi (Vergence Angle)
# 
# XRange_LL  <- range(datCapture_LL$Undershoot) #seq(0,2,0.2)
# YRange_LL <- range(datCapture_LL$CaptureSpeed) ##We limit The information Obtained To Reasonable Ranges Of Phi (Vergence Angle)
# 
# XRange_DL  <- range(datCapture_DL$Undershoot) #seq(0,2,0.2)
# YRange_DL <- range(datCapture_DL$CaptureSpeed) ##We limit The information Obtained To Reasonable Ranges Of Phi (Vergence Angle)
# 

XRange  <- c(0,0.8) #
YRange <- c(0,60) ##We limit The information Obtained To Reasonable Ranges Of Phi (Vergence Angle)
nSamples <- 1000
  
stat_Cap_NF <- bootStrap_stat(datCapture_NL$DistanceToPrey,datCapture_NL$CaptureSpeed,nSamples,XRange,YRange)
stat_Cap_LF <- bootStrap_stat(datCapture_LL$DistanceToPrey,datCapture_LL$CaptureSpeed,nSamples,XRange,YRange)
stat_Cap_DF <- bootStrap_stat(datCapture_DL$DistanceToPrey,datCapture_DL$CaptureSpeed,nSamples,XRange,YRange)


stat_Cap_fast_NF <- bootStrap_stat(datCapture_NL[datCapture_NL$Cluster == "fast",]$DistanceToPrey,datCapture_NL[datCapture_NL$Cluster == "fast",]$CaptureSpeed,nSamples,XRange,YRange)
stat_Cap_fast_LF <- bootStrap_stat(datCapture_LL[datCapture_LL$Cluster == "fast",]$DistanceToPrey,datCapture_LL[datCapture_LL$Cluster == "fast",]$CaptureSpeed,nSamples,XRange,YRange)
stat_Cap_fast_DF <- bootStrap_stat(datCapture_DL[datCapture_DL$Cluster == "fast",]$DistanceToPrey,datCapture_DL[datCapture_DL$Cluster == "fast",]$CaptureSpeed,nSamples,XRange,YRange)



## Distance Vs Capture Speed Mututal INformation 
bkSeq <- seq(0,2,0.02)
range(stat_Cap_NF$MI)
hist(stat_Cap_NF$MI,xlim=c(0,2),ylim=c(0,300),col=colourL[2],breaks = bkSeq ,
     xlab="MI capture speed and distance to prey", main="Bootstrapped Mutual information")
hist(stat_Cap_LF$MI,xlim=c(0,2),col=colourL[1],add=TRUE ,breaks = bkSeq)
hist(stat_Cap_DF$MI,xlim=c(0,2),col=colourL[3],add=TRUE,breaks = bkSeq )


##Correlation
bkSeq <- seq(-0.1,0.8,0.02)
hist(stat_Cap_NF$corr,xlim=c(-0.1,0.8),ylim=c(0,300),col=colourL[2],breaks = bkSeq,xlab="Pearson's correlation speed vs distance",main="Bootstraped 0.80" )
hist(stat_Cap_LF$corr,xlim=c(-0.1,0.8),col=colourL[1],add=TRUE ,breaks = bkSeq)
hist(stat_Cap_DF$corr,xlim=c(-0.1,0.8),col=colourL[3],add=TRUE,breaks = bkSeq )

##LF Explores More Speeds - Higher Speed Entropy
bkSeq <- seq(0,4,0.05)
hist(stat_Cap_NF$entropy_Y,xlim=c(1,4),col=colourL[2], breaks=bkSeq,xlab="Capture speed entropy  ",main=NA  )
hist(stat_Cap_LF$entropy_Y,xlim=c(1,4),col=colourL[1],add=TRUE, breaks=bkSeq)
hist(stat_Cap_DF$entropy_Y,xlim=c(1,4),col=colourL[3],add=TRUE, breaks=bkSeq)

##LF Explores More Distances - Higher Prey-Distance Entropy
hist(stat_Cap_NF$entropy_X,xlim=c(1,4),col=colourL[2], breaks=bkSeq,xlab="Distance to prey entropy  " ,main=NA )
hist(stat_Cap_LF$entropy_X,xlim=c(1,4),col=colourL[1], breaks=bkSeq,add=TRUE )
hist(stat_Cap_DF$entropy_X,xlim=c(1,4),col=colourL[3], breaks=bkSeq,add=TRUE )

### DENSITIES ####
pBw <- 0.02

# Plot Fast_Cluster Speed Vs Distance Correlation - bootstraped Stat ##
strPlotName = paste(strPlotExportPath,"/stat/fig4S1_statbootstrap_correlationFastClust_SpeedVsDistance.pdf",sep="")
pdf(strPlotName,width=7,height=7,title="Correlations In Speed/Distance Fast cluster capture data ",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))
  par(mar = c(3.9,4.7,1,1))

  plot(density(stat_Cap_fast_NF$corr,kernel="gaussian",bw=pBw),
       col=colourLegL[1],xlim=c(0,1),lwd=3,lty=1,ylim=c(0,10),main=NA, xlab=NA,ylab=NA,cex=cex,cex.axis=cex) #expression(paste("slope ",gamma) ) )
  lines(density(stat_Cap_fast_LF$corr,kernel="gaussian",bw=pBw),col=colourLegL[2],lwd=3,lty=2)
  lines(density(stat_Cap_fast_DF$corr,kernel="gaussian",bw=pBw),col=colourLegL[3],lwd=3,lty=3)
  
  # legend("topright",         legend=c(  expression (),
  #                    bquote(NF~ ''  ),
  #                    bquote(LF ~ '' ),
  #                    bquote(DF ~ '' )  ), ##paste(c("DL n=","LL n=","NL n="),c(NROW(lFirstBoutPoints[["DL"]][,1]),NROW(lFirstBoutPoints[["LL"]][,1]) ,NROW(lFirstBoutPoints[["NL"]][,1] ) ) )
  #         col=colourLegL,lty=c(1,2,3),lwd=3,cex=cex)
  mtext(side = 1,cex=cex,cex.main=cex, line = lineXAxis, expression(paste("Correlation of capture speed to prey distance  ") ))
  mtext(side = 2,cex=cex,cex.main=cex, line = lineAxis, expression("Density function"))

dev.off()

# Plot Speed Vs Distance Correlation - bootstraped Stat ##
strPlotName = paste(strPlotExportPath,"/stat/fig5_statbootstrap_correlation_SpeedVsDistance.pdf",sep="")
pdf(strPlotName,width=7,height=7,title="Correlations In Speed/Distance capture  variables",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))
par(mar = c(3.9,4.7,1,1))

  plot(density(stat_Cap_NF$corr,kernel="gaussian",bw=pBw),
       col=colourLegL[1],xlim=c(0,1),lwd=3,lty=1,ylim=c(0,10),main=NA, xlab=NA,ylab=NA,cex=cex,cex.axis=cex) #expression(paste("slope ",gamma) ) )
  lines(density(stat_Cap_LF$corr,kernel="gaussian",bw=pBw),col=colourLegL[2],lwd=3,lty=2)
  lines(density(stat_Cap_DF$corr,kernel="gaussian",bw=pBw),col=colourLegL[3],lwd=3,lty=3)
  
# legend("topright",         legend=c(  expression (),
#                    bquote(NF~ ''  ),
#                    bquote(LF ~ '' ),
#                    bquote(DF ~ '' )  ), ##paste(c("DL n=","LL n=","NL n="),c(NROW(lFirstBoutPoints[["DL"]][,1]),NROW(lFirstBoutPoints[["LL"]][,1]) ,NROW(lFirstBoutPoints[["NL"]][,1] ) ) )
#         col=colourLegL,lty=c(1,2,3),lwd=3,cex=cex)
  mtext(side = 1,cex=cex,cex.main=cex, line = lineXAxis, expression(paste("Correlation of capture speed to prey distance  ") ))
  mtext(side = 2,cex=cex,cex.main=cex, line = lineAxis, expression("Density function"))

dev.off()





############# BOOTSTRAP 


meanMI <- list(MI_NF=mean(stat_Cap_NF$MI),MI_LF=mean(stat_Cap_LF$MI),MI_DF=mean(stat_Cap_DF$MI))
barplot(c(meanMI$MI_NF,meanMI$MI_LF,meanMI$MI_DF),ylim=c(0,1) )

# library(ggplot)
# dodge <- position_dodge(width = 0.9)
# limits <- aes(ymax = mean(datXYAnalysis$MI) + sd(datXYAnalysis$MI)/sqrt(NROW((datXYAnalysis$MI))),
#               ymin = mean(datXYAnalysis$MI) - 2*sd(datXYAnalysis$MI)/sqrt(NROW((datXYAnalysis$MI))))
# 
# p <- ggplot(data = datXYAnalysis, aes(y = MI ))
XRange  <- c(0,2) #
YRange  <- c(0,60) ##We limit The information Obtained To Reasonable Ranges Of Phi (Vergence Angle)
smethod <- "spearman"
###### UNDERSHOOT TO SPEED - ALL 
  stat_CapTurnVsSpeed_NF <- bootStrap_stat(datCapture_NL$Undershoot,datCapture_NL$CaptureSpeed,10000,XRange,YRange,smethod)
  stat_CapTurnVsSpeed_LF <- bootStrap_stat(datCapture_LL$Undershoot,datCapture_LL$CaptureSpeed,10000,XRange,YRange,smethod)
  stat_CapTurnVsSpeed_DF <- bootStrap_stat(datCapture_DL$Undershoot,datCapture_DL$CaptureSpeed,10000,XRange,YRange,smethod)
  
  stat_CapTurnVsSpeed_fast_NF <- bootStrap_stat(datCapture_NL[datCapture_NL$Cluster == "fast", ]$Undershoot,datCapture_NL[datCapture_NL$Cluster == "fast", ]$CaptureSpeed,10000,XRange,YRange,smethod)
  stat_CapTurnVsSpeed_fast_LF <- bootStrap_stat(datCapture_LL[datCapture_LL$Cluster == "fast", ]$Undershoot,datCapture_LL[datCapture_LL$Cluster == "fast", ]$CaptureSpeed,10000,XRange,YRange,smethod)
  stat_CapTurnVsSpeed_fast_DF <- bootStrap_stat(datCapture_DL[datCapture_DL$Cluster == "fast", ]$Undershoot,datCapture_DL[datCapture_DL$Cluster == "fast", ]$CaptureSpeed,10000,XRange,YRange,smethod)
  
  stat_CapTurnVsSpeed_slow_NF <- bootStrap_stat(datCapture_NL[datCapture_NL$Cluster == "slow", ]$Undershoot,datCapture_NL[datCapture_NL$Cluster == "slow", ]$CaptureSpeed,10000,XRange,YRange,smethod)
  stat_CapTurnVsSpeed_slow_LF <- bootStrap_stat(datCapture_LL[datCapture_LL$Cluster == "slow", ]$Undershoot,datCapture_LL[datCapture_LL$Cluster == "slow", ]$CaptureSpeed,10000,XRange,YRange,smethod)
  stat_CapTurnVsSpeed_slow_DF <- bootStrap_stat(datCapture_DL[datCapture_DL$Cluster == "slow", ]$Undershoot,datCapture_DL[datCapture_DL$Cluster == "slow", ]$CaptureSpeed,10000,XRange,YRange,smethod)
  
  
  #  PLot Density Turn Vs Speed
  #strPlotName = paste(strPlotExportPath,"/stat/fig6_statbootstrap_Spearman_correlation_TurnVsSpeed.pdf",sep="")
  strPlotName = paste(strPlotExportPath,"/stat/fig6_statbootstrap_correlation_TurnVsSpeed.pdf",sep="")
  pdf(strPlotName,width=7,height=7,title="Correlations In hunt variables - turn-ratio vs capture Speed",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))
  par(mar = c(3.9,4.7,1,1))
  
    pBw <- 0.02
    plot(density(stat_CapTurnVsSpeed_NF$corr,kernel="gaussian",bw=pBw),
         col=colourLegL[1],xlim=c(-0.5,0.5),lwd=3,lty=1,ylim=c(0,10),main=NA, xlab=NA,ylab=NA,cex=cex,cex.axis=cex) #expression(paste("slope ",gamma) ) )
    lines(density(stat_CapTurnVsSpeed_LF$corr,kernel="gaussian",bw=pBw),col=colourLegL[2],lwd=3,lty=2)
    lines(density(stat_CapTurnVsSpeed_DF$corr,kernel="gaussian",bw=pBw),col=colourLegL[3],lwd=3,lty=3)
    mtext(side = 1,cex=cex,cex.main=cex, line = lineXAxis, expression(paste("Correlation of turn-ratio to capture speed  ") ))
    mtext(side = 2,cex=cex,cex.main=cex, line = lineAxis, expression("Density function"))
  
  dev.off()  
  
  ## Evaluate Probabilities Correlations
  ## The p-value is the probability that the difference between the sample means is at least as large as what has been observed,
  ## under the assumption that the population means are equal. p < thres  the null hypothesis is rejected in favor of the alternative hypothesis.
  message("significance")
  
  t.test(x=stat_CapTurnVsSpeed_LF$corr,alternative = "less") #****  LF less than 0
  t.test(x=stat_CapTurnVsSpeed_NF$corr,alternative = "greater")
  t.test(x=stat_CapTurnVsSpeed_DF$corr,alternative = "less") #** DF is also less Than zero
  t.test(x=stat_CapTurnVsSpeed_LF$corr,y=stat_CapTurnVsSpeed_DF$corr,alternative = "less") ##But LF has higher corr  than DF
  t.test(x=stat_CapTurnVsSpeed_LF$corr,y=stat_CapTurnVsSpeed_NF$corr,alternative = "less") ## LF has higher corr of undersh to dist than NF
  
  
  #  PLot Density Turn Vs FAST Speed
  #strPlotName = paste(strPlotExportPath,"/stat/fig6_statbootstrap_Spearman_correlation_TurnVsSpeed.pdf",sep="")
  strPlotName = paste(strPlotExportPath,"/stat/fig6_statbootstrap_correlation_TurnVsFastClusterSpeed.pdf",sep="")
  pdf(strPlotName,width=7,height=7,title="Correlations In hunt variables - turn-ratio vs Fast Cluster capture Speeds",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))
    par(mar = c(3.9,4.7,1,1))
    pBw <- 0.02
    plot(density(stat_CapTurnVsSpeed_fast_NF$corr,kernel="gaussian",bw=pBw),
         col=colourLegL[1],xlim=c(-0.5,0.5),lwd=3,lty=1,ylim=c(0,10),main=NA, xlab=NA,ylab=NA,cex=cex,cex.axis=cex) #expression(paste("slope ",gamma) ) )
    lines(density(stat_CapTurnVsSpeed_fast_LF$corr,kernel="gaussian",bw=pBw),col=colourLegL[2],lwd=3,lty=2)
    lines(density(stat_CapTurnVsSpeed_fast_DF$corr,kernel="gaussian",bw=pBw),col=colourLegL[3],lwd=3,lty=3)
    mtext(side = 1,cex=cex,cex.main=cex, line = lineXAxis, expression(paste("Correlation of turn-ratio to clustered capture speed") ))
    mtext(side = 2,cex=cex,cex.main=cex, line = lineAxis, expression("Density function"))
  
  dev.off()  
  #  PLot Density Turn Vs FAST Speed
  #strPlotName = paste(strPlotExportPath,"/stat/fig6_statbootstrap_Spearman_correlation_TurnVsSpeed.pdf",sep="")
  strPlotName = paste(strPlotExportPath,"/stat/fig6_statbootstrap_correlation_TurnVsSlowClusterSpeed.pdf",sep="")
  pdf(strPlotName,width=7,height=7,title="Correlations In hunt variables - turn-ratio vs Slow Cluster capture Speeds",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))
    par(mar = c(3.9,4.7,1,1))
    pBw <- 0.02
    plot(density(stat_CapTurnVsSpeed_slow_NF$corr,kernel="gaussian",bw=pBw),
         col=colourLegL[1],xlim=c(-0.5,0.5),lwd=3,lty=1,ylim=c(0,10),main=NA, xlab=NA,ylab=NA,cex=cex,cex.axis=cex) #expression(paste("slope ",gamma) ) )
    lines(density(stat_CapTurnVsSpeed_slow_LF$corr,kernel="gaussian",bw=pBw),col=colourLegL[2],lwd=3,lty=2)
    lines(density(stat_CapTurnVsSpeed_slow_DF$corr,kernel="gaussian",bw=pBw),col=colourLegL[3],lwd=3,lty=3)
    mtext(side = 1,cex=cex,cex.main=cex, line = lineXAxis, expression(paste("Correlation of turn-ratio to clustered capture speed") ))
    mtext(side = 2,cex=cex,cex.main=cex, line = lineAxis, expression("Density function"))
  dev.off()  
  
  
  
  # TURN Vs Capture Speed Mututal INformation 
  bkSeq <- seq(0,4,0.02)
  hist(stat_CapTurnVsSpeed_NF$MI,xlim=c(0,3),ylim=c(0,1000),col=colourL[2],breaks = bkSeq ,
       xlab="MI capture speed and distance to prey", main="Bootstrapped Mutual information")
  hist(stat_CapTurnVsSpeed_LF$MI,xlim=c(0,3),col=colourL[1],add=TRUE ,breaks = bkSeq)
  hist(stat_CapTurnVsSpeed_DF$MI,xlim=c(0,3),col=colourL[3],add=TRUE,breaks = bkSeq )
  
  
  
  # TURN Correlation to Speed / For LF undershooting is combined with faster captures (and more distal) - Not for NF, or DF
  bkSeq <- seq(-0.8,0.8,0.02)
  hist(stat_CapTurnVsSpeed_NF$corr,xlim=c(-0.8,0.8),ylim=c(0,300),col=colourL[2],breaks = bkSeq,xlab="Pearson's correlation turn-ratio vs speed",main="Bootstraped 0.80" )
  hist(stat_CapTurnVsSpeed_LF$corr,xlim=c(-0.8,0.8),col=colourL[1],add=TRUE ,breaks = bkSeq)
  hist(stat_CapTurnVsSpeed_DF$corr,xlim=c(-0.8,0.8),col=colourL[3],add=TRUE,breaks = bkSeq )
  

  
  
#### UNDERSHOOT TO DISTANCE FROM PREY 
  XRange  <- c(0,2) #
  YRange <- c(0,0.6) ##We limit The information Obtained To Reasonable Ranges Of Phi (Vergence Angle)
  
  stat_CapTurnVsDist_NF <- bootStrap_stat(datCapture_NL$Undershoot,datCapture_NL$DistanceToPrey,10000,XRange,YRange)
  stat_CapTurnVsDist_LF <- bootStrap_stat(datCapture_LL$Undershoot,datCapture_LL$DistanceToPrey,10000,XRange,YRange)
  stat_CapTurnVsDist_DF <- bootStrap_stat(datCapture_DL$Undershoot,datCapture_DL$DistanceToPrey,10000,XRange,YRange)
  
    # TURN Vs Capture Speed Mutual INformation  
  bkSeq <- seq(0,4,0.02)
  hist(stat_CapTurnVsDist_NF$MI,xlim=c(0,3),ylim=c(0,1000),col=colourL[2],breaks = bkSeq ,
       xlab="MI turn-ratio and distance to prey", main="Bootstrapped Mutual information")
  hist(stat_CapTurnVsDist_LF$MI,xlim=c(0,3),col=colourL[1],add=TRUE ,breaks = bkSeq)
  hist(stat_CapTurnVsDist_DF$MI,xlim=c(0,3),col=colourL[3],add=TRUE,breaks = bkSeq )
  
  # TURN Correlation to Speed - DF/LF UNdershoot correlates with distance increase -  NF, the opposite correlation arises
  #require( tikzDevice )
  #strPlotName = paste(strPlotExportPath,"/Correlations_HuntTurnVsDist.tex",sep="")
  #tikz( strPlotName )
  
    bkSeq <- seq(-0.8,0.8,0.02)
    hist(stat_CapTurnVsDist_NF$corr,xlim=c(-0.8,0.8),ylim=c(0,300),col=colourL[2],breaks = bkSeq,xlab=" correlation Turn-ratio vs distance",main="Bootstraped 0.80" )
    hist(stat_CapTurnVsDist_LF$corr,xlim=c(-0.8,0.8),col=colourL[1],add=TRUE ,breaks = bkSeq)
    hist(stat_CapTurnVsDist_DF$corr,xlim=c(-0.8,0.8),col=colourL[3],add=TRUE,breaks = bkSeq )
    
#  dev.off()


  ### DENSITY PLOT  
  #strPlotName = paste(strPlotExportPath,"/stat/fig6_statbootstrap_Spearman_correlation_TurnVsDistance.pdf",sep="")
    strPlotName = paste(strPlotExportPath,"/stat/fig6_statbootstrap_correlation_TurnVsDistance.pdf",sep="")
  pdf(strPlotName,width=7,height=7,title="Correlations In hunt variables - turn-ratio vs capture Speed",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))
    par(mar = c(3.9,4.7,1,1))
  
  pBwpBw <- 0.02
    plot(density(stat_CapTurnVsDist_NF$corr,kernel="gaussian",bw=pBw),
       col=colourLegL[1],xlim=c(-0.5,0.5),lwd=3,lty=1,ylim=c(0,10),main=NA, xlab=NA,ylab=NA,cex=cex,cex.axis=cex) #expression(paste("slope ",gamma) ) )
    lines(density(stat_CapTurnVsDist_LF$corr,kernel="gaussian",bw=pBw),col=colourLegL[2],lwd=3,lty=2)
    lines(density(stat_CapTurnVsDist_DF$corr,kernel="gaussian",bw=pBw),col=colourLegL[3],lwd=3,lty=3)
    mtext(side = 1,cex=cex,cex.main=cex, line = lineXAxis, expression(paste("Correlation of turn-ratio to distance to prey  ") ))
    mtext(side = 2,cex=cex,cex.main=cex, line = lineAxis, expression("Density function"))
  
  dev.off()  

  ###
  
  
  XRange  <- c(0,0.8) #
  YRange <- c(0,1) ##We limit The information Obtained To Reasonable Ranges Of Phi (Vergence Angle)
  ### DENSITIES ####
  
  
  datCapture_NL_clust <- datCapture_NL[datCapture_NL$Cluster == "fast",] #datCapture_NL #
  datCapture_LL_clust <- datCapture_LL[datCapture_LL$Cluster == "fast",]#datCapture_LL# 
  datCapture_DL_clust <- datCapture_DL[datCapture_DL$Cluster == "fast",] #datCapture_DL# 
  
  stat_CapDistVsTime_NF <- bootStrap_stat(datCapture_NL_clust$DistanceToPrey,datCapture_NL_clust$FramesToHitPrey/G_APPROXFPS,10000,XRange,YRange,"spearman")
  stat_CapDistVsTime_LF <- bootStrap_stat(datCapture_LL_clust$DistanceToPrey,datCapture_LL_clust$FramesToHitPrey/G_APPROXFPS,10000,XRange,YRange,"spearman")
  stat_CapDistVsTime_DF <- bootStrap_stat(datCapture_DL_clust$DistanceToPrey,datCapture_DL_clust$FramesToHitPrey/G_APPROXFPS,10000,XRange,YRange,"spearman")
  
  # Plot Speed Vs Distance Correlation - bootstraped Stat ##
strPlotName = paste(strPlotExportPath,"/stat/fig4I_statbootstrap_corrSpearman_DistanceVsTimeToPrey_fastCluster.pdf",sep="")
pdf(strPlotName,width=7,height=7,title="Correlations In between Distance And Number of Frames to Get to Prey For Fast Capture swims ",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))
  par(mar = c(3.9,4.7,1,1))
  pBw <- 0.02
  plot(density(stat_CapDistVsTime_NF$corr,kernel="gaussian",bw=pBw),
       col=colourLegL[1],xlim=c(-0.5,0.5),lwd=3,lty=1,ylim=c(0,10),main=NA, xlab=NA,ylab=NA,cex=cex,cex.axis=cex) #expression(paste("slope ",gamma) ) )
  lines(density(stat_CapDistVsTime_LF$corr,kernel="gaussian",bw=pBw),col=colourLegL[2],lwd=3,lty=2)
  lines(density(stat_CapDistVsTime_DF$corr,kernel="gaussian",bw=pBw),col=colourLegL[3],lwd=3,lty=3)
  
  # legend("topright",         legend=c(  expression (),
  #                    bquote(NF~ ''  ),
  #                    bquote(LF ~ '' ),
  #                    bquote(DF ~ '' )  ), ##paste(c("DL n=","LL n=","NL n="),c(NROW(lFirstBoutPoints[["DL"]][,1]),NROW(lFirstBoutPoints[["LL"]][,1]) ,NROW(lFirstBoutPoints[["NL"]][,1] ) ) )
  #         col=colourLegL,lty=c(1,2,3),lwd=3,cex=cex)
  mtext(side = 1,cex=cex,cex.main=cex, line = lineXAxis, expression(paste("Correlation of time to hit prey and distance") ))
  mtext(side = 2,cex=cex,cex.main=cex, line = lineAxis, expression("Density function"))
  
dev.off()
message("Significance t-test LF < NF" )
t.test(x=stat_CapDistVsTime_LF$corr,y=stat_CapDistVsTime_NF$corr,alternative="less")
t.test(x=stat_CapDistVsTime_LF$corr,y=stat_CapDistVsTime_DF$corr,alternative="less")
t.test(x=stat_CapDistVsTime_NF$corr,y=stat_CapDistVsTime_DF$corr,alternative="less")

  ### CORRELOLAGRAM ###

library(corrgram)
layout(matrix(c(1,2,3),1,3, byrow = FALSE))
#Margin: (Bottom,Left,Top,Right )
par(mar = c(3.9,4.7,12,1))

strPlotName = paste(strPlotExportPath,"/Correlations_Huntvariables_NF.pdf",sep="")
pdf(strPlotName,width=8,height=8,title="Correlations In hunt variables",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))

corrgram(cbind(Speed=datCapture_NL$CaptureSpeed,Dist=datCapture_NL$DistanceToPrey,Turnratio=datCapture_NL$Undershoot,FastCluster=datCapture_NL$Cluster)
               , order=FALSE, lower.panel=panel.pie ,
         upper.panel=NULL, text.panel=panel.txt,
         main="NF Hunt variable correlations")
dev.off()

strPlotName = paste(strPlotExportPath,"/Correlations_Huntvariables_LF.pdf",sep="")
pdf(strPlotName,width=8,height=8,title="Correlations In hunt variables",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))
  corrgram(cbind(Speed=datCapture_LL$CaptureSpeed,Dist=datCapture_LL$DistanceToPrey,Turnratio=datCapture_LL$Undershoot,FastCluster=datCapture_LL$Cluster)
         , order=FALSE, lower.panel=panel.pie ,
         upper.panel=NULL, text.panel=panel.txt,
         main="LF Hunt variable correlations")
dev.off()

strPlotName = paste(strPlotExportPath,"/Correlations_Huntvariables_DF.pdf",sep="")
pdf(strPlotName,width=8,height=8,title="Correlations In hunt variables",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))

  corrgram(cbind(Speed=datCapture_DL$CaptureSpeed,Dist=datCapture_DL$DistanceToPrey,Turnratio=datCapture_DL$Undershoot,FastCluster=datCapture_DL$Cluster)
           , order=FALSE, lower.panel=panel.pie ,
           upper.panel=NULL, text.panel=panel.txt,
           main="DF Hunt variable correlations")
dev.off()

##redundancy
#1-H_X/2^3
#1-H_Y/2^3

##Verify
library(entropy)

mi.empirical(freqM_NF,unit="log2" ) 
mi.empirical(freqM_LF,unit="log2" ) 
mi.empirical(freqM_DF,unit="log2" )  

  PVec=rep(0,NROW(Grid)) 
  ##Calc Density for all input Space
  for (i in 1:NROW(Grid) )
  {
    PVec[i] <- phiDens(Grid[i,1],Grid[i,2],Ulist)
  }
  ##Normalize to Probability
  PVec=PVec/sum(PVec)
  
  # Convert Pvec to a matrix / 
  PMatrix=matrix(PVec,nrow=length(PhiRange),ncol=length(DistRange),byrow = FALSE)
  
  ##Image shows a transpose Of the PMatrix, - In reality Rows contain Phi, and Cols are X 
  #image(t(PMatrix),y=PhiRange,x=DistRange)
  MargVec=rowSums(PMatrix) ### Marginalize across X to obtain P(Response/Phi)
  
  Iloc=PMatrix/MargVec*length(DistRange) ##Information On Local x/For Each X - Assume X is unif. and so Prob[X]=1/Length(X)
  
  ###row sum
  sel=PMatrix>0
  #INFO=sums(PMatrix[sel]*log2(Iloc[sel]) )
  ### Return Marginals I_xPhi
  mInfo <- PMatrix*log2(Iloc)
  
  ##Calc Marginals only on relevant Region - up to min distance from Target
  ##Make Binary Array indicating OutOf Bound regions
  vIntRegion<-as.numeric( DistRange >= minDist)
  mIntRegion <- t(matrix(vIntRegion,dim(mInfo)[2],dim(mInfo)[1]))
  
  INFO=colSums(mInfo*mIntRegion,na.rm=TRUE )
  
#  return(INFO)
#}
  
  
  
  
  

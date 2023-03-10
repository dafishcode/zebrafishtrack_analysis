### Analyse identified and Retracked (2nd pass), hunt events ###
### Library For for the Analysis of Tracking data in the carefully *retracked* Hunt Episodes imported ###
## Smooths eye trajectories, fish speed, detects Bouts, turn events, angles produces a plot containing Detection Points and Motion Relative to Tracked Prey ##

## Note, Bouts are given sequence numbers in time of occurance and rank in order going from close to prey capture backwards
## Turns towards prey are also marked, and these need to be towards the prey, but also the turn needs to reduce the bearing to prey by at least 10% / Otherwise it is not considered a turn

library(signal)
library(Rwave)
#library(MASS)
library(mclust,quietly = TRUE)

#library(sBIC)

citation("mclust")



## Setup Filters ## Can Check Bands with freqz(bf_speed) ## These are used in filterEyeTailNoise 
Fs <- 410; #sampling rate
bf_tail <- butter(1, c(0.01,0.3),type="pass"); ##Remove DC
bf_tailClass <- butter(4, c(0.01,0.35),type="pass"); ##Remove DC
bf_tailClass2 <- butter(4, 0.05,type="low"); ##Remove DC

bf_eyes <- butter(4, 0.07,type="low",plane="z"); #"z" for a digital filter or "s" for an analog filter.
bf_speed <- butter(4, 0.06,type="low");  ##Focus On Low Fq to improve Detection Of Bout Motion and not little Jitter motion
bf_tailSegSize <- butter(4, 0.02,type="low"); ## Tail Segmemt Size iF Used to Estimate Pitch - Stiking Upwards

## Processes The Noise IN the recorded Frames of Fish#'s Eye and Tail Motion
##Filters Fish Records - For Each Prey ID Separatelly
## As Each Row Should Contain a unique fish snapshot and not Repeats for each separate Prey Item - Ie A frame associated with a single preyID
## returns the original data frame, now with L/R Eye angles and tail motion having been filtered
filterEyeTailNoise <- function(datFishMotion)
{
  
  if (NROW(datFishMotion) < 2)
    return(datFishMotion)
  #dir.create(strFolderName )
  ##Remove NAs

    lMax <- 55
    lMin <- -20
    #spectrum(datFishMotion$LEyeAngle)
    datFishMotion$LEyeAngle <- clipEyeRange(datFishMotion$LEyeAngle,lMin,lMax)
    datFishMotion$LEyeAngle <-medianf(datFishMotion$LEyeAngle,nEyeFilterWidth)
    datFishMotion$LEyeAngle[is.na(datFishMotion$LEyeAngle)] <- 0
    datFishMotion$LEyeAngle <-filtfilt(bf_eyes,datFishMotion$LEyeAngle) # filtfilt(bf_eyes, medianf(datFishMotion$LEyeAngle,nFrWidth)) #meanf(datHuntEventMergedFrames$LEyeAngle,20)
    
    #X11()
    #lines(medianf(datFishMotion$LEyeAngle,nFrWidth),col='red')
    #lines(datFishMotion$LEyeAngle,type='l',col='blue')
    ##Replace Tracking Errors (Values set to 180) with previous last known value
    
    lMax <- 20
    lMin <- -55
    datFishMotion$REyeAngle <- clipEyeRange(datFishMotion$REyeAngle,lMin,lMax)
    datFishMotion$REyeAngle <-medianf(datFishMotion$REyeAngle,nEyeFilterWidth)
    datFishMotion$REyeAngle[is.na(datFishMotion$REyeAngle)] <- 0
    datFishMotion$REyeAngle <- filtfilt(bf_eyes,datFishMotion$REyeAngle  ) #meanf(datHuntEventMergedFrames$REyeAngle,20)
    #datFishMotion$REyeAngle <-medianf(datFishMotion$REyeAngle,nFrWidth)
  
    
    ##Fix Angle Circular Distances by DiffPolar Fix on Displacement and then Integrate back to Obtain fixed Angles  
    lMax <- +75; lMin <- -75 ;
    datFishMotion$DThetaSpine_7 <- filtfilt(bf_tail, cumsum(diffPolar( datFishMotion$DThetaSpine_7))+datFishMotion$DThetaSpine_7[1]  )
    datFishMotion$DThetaSpine_6 <- filtfilt(bf_tail, cumsum(diffPolar( datFishMotion$DThetaSpine_6))+datFishMotion$DThetaSpine_6[1] )
    datFishMotion$DThetaSpine_5 <- filtfilt(bf_tail, cumsum(diffPolar( datFishMotion$DThetaSpine_5))+datFishMotion$DThetaSpine_5[1]  )
    datFishMotion$DThetaSpine_4 <- filtfilt(bf_tail, cumsum(diffPolar( datFishMotion$DThetaSpine_4))+datFishMotion$DThetaSpine_4[1] )
    datFishMotion$DThetaSpine_3 <- filtfilt(bf_tail, cumsum(diffPolar( datFishMotion$DThetaSpine_3))+datFishMotion$DThetaSpine_3[1] )
    datFishMotion$DThetaSpine_2 <- filtfilt(bf_tail, cumsum(diffPolar( datFishMotion$DThetaSpine_2))+datFishMotion$DThetaSpine_2[1] )
    datFishMotion$DThetaSpine_1 <- filtfilt(bf_tail, cumsum(diffPolar( datFishMotion$DThetaSpine_1))+datFishMotion$DThetaSpine_1[1] )

  
  return(datFishMotion)
}


## 
#Returns F: corresponding frequencies for the constracuted wavelet scales given #Octaves and Voices
#Fc Assumes Centre Frequency For Wavelet Function (ie morlet)
getfrqscales <- function(nVoices,nOctaves,Fs,w0)
{
  a0 <- 2^(1/nVoices)
  
  #For example, assume you are using the CWT and you set your base to s0=21/12.
  #To attach physical significance to that scale, you must multiply by the sampling interval ??t, 
  #so a scale vector covering approximately four octaves with the sampling interval taken into account is sj_0 ??t j=1,2,..48. 
  #Note that the sampling interval multiplies the scales, it is not in the exponent. For discrete wavelet transforms the base scale is always 2.
  scales <- a0^seq(to=1,by=-1,from=nVoices*nOctaves)*1/Fs
  Fc <- pi/w0 ## Morlet Centre Frequency is 1/2 when w0=2*pi
  Frq <- Fc/(scales )

  return(Frq)
}

plotTailSpectrum <- function(w)
{
  w.spec <- spectrum(w,log="no",span=10,plot=FALSE,method="pgram")
  spx <- w.spec$freq*Fs
  spy <- 2*w.spec$spec #We should also multiply the spectral density by 2 so that the area under the periodogram actually equals the variance   of the time series
  #png(filename=paste(strPlotExportPath,"/TailSpectrum_exp",expID,"_event",eventID,"_track",trackID,".png",sep="") );
  
  plot(spy~spx,xlab="frequency",ylab="spectral density",type='l',xlim=c(0,60) ) 
}

## Uses Wavelets to obtain the power Fq Spectrum of the tail beat in time
## w input wave 
## returns the original object w, augmented with w.cwt w.coefSq (Power) etc.
## modal Frequencies (w.FqMod) used to detect tail beat frequency
getPowerSpectrumInTime <- function(w,Fs)
{
  ##Can Test Wavelet With Artificial Signal Sample Input Signal
  #t = seq(0,1,len=Fs)
  #w = 2 * sin(2*pi*16*t)*exp(-(t-.25)^2/.001)
  #w= w + sin(2*pi*128*t)*exp(-(t-.55)^2/.001)
  #w= w + sin(2*pi*64*t)*exp(-(t-.75)^2/.001)
  #w = ts(w,deltat=1/Fs)
  N_MODESAMPLES <- 20
  w.Fs <- Fs
  w.nVoices <- 12
  w.nOctaves <- 32
  w.W0 <- 2*pi
  
  ##Remove Missing Values
  w <- na.omit(w) 
  w.cwt <- cwt(w,noctave=w.nOctaves,nvoice=w.nVoices,plot=FALSE,twoD=TRUE,w0=w.W0)
  w.coefSq <- Mod(w.cwt)^2 #Power

  w.Frq <- getfrqscales(w.nVoices,w.nOctaves,w.Fs,w.W0)
  
  ###Make Vector Of Maximum Power-Fq Per Time Unit
  vFqMed <- rep(0,NROW(w.coefSq))
  for (i in 1:NROW(w.coefSq) )
  {
    ##Where is the Max Power at Each TimeStep?
    idxDomFq <- which(w.coefSq[i,NROW( w.Frq):1] == max(w.coefSq[i,NROW(w.Frq):1]))
    FqRank <- which(rank(w.coefSq[i,NROW(w.Frq):1] ) > (NROW(w.Frq)-N_MODESAMPLES)  )
    vFqMed[i] <- median(w.Frq[FqRank]) # sum(w.coefSq[i,NROW(w.Frq):1]*w.Frq)/sum(w.Frq) #/sum(w.coefSq[i,NROW(w.Frq):1]) #w.Frq[idxDomFq] #max(coefSq[i,idxDomFq]*Frq[idxDomFq]) #sum(coefSq[i,NROW(Frq):1]*Frq)/sum(Frq) #lapply(coefSq[,NROW(Frq):1],median)
  }

  
  w.FqMod <-vFqMed #
 # X11()
#  plot(vFqMed,type='l')
  return (list(wavedata=w,nVoices=w.nVoices,nOctaves=w.nOctaves ,MorletFrequency=w.W0, cwt=w.cwt,cwtpower=w.coefSq,Frq=w.Frq,freqMode=w.FqMod,Fs=w.Fs) )
}


## w <- Object containing Filtered Tail Segment motion (Usually the Delta angles of last 2 segments combined )
##     w.cwt <- The Continuous Wavelet Transform 
#     w.nVoices
#     w.nOctaves
## returns
plotTailPowerSpectrumInTime <- function(lwlt)
{
  
  #scales <- a0^seq(to=1,by=-1,from=nVoices*nOctaves)*1/Fs
  #Fa <- 1/2 ## Morlet Centre Frequency is 1/2 when w0=2*pi
  #Frq <- Fa/(scales )
  #Frequencies = cbind(scale=scales*(1/Fs), Frq, Period = 1./Frq)
  
  Frq <- lwlt$Frq
  #
  #plot(raster((  (vTailDisp.cwt)*1/Fs ) ), )
  #print(plot.cwt(tmp,xlab="time (units of sampling interval)"))
 ##"Frequency Content Of TailBeat"
  collist<-c("#053061","#2166AC","#4393C3","#92C5DE","#D1E5F0","#F7F7F7","#FDDBC7","#F4A582","#D6604D","#B2182B","#67001F")
  ColorRamp<-colorRampPalette(collist)(10000)
  image(x=(1000*1:NROW(lwlt$cwtpower)/lwlt$Fs),y=Frq,z=lwlt$cwtpower[,NROW(Frq):1]
        ,useRaster = FALSE
        ,main = NA
        ,xlab = NA#"Time (msec)"
        ,ylab = NA
        ,cex.lab = FONTSZ_AXISLAB
        ,cex.axis=FONTSZ_AXIS
        ,ylim=c(0,60)
        ,col=ColorRamp
  )
  mtext(side = 1,padj=1,cex=FONTSZ_AXISLAB*1.2, line = 2.2, "Time (msec)", font=2 )
  mtext(side = 2,padj=-1,cex=FONTSZ_AXISLAB*1.2, line = 2.2, "Beat Frequency (Hz)", font=2 ) 
  
  #contour(coefSq,add=T)
  #plot(coefSq[,13]   ,type='l') ##Can Plot Single Scale Like So
  
  
}

##Returns most active nSelectComponents activity Bout Detection Thresholds - can be used to set what min bout speed is , and 
## what capture speed bout can be above median of the function's return value ie median(clusterActivity[boutCluster])
## and min Bout Speed can be min(clusterActivity[boutCluster])
## As datHuntEventMergedFrames contains stiched hunt events together back to back, the max speeed can be misleading - as position quickly jumps at stich poitns
## As such the fastest component (~400mm/sec) is removed
getMotionBoutSpeedThresholds <- function(datHuntEventMergedFrames)
{
  nNumberOfComponents = 17
  nSelectComponents = 6##5##7
  
  #### PROCESS BOUTS ###
  vDeltaDisplacement   <- sqrt(diff(datHuntEventMergedFrames$posX,lag=1,differences=1)^2+diff(datHuntEventMergedFrames$posY,lag=1,differences=1)^2) ## Path Length Calculated As Total Displacement
  
  #nNumberOfBouts       <- 
  dframe               <- diff(datHuntEventMergedFrames$frameN,lag=1,differences=1)
  dframe               <- dframe[dframe > 0] ##Clear Any possible Nan - and Convert To Time sec  
  vFs                   <- datHuntEventMergedFrames$fps[1:NROW(dframe)]
  vEventSpeed_smooth          <- meanf(vDeltaDisplacement[1:NROW(dframe)]/dframe,5) ##IN (mm) Divide Displacement By TimeFrame to get Instantentous Speed, Apply Mean Filter Smooth Out 
  vEventSpeed_smooth[is.na(vEventSpeed_smooth)] = 0
  vEventSpeed_smooth <- filtfilt(bf_speed, vEventSpeed_smooth) #meanf(vEventSpeed,100) #
  vEventSpeed_smooth[vEventSpeed_smooth < 0] <- 0 ## Remove -Ve Values As an artefact of Filtering
  vEventSpeed_smooth[is.na(vEventSpeed_smooth)] = 0
  vEventSpeed_smooth_mm <- vFs*vEventSpeed_smooth*DIM_MMPERPX
  
  ##Can use a fit scan to detect best number of components and then choose half as the most active side of these
  #fitBIC <- mclustBIC(vEventSpeed_smooth_mm ,G=1:(nNumberOfComponents),prior =  priorControl(functionName="defaultPrior", mean=c(c(0.5),c(2),c(5),c(8),c(10),c(12),c(14),c(14)) ,shrinkage=0.1 ) )
  #plot(fitBIC)
  ##Select Largest Number Of Components That does not Crash !
  #message(attr(fitBIC,"returnCodes"))
  #nNumberOfComponents <- max(which(attr(fitBIC,"returnCodes")[,2] == 0))
  #nSelectComponents <- round(nNumberOfComponents/2)
  
  
  fit <- Mclust(vEventSpeed_smooth_mm ,G=nNumberOfComponents,modelNames = "V",
                prior =  priorControl(functionName="defaultPrior",mean=seq(1:nNumberOfComponents),shrinkage=0.1 ) )  
  
  #summary(fit)
  
  boutClass <- fit$classification
  clusterActivity <- vector()
  for (i in unique(boutClass))
    clusterActivity[i] <- max(vEventSpeed_smooth_mm[boutClass == i])#,mean(pvEventSpeed[boutClass == 2]),mean(pvEventSpeed[boutClass == 3]))
  #clusterActivity <- c(mean(pvEventSpeed[boutClass == 1]),mean(pvEventSpeed[boutClass == 2]))
  
  clusterActivity[is.na(clusterActivity)] <- 0
 
  ##Get rid of the Fastest one, as that is just the transition between events
  maxBoutCluster <- which(clusterActivity == max(clusterActivity))
  
  ##Select the Top nSelectComponents of clusterActivity
  boutCluster <- c(which(rank(clusterActivity) >  (nNumberOfComponents-nSelectComponents) & 
                           clusterActivity > G_THRES_MOTION_BOUT_SPEED/2 &
                           clusterActivity < clusterActivity[maxBoutCluster]  ) )   
  
  ##
  return ( clusterActivity[boutCluster] )
}


## Uses the tracked data to suggest good thresholds for bout classification, 
## Clusters Fish Speed Measurements into Bout And Non Bout
##Use 3 For Better Discrimination When  There Are Exist Bouts Of Different Size

getTailBoutThresholds <- function(datHuntEventMergedFrames)
{
  
  
  nNumberOfComponents = 20
  nSelectComponents = 2
  colClass <- c("#FF0000","#04A022","#0000FF")
  
  vTailDisp <-  datHuntEventMergedFrames$DThetaSpine_6 + datHuntEventMergedFrames$DThetaSpine_7 #+ datRenderHuntEvent$DThetaSpine_7 #+ datRenderHuntEvent$DThetaSpine_7 #abs(datRenderHuntEvent$DThetaSpine_1) +  abs(datRenderHuntEvent$DThetaSpine_2) + abs(datRenderHuntEvent$DThetaSpine_3) + abs(datRenderHuntEvent$DThetaSpine_4) + abs(datRenderHuntEvent$DThetaSpine_5) + abs(datRenderHuntEvent$DThetaSpine_6) + abs(datRenderHuntEvent$DThetaSpine_7)
  vTailDisp <- filtfilt(bf_tailClass, clipEyeRange(vTailDisp,-120,120))
  vFs                   <- datHuntEventMergedFrames$fps[1:NROW(dframe)]
  lwlt <- getPowerSpectrumInTime(vTailDisp,mean(vFs) )##Fix Length Differences
  x <- lwlt$freqMode
  ##Automatic Component number selection
  ### INcreased to 3 Clusters TO Include Other Non-Bout Activity
  ##prior=priorControl(functionName="defaultPrior",shrinkage = 0) modelNames = "V"  prior =  shrinkage = 0,modelName = "VVV"
  #modelNames = "EII"
  ###I can test For Possibility Of Clustering With G=n using mclustBIC returnCodes - When 0 Its succesfull
  fitBIC <- mclustBIC(x ,G=3:(nNumberOfComponents),prior =  priorControl(functionName="defaultPrior", mean=c(c(0.5),c(2),c(10),c(20),c(30),c(40)) ,shrinkage=0.1 ) )
  #plot(fitBIC)
  ##Select Largest Number Of Components That does not Crash !
  message(attr(fitBIC,"returnCodes"))
  nNumberOfComponents <- max(which(attr(fitBIC,"returnCodes")[,2] == 0))
  nSelectComponents <- round(nNumberOfComponents/3) ##select 1/2 of most active components
  message(paste("Setting TailClust Comp. to N:",nNumberOfComponents,"Select n:",nSelectComponents) )
  
  fit <- Mclust(x ,G=nNumberOfComponents,modelNames = "V",prior =  priorControl(functionName="defaultPrior", mean=c(c(1),c(4),c(10),c(13),c(18),c(30)),shrinkage=0.1 ) )  


  #summary(fit)
  
  boutClass <- fit$classification
  clusterActivity <- vector()
  for (i in unique(boutClass))
    clusterActivity[i] <- max(x[boutClass == i])#,mean(pvEventSpeed[boutClass == 2]),mean(pvEventSpeed[boutClass == 3]))
  #clusterActivity <- c(mean(pvEventSpeed[boutClass == 1]),mean(pvEventSpeed[boutClass == 2]))
  
  clusterActivity[is.na(clusterActivity)] <- 0
  
  ##Get rid of the Fastest one, as that is just the transition between events
  maxBoutCluster <- which(clusterActivity == max(clusterActivity))
  
  ##Select the Top nSelectComponents of clusterActivity
  boutCluster <- c(which(rank(clusterActivity) >  (nNumberOfComponents-nSelectComponents) & 
                           clusterActivity > 1 &
                           clusterActivity < clusterActivity[maxBoutCluster]  ) )   
  
  return ( clusterActivity[boutCluster] )
  
}


##Clusters Fish Speed Measurements into Bout And Non Bout
##Use multiple components #17, and select top 6 active ones whose activity is above minMotionSpeed
detectMotionBouts <- function(vEventSpeed,minMotionSpeed)
{
 
  
  return(which(abs(vEventSpeed) > minMotionSpeed))
  
}


##Detect Motion/Turn Events through Changes in Speed, - Connect events within a set frame-window to be a single event
# Returns data frame of with frameIdxs of start end frames of bound events
detectMotionBoutsV2 <- function(vEventSpeed,minMotionSpeed,minFramesBetweenEvents)
{
  
  idxBout <-  which(abs(vEventSpeed) > minMotionSpeed)
  
  ## Identify Blocks of frames belonging to the same turn
  blockBoutFramesIDs <- split(idxBout,
                              ##Sum Increments When the following Indicators Of Changing Class Become TRUE (I added Track Splitters when Exp or Event Change)
                              cumsum(c(1, diff(idxBout) > minFramesBetweenEvents )  ) 
  )
  #tblockTurnFramesIDsurnBlock <- rle(datDomainTrajectory$IndTurnBout)
  ## Tabulate DEtected Turns 
  datBoutIDs <- ldply (blockBoutFramesIDs, data.frame)
  names(datBoutIDs) <- c("boutID","frameIdx")
  boutStartFrame <- tapply(datBoutIDs$frameIdx,datBoutIDs$boutID,min)
  boutEndFrame <- tapply(datBoutIDs$frameIdx,datBoutIDs$boutID,max)

  datTrackletBouts <- data.frame(boutID=names(boutEndFrame),boutStartFrame,boutEndFrame)
  orderSeq <- order(as.numeric(as.character(datTrackletBouts$boutID)) ) ##Fix Turn Order 
  datTrackletBouts <- datTrackletBouts[orderSeq,]
  
  return(datTrackletBouts)
}



##Simple Threshold to Classify Fish Tail FQ Measurements into Bout And Non Bout
detectTailBouts <- function(vTailMotionFq)
{

  x  <-  vTailMotionFq
  return (which(x > G_THRES_TAILFQ_BOUT)) ###Stop here - keep it simple > 10Hz
  
}

## Notes: Converted To Use 1Dim only Turnspeed to Detect Turns / Can use Tail Motion but I was getting False Positives when combined
detectTurnBouts <- function(vTurnSpeed,vTailDispFilt,minTurnSpeed=NA)
{
  vTurnSpeed <- na.exclude(abs(vTurnSpeed))
  
  nNumberOfComponents = max(3,round( (max(vTurnSpeed)-min(vTurnSpeed))/1 ))
  nSelectComponents = round(nNumberOfComponents*0.85)
  
  ##Fetch Heurestic Threshold 
  if (is.na(minTurnSpeed))
    minTurnSpeed <- mean(abs(vTurnSpeed))
  
  nRec <- NROW(vTurnSpeed)# min(NROW(vTailDispFilt),NROW(vTurnSpeed))
  ##Fix Length Differences
  pvEventSpeed <-  abs(vTurnSpeed[1:nRec])
  #pvTailDispFilt <-  abs(vTailDispFilt[1:nRec])
  #t <- datRenderHuntEvent$frameN
  
  #X11();plot(pvEventSpeed,pvTailDispFilt,type='p')
  
  #xy <- cbind(pvEventSpeed,pvTailDispFilt) ##Disregard Tail Flips / As I get false Positives 
  x <- pvEventSpeed
  #X11();plot(pvEventSpeed,type='p')
  #BIC <- mclustBIC(dEventSpeed)
  
  ### INcreased to 3 Clusters TO Include Other Non-Bout Activity
  ##prior=priorControl(functionName="defaultPrior",shrinkage = 0) modelNames = "V"  prior =  shrinkage = 0,modelName = "VVV"
  #fit <- Mclust(xy ,G=nNumberOfComponents,modelNames = "VII", prior =  priorControl(functionName="defaultPrior", mean=c(c(0.05,1),c(0.05,20),c(1.5,15),c(2.5,20)),shrinkage=0.1 ) )
  priorMu <- seq(min(vTurnSpeed),max(vTurnSpeed),(max(vTurnSpeed)-min(vTurnSpeed)) / nNumberOfComponents)
  fit <- Mclust(x ,G=nNumberOfComponents,modelNames = "V", prior =  priorControl(functionName="defaultPrior", mean=  priorMu ,shrinkage=0.1 ) )  
  
#  summary(fit)
  
  boutClass <- fit$classification
  clusterActivity <- vector()
  for (i in 1:nNumberOfComponents)
    clusterActivity[i] <- max( pvEventSpeed[boutClass == i])#,mean(pvEventSpeed[boutClass == 2]),mean(pvEventSpeed[boutClass == 3]))
  #clusterActivity <- c(mean(pvEventSpeed[boutClass == 1]),mean(pvEventSpeed[boutClass == 2]))
  
  #boutCluster <- which(clusterActivity == max(clusterActivity))
  ##select the clusters n= (nNumberOfComponents-nSelectComponents) with highest activity - and above min threshold 
  boutCluster <- c(which(rank(clusterActivity) >  (nNumberOfComponents-nSelectComponents) & 
                           clusterActivity > minTurnSpeed) )   
  
  #points(which( fit$z[,2]> fit$z[,1]*prior_factor ), dEventSpeed[ fit$z[,2]> fit$z[,1]*prior_factor  ],type='p',col=colClass[3])
  ## Add Prior Bias to Selects from Clusters To The 
  return (which(boutClass %in% boutCluster ) )
  
  
}


##Clusters Fish Speed Measurements into Bout And Non Bout
##Use 3 For Better Discrimination When  There Are Exist Bouts Of Different Size
detectMotionBouts2 <- function(vEventSpeed,vTailDispFilt)
{
  nNumberOfComponents = 5
  nSelectComponents = 3
  prior_factor2 <- 0.90 ## Adds a prior shift in the threshold Of Classification
  prior_factor1 <- 1.0 ## Adds a prior shift in the threshold Of Classification 
  colClass <- c("#FF0000","#04A022","#0000FF")
  
  nRec <- min(NROW(vTailDispFilt),NROW(vEventSpeed))
  ##Fix Length Differences
  pvEventSpeed <-  vEventSpeed[1:nRec]
  pvTailDispFilt <-  abs(vTailDispFilt[1:nRec])
  #t <- datRenderHuntEvent$frameN
  
  #X11();plot(pvEventSpeed,pvTailDispFilt,type='p')
  
  xy <- cbind(pvEventSpeed,pvTailDispFilt)
  #X11();plot(pvEventSpeed,type='p')
  #BIC <- mclustBIC(dEventSpeed)
  
  ### INcreased to 3 Clusters TO Include Other Non-Bout Activity
  ##prior=priorControl(functionName="defaultPrior",shrinkage = 0) modelNames = "V"  prior =  shrinkage = 0,modelName = "VVV"
  #modelNames = "EII"
  fit <- Mclust(xy ,G=nNumberOfComponents,modelNames = "VII",prior =  priorControl(functionName="defaultPrior", mean=c(c(0.01,0.1),c(0.01,5),c(0.05,5),c(0.02,2),c(0.4,20),c(1.5,25)),shrinkage=0.1 ) )  
  # "VVV" check out doc mclustModelNames
  #fit <- Mclust(xy ,G=2, ,prior =  priorControl(functionName="defaultPrior", mean=c(c(0.005,0),c(0.5,15)),shrinkage=0.8 ) )  #prior=priorControl(functionName="defaultPrior",shrinkage = 0) modelNames = "V"  prior =  shrinkage = 0,modelName = "VVV"
  
  #fit <- Mclust(xy ,G=3 )  #prior=priorControl(functionName="defaultPrior",shrinkage = 0) modelNames = "V"  prior =  shrinkage = 0,modelName = "VVV"
  summary(fit)
  
#  X11()
#plot(fit, what="density", main="", xlab="Velocity (Mm/s)")
# rug(xy)
  
  #X11()
  
  #plot(pvEventSpeed[1:nRec],type='l',col=colClass[1])
  #points(which(boutClass == 3), pvEventSpeed[boutClass == 3],type='p',col=colClass[2])
  
  ##Find Which Cluster Contains the Highest Peaks
  boutClass <- fit$classification
  clusterActivity <- vector()
  for (i in unique(boutClass))
    clusterActivity[i] <- max(pvEventSpeed[boutClass == i])#,mean(pvEventSpeed[boutClass == 2]),mean(pvEventSpeed[boutClass == 3]))
  #clusterActivity <- c(mean(pvEventSpeed[boutClass == 1]),mean(pvEventSpeed[boutClass == 2]))
  
  #boutCluster <- which(clusterActivity == max(clusterActivity))
  ##Select the Top nSelectComponents of clusterActivity
  boutCluster <- c(which(rank(clusterActivity) >  (nNumberOfComponents-nSelectComponents) ))   
  #points(which( fit$z[,2]> fit$z[,1]*prior_factor ), dEventSpeed[ fit$z[,2]> fit$z[,1]*prior_factor  ],type='p',col=colClass[3])
  ## Add Prior Bias to Selects from Clusters To The 
  return (which(fit$classification %in% boutCluster ) )
  #return (which( fit$z[,3]> fit$z[,1]*prior_factor1 | fit$z[,3]> fit$z[,2]*prior_factor2    )) #
  
}

## Distance To Prey Handling  -- Fixing missing Values By Interpolation Using Fish Motion##
## Can Extend Beyond Last Frame Of Where Prey Was Last Seen , By X Frames
interpolateDistToPrey <- function(vDistToPrey,vEventSpeed_smooth, frameRegion = NA)
{
  if (!is.na(frameRegion))
    recLength <- NROW(frameRegion)
  else
    recLength <- NROW(vDistToPrey) 
  
 # stopifnot(recLength <= NROW(vEventSpeed_smooth)) ##Check For Param Error
  
  vDistToPreyInt <- rep(NA,recLength) ##Expand Dist To Prey To Cover Whole Motion Record
  vDistToPreyInt[1:recLength] <-vDistToPrey[1:recLength] ## ##Place Known Part of the vector
  
    ##Calc Speed - And Use it To Merge The Missing Values 
  vSpeedToPrey         <- c(diff(vDistToPreyInt,lag=1,differences=1),NA)
  
  vSpeedToPrey[is.na(vSpeedToPrey)] <- vEventSpeed_smooth[which(is.na(vSpeedToPrey))] ##Complete The Missing Speed Record To Prey By Using ThE fish Speed as estimate
  
  ## Interpolate Missing Values from Fish Speed - Assume Fish Is moving to Prey ##
  ##Estimate Initial DIstance From Prey Onto Which We Add the integral of Speed, By Looking At Initial PreyDist and adding any fish displacemnt to this in case The initial dist Record Is NA
  vDistToPreyInt[!is.na(vDistToPreyInt)] <- (cumsum(vSpeedToPrey[!is.na(vDistToPreyInt)]) ) ##But diff and integration Caused a shift
  
  vDistToPreyInt[9:(NROW(vDistToPreyInt))] <- vDistToPreyInt[1:(NROW(vDistToPreyInt)-min(8,NROW(vDistToPreyInt)) )] ##Fix Time Shift - If NROW > 8
  ##Compare Mean Distance Between them - Only Where Orig. PreyDist Is not NA - To obtain Integral Initial Constant (Starting Position)
  InitDistance             <- mean(vDistToPrey[!is.na(vDistToPrey)]-vDistToPreyInt[!is.na(vDistToPrey)],na.rm = TRUE )  ##vDistToPrey[!is.na(vDistToPrey)][1] + sum(vEventSpeed_smooth[(1:which(!is.na(vDistToPrey))[1])])
  
  #Add The Missing Speed Values From The fish Speed, Assumes Prey Remains Fixed And Fish Moves towards Prey
  #SpeedToPrey[is.na(vSpeedToPrey)] <- vEventSpeed_smooth[is.na(vSpeedToPrey)] ##Complete The Missing Speed Record To Prey By Using ThE fish Speed as estimate

  #vDistToPreyInt[is.na(vDistToPreyInt)] <- (cumsum(vSpeedToPrey[is.na(vDistToPreyInt)]) ) ##Add The Uknown Bit Using THE Fish's Speed and assuming the Prey Position Remains Fixed
  vDistToPreyInt <- (cumsum(vSpeedToPrey) ) ##Add The Uknown Bit Using THE Fish's Speed and assuming the Prey Position Remains Fixed
  
  vDistToPrey_Fixed <- InitDistance +  vDistToPreyInt# (cumsum(vSpeedToPrey))) ## From Initial Distance Integrate the Displacents / need -Ve Convert To Increasing Distance
  
  
  #X11() ##Compare Estimated To Recorded Prey Distance
  #plot(vDistToPrey_Fixed,type='l')
  #lines(vDistToPrey,type='l',col="blue")
  #legend()
  
  return(vDistToPrey_Fixed)
}



## Returns A list of vectors showing bearing Angle To Each Prey 
calcRelativeAngleToPrey <- function(datRenderHuntEvent)
{
  
  ### Plot Relative Angle To Each Prey ###
  vTrackedPreyIDs <- unique(datRenderHuntEvent$PreyID)
  
  
  #Range <- ((max(datRenderHuntEvent[!is.na(datRenderHuntEvent$PreyID),]$frameN) - min(datRenderHuntEvent$frameN) ) / G_APPROXFPS)+1
  relAngle <- list()
  
  n <- 0
  for (f in vTrackedPreyIDs)
  {
    n<-n+1
    #message(f)
    
    if (is.na(f))
      next
    
    datRenderPrey <- datRenderHuntEvent[datRenderHuntEvent$PreyID == f,]
    ##Atan2 returns -180 to 180, so 1st add 180 to convert to 360, then sub the fishBody Angle, then Mod 360 to wrap in 360deg circle, then sub 180 to convert to -180 to 180 relative to fish heading angles
    ##dd Time Base As frame Number on First Column
    relAngle[[as.character(f)]]  <- cbind(datRenderPrey$frameN, 
                                          ( ( 180 +  180/pi * atan2(datRenderPrey$Prey_X -datRenderPrey$posX,datRenderPrey$posY - datRenderPrey$Prey_Y)) -datRenderPrey$BodyAngle    ) %% 360 - 180
    )
  }
  #points(relAngle[[as.character(f)]],datRenderPrey$frameN,type='b',cex=0.2,xlim=c(-180,180))
  
  ##Convert Frames To Seconds
  
  return (relAngle)
  
}
#


##
## Identify Bout Sections and Get Data On Durations etc.
##Uses The Detected Regions Of Bouts to extract data, on BoutOnset-Offset - Duration, Distance from Prey and Bout Power as a measure of distance moved during bout
## Note: Incomplete Bouts At the end of the trajectory will be discarted  
## regionToAnalyse - Sequence of Idx On Which To Obtain Bout Motion Data - Usually Set from 1st to last point of prey capture for a specific Prey Item
calcMotionBoutInfo2 <- function(ActivityboutIdx,TurnboutsIdx,HuntRangeIdx,vEventSpeed_smooth,vDistToPrey,vBearingToPrey,vTailMotion,regionToAnalyse,plotRes=FALSE)
{
  ##Grey Point
  colourG <- c(rgb(0.6,0.6,0.6,0.5)) ##Region (Transparency)    
  idx_Terminal         <- min(max(HuntRangeIdx)+Fs/10,max(regionToAnalyse))
  ActivityboutIdx_cleaned <- ActivityboutIdx[ActivityboutIdx < idx_Terminal ] #[ActivityboutIdx %in% regionToAnalyse]  #[which(vEventSpeed_smooth[ActivityboutIdx] > G_MIN_BOUTSPEED   )  ]
  
  meanBoutSpeed <- median(vEventSpeed_smooth[ActivityboutIdx_cleaned])
  vEventPathLength <- cumsum(vEventSpeed_smooth) ### Speed is in mm 
  
  ##Binarize , Use indicator function 1/0 for frames where Motion Occurs
  ##Bouts only within hunting region ##
  vMotionBout <- vEventSpeed_smooth[1:idx_Terminal]
  vMotionBout[ 1:NROW(vMotionBout) ]   <- 0
  vMotionBout[ ActivityboutIdx_cleaned  ] <- 1 ##Set Detected BoutFrames As Motion Frames
  
  vTurnBout <- vEventSpeed_smooth
  vTurnBout[ 1:NROW(vMotionBout) ]   <- 0 ##Use vMotionBout Size / In case there are differeced due to ActivityboutIdx_cleaned
  vTurnBout[ TurnboutsIdx  ] <- 1 ##Set Detected BoutFrames As Motion Frames
  
  ##Make Initial Cut So There is always a Bout On/Off 1st & Last Frame Is always a pause
  vMotionBout[1] <- 0
  vMotionBout[2] <- 1
  vMotionBout[NROW(vMotionBout)] <- 0
  
  ##Bouts only within hunting region ##
  vMotionBout_OnOffDetect <- diff(vMotionBout[1:idx_Terminal]) ##Set 1n;s on Onset, -1 On Offset of Bout
  ##Detect Speed Minima
  boutEdgesIdx <- find_peaks((max(vEventSpeed_smooth)- vEventSpeed_smooth)*100,Fs/5)
  
  
  ##Bout On Points Are Found At the OnSet Of the Rise/ inflexion Point - Look for Previous derivative /Accelleration change
  vMotionBout_On <- which(vMotionBout_OnOffDetect == 1)+1

  if (NROW(vMotionBout_On) == 1)
    warning("No Bout Onset Detected")
    

  vMotionBout_Off <- which(vMotionBout_OnOffDetect[vMotionBout_On[1]:length(vMotionBout_OnOffDetect)] == -1)+vMotionBout_On[1] 
  iPairs <- min(length(vMotionBout_On),length(vMotionBout_Off)) ##We can Only compare paired events, so remove an odd On Or Off Trailing Event

      
  ##Ignore An Odd, Off Event Before An On Event, (ie start from after the 1st on event)
  ## Get Bout Statistics Again Now Using Run Length Encoding Method 
  ## Take InterBoutIntervals in msec from Last to first - 
  vMotionBout_rle <- rle(vMotionBout)
  vTurnBout_rle <- rle(vTurnBout)
  
  ##Filter Out Small Bouts/Pauses -
  idxShort <- which(vMotionBout_rle$lengths < max(MIN_BOUT_DURATION,MIN_BOUT_PAUSE) )
  for (jj in idxShort)
  {
    ##Fill In this Gap
    idxMotionStart <- sum(vMotionBout_rle$length[1:(jj-1)])
    idxMotionEnd <- idxMotionStart + vMotionBout_rle$length[jj]
    
    if( vMotionBout_rle$values[jj] == 1 &  vMotionBout_rle$lengths[jj] < MIN_BOUT_DURATION) # If this is a Motion
      vMotionBout[idxMotionStart:idxMotionEnd] <- 0 ##Replace short motion with Pause

    if( vMotionBout_rle$values[jj] == 0 &  vMotionBout_rle$lengths[jj] < MIN_BOUT_PAUSE) # If this is a pause
      vMotionBout[idxMotionStart:idxMotionEnd] <- 1 ##Replace short Pause with Motion
    
  }
  ##Make Initial Cut So 1st & Last Frame Is always a pause
  vMotionBout[1] <- 0
  vMotionBout[NROW(vMotionBout)] <- 0
  
  ##Redo Fixed Binary Vector
  vMotionBout_rle <- rle(vMotionBout)

  if (NROW(vMotionBout_rle$values[vMotionBout_rle$values == 1]) == 0)
  {
    lastBout <- 0
    firstBout <- 0
  }
  else
  {
    lastBout <- max(which(vMotionBout_rle$values == 1))
    firstBout <- min(which(vMotionBout_rle$values[1:lastBout] == 1))
  }
  
  if (lastBout < 1)
  {
    warning(paste("No Bouts Detected for idx:") )
    return (NA)
  }
  
  
  vMotionBoutDuration <- NA
  vMotionBoutIBI <- NA
  vMotionBoutDistanceToPrey_mm <-NA
  vMotionBoutDistanceTravelled_mm <-NA
  vTurnBoutAngle <- NA
  vMotionBout_On <-NA
  vMotionBout_Off <-NA
  
  vEventPathLength_mm<- vEventPathLength*DIM_MMPERPX
  vEventSpeed_smooth_mm <- Fs*vEventSpeed_smooth*DIM_MMPERPX
  
  ##Skip If Recording Starts With Bout , And Catch The One After the First Pause
  if (lastBout > firstBout) ##If More than One Bout Exists
  {
    vMotionBoutIBI <-1000*vMotionBout_rle$lengths[seq(lastBout-1,firstBout,-2 )]/Fs #' IN msec and in reverse Order From Prey Capture Backwards
    ##Add One Since IBI count is 1 less than the bout count
    vMotionBoutIBI <- c(vMotionBoutIBI,NA)
    
  }
    ##Now That Indicators Have been integrated On Frames - Redetect On/Off Points
    vMotionBout_OnOffDetect <- diff(vMotionBout) ##Set 1n;s on Onset, -1 On Offset of Bout
    vMotionBout_On <- which(vMotionBout_OnOffDetect == 1)+1
    vMotionBout_Off <- which(vMotionBout_OnOffDetect == -1)+1
    if ( lastBout > 0    )
      vMotionBoutDuration <-1000*vMotionBout_rle$lengths[seq(lastBout,firstBout,-2 )]/Fs ##Measure Duration From Lengths Of Active Motion Using RLE flag
    else
      vMotionBoutDuration <-1000*vMotionBout_rle$lengths[1]/Fs ##Measure Duration From Lengths Of Active Motion Using RLE flag
    
    ##Re-adjust pair count
    iPairs <- min(length(vMotionBout_On),length(vMotionBout_Off)) 
    
    vMotionBoutDistanceToPrey_mm    <- vDistToPrey[vMotionBout_On]*DIM_MMPERPX
    vMotionBoutDistanceTravelled_mm <- (vEventPathLength_mm[vMotionBout_Off[1:iPairs] ] - vEventPathLength_mm[vMotionBout_On[1:iPairs] ]) ##The Power of A Bout can be measured by distance Travelled
    vTurnBoutAngle                  <- (vBearingToPrey[vMotionBout_Off[1:iPairs],2] - vBearingToPrey[vMotionBout_On[1:iPairs],2])
    # Measure peak speed for each bout 
    
    
    cntS <- 0;  vMotionPeakSpeed_mm <- vector()
    for (boutOn in vMotionBout_On[1:iPairs])
    {
      cntS <- cntS + 1
      vMotionPeakSpeed_mm[cntS] <- max(vEventSpeed_smooth_mm[ boutOn:vMotionBout_Off[cntS] ],na.rm=TRUE) ##Hold Max mm/sec speed of this bout
    }
  

    
  
  ## Denotes the Relative Time of Bout Occurance as a Sequence 1 is first, ... 10th -closer to Prey
  boutSeq <- seq(NROW(vMotionBoutDuration),1,-1 ) ##The time Sequence Of Event Occurance (Fwd Time)
  boutRank <- seq(1,NROW(vMotionBoutDuration),1 ) ##Denotes Reverse Order - From Prey Captcha being First going backwards to the n bout
  turnSeq <- rep(0,NROW(vMotionBoutDuration))   ##Empty Vector Of Indicating The Number of Turns that have occured up to a Bout
  
  ## TURN TO PREY SEQUENCE NUMBERING 
  ## Assign A TurnSequence Number to Each Detected Bout / Used to Select 1 turn to prey etc..
  ## Go through Each MotionBout and Check If Turns Detected within Each Bout / Then Increment Counter
  turnCount <- 0
  
  if (NROW(vMotionBout_On) > 0)
  {
    for (tidx in 1:NROW(vMotionBout_On) ) 
    {
      turnSeq[tidx] <- 0
      ##Check if Turn frames Detected during bout
      if ( any( vTurnBout[vMotionBout_On[tidx]:vMotionBout_Off[tidx] ] > 0) ) 
      {
        ##Only score those that are towards Prey / and not NA
        if (!is.na(vBearingToPrey[vMotionBout_On[tidx],2]) & !is.na(vBearingToPrey[vMotionBout_Off[tidx],2]))
        {
          ##Check That Detected TurnBout Reduces Angle To Prey
          ##  by at least 10% - Filter Out Non Turn To PRey Items / Tiny Turns before big swing to towards prey
          if ( abs( vBearingToPrey[vMotionBout_Off[tidx],2] )  < 0.90*abs(vBearingToPrey[vMotionBout_On[tidx],2] )  )
          {
            message( paste(tidx," has turn towards prey :", abs(vBearingToPrey[vMotionBout_On[tidx],2]-vBearingToPrey[vMotionBout_Off[tidx],2] )    ) )
            turnCount <- turnCount + 1
            turnSeq[tidx] <- turnCount
          }
        }##check for missing values
      }
    }
  } ##If motion bout Exists
  
  
  ##Reverse Order 
  vMotionBoutDistanceToPrey_mm    <- vMotionBoutDistanceToPrey_mm[boutSeq] 
  vMotionBoutDistanceTravelled_mm <- vMotionBoutDistanceTravelled_mm[boutSeq]
  vMotionPeakSpeed_mm             <-vMotionPeakSpeed_mm[boutSeq]
  vTurnBoutAngle <- vTurnBoutAngle[boutSeq]
  vMotionBout_On <- vMotionBout_On[boutSeq]
  vMotionBout_Off <- vMotionBout_Off[boutSeq]
  turnSeq <- turnSeq[boutSeq]
  ##Check for Errors
  #stopifnot(vMotionBout_rle$values[NROW(vMotionBout_rle$lengths)] == 0 )###Check End With  Pause Not A bout
  stopifnot(vMotionBout_rle$values[firstBout+1] == 0 ) ##THe INitial vMotionBoutIBI Is not Actually A pause interval , but belongs to motion!

    
  ##Combine and Return
  datMotionBout <- cbind(boutSeq,boutRank,vMotionBout_On,vMotionBout_Off,
                         vMotionBoutIBI,vMotionBoutDuration,
                         vMotionBoutDistanceToPrey_mm,vMotionBoutDistanceTravelled_mm,vMotionPeakSpeed_mm,
                         vTurnBoutAngle,turnSeq) ##Make Data Frame
  
  
  #### PLOT DEBUG RESULTS ###
  ##Make Shaded Polygons
  if (plotRes)
  {
    #vEventSpeed_smooth <- vEventSpeed_smooth*5
    
    lshadedBout <- list()
    #t <- seq(1:NROW(vEventPathLength_mm))/(Fs/1000)
    t <- seq(1:NROW(regionToAnalyse))/(Fs/1000) ##Time Vector / Starts from 0 , not where regionToAnalyse starts
    for (i in 1:NROW(vMotionBout_Off))  
    {
      lshadedBout[[i]] <- rbind(
        cbind(t[vMotionBout_Off[i] ],0*vEventSpeed_smooth[vMotionBout_Off[i]]-1),
        cbind(t[vMotionBout_Off[i] ], max(vEventPathLength_mm) ), #vEventPathLength_mm[vMotionBout_Off[i]]+15),
        cbind(t[vMotionBout_On[i] ], max(vEventPathLength_mm) ),#vEventPathLength_mm[vMotionBout_On[i]]+15),
        cbind(t[vMotionBout_On[i] ], 0*vEventSpeed_smooth[vMotionBout_On[i]]-1) ##Start from Low X Axis Height
      )
    }
    
    ##Plot Displacement and Speed(Scaled)
    vTailDispFilt <- filtfilt( bf_tailClass2, abs(filtfilt(bf_tailClass, (vTailMotion) ) ) )
    if (max(vEventPathLength_mm) < 10)
      ymax <- 10 #max(vEventPathLength_mm[!is.na(vEventPathLength_mm)])
    else
      ymax <- 15 #max(vEventPathLength_mm[!is.na(vEventPathLength_mm)])
    
    plot(t,vEventPathLength_mm[regionToAnalyse],
         main="Body Motion",
         ylab=NA,
         xlab=NA, #"msec",
         cex.lab = FONTSZ_AXISLAB,
         cex.axis = FONTSZ_AXIS,
         ylim=c(-0.3, ymax  ),type='l',lty=1,lwd=3,col=colourG) ##PLot Total Displacemnt over time
    ##Slide Time of Hunt Onset to Set 0 at time of of region to analyse
    lines(t[HuntRangeIdx-min(regionToAnalyse)],vEventPathLength_mm[HuntRangeIdx],xlab= NA,#"(msec)", 
          ylab=NA,cex=1,lwd=3,lty=1,pch=16,
          col="black")
    
    par(new=TRUE) ##Add To Path Length Plot But On Separate Axis So it Scales Nicely
    
    
    plot(t,vEventSpeed_smooth_mm[regionToAnalyse],type='l',
         axes=F,xlab=NA,ylab=NA,col=colourG,ylim=c(0,25),lwd=3,lty=4,
         cex.lab = FONTSZ_AXISLAB,
         cex.axis = FONTSZ_AXIS
    ) ##Plot Motion Speed / Shift HuntIdx Time Back to Start of Region to Analyse
    lines(t[HuntRangeIdx-min(regionToAnalyse)],vEventSpeed_smooth_mm[HuntRangeIdx],xlab= NA,#"(msec)",
          ylab=NA,cex=1,lwd=3,lty=1,
          col="blue")
    
    axis(side = 4,col="blue",cex.axis = FONTSZ_AXIS)
    mtext(side = 4,cex=FONTSZ_AXISLAB, line = 2.2, 'Speed (mm/sec)' ,font=2)
    #mtext(side = 1,cex=FONTSZ_AXISLAB, line = 2.2, "Time (msec)", font=2 )
    mtext(side = 2,cex=FONTSZ_AXISLAB, padj=-0.1,line = 2.2, "Distance Travelled (mm)", font=2 ) 
    
    
    #lines(vTailDispFilt*DIM_MMPERPX,type='l',col="magenta")
    #points(t[ActivityboutIdx],vEventSpeed_smooth[ActivityboutIdx],col="grey",pch=16,cex=1.1) ## For Bout Debug
    #points(t[ActivityboutIdx_cleaned],vEventSpeed_smooth[ActivityboutIdx_cleaned],col="red") ## For Bout Debug
    #points(t[TurnboutsIdx],vEventSpeed_smooth[TurnboutsIdx],col="darkblue",pch=19,cex=0.4) ##SHow Detected Turn Idxs  ## For Bout Debug
    #points(t[vMotionBout_On],vEventSpeed_smooth[vMotionBout_On],col="blue",pch=17,lwd=3)## For Bout Debug
    #points(t[vMotionBout_Off],vEventSpeed_smooth[vMotionBout_Off],col="purple",pch=14,lwd=3) 
    #points(t[boutEdgesIdx],vEventSpeed_smooth[boutEdgesIdx],col="red",pch=8,lwd=3)  ## For Bout Debug

    ###Show Bout Region    
   # segments(t[vMotionBout_Off],vEventSpeed_smooth[vMotionBout_Off]-1,t[vMotionBout_Off],0*vEventPathLength[vMotionBout_Off]+15,lwd=1.2,col="purple")
   #  segments(t[vMotionBout_On],vEventSpeed_smooth[vMotionBout_On]-1,t[vMotionBout_On],0*vEventPathLength[vMotionBout_On]+15,lwd=0.9,col="green")
    ##Show Bout Region
    for (poly in lshadedBout)
      polygon(poly,density=3,angle=-45) 
    
    #legend("topleft",legend=c("M Bout", "M End","Turn","Activity"),col=c("blue","purple","darkblue","grey"),pch=c(17,14,19,16) )
    legend("topleft",legend=c(" Displacement", "Speed"),col=c("black","blue","grey"),lty=c(1,4),lwd=c(3,2) )
    #lines(vMotionBoutDistanceToPrey_mm,col="purple",lw=2)
    pkPt <- round(vMotionBout_On+(vMotionBout_Off-vMotionBout_On )/2)
    text(t[pkPt],vEventSpeed_smooth[pkPt]+0.5,labels=boutSeq) ##Show Bout Sequence IDs to Debug Identification  
    #legend(1,100,c("PathLength","FishSpeed","TailMotion","BoutDetect","DistanceToPrey" ),fill=c("black","blue","magenta","red","purple") )
    
    plot(t,vTailMotion[regionToAnalyse],type='l',
         xlab=NA,ylab=NA, # "msec",
         col=colourG,
         main="Tail Motion",lwd=2,
         cex.lab = FONTSZ_AXISLAB,
         cex.axis = FONTSZ_AXIS)
    lines(t[HuntRangeIdx-min(regionToAnalyse)],vTailMotion[HuntRangeIdx],type='l',
         xlab=NA,ylab=NA, # "msec",
         col="red",lwd=2)
    
    lines(t,vTailDispFilt[regionToAnalyse],col="black",lwd=2 )
   # mtext(side = 1,cex=FONTSZ_AXISLAB, line = 2.2, "Time (msec)", font=2 )
    mtext(side = 2,cex=FONTSZ_AXISLAB, padj=-0.1, line = 2.2, expression("Tail Tip Angle"^degree~""), font=2 ) 
    
    
  } ##If Plot Flag Is Set 
  
  message(paste("Number oF Bouts:",NROW(datMotionBout)))
  # dev.copy(png,filename=paste(strPlotExportPath,"/Movement-Bout_exp",expID,"_event",eventID,"_track",trackID,".png",sep="") );
  

  return(datMotionBout)
}


##Returns List of dataframes with PreyAzimuth Vs Distance for each hunt Episode In INdex LIst
getPreyAzimuthForHuntEvents <- function(datTrackedEventsRegister,datHuntEventMergedFrames,idxTargetSet)
{
  ### Obtain Matrix of relative Angles 
  lrecAzimuth  <- list()
  
  cnt <- 0
  
  for (idxH in idxTargetSet )# idxTestSet NROW(datTrackedEventsRegister) #1:NROW(datTrackedEventsRegister)
  {
    cnt  = cnt + 1
    message(paste("######### Processing ",cnt," ######") )
    
    
    expID <- datTrackedEventsRegister[idxH,]$expID
    trackID<- datTrackedEventsRegister[idxH,]$trackID
    eventID <- datTrackedEventsRegister[idxH,]$eventID
    groupID <- datTrackedEventsRegister[idxH,]$groupID
    selectedPreyID <- datTrackedEventsRegister[idxH,]$PreyIDTarget
    
    message(paste(idxH, ".Process Hunt Event Expid:",expID,"Event:",eventID))
    
    datPlaybackHuntEvent <- datHuntEventMergedFrames[datHuntEventMergedFrames$expID==expID 
                                                     & datHuntEventMergedFrames$trackID==trackID 
                                                     & datHuntEventMergedFrames$eventID==eventID,]
    
    lrecAzimuth[[cnt]] <- data.frame(do.call(rbind,
                                             calcPreyAzimuth(datPlaybackHuntEvent[datPlaybackHuntEvent$LEyeAngle - datPlaybackHuntEvent$REyeAngle > G_THRESHUNTVERGENCEANGLE,] )
    ) )
  }
  
  return (lrecAzimuth)
}

## Does A histogram FOr Prey Azimuth Per Hunt Event - Eye Binarized to azimuth location occupied per Hunt Event
getPreyAzimuthBinHist <- function(lrecAzimuth,Azi.breaks,dist.breaks)
{
  
  ## Run Binarized Histogram
  lhistAzimuth <- list()
  for (i in 1:NROW(lrecAzimuth))
    lhistAzimuth[[i]] <- histj(lrecAzimuth[[i]]$distPX*DIM_MMPERPX,lrecAzimuth[[i]]$azimuth,dist.breaks,Azi.breaks )
  
  return(lhistAzimuth)
}##
##


## Histogram Binarized - Used For Azimuth VS Dis 2D histogram###
histj<- function(x,y,x.breaks,y.breaks){
  c1 = as.numeric(cut(x,breaks=x.breaks));
  c2 = as.numeric(cut(y,breaks=y.breaks));
  mat<-matrix(0,ncol=length(y.breaks)-1,nrow=length(x.breaks)-1);
  mat[cbind(c1,c2)] = 1;
  return(mat)
}  



######################OLD CODE ####################
# 
# ## Identify Bout Sections and Get Data On Durations etc.
# ##Uses The Detected Regions Of Bouts to extract data, on BoutOnset-Offset - Duration, Distance from Prey and Bout Power as a measure of distance moved during bout
# ## Note: Incomplete Bouts At the end of the trajectory will be discarted  
# ## regionToAnalyse - Sequence of Idx On Which To Obtain Bout Motion Data - Usually Set from 1st to last point of prey capture for a specific Prey Item
# calcMotionBoutInfo <- function(ActivityboutIdx,vEventSpeed_smooth,vDistToPrey,vTailMotion,regionToAnalyse,plotRes=FALSE)
# {
#   ActivityboutIdx_cleaned <- ActivityboutIdx[ActivityboutIdx %in% regionToAnalyse]  #[which(vEventSpeed_smooth[ActivityboutIdx] > G_MIN_BOUTSPEED   )  ]
#   
#   meanBoutSpeed <- median(vEventSpeed_smooth[ActivityboutIdx_cleaned])
#   
#   ##Binarize , Use indicator function 1/0 for frames where Motion Occurs
#   vMotionBout <- vEventSpeed_smooth
#   vMotionBout[ 1:NROW(vMotionBout) ]   <- 0
#   vMotionBout[ ActivityboutIdx_cleaned  ] <- 1 ##Set Detected BoutFrames As Motion Frames
#   
#   
#   #vMotionBout_rle <- rle(vMotionBout)
#   
#   ##Invert Speed / And Use Peak Finding To detect Bout Edges (Troughs are Peaks in the Inverse image)
#   boutEdgesIdx <- find_peaks((max(vEventSpeed_smooth)- vEventSpeed_smooth)*100,Fs/5)
#   vEventAccell_smooth_Onset  <- boutEdgesIdx
#   vEventAccell_smooth_Offset <- c(boutEdgesIdx,NROW(vEventSpeed_smooth))
#   #vMotionBout[boutEdgesIdx]  <- 0 ##Set Edges As Cut Points XX
#   
#   vMotionBout_OnOffDetect <- diff(vMotionBout) ##Set 1n;s on Onset, -1 On Offset of Bout
#   #X11()
#   #plot(vEventSpeed_smooth, type='l', main="Unprocessed Cut Points")
#   #points(vEventAccell_smooth_Onset,vEventSpeed_smooth[vEventAccell_smooth_Onset])
#   #points(vEventAccell_smooth_Offset,vEventSpeed_smooth[vEventAccell_smooth_Offset],pch=6)
#   
#   
#   ##Bout On Points Are Found At the OnSet Of the Rise/ inflexion Point - Look for Previous derivative /Accelleration change
#   vMotionBout_On <- which(vMotionBout_OnOffDetect == 1)+1
#   
#   # stopifnot(NROW(vMotionBout_On) > 0) ##No Bouts Detected
#   
#   ##Ignore An Odd, Off Event Before An On Event, (ie start from after the 1st on event)
#   vMotionBout_Off <- which(vMotionBout_OnOffDetect[vMotionBout_On[1]:length(vMotionBout_OnOffDetect)] == -1)+vMotionBout_On[1] 
#   iPairs <- min(length(vMotionBout_On),length(vMotionBout_Off)) ##We can Only compare paired events, so remove an odd On Or Off Trailing Event
#   
#   ##Fix Detected Bout Points-
#   ##Remove The Motion Regions Where A Peak Was not detected / Only Keep The Bouts with Peaks
#   ## Shift the time of Bout to the edges where Start is on the rising foot of speed and stop are on the closest falling foot (This produces dublicates that are removed later)
#   
#   vMotionBout[1:length(vMotionBout)] = 0 ##Reset / Remove All Identified Movement
#   for (i in 1:iPairs)
#   {
#     ###Motion Interval belongs to a detect bout(peak)  // Set Frame Indicators vMotionBout To Show Bout Frames
#     if (any( ActivityboutIdx_cleaned >= vMotionBout_On[i] & ActivityboutIdx_cleaned < vMotionBout_Off[i] ) == TRUE)
#     { 
#       ##Fix Bout Onset Using Accelleration To Detect When Bout Actually Began
#       ##Find Closest Speed Onset
#       ##Calculate TimeDiff Between Detected BoutOnset And Actual Accelleration Onsets - Find the Onset Preceding the Detected Bout 
#       OnSetTD <- vMotionBout_On[i] - vEventAccell_smooth_Onset[!is.na(vEventAccell_smooth_Onset)]
#       ##Shift To Correct Onset Of Speed Increase / Denoting Where Bout Actually Began ##FIX ONSETS 
#       ###Leave Out For Now
#       if (NROW( (OnSetTD[OnSetTD > 0  ]) )>0) ##If Start Of Accellaration For this Bout Can Be Found / Fix It otherwise Leave it alone
#       {
#         idxMinStartOfBout <- which(OnSetTD == min(OnSetTD[OnSetTD > 0  ]))
#         TDNearestBout <- (vMotionBout_On - vEventAccell_smooth_Onset[idxMinStartOfBout]) ##Invert Sign so as to detect TDs preceding the end 
#         idxDetectedFirstFrameOfBout <- max(which(TDNearestBout == min(TDNearestBout[TDNearestBout>0]) )  ) ##max to pick the last one in case duplicate vMotionBout_Off values
#         #vMotionBout_On[i] <-  vMotionBout_On[i] - min(OnSetTD[OnSetTD > 0  ])
#         vMotionBout_On[i] <-  vMotionBout_On[idxDetectedFirstFrameOfBout]
#       }
#       
#       ##FIX OFFSET to The Last MotionBoutIdx Detected Before the next BoutStart (where Decellaration Ends and A new One Begins)
#       OffSetTD <- vEventAccell_smooth_Offset[!is.na(vEventAccell_smooth_Offset)] - vMotionBout_Off[i]  
#       if (NROW(OffSetTD[OffSetTD > 0  ]) > 0) ##If An Offset Can Be Found (Last Bout Maybe Runs Beyond Tracking Record)
#       { ##Find Last Detected Point In bout
#         idxMaxEndOfBout <- which(OffSetTD == min(OffSetTD[OffSetTD > 0  ]))
#         ##Last Detected Frame Before End is:
#         TDNearestBout <- -(vMotionBout_Off - vEventAccell_smooth_Offset[idxMaxEndOfBout]) ##Invert Sign so as to detect TDs preceding the end 
#         ##Find Which MotionBout Idx is the The Last One
#         idxDetectedLastFrameOfBout <- max(which(TDNearestBout == min(TDNearestBout[TDNearestBout>0]) )  ) ##max to pick the last one in case duplicate vMotionBout_Off values
#         # vSpeedHillEdge <- vMotionBout_Off[i] + min(OffSetTD[OffSetTD > 0  ]) ##How Far  is the next Edge
#         ##Choose Closest Either The Last Detected Point Or The End/ Edge Of Speed Hill
#         vMotionBout_Off[i] <-  vMotionBout_Off[idxDetectedLastFrameOfBout] #min(vSpeedHillEdge,vMotionBout_Off[idxDetectedLastFrameOfBout]) ##+ min(OffSetTD[OffSetTD > 0  ]) ##Shift |Forward To The End Of The bout
#       }
#       
#       vMotionBout[vMotionBout_On[i]:(vMotionBout_Off[i]) ] = 1 ##Set As Motion Frames
#     }
#     else
#     {##Remove the Ones That Do not Have a peak In them
#       vMotionBout_On[i] = NA 
#       vMotionBout_Off[i] = NA
#     }
#     
#     
#   } ###For Each Pair Of On-Off MotionBout 
#   
#   ##In Case On/Off Motion Becomes COntigious Then RLE will fail to detect it - So Make Sure Edges are there
#   #vMotionBout[vMotionBout_On+1] = 1
#   vMotionBout[vMotionBout_Off] = 0 ##Make Sure Off Remains / For Rle to Work
#   
#   #X11()
#   #plot(vEventAccell_smooth,type='l',main="Processed Cut-Points")
#   #points(vMotionBout_On,vEventAccell_smooth[vMotionBout_On])
#   #points(vMotionBout_Off,vEventAccell_smooth[vMotionBout_Off],pch=6)
#   
#   
#   ##Get Bout Statistics #### NOt Used / Replaced##
#   #vMotionBoutDuration_msec <- vMotionBout_Off[1:iPairs]-vMotionBout_On[1:iPairs]
#   #vMotionBoutDuration_msec <- 1000*vMotionBoutDuration_msec[!is.na(vMotionBoutDuration_msec)]/Fs
#   #vMotionBoutIntervals_msec <- 1000*(vMotionBout_On[3:(iPairs)] - vMotionBout_Off[2:(iPairs-1)])/Fs
#   ############################
#   
#   
#   ## Get Bout Statistics Again Now Using Run Length Encoding Method 
#   ## Take InterBoutIntervals in msec from Last to first - 
#   vMotionBout_rle <- rle(vMotionBout)
#   lastBout <- max(which(vMotionBout_rle$values == 1))
#   firstBout <- min(which(vMotionBout_rle$values[2:lastBout] == 1)+1) ##Skip If Recording Starts With Bout , And Catch The One After the First Pause
#   vMotionBoutIBI <-1000*vMotionBout_rle$lengths[seq(lastBout-1,1,-2 )]/Fs #' IN msec and in reverse Order From Prey Capture Backwards
#   ##Now That Indicators Have been integrated On Frames - Redetect On/Off Points
#   vMotionBout_OnOffDetect <- diff(vMotionBout) ##Set 1n;s on Onset, -1 On Offset of Bout
#   vMotionBout_On <- which(vMotionBout_OnOffDetect == 1)+1
#   vMotionBout_Off <- which(vMotionBout_OnOffDetect == -1)+1
#   vMotionBoutDuration <-1000*vMotionBout_rle$lengths[seq(lastBout,2,-2 )]/Fs
#   
#   vEventPathLength_mm<- vEventPathLength*DIM_MMPERPX
#   ## Denotes the Relative Time of Bout Occurance as a Sequence 1 is first, ... 10th -closer to Prey
#   boutSeq <- seq(NROW(vMotionBoutIBI),1,-1 ) 
#   boutRank <- seq(1,NROW(vMotionBoutIBI),1 ) ##Denotes Reverse Order - From Prey Captcha being First going backwards to the n bout
#   ## TODO FIx these
#   vMotionBoutDistanceToPrey_mm <- vDistToPrey[vMotionBout_On]*DIM_MMPERPX
#   vMotionBoutDistanceTravelled_mm <- (vEventPathLength_mm[vMotionBout_Off[1:iPairs]]-vEventPathLength_mm[vMotionBout_On[1:iPairs]]) ##The Power of A Bout can be measured by distance Travelled
#   
#   ##Reverse Order 
#   vMotionBoutDistanceToPrey_mm <- vMotionBoutDistanceToPrey_mm[boutSeq] 
#   vMotionBoutDistanceTravelled_mm <- vMotionBoutDistanceTravelled_mm[boutSeq]
#   
#   ##Check for Errors
#   stopifnot(vMotionBout_rle$values[NROW(vMotionBout_rle$lengths)] == 0 )
#   stopifnot(vMotionBout_rle$values[firstBout+1] == 0 ) ##THe INitial vMotionBoutIBI Is not Actually A pause interval , but belongs to motion!
#   
#   ##Combine and Return
#   datMotionBout <- cbind(boutSeq,boutRank,vMotionBout_On,vMotionBout_Off,vMotionBoutIBI,vMotionBoutDuration,vMotionBoutDistanceToPrey_mm,vMotionBoutDistanceTravelled_mm) ##Make Data Frame
#   
#   
#   #### PLOT DEBUG RESULTS ###
#   ##Make Shaded Polygons
#   if (plotRes)
#   {
#     #vEventSpeed_smooth <- vEventSpeed_smooth*5
#     
#     lshadedBout <- list()
#     t <- seq(1:NROW(vEventPathLength_mm))/(Fs/1000)
#     for (i in 1:NROW(vMotionBout_Off))  
#     {
#       lshadedBout[[i]] <- rbind(
#         cbind(t[vMotionBout_Off[i] ],vEventSpeed_smooth[vMotionBout_Off[i]]-1),
#         cbind(t[vMotionBout_Off[i] ], max(vEventPathLength_mm) ), #vEventPathLength_mm[vMotionBout_Off[i]]+15),
#         cbind(t[vMotionBout_On[i] ], max(vEventPathLength_mm) ),#vEventPathLength_mm[vMotionBout_On[i]]+15),
#         cbind(t[vMotionBout_On[i] ], vEventSpeed_smooth[vMotionBout_On[i]]-1)
#       )
#     }
#     
#     ##Plot Displacement and Speed(Scaled)
#     vTailDispFilt <- filtfilt( bf_tailClass2, abs(filtfilt(bf_tailClass, (vTailMotion) ) ) )
#     
#     plot(t,vEventPathLength_mm,ylab="mm",
#          xlab="msec",
#          ylim=c(-0.3,max(vEventPathLength_mm[!is.na(vEventPathLength_mm)])  ),type='l',lwd=3) ##PLot Total Displacemnt over time
#     par(new=T) ##Add To Path Length Plot But On Separate Axis So it Scales Nicely
#     par(mar=c(4,4,2,2))
#     plot(t,vEventSpeed_smooth,type='l',axes=F,xlab=NA,ylab=NA,col="blue")
#     axis(side = 4,col="blue")
#     mtext(side = 4, line = 3, 'Speed (mm/sec)')
#     
#     #lines(vTailDispFilt*DIM_MMPERPX,type='l',col="magenta")
#     points(t[MoveboutsIdx],vEventSpeed_smooth[MoveboutsIdx],col="black")
#     points(t[MoveboutsIdx_cleaned],vEventSpeed_smooth[MoveboutsIdx_cleaned],col="red")
#     points(t[vMotionBout_On],vEventSpeed_smooth[vMotionBout_On],col="blue",pch=17,lwd=3)
#     segments(t[vMotionBout_Off],vEventSpeed_smooth[vMotionBout_Off]-1,t[vMotionBout_Off],vEventPathLength[vMotionBout_Off]+15,lwd=1.2,col="purple")
#     points(t[vMotionBout_Off],vEventSpeed_smooth[vMotionBout_Off],col="purple",pch=14,lwd=3)
#     points(t[boutEdgesIdx],vEventSpeed_smooth[boutEdgesIdx],col="red",pch=8,lwd=3) 
#     segments(t[vMotionBout_On],vEventSpeed_smooth[vMotionBout_On]-1,t[vMotionBout_On],vEventPathLength[vMotionBout_On]+15,lwd=0.9,col="green")
#     for (poly in lshadedBout)
#       polygon(poly,density=3,angle=-45) 
#     
#     #lines(vMotionBoutDistanceToPrey_mm,col="purple",lw=2)
#     text(t[round(vMotionBout_On+(vMotionBout_Off-vMotionBout_On )/2)],max(vEventSpeed_smooth)+3,labels=boutSeq) ##Show Bout Sequence IDs to Debug Identification  
#     #legend(1,100,c("PathLength","FishSpeed","TailMotion","BoutDetect","DistanceToPrey" ),fill=c("black","blue","magenta","red","purple") )
#     
#     plot(t[1:NROW(vTailMotion)],vTailMotion,type='l',
#          xlab="msec",
#          col="red",main="Tail Motion")
#     lines(t[1:NROW(vTailMotion)],vTailDispFilt,col="black" )
#     
#   } ##If Plot Flag Is Set 
#   
#   message(paste("Number oF Bouts:",NROW(datMotionBout)))
#   # dev.copy(png,filename=paste(strPlotExportPath,"/Movement-Bout_exp",expID,"_event",eventID,"_track",trackID,".png",sep="") );
#   
#   #  dev.off()
#   
#   
#   ## Plot The Start Stop Motion Bout Binarized Data
#   #vMotionBout[is.na(vMotionBout)] <- 0
#   #vMotionBout_On[is.na(vMotionBout_On)] <- 0
#   #vMotionBout_Off[is.na(vMotionBout_Off)] <- 0
#   
#   #X11()
#   #plot(vMotionBout,type='p',xlim=c(0,max(vMotionBout_Off) )  )
#   #plot(MoveboutsIdx_cleaned,vMotionBout[MoveboutsIdx_cleaned],col="red",type='p')
#   #segments(seq(1:NROW(vMotionBout)),vMotionBout,seq(1:NROW(vMotionBout)),vMotionBout+0.04,lwd=0.2)
#   
#   #points(vMotionBout_On,vMotionBout[vMotionBout_On],col="green",pch=2,cex=2) ##On
#   #points(vMotionBout_Off,vMotionBout[vMotionBout_Off],col="purple",pch=13,cex=2)##Off
#   
#   
#   return(datMotionBout)
# }
######################################## END OF V1 #############


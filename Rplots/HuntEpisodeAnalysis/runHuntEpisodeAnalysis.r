
### Hunt Episode Data Extraction and Analysis Scripts 
### Kostasl Jul 2018 
## It is aimed at identified hunt event that have been carefully retracked and imported separatelly from these new Tracked CsV files using runImportHuntEpisodeTrackFiles
## It provides the data for identifying Bouts using FishSpeed. 
## Notes: 
## * Gaussian Mixt. Clusters are used to Identify Bout from Speeds, however the BoutOnset-Offset Is then Fixed To Identify When Speed Ramps Up , 
## and final decelpartion is used to obtain  more accurate estimates of BoutDurations-
## * The Distance to Prey Is calculated But Also Interpolated using Fish Displacement where there are missing values - 
## \Notes:
## Can use findLabelledEvent( datTrackedEventsRegister[IDXOFHUNT,]) to locate which HuntEvent is associated from the Labelled Set Record, And Retrack it by running 
## main_LabellingBlind.r and providing the row.name as ID 
##Requires :@
# install.packages("signal"))
# install.packages("mclust")
# install.packages("Rwave")
#install.packages('extrafont') #then run font_import()

### TODO 1st Turn To Prey Detection Needs checking/fixing, 
#####


library(MASS)
library(mclust,quietly = TRUE) 

require(Rwave) 
library(extrafont)


source("HuntEpisodeAnalysis/HuntEpisodeAnalysis_lib.r")
source("TrackerDataFilesImport_lib.r")
source("plotTrackScatterAndDensities.r")
source("DataLabelling/labelHuntEvents_lib.r") ##for convertToScoreLabel

strDataFileName <- paste(strDataExportDir,"/setn_huntEventsTrackAnalysis_SetB",".RData",sep="") ##To Which To Save After Loading

strRegisterDataFileName <- paste(strDataExportDir,"/setn_huntEventsTrackAnalysis_Register_SetB",".rds",sep="") #Processed Registry on which we add 
message(paste(" Importing Retracked HuntEvents from:",strDataFileName))

G_THRESHUNTVERGENCEANGLE <- 40 ##Redifine Here Over main_Tracking - Make it looser so to detect 1st turn to Prey
#    for (i in 1:40) dev.off()
#
############# Analysis AND REPLAY OF HUNT EVENTS ####
load(strDataFileName) ## Load Imported Hunt Event Tracks - THe detailed Retracked Events
datTrackedEventsRegister <- readRDS(strRegisterDataFileName) ## THis is the Processed Register File On 
remove(lMotionBoutDat)
lMotionBoutDat <- readRDS(paste(strDataExportDir,"/huntEpisodeAnalysis_MotionBoutData.rds",sep="") ) #Processed Registry on which we add )
lEyeMotionDat <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_EyeMotionData",".rds",sep="")) #Processed Registry on which we add )
bSaveNewMotionData <- FALSE ##Overwrite the lMotionBoutDatFile

strGroupID <- levels(datTrackedEventsRegister$groupID)

##Make an Updated list of ReTracked Hunt Events that have been imported
# datTrackedEventsRegister <- data.frame(unique(cbind(datHuntEventMergedFrames$expID,datHuntEventMergedFrames$eventID,datHuntEventMergedFrames$trackID) ))

###
#nEyeFilterWidth <- nFrWidth*6 ##For Median Filtering ##moved to main

### RESET Storage Structs ###
remove(lMotionBoutDat)
remove(lEyeMotionDat)
############################

if (!exists("lMotionBoutDat" ,envir = globalenv(),mode="list"))
  lMotionBoutDat <<- list() ##Declared In Global Env


if (!exists("lEyeMotionDat" ,envir = globalenv(),mode="list"))
  lEyeMotionDat <<- list() ##Declared In Global Env

idxH <- 20
idTo <- 20#NROW(datTrackedEventsRegister)

idxDLSet <- which(datTrackedEventsRegister$groupID == "DL")
idxNLSet <- which(datTrackedEventsRegister$groupID == "NL")
idxLLSet <- which(datTrackedEventsRegister$groupID == "LL")
idxTestSet = c(idxDLSet,idxLLSet,idxNLSet)  #c(16,17)# #c(96,74) ##Issue with IDS when not put in groupID correct order

cnt = 0


for (idxH in idxLLSet )# idxTestSet NROW(datTrackedEventsRegister) #1:NROW(datTrackedEventsRegister)
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
  
  
  strFolderName <- paste( strPlotExportPath,"/renderedHuntEvent",expID,"_event",eventID,"_track",trackID,sep="" )
  
  ############ PREY SELECTION #####
  ## Begin Data EXtraction ###
  ## Remove Multiple Prey Targets ########
  ##Get Number oF Records per Prey
  tblPreyRecord <-table(datPlaybackHuntEvent$PreyID) 
  if (NROW(tblPreyRecord) > 1)
    stop("Multiple Prey Items Tracked In Hunt Episode-/ Auto Selecting Longest Track is OFF - Need to Manually Join Prey Tracks - Stop Here")
  if (NROW(tblPreyRecord) < 1)
  {
    warning(paste(" Skipping No Prey ID for " ,expID,"_event",eventID,"_track",trackID, sep="" )  ) 
    next
  }
  
  ##### FILTERS #######
  message("Filtering Fish Motion (on all PreyID replicates)...")
  ldatFish <- list()
  for (p in names(tblPreyRecord))
  {
    #message(p)
    ldatFish[[as.character(p)]] <- filterEyeTailNoise(datPlaybackHuntEvent[!is.na(datPlaybackHuntEvent$PreyID) 
                                                                           & datPlaybackHuntEvent$PreyID == p,])
  }
  ldatFish[["NA"]] <- filterEyeTailNoise(datPlaybackHuntEvent[is.na(datPlaybackHuntEvent$PreyID) ,])
  
  ##Recombine the datframes Split By PreyID
  datPlaybackHuntEvent <- do.call(rbind,ldatFish)
  
  
  ###### CARTOON PLAYBACK / RENDER HUNT EVENT ######
  ## renderHuntEventPlayback(datPlaybackHuntEvent,selectedPreyID,speed=1)# saveToFolder =  strFolderName,saveToFolder =  strFolderName#saveToFolder =  strFolderName
  ##Make Videos With FFMPEG :
  #ffmpeg  -start_number 22126 -i "%5d.png"  -c:v libx264  -preset slow -crf 0  -vf fps=30 -pix_fmt yuv420p -c:a copy renderedHuntEvent3541_event14_track19.mp4
  #ffmpeg  -start_number 5419 -i "%5d.png"  -c:v libx264  -preset slow -crf 0  -vf fps=400 -pix_fmt yuv420p -c:a copy renderedHuntEvent4041_event13_track4.mp4
  ########################
  
  
  ##Add PreyTarget ID To Register Save The Prey Target To Register
  if (!any(names(datTrackedEventsRegister) == "PreyIDTarget"))
    datTrackedEventsRegister$PreyIDTarget <- NA
  if (!any(names(datTrackedEventsRegister) == "startFrame"))
    datTrackedEventsRegister$startFrame <- NA
  
  ##Set To 1st Frame In Hunt Event
  datTrackedEventsRegister[idxH,]$startFrame   <- min(datPlaybackHuntEvent$frameN)
  
  #selectedPreyID <- max(as.numeric(names(which(tblPreyRecord == max(tblPreyRecord)))))
  ##Check If Assigned OtherWise Automatically Select the longest Track
  if (is.na(datTrackedEventsRegister[idxH,]$PreyIDTarget)) 
  {
    selectedPreyID <-  max(as.numeric(names(which(tblPreyRecord == max(tblPreyRecord)))))
    if (!is.numeric( selectedPreyID) | is.infinite( selectedPreyID)   )
    {
      stop("Error on setting selectedPreyID automatically ")
      next()
    }
    datTrackedEventsRegister[idxH,]$PreyIDTarget <- selectedPreyID
    datTrackedEventsRegister[idxH,]$PreyCount    <- NROW(tblPreyRecord)
    #datTrackedEventsRegister[idxH,]$startFrame   <- min(datPlaybackHuntEvent$frameN)
    saveRDS(datTrackedEventsRegister,file=strRegisterDataFileName) ##Save With Dataset Idx Identifier
  }
  
  #
  ##Save The Selected Prey Item
  if (selectedPreyID != datTrackedEventsRegister[idxH,]$PreyIDTarget)
  {
    message(paste("Targeted Prey Changed For Hunt Event to ID:",selectedPreyID," - Updating Register...") )
    datTrackedEventsRegister[idxH,]$PreyIDTarget <- selectedPreyID
    saveRDS(datTrackedEventsRegister,file=strRegisterDataFileName) ##Save With Dataset Idx Identifier
  }
  ################ END OF PREY SELECT / Start Processing ###
  
  
  ## Select Prey Specific Subset
  datFishMotionVsTargetPrey <- ldatFish[[as.character(selectedPreyID)]] #datPlaybackHuntEvent[datPlaybackHuntEvent$PreyID == ,] 
  ##datRenderHuntEvent <- datFishMotionVsTargetPrey
  datRenderHuntEvent <- datPlaybackHuntEvent
  
  ### Filter / Process Motion Variables - Noise Removal / 
  #datFishMotionVsTargetPrey <- filterEyeTailNoise(datFishMotionVsTargetPrey)
  ##
  ##Vector Of Vergence Angle
  Fs <- unique(datFishMotionVsTargetPrey$fps)*0.90 ##Reduce Nominal By 10% as it is usually not achieved
  vEyeV <- datFishMotionVsTargetPrey$LEyeAngle-datFishMotionVsTargetPrey$REyeAngle
  

  #### PROCESS BOUTS ###
  vDeltaXFrames        <- diff(datRenderHuntEvent$posX,lag=1,differences=1)
  vDeltaYFrames        <- diff(datRenderHuntEvent$posY,lag=1,differences=1)
  vDeltaDisplacement   <- sqrt(vDeltaXFrames^2+vDeltaYFrames^2) ## Path Length Calculated As Total Displacement
  
  
  #nNumberOfBouts       <- 
  dframe               <- diff(datRenderHuntEvent$frameN,lag=1,differences=1)
  dframe               <- dframe[dframe > 0] ##Clear Any possible Nan - and Convert To Time sec  
  vEventSpeed          <- meanf(vDeltaDisplacement/dframe,5) ##IN (mm) Divide Displacement By TimeFrame to get Instantentous Speed, Apply Mean Filter Smooth Out 
  

  vDeltaBodyAngle      <- diffPolar(datRenderHuntEvent$BodyAngle) #(  ( 180 +  180/pi * atan2(datRenderPrey$Prey_X -datRenderPrey$posX,datRenderPrey$posY - datRenderPrey$Prey_Y)) -datRenderPrey$BodyAngle    ) %% 360 - 180
  vTurnSpeed           <- meanf(vDeltaBodyAngle[1:NROW(dframe)]/dframe,5)
  vAngleDisplacement   <- cumsum(vDeltaBodyAngle)

    
  #vEventPathLength     <- cumsum(vEventSpeed) ##Noise Adds to Length
  vDistToPrey          <- meanf(sqrt( (datFishMotionVsTargetPrey$Prey_X -datFishMotionVsTargetPrey$posX )^2 + (datFishMotionVsTargetPrey$Prey_Y - datFishMotionVsTargetPrey$posY)^2   ),3)
  vSpeedToPrey         <- diff(vDistToPrey,lag=1,differences=1)
  lAngleToPrey <- calcRelativeAngleToPrey(datRenderHuntEvent)
  
  ##Calc Angle To Prey Per Bout
  vAngleToPrey <- data.frame(lAngleToPrey[as.character(selectedPreyID)])
  names(vAngleToPrey) = c("frameN","AngleToPrey")
  ## Tail Motion ####
  vTailDir <-  datRenderHuntEvent$DThetaSpine_1 +  datRenderHuntEvent$DThetaSpine_2 + datRenderHuntEvent$DThetaSpine_3 + datRenderHuntEvent$DThetaSpine_4 + datRenderHuntEvent$DThetaSpine_5 + datRenderHuntEvent$DThetaSpine_6 + datRenderHuntEvent$DThetaSpine_7
  vTailDisp <-  datRenderHuntEvent$DThetaSpine_6 + datRenderHuntEvent$DThetaSpine_7 #+ datRenderHuntEvent$DThetaSpine_7 #+ datRenderHuntEvent$DThetaSpine_7 #abs(datRenderHuntEvent$DThetaSpine_1) +  abs(datRenderHuntEvent$DThetaSpine_2) + abs(datRenderHuntEvent$DThetaSpine_3) + abs(datRenderHuntEvent$DThetaSpine_4) + abs(datRenderHuntEvent$DThetaSpine_5) + abs(datRenderHuntEvent$DThetaSpine_6) + abs(datRenderHuntEvent$DThetaSpine_7)
  vTailDisp <- filtfilt(bf_tailClass, clipEyeRange(vTailDisp,-120,120))
  vTailDispFilt <- filtfilt(bf_tailClass2,abs( vTailDisp) )  ##Heavily Filtered and Used For Classifying Bouts
  ## Tail Segment Size - Filtered Heavily to Detect Slow Tilt Toward Prey
  nPad <- 200
  vTailSegSize <- medianf( ##Append To Start And end so No Sudden Clipping Occurs
    c( rep ( head( datRenderHuntEvent$TailSegLength,1),nPad), datRenderHuntEvent$TailSegLength,rep ( tail( datRenderHuntEvent$TailSegLength,1),nPad)),10)  ##Filter Fast Tail Size Fluctuations
  ##Remove Out Of Range Values Clip to +- 1SD ## Set to Mean Value
  vTailSegSize[vTailSegSize < (mean(vTailSegSize)-1.5*sd(vTailSegSize) ) ] <- mean(vTailSegSize)-1.5*sd(vTailSegSize)
  vTailSegSize[vTailSegSize > (mean(vTailSegSize)+1.5*sd(vTailSegSize) ) ] <- mean(vTailSegSize)+1.5*sd(vTailSegSize)
  vTailSegSize <-  filtfilt( bf_tailSegSize,vTailSegSize) 
  vTailSegSize <- vTailSegSize[nPad:(NROW(vTailSegSize)-nPad)] ##Remove now Filtered / Padded Edges
  
  #vDPitchEstimate <- -(1/max(vTailSegSize))*asin((vTailSegSize)/max(vTailSegSize))*180/pi ##Estimate The Angle looking Upwards (towards the surface) of the larvae
  ##Change in Pitch Angle acos() 
  ## We can estimate a eye Angle Correction Factor due to tile as atan(tan(thetaV)*(vTailSegSize)/max(vTailSegSize) )
  ## Estimate Tail Seg Size At level / Use Mean value Above Median :
  TailSegSize_level <- mean( vTailSegSize[vTailSegSize > median(vTailSegSize)] )
  vPitchEstimate <- acos((vTailSegSize)/TailSegSize_level)*180/pi ##Estimate Pitch Assuming maxTailSeg Represents Level Fish
  vDPitchEstimate <- (-asin(diff(vTailSegSize)/TailSegSize_level) )*180/pi ##Change in Pitch
  vEyeVPitchCorrected <- 2*atan( tan( (pi/180) * vEyeV/2)/(TailSegSize_level/(vTailSegSize) ) )*180/pi ##Assume Top Angle Of a triangle of projected points - where the top point moves closer to base as the pitch increases
  #X11()
  #plot((1000*1:NROW(vTailDisp)/Fs),vTailDisp,type='l')
  
  ##Plot Tail Spectral Density
  #png(filename=paste(strPlotExportPath,"/TailSpectrum",idxH,"_exp",expID,"_event",eventID,"_track",trackID,".png",sep="") );
  
  #dev.off()
  
  #tmp<-mk.cwt(w,noctave = floor(log2(length(w)))-1,nvoice=10)
  
  #speed_Smoothed <- meanf(vEventSpeed,10)
  ##Replace NA with 0s
  vEventSpeed[is.na(vEventSpeed)] = 0
  vEventSpeed_smooth <- filtfilt(bf_speed, vEventSpeed) #meanf(vEventSpeed,100) #
  vEventSpeed_smooth[vEventSpeed_smooth < 0] <- 0 ## Remove -Ve Values As an artefact of Filtering
  vEventSpeed_smooth[is.na(vEventSpeed_smooth)] = 0
  vEventPathLength <- cumsum(vEventSpeed_smooth)
  
  vTurnSpeed[is.na(vTurnSpeed)] <- 0
  vTurnSpeed <- filtfilt(bf_speed, vTurnSpeed)
  
  vDistToPrey_Fixed_FullRange    <- interpolateDistToPrey(vDistToPrey[1:NROW(vEventSpeed_smooth)],vEventSpeed_smooth)
  
  #plot(vTailDisp,type='l')
  ## Do Wavelet analysis Of Tail End-Edge Motion Displacements - 
  # Returns List Structure will all Relevant Data including Fq Mode Per Time Unit
  lwlt <- getPowerSpectrumInTime(vTailDisp,Fs)
  
  #MoveboutsIdx <- detectMotionBouts(vEventSpeed)##find_peaks(vEventSpeed_smooth*100,25)
  #### Cluster Tail Motion Wtih Fish Speed - Such As to Identify Motion Bouts Idx 
  #vMotionSpeed <- vEventSpeed_smooth + vTurnSpeed
  #MoveboutsIdx <- detectMotionBouts2(vEventSpeed_smooth,lwlt$freqMode)

  ########## BOUT DETECTION #################
  TurnboutsIdx <- NA
  MoveboutsIdx <- NA
  TailboutsIdx <- NA
  
  MoveboutsIdx <- detectMotionBouts(vEventSpeed_smooth,0.15)
  TailboutsIdx <- detectTailBouts(lwlt$freqMode)
  
  ##Note that sensitivity of this Determines detection of 1st turn to Prey
  TurnboutsIdx <- detectTurnBouts(abs(vTurnSpeed),lwlt$freqMode,0.2) 
  
  MoveboutsIdx  <- c(TailboutsIdx, MoveboutsIdx,TurnboutsIdx )
  ##Score Detected Frames On Overlapping Detectors
  tblMoveboutsScore<- table(MoveboutsIdx[!is.na(MoveboutsIdx)])
  ##Select Bouts Based On Score. ex. score >= 3 means it Exceeds Speed+Tail Motion+Turn+Tail Motion Thresholds
  MoveboutsIdx_cleaned <- as.numeric(names(tblMoveboutsScore[tblMoveboutsScore>G_MIN_BOUTSCORE]))
  
  stopifnot(NROW(MoveboutsIdx_cleaned) > 0 )
  # # # # # # # # # # # # # ## # ## # # # # # 
  
  ##Find Region Of Interest For Analysis Of Bouts
  ## As the Furthers point Between : Either The Prey Distance Is minimized, or The Eye Vergence Switches Off) 
  ## which(datFishMotionVsTargetPrey$LEyeAngle > G_THRESHUNTANGLE) , which(datFishMotionVsTargetPrey$REyeAngle < -G_THRESHUNTANGLE) )) -50,
  
  ##Analyse from 1st Turn (assume Towardsprey) that is near the eye Vergence time point 
  startFrame <-NA
#  if (NROW(TurnboutsIdx) > 3) ##If Turns Have been detected then Use 1st Turn Near eye V as startFrame for Analysis
#  {
#    ##Take 1st turn to prey Close to Eye V
#    startFrame <- TurnboutsIdx[min(which( TurnboutsIdx >= min(which(vEyeV > G_THRESHUNTVERGENCEANGLE) -10)  ) )]-50 
#  }
  
  
  if (is.na(startFrame))
  {
    startFrame <- max(1,min(which(vEyeV > G_THRESHUNTVERGENCEANGLE) -50) )##Start from point little earlier than Eye V
    message(paste("Warning: No TurnBouts Detected idxH:",idxH )  )
  }
    
   
  
  regionToAnalyse       <-seq(max( c(startFrame,1  ) ) , #
                              min(
                                which(vDistToPrey_Fixed_FullRange == min(vDistToPrey_Fixed_FullRange)), 
                                max(which(vEyeV > G_THRESHUNTVERGENCEANGLE) )  
                                ) + 20
                              ) ##Set To Up To The Minimum Distance From Prey
  
  vDistToPrey_Fixed      <- interpolateDistToPrey(vDistToPrey_Fixed_FullRange,vEventSpeed_smooth,regionToAnalyse)
  
  
    
  #  plot(vTailDispFilt,type='l')
  #  points(which(vTailActivity==1),vTailDispFilt[which(vTailActivity==1)])
  
  #points(vTailActivity)
  ##Distance To PRey
  ##Length Of Vector Determines Analysis Range For Motion Bout 
  #MoveboutsIdx_cleaned <- which(vTailActivity==1)

  ################  PLot Event Detection Summary #################
  #
  strPlotFileName <- paste(strPlotExportPath,"/MotionBoutPage",idxH,"_exp",expID,"_event",eventID,"_track",trackID,".pdf",sep="")
  pdf(strPlotFileName,width = 8,height = 10 ,paper = "a4",onefile = TRUE );
  #X11()
  par(mar=c(4,4,1.5,1.5))
  
  #layout(matrix(c(1,6,2,6,3,7,4,7,5,8), 5, 2, byrow = TRUE))
  layout(matrix(c(1,5,2,5,3,6,4,6), 4, 2, byrow = TRUE))
    t <- seq(1:NROW(vEventSpeed_smooth))/(Fs/1000) ##Time Vector

    lMotionBoutDat[[idxH]]  <- calcMotionBoutInfo2(MoveboutsIdx_cleaned,
                                                   TurnboutsIdx,
                                                   vEventSpeed_smooth,
                                                   vDistToPrey_Fixed_FullRange,
                                                   vAngleToPrey,
                                                   vTailDisp,
                                                   regionToAnalyse,plotRes = TRUE)
    datMotionBout = data.frame( lMotionBoutDat[[idxH]]  )
    if (is.na( lMotionBoutDat[[idxH]] ) )
    {
      stop(paste("*** No Bouts detected for idxH:",idxH ) ) 
      next
    }
    ## Change In Fish Heading
    plot(t,vAngleDisplacement[1:NROW(t)],type='l',ylim=c(-70,70),
         xlab= NA,#"(msec)",
         ylab=NA,
         col="blue",main=" Angle Displacement")
    ## Note First Turn To Prey On Plot  ##
    tFirstTurnToPreyS <-datMotionBout[datMotionBout$turnSeq==1,]$vMotionBout_On
    tFirstTurnToPreyE <-datMotionBout[datMotionBout$turnSeq==1,]$vMotionBout_Off
    points(t[tFirstTurnToPreyS], vAngleDisplacement[tFirstTurnToPreyS],pch=2,cex=2.5,col="red") ##Start 1st Turn
    points(t[tFirstTurnToPreyE], vAngleDisplacement[tFirstTurnToPreyE],pch=6,cex=2.5,col="black") ##End 1st Turn
    lines(t,cumsum(vTurnSpeed)[1:NROW(t)],type='l',lwd=2,lty=1,      xlab=NA,          ylab=NA,          col="blue4")
    
    ###  Pitch (Upwards Tilt)
    lines(t,vPitchEstimate[1:NROW(t)],type='l',lwd=2,col='purple',lty=2) ## Pitch 
    legend("topleft",legend=c("Yaw","Pitch"),col=c("blue4","purple"),lty=c(1,5),lwd=2 )
    axis(side=2,tick=TRUE,font=2)
    axis(side=1,tick=TRUE,font=2)
    mtext(side = 2,cex=0.8, line = 2.2, expression('Angle'^degree), font=2 ) 
    
  
    ## Add Eye Angles  ##
    #par(new = TRUE )
    par(mar=c(4,4,2,2))
    plot(t,-filtfilt(bf_eyes,datRenderHuntEvent$REyeAngle[1:NROW(t)] ) ,col="red3",type='l',xlab=NA,ylab=NA,cex=1.2,ylim=c(0,80),lwd=2,lty=1) #,axes=F
    lines(t,filtfilt(bf_eyes,datRenderHuntEvent$LEyeAngle[1:NROW(t)] ),col="blue",type='l',xlab=NA,ylab=NA,lwd=2,lty=1) #axes=F
    ## Plot Eye Vergence 
    lines(t,vEyeV[1:NROW(t)],axes=F,col="magenta",type='l',xlab=NA,ylab=NA,lwd=2,lty=2)
    lines(t,vEyeVPitchCorrected[1:NROW(t)],axes=F,col=rfc(11)[11],type='l',xlab=NA,ylab=NA,lwd=2,lty=4)
    legend("bottomleft", horiz= F,  ncol =2,
           legend=c("R Eye ","L Eye ","Vergence","Vergence (C)"),
           col=c("red3","blue","magenta",rfc(11)[11]),lty=c(1,1,2,4),lwd=2 )
    
    mtext(side = 1,cex=0.8, line = 2.2, "Time (msec)", font=2 )
    mtext(side = 2,cex=0.8, line = 2.2, expression('Eye Angle'^degree), font=2 ) 
    
   #### /////////// ###
    #plotAngleToPreyAndDistance(datRenderHuntEvent,vDistToPrey_Fixed_FullRange,t)
    
    
    polarPlotAngleToPreyVsDistance(datPlaybackHuntEvent) #5
    polarPlotAngleToPrey(datPlaybackHuntEvent) #6
    #plotTailPowerSpectrumInTime(lwlt) #7
    #plotTailSpectrum(vTailDisp)##Tail Spectrum #8

  dev.off() 
  embed_fonts(strPlotFileName)
  ## END OF SUMMARY HUNT EVENT PLOT ##
  
  strPlotFileName <- paste(strPlotExportPath,"/TailSpectrum",idxH,"_exp",expID,"_event",eventID,"_track",trackID,".pdf",sep="")
  pdf(strPlotFileName,width = 8,height = 12 ,paper = "a4",onefile = TRUE );
  layout(matrix(c(1,2), 2, 1, byrow = TRUE))
      plotTailPowerSpectrumInTime(lwlt)
      plotTailSpectrum(vTailDisp)##Tail Spectrum
  dev.off() 
  embed_fonts(strPlotFileName)
  
  ##Tail Fq Mode
  #X11()
  #plot(1000*1:NROW(lwlt$freqMode)/lwlt$Fs,lwlt$freqMode,type='l',ylim=c(0,50),xlab="msec",ylab="Hz",main="Tail Beat Fq Mode")
  
  ##Exclude Idx of Bouts for Which We do not have an angle -Make Vectors In the Right Sequence 
  BoutOnsetWithinRange <- lMotionBoutDat[[idxH]][,"vMotionBout_On"][ lMotionBoutDat[[idxH]][,"vMotionBout_On"] < NROW(vAngleToPrey ) ][lMotionBoutDat[[idxH]][,"boutSeq"]]
  BoutOffsetWithinRange <- lMotionBoutDat[[idxH]][,"vMotionBout_Off"][ lMotionBoutDat[[idxH]][,"vMotionBout_Off"] < NROW(vAngleToPrey ) ][lMotionBoutDat[[idxH]][,"boutSeq"]]
  vAnglesAtOnset <- vAngleToPrey[BoutOnsetWithinRange ,2]
  vAnglesAtOffset <- vAngleToPrey[BoutOffsetWithinRange,2]
  
  ## Measure Change In Prey Angle During IBI
  vDeltaPreyAngle <- c(NA, ##First Bout Does not have an IBI nor a IBIAngleChange
                       vAngleToPrey[BoutOnsetWithinRange[2:(NROW(BoutOnsetWithinRange))],2] - vAngleToPrey[BoutOffsetWithinRange[1:(NROW(BoutOffsetWithinRange)-1)],2]
  )
  
  ##More Accuratelly Measure Angular Path Length Of Prey Angle Between Bouts - During the pause - Not Just the Difference Between Start-End Angle
  vBearingToPreyPath <- vector()
  for (p in 1:(NROW(BoutOffsetWithinRange)-1) )
  {
    vBearingToPrey <- vAngleToPrey[BoutOffsetWithinRange[p]:BoutOnsetWithinRange[p+1],2] 
    vBearingToPreyPath[p] <- sqrt(sum(diff(vBearingToPrey)^2)) ##Length of Path that the Prey Angle takes in the TimeFrame of the IBI
  }
    
  dBearingToPrey <- vAngleToPrey[BoutOffsetWithinRange[1:(NROW(BoutOffsetWithinRange)-1)],2]
  vPreyAnglePathLength <- c(NA,vBearingToPreyPath)
  
  rows <- NROW(lMotionBoutDat[[idxH]])
  stopifnot(rows > 0)
  lMotionBoutDat[[idxH]] <- cbind(lMotionBoutDat[[idxH]] ,
                                  OnSetAngleToPrey      = vAnglesAtOnset[lMotionBoutDat[[idxH]][,"boutSeq"]], ##Reverse THe Order Of Appearance Before Col. Bind
                                  OffSetAngleToPrey     = vAnglesAtOffset[lMotionBoutDat[[idxH]][,"boutSeq"]],
                                  IBIAngleToPreyChange  = vDeltaPreyAngle[lMotionBoutDat[[idxH]][,"boutSeq"]],
                                  IBIAngleToPreyLength  = vPreyAnglePathLength[lMotionBoutDat[[idxH]][,"boutSeq"]],
                                  RegistarIdx           = as.numeric(rep(idxH,rows)),
                                  expID                 = as.numeric(rep(expID,rows)),
                                  eventID               = as.numeric(rep(eventID,rows)),
                                  groupID               = rep((groupID) ,rows), ##as.character
                                  PreyCount             = rep(NROW(tblPreyRecord),rows)
                                  )
  
  ## Eye Angle Vs Distance ##
  ##Exclude the capture bout / attack / by excluding the last bout (which is 1st item on Motion Bout list <=> rank 1)
  EyeRegionToExtract <- seq( max(1,startFrame-1200), max(regionToAnalyse[ regionToAnalyse <= lMotionBoutDat[[idxH]][1,"vMotionBout_On"] ]) )
  bCaptureStrike <- 0
  
  ##If The last bout looks like a captcha / Use Distance travelled to detect Strong Propulsion in the last Bout
  ## TODO Change this to a velocity Estimate for capture strike
  ##if (lMotionBoutDat[[idxH]][1,"vMotionBoutDistanceTravelled_mm"] > 0.5) 
if (vEventSpeed_smooth[regionToAnalyse] > G_THRES_CAPTURE_SPEED)
    bCaptureStrike <- 1 ##Set Flag
  
  rows <- NROW(datRenderHuntEvent$LEyeAngle[EyeRegionToExtract])
  
  ##Estimate Pitch From Length Changes
  
  lEyeMotionDat[[idxH]] <- cbind(LEyeAngle=datRenderHuntEvent$LEyeAngle[EyeRegionToExtract ],
                                 REyeAngle=datRenderHuntEvent$REyeAngle[EyeRegionToExtract],
                                 PitchEstimate=vPitchEstimate,
                                 PitchEstimateChange=vDPitchEstimate,
                                 EyeVPitchCorrected=vEyeVPitchCorrected,
                                 DistToPrey=vDistToPrey_Fixed_FullRange[EyeRegionToExtract]*DIM_MMPERPX,
                                 DistToPreyInit= vDistToPrey_Fixed_FullRange[EyeRegionToExtract[min(which(EyeRegionToExtract > 0) ) ]]*DIM_MMPERPX,
                                 RegistarIdx           = as.numeric(rep(idxH,rows)),
                                 expID                 = as.numeric(rep(expID,rows)),
                                 eventID               = as.numeric(rep(eventID,rows)),
                                 groupID               = rep((groupID) ,rows), ##as.character
                                 doesCaptureStrike     = rep((bCaptureStrike) ,rows) ##Add A flag on record to say this Hunt event includes a capture strike
                                )
  
  #X11();plot(1000*(1:NROW(lEyeMotionDat[[idxH]][,"LEyeAngle"]))/G_APPROXFPS ,lEyeMotionDat[[idxH]][,"LEyeAngle"] )
} ###END OF EACH Hunt Episode Loop 


########## SAVE Processed Hunt Events ###########
if (bSaveNewMotionData)
  saveRDS(lMotionBoutDat,file=paste(strDataExportDir,"/huntEpisodeAnalysis_MotionBoutData",".rds",sep="") ) #Processed Registry on which we add )
#datEpisodeMotionBout <- lMotionBoutDat[[1]]


########## SAVE Processed Hunt Events ###########
if (bSaveNewMotionData)
  saveRDS(lEyeMotionDat,file=paste(strDataExportDir,"/huntEpisodeAnalysis_EyeMotionData",".rds",sep="") ) #Processed Registry on which we add )
#datEpisodeMotionBout <- lMotionBoutDat[[1]]

 ############# VERIFY ###
####Select Subset Of Data To Analyse
datMotionBoutCombinedAll <-  data.frame( do.call(rbind,lMotionBoutDat ) )
#datMotionBoutCombined$groupID <- levels(datTrackedEventsRegister$groupID)[datMotionBoutCombined$groupID]

### CHECK Process ##
##Check If all where processed
message(" Huntevent Processing Summary #EventInRegistry/#EventsProcessed")
for (gp in strGroupID)
{
  idxProc <- unique(datMotionBoutCombinedAll[datMotionBoutCombinedAll$groupID == which(strGroupID == gp),]$RegistarIdx)
  idxReg <- as.numeric( rownames(datTrackedEventsRegister[datTrackedEventsRegister$groupID == gp,]) ) 
  
  message(paste(gp , " did ",
                NROW(idxProc),
                "/",NROW(idxReg ) ) )
  
  
  message(paste("Missing Reg Idxs:",paste(list(idxReg[!(idxReg %in% idxProc)]), sep="," ) ) )
  
}

       



## Make Distance Vs Eye Angle Vectors ##
## PLOT EYE Vs Distance ##
lEyeLDistMatrix <- list()
lEyeRDistMatrix <- list()
lEyeVDistMatrix <- list()
lPreyAngleDistMatrix <- list()

nBreaks <- 50
maxDist <- 5 #5mm Range
stepDist <- maxDist/nBreaks
vDist <- seq(0,to=maxDist,by=stepDist)
for (strGroup in strGroupID)
{
  mrow <- 1
  lEyeLDistMatrix[[strGroup]] <- matrix(NA,nrow=80,ncol=nBreaks+1)
  lEyeRDistMatrix[[strGroup]] <- matrix(NA,nrow=80,ncol=nBreaks+1)
  lEyeVDistMatrix[[strGroup]] <- matrix(NA,nrow=80,ncol=nBreaks+1)
  lPreyAngleDistMatrix <- matrix(NA,nrow=80,ncol=nBreaks+1)
  
  for (recE in lEyeMotionDat) ##For Each Hunt Event 
  {
    if (is.null(recE))
      next()
    
    ## Filter Noise 
    recE[is.na(recE[,"REyeAngle"]) ,"REyeAngle"]  <- 0
    recE[,"REyeAngle"] <- filtfilt(bf_eyes,recE[,"REyeAngle"]  ) 
    recE[is.na(recE[,"LEyeAngle"]) ,"LEyeAngle"]  <- 0
    recE[,"LEyeAngle"] <- filtfilt(bf_eyes,recE[,"LEyeAngle"]  ) 
    
    groupID <- datTrackedEventsRegister[unique(recE[,"RegistarIdx"]),]$groupID
    if (as.character(groupID) != strGroup )
      next() ##Looking For EyeM Of Specific Group/ Skip Others
    
    ##Go through Each distance and record Eye Angle
    for (d in 0:nBreaks)
    {
      recLEye <- recE[ recE[,"DistToPrey"] > d*stepDist & recE[,"DistToPrey"] <= (d+1)*stepDist ,"LEyeAngle"]
      recREye <- recE[ recE[,"DistToPrey"] > d*stepDist & recE[,"DistToPrey"] <= (d+1)*stepDist ,"REyeAngle"]
      
      if (any(is.nan(recLEye) | is.nan(recREye) ))
        stop("Nan In Eye Angle")
      
      if (NROW(recLEye) > 0)
        lEyeLDistMatrix[[strGroup]][mrow,d] <- mean(recLEye,na.rm=TRUE )##Pick the mean value
      else
        lEyeLDistMatrix[[strGroup]][mrow,d] <- NA

      if (NROW(recREye) > 0)
        lEyeRDistMatrix[[strGroup]][mrow,d] <- mean(recREye,na.rm=TRUE )##Pick the mean value
      else
        lEyeRDistMatrix[[strGroup]][mrow,d] <- NA
      
      ##Combine into Vergence Angle Matrix
      lEyeVDistMatrix[[strGroup]][mrow,d] <- lEyeLDistMatrix[[strGroup]][mrow,d] - lEyeRDistMatrix[[strGroup]][mrow,d]
     
      
    } ##For each Distance In Vector
    
    mrow <- mrow + 1
  } ##For each EyeData Rec
}


strPlotFileName = paste(strPlotExportPath,"/EyeVsPreyDistanceFiltHuntMode_LL.pdf",sep="")
pdf(file= strPlotFileName,
    title="Mean Eye HUNT (>45 degrees) Vergence Vs Distance from Prey  LF" )
#plotMeanEyeV(lEyeVDistMatrix[["NL"]],colourH[1],addNewPlot=TRUE)
lHuntEyeVDistMatrix <- lEyeVDistMatrix[["LL"]]
lHuntEyeVDistMatrix[lHuntEyeVDistMatrix < G_THRESHUNTVERGENCEANGLE] <- NA
nLarvaCount <- NROW(unique(datTrackedEventsRegister[idxLLSet,"expID"]))
nEpisodeCount <- NROW(idxLLSet)
plotMeanEyeV(lHuntEyeVDistMatrix
             ,colourH[2],addNewPlot=TRUE)
legend("topright",fill=colourH[2], legend = c(  expression (),
                                                bquote( ~ .(nEpisodeCount)~'Episodes' / .(nLarvaCount) ~ "Larvae"  ) ##Evoked Activity
))


mtext(side = 1,cex=0.8, line = 2.2, "Distance from prey (mm)", font=2 )
mtext(side = 2,cex=0.8, line = 2.2, expression("Eye Vergence " (v^degree)  ), font=2 ) 
dev.off()

embed_fonts(strPlotFileName)


## Plot The Mean V vergence And Std Error  SEM
##Perhapse make it more convincing by Only Include EyeV > HuntThreshold ##
strPlotFileName = paste(strPlotExportPath,"/EyeVsPreyDistanceFiltHuntMode_ALL.pdf",sep="")
pdf(file= strPlotFileName,
    title="Mean Eye Vergence Vs Distance from Prey  NF,LF,DF" )

lHuntEyeVDistMatrix_NL <- lEyeVDistMatrix[["NL"]]
lHuntEyeVDistMatrix_NL[lHuntEyeVDistMatrix_NL < G_THRESHUNTVERGENCEANGLE] <- NA
plotMeanEyeV(lHuntEyeVDistMatrix_NL,colourH[1],addNewPlot=TRUE)

lHuntEyeVDistMatrix_LL <- lEyeVDistMatrix[["LL"]]
lHuntEyeVDistMatrix_LL[lHuntEyeVDistMatrix_LL < G_THRESHUNTVERGENCEANGLE] <- NA
plotMeanEyeV(lHuntEyeVDistMatrix_LL,colourH[2],addNewPlot=FALSE)

lHuntEyeVDistMatrix_DL <- lEyeVDistMatrix[["DL"]]
lHuntEyeVDistMatrix_DL[lHuntEyeVDistMatrix_DL < G_THRESHUNTVERGENCEANGLE] <- NA
plotMeanEyeV(lHuntEyeVDistMatrix_DL,colourH[3],addNewPlot=FALSE)

legend("topright",fill=colourH, legend = c(  expression (),
                                  bquote(NF["s"] ~ '#' ~ .(NROW(idxNLSet) )  ),
                                  bquote(LF["e"] ~ '#' ~ .(NROW(idxLLSet) )  ),
                                  bquote(DF["e"] ~ '#' ~ .(NROW(idxDLSet) )  ) ) )
mtext(side = 1,cex=0.8, line = 2.2, "Distance from prey (mm)", font=2 )
mtext(side = 2,cex=0.8, line = 2.2, expression("Eye Vergence " (v^degree)  ), font=2 ) 

dev.off()
embed_fonts(strPlotFileName)


##Plot An Example from Each 
plot(seq(0,maxDist,stepDist),-lEyeRDistMatrix[["NL"]][1,],xlab="Distance (mm)" ,type="l",col="red",ylim=c(0,80),main="Right Eye")
lines(seq(0,maxDist,stepDist),-lEyeRDistMatrix[["LL"]][1,],xlab="Distance (mm)" ,type="l",col="green",ylim=c(0,80))
lines(seq(0,maxDist,stepDist),-lEyeRDistMatrix[["DL"]][1,],xlab="Distance (mm)" ,type="l",col="blue",ylim=c(0,80))



## PLOT EYE Vs Distance ##
nlimit <- 3
n<- 0
for (strGroup in strGroupID)
{
  plot(0, 0 ,type="l",col="blue",ylim=c(0,45),xlim=c(0,4),main=paste("Left Eye Vs Dist To Prey ",strGroup) )
  for (recE in lEyeMotionDat)
  {
    print(n)
    if (is.null(recE))
      next()
    
    groupID <- datTrackedEventsRegister[unique(recE[,"RegistarIdx"]),]$groupID
    if (as.character(groupID) != strGroup )
      next()
    
    if (n > nlimit)
      break
    #lines(recE[,"DistToPrey"], recE[,"LEyeAngle"] ,type="l",col="blue",ylim=c(0,45),xlim=c(0,4))
    points(recE[,"DistToPrey"], recE[,"LEyeAngle"] ,type="p",col="blue",ylim=c(0,45),xlim=c(0,4),cex=0.2)
    n <- n + 1
  }
  
}


## PLOT EYE Vs Distance ##
for (strGroup in strGroupID)
{
  plot(0, 0 ,type="l",col="blue",ylim=c(0,45),xlim=c(0,4),main=paste("Right Eye Vs Dist To Prey ",strGroup) )
  for (recE in lEyeMotionDat)
  {
    if (is.null(recE))
      next()
    
    groupID <- datTrackedEventsRegister[unique(recE[,"RegistarIdx"]),]$groupID
    if (as.character(groupID) != strGroup )
      next()
    #lines(recE[,"DistToPrey"], recE[,"LEyeAngle"] ,type="l",col="blue",ylim=c(0,45),xlim=c(0,4))
    lines(recE[,"DistToPrey"], -1*recE[,"REyeAngle"] ,type="l",col="red",ylim=c(0,45),xlim=c(0,4))
  }
}
##On Bout Leng

##On Bout Lengths ##Where Seq is the order Of Occurance, While Rank denotes our custom Ordering From Captcha backwards

######### AnALYSIS OF Hunt Event Data ##############
##Make Vector Of Number oF Bouts Vs Distance
lBoutInfoPerEvent <- list()
for (rec in lMotionBoutDat)
{
  if (is.null(rec)) next;
  ##Take Distance of the 1st bout Detected (which has the largest #Rank (1 First Bout, N Last/Capture Bout))
  lBoutInfoPerEvent[[rec[1,"RegistarIdx"]]] <- list(nBouts=as.numeric(max(rec[,"boutSeq"])),
                                                       Distance= unique(as.numeric(rec[rec[,"boutRank"] == max(rec[,"boutRank"]),"vMotionBoutDistanceToPrey_mm"])),
                                                       Angle= unique(as.numeric(rec[rec[,"boutRank"] == max(rec[,"boutRank"]),"OnSetAngleToPrey"])), ##
                                                       groupID = (datTrackedEventsRegister[ as.numeric(rec[1,"RegistarIdx"]),"groupID" ]),
                                                       Duration= unique(as.numeric(rec[rec[,"boutRank"] == min(rec[,"boutRank"]),"vMotionBout_Off"]) - as.numeric(rec[rec[,"boutRank"] == max(rec[,"boutRank"]),"vMotionBout_On"]))
                                                       )
}

groupID <- which(levels(datTrackedEventsRegister$groupID) == "NL")

datBoutVsPreyDistance <-  data.frame( do.call(rbind,lBoutInfoPerEvent ) )
#datBoutVsPreyDistance[datBoutVsPreyDistance$groupID == (groupID),] ##Select Group For Analysis / Plotting

strGroupID <- levels(datTrackedEventsRegister$groupID)[unlist(unique(datBoutVsPreyDistance$groupID))] 

### Distance ColourRing ##
##Calculate Colour Idx For Each Of the Distances - Based on ncolBands
vUniqDist <- unique(round(unlist(datBoutVsPreyDistance$Distance)*10))
ncolBands <- 15
vcolIdx <-  vector() ; ##Distances Rounded / Indexed 
vdistToPrey <- round(unlist(datBoutVsPreyDistance$Distance)*10)
maxDistanceToPrey <- 50
vdistToPrey[vdistToPrey>maxDistanceToPrey] <- maxDistanceToPrey
vcolBands <- seq(min(vUniqDist),maxDistanceToPrey,length.out = ncolBands) 
for (j in 1:NROW(unlist(datBoutVsPreyDistance$Distance))) 
  vcolIdx[j] <- min(which(vcolBands >=  vdistToPrey[j] ))

# ) 
######Plot Turn Angle Vs Bearing - With DISTANCE Colour Code
Polarrfc <- colorRampPalette(rev(brewer.pal(15,'Spectral')));
colR <- c(Polarrfc( ncolBands ));
colourL <- c("#0303E6AF","#03B303AF","#E60303AF")
pchL <-c(16,2,4)
####### PLOT Turning Bout Vs Bearing TO Prey - Does the animal estimate turn amount Well?




pdf(file= paste(strPlotExportPath,"/DistanceVsBoutCount_",paste(strGroupID,collapse="-" ),".pdf",sep="",collapse="-"))
#X11()
plot(unlist(datBoutVsPreyDistance$nBouts),unlist(datBoutVsPreyDistance$Distance),
     main = paste("Initial distance to Prey Vs Bouts Performed",paste(strGroupID,collapse="," ) ) ,
     ylab="Distance to Prey  (mm)",
     xlab="Number of Tracking Movements",
     ylim=c(0,6),
     xlim=c(0,max(unlist(datBoutVsPreyDistance$nBouts) )),
     col=colourL[as.numeric(datBoutVsPreyDistance$groupID)],
     pch=pchL[as.numeric(datBoutVsPreyDistance$groupID)]
     )
legend("topleft",legend=c("DL","LL","NL"), pch=pchL,col=colourL)
dev.off()

pdf(file= paste(strPlotExportPath,"/BearingVsBoutCount_",paste(strGroupID,collapse="-"),".pdf",sep=""))

#X11()
datBoutAngle <- unlist(datBoutVsPreyDistance$Angle)
plot(unlist(datBoutVsPreyDistance$nBouts),ifelse(is.na(datBoutAngle),0,datBoutAngle),
     main = paste("Initial Bearing to Prey Vs Bouts Performed",paste(strGroupID,collapse=",") ) ,
     ylab="Angle to Prey  (deg)",
     xlab="Number of Tracking Movements",
     ylim=c(-80,80),xlim=c(0,max(unlist(datBoutVsPreyDistance$nBouts) )),
     #col=colR[vcolIdx],
     col=colourL[as.numeric(datBoutVsPreyDistance$groupID)],
     pch=pchL[as.numeric(datBoutVsPreyDistance$groupID)])
legend("topleft",legend=c("DL","LL","NL"), pch=pchL,col=colourL)
dev.off()



pdf(file= paste(strPlotExportPath,"/DurationVsBoutCount_",paste(strGroupID,collapse="-"),".pdf",sep="",collapse="-" ))
#X11()
plot(unlist(datBoutVsPreyDistance$nBouts),1000*unlist(datBoutVsPreyDistance$Duration)/Fs,
     main = paste("Duration Of Hunt Event Vs Bouts Performed ",paste(strGroupID,collapse=",") )  ,
     ylab="Time  (msec)",
     xlab="Number of Tracking Movements",
     ylim=c(0,5000),xlim=c(0,max(unlist(datBoutVsPreyDistance$nBouts) )),
     col=colourL[as.numeric(datBoutVsPreyDistance$groupID)],
     pch=pchL[as.numeric(datBoutVsPreyDistance$groupID)])
legend("topleft",legend=c("DL","LL","NL"), pch=pchL,col=colourL)
dev.off()

pdf(file= paste(strPlotExportPath,"/DurationVsDistance_",paste(strGroupID,collapse="-"),".pdf",sep=""))
plot(unlist(datBoutVsPreyDistance$Distance),1000*unlist(datBoutVsPreyDistance$Duration)/Fs,
     main = paste("Duration Of Hunt Event Vs Distance ",paste(strGroupID,collapse=",") )  ,
     ylab="Time  (msec)",
     xlab="Distance (mm)",
     ylim=c(0,5000),xlim=c(0,6),
     col=colourL[as.numeric(datBoutVsPreyDistance$groupID)],
     pch=pchL[as.numeric(datBoutVsPreyDistance$groupID)])
legend("topleft",legend=c("DL","LL","NL"), pch=pchL,col=colourL)
dev.off()



##       Turns Vs Bearing To Prey ########### 



####### PLOT Turning Bout Vs Bearing TO Prey - Does the animal estimate turn amount Well ###############################
##Add Angle To Prey OnTop Of Eye Angles##
Polarrfc <- colorRampPalette(rev(brewer.pal(9,'Blues')));
#X11()
colR <- c("#000000",Polarrfc(max(datMotionBoutCombinedAll$boutRank) ) ,"#FF0000"); ##Make Colour Range for Seq
ncolBands <- NROW(colR)

strGroupID <- levels(datTrackedEventsRegister$groupID)
lFirstBoutPoints <- list() ##Add Dataframes Of 1st bout Turns for Each Group
###### PLOT BOUTTURN Vs Prey Angle Coloured with BOUTSEQ ################
for (gp in strGroupID)
{
  groupID <- which(levels(datTrackedEventsRegister$groupID) == gp)

  datMotionBoutCombinedAll$vMotionBoutDistanceToPrey_mm <- as.numeric(datMotionBoutCombinedAll$vMotionBoutDistanceToPrey_mm)
  datMotionBoutCombined <-datMotionBoutCombinedAll[datMotionBoutCombinedAll$groupID == as.numeric(groupID), ] #Select Group
  
  datMotionBoutCombined$boutRank <- as.numeric(datMotionBoutCombined$boutRank)
  datMotionBoutTurnToPrey <- datMotionBoutCombined[abs(datMotionBoutCombined$OnSetAngleToPrey) >= abs(datMotionBoutCombined$OffSetAngleToPrey) , ]
  datMotionBoutTurnToPrey <- datMotionBoutTurnToPrey[!is.na(datMotionBoutTurnToPrey$RegistarIdx),]
  ## Punctuate 1st Turn To Prey
  #lFirstBoutPoints[[gp]] <- cbind(OnSetAngleToPrey = datMotionBoutCombined[datMotionBoutCombined$turnSeq == 1 & datMotionBoutCombined$boutSeq == 1 ,]$OnSetAngleToPrey,
  #                            Turn= datMotionBoutCombined[datMotionBoutCombined$turnSeq == 1 & datMotionBoutCombined$boutSeq == 1 ,]$OnSetAngleToPrey - datMotionBoutCombined[datMotionBoutCombined$turnSeq == 1 & datMotionBoutCombined$boutSeq == 1,]$OffSetAngleToPrey
  #                            , RegistarIdx=datMotionBoutCombined[datMotionBoutCombined$turnSeq == 1 & datMotionBoutCombined$boutSeq == 1 ,]$RegistarIdx)
  lFirstBoutPoints[[gp]] <- cbind(OnSetAngleToPrey = datMotionBoutTurnToPrey[datMotionBoutTurnToPrey$turnSeq == 1 ,]$OnSetAngleToPrey,
                                  Turn= datMotionBoutTurnToPrey[ datMotionBoutTurnToPrey$turnSeq == 1 ,]$OnSetAngleToPrey - datMotionBoutTurnToPrey[ datMotionBoutTurnToPrey$turnSeq == 1,]$OffSetAngleToPrey
                                  , RegistarIdx=datMotionBoutTurnToPrey[ datMotionBoutTurnToPrey$turnSeq == 1 ,]$RegistarIdx)
  
  
  ##Searching 
  #unlist(lFirstBoutPoints[[gp]][ lFirstBoutPoints[[gp]][,"Turn"] < 10,])
  pdf(file= paste(strPlotExportPath,"/BoutTurnsToPreyWithBoutSeq_",gp,".pdf",sep=""))
  plot(datMotionBoutCombined$OnSetAngleToPrey,datMotionBoutCombined$OnSetAngleToPrey-datMotionBoutCombined$OffSetAngleToPrey,
     main=paste("Turn Size Vs Bearing To Prey ",gp, " (l=",NROW(unique(datMotionBoutCombined$expID)),",n=",NROW((datMotionBoutCombined$expID)),")",sep="" ),
     xlab="Bearing To Prey prior to Bout",ylab="Bearing Change After Bout",xlim=c(-100,100),
     ylim=c(-100,100),
     col=colR[datMotionBoutCombined$boutSeq] ,pch=19) ##boutSeq The order In Which The Occurred Coloured from Dark To Lighter
  points(lFirstBoutPoints[[gp]][,1],
         lFirstBoutPoints[[gp]][,2],
         pch=9)
  points(1:ncolBands,rep(-90, ncolBands), col=colR[1:ncolBands],pch=15) ##Add Legend Head Map
  text(-3,-87,labels = paste(min(datMotionBoutCombined$boutRank) ,"#" )  ) ##Heatmap range min
  text(ncolBands+4,-87,labels = paste(max(datMotionBoutCombined$boutRank) ,"#" )  )
  ##Draw 0 Vertical Line
  segments(0,-90,0,90); segments(-90,0,90,0); segments(-90,-90,90,90,lwd=2);
  dev.off()
  ## Plot arrows showing Bout Turns Connecting Bouts From Same Experiment
  #for (expID in unique(datMotionBoutCombined$expID) ) 
  #{
  #  datExp <- datMotionBoutCombined[datMotionBoutCombined$expID ==expID, ]
  #  for (ii in max(datExp$boutSeq):2) ##Draw Arrows Showing Sequence Of Bouts
  #    arrows(x0=datExp[ii,]$OnSetAngleToPrey, y0= datExp[ii,]$OnSetAngleToPrey-datExp[ii,]$OffSetAngleToPrey ,
  #          x1=datExp[ii-1,]$OnSetAngleToPrey, y1=datExp[ii-1,]$OnSetAngleToPrey-datExp[ii-1,]$OffSetAngleToPrey,
  #          length = 0.1)
  #}


} ## Go through each group - Extract Firstbout 

##Save List on First Bout Data
saveRDS(lFirstBoutPoints,file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData",".rds",sep="") ) #Processed Registry on which we add )



### FIRST Bout TURN COMPARISON BETWEEN GROUPS  ###
### Here We Need To Detect The 1st Turn To Prey , Not Just 1st Bout
pdf(file= paste(strPlotExportPath,"/BoutTurnsToPreyCompareFirstBoutOnly_All3.pdf",sep=""))
#X11()
  plot(lFirstBoutPoints[["DL"]][,1], lFirstBoutPoints[["DL"]][,2],
     main=paste("Turn Size Vs Bearing To Prey ", sep=""),
     xlab="Bearing To Prey prior to Bout",ylab="Bearing Change After Bout",xlim=c(-100,100),
     ylim=c(-100,100),
     col=colourP[1] ,pch=pchL[1]) ##boutSeq The order In Which The Occurred Coloured from Dark To Lighter
  ##Draw 0 Vertical Line
  segments(0,-90,0,90); segments(-90,0,90,0); segments(-90,-90,90,90,lwd=1,lty=2);
  text(lFirstBoutPoints[["DL"]][,1]+2,lFirstBoutPoints[["DL"]][,2]+5,labels=lFirstBoutPoints[["DL"]][,3],cex=0.8,col="darkblue")
  abline(lm(lFirstBoutPoints[["DL"]][,2] ~ lFirstBoutPoints[["DL"]][,1]),col=colourH[1],lwd=3.0) ##Fit Line / Regression
  #abline( lsfit(lFirstBoutPoints[["DL"]][,2], lFirstBoutPoints[["DL"]][,1] ) ,col=colourH[1],lwd=2.0)
  ##LL
  points(lFirstBoutPoints[["LL"]][,1], lFirstBoutPoints[["LL"]][,2],pch=pchL[2],col=colourP[2])
  text(lFirstBoutPoints[["LL"]][,1]+2,lFirstBoutPoints[["LL"]][,2]+5,labels=lFirstBoutPoints[["LL"]][,3],cex=0.8,col="darkgreen")
  abline(lm(lFirstBoutPoints[["LL"]][,2] ~ lFirstBoutPoints[["LL"]][,1]),col=colourH[2],lwd=3.0)
  #abline(lsfit(lFirstBoutPoints[["LL"]][,2], lFirstBoutPoints[["LL"]][,1] ) ,col=colourH[2],lwd=2.0)
  ##NL
  points(lFirstBoutPoints[["NL"]][,1], lFirstBoutPoints[["NL"]][,2],pch=pchL[3],col=colourP[3])
  text(lFirstBoutPoints[["NL"]][,1]+2,lFirstBoutPoints[["NL"]][,2]+5,labels=lFirstBoutPoints[["NL"]][,3],cex=0.8,col="darkred")
  abline(lm(lFirstBoutPoints[["NL"]][,2] ~ lFirstBoutPoints[["NL"]][,1]),col=colourH[3],lwd=3.0)
  #abline( lsfit(lFirstBoutPoints[["NL"]][,2], lFirstBoutPoints[["NL"]][,1] ) ,col=colourH[3],lwd=2.0)
  legend("topleft",legend=paste(c("DL n=","LL n=","NL n="),c(NROW(lFirstBoutPoints[["DL"]][,1]),NROW(lFirstBoutPoints[["LL"]][,1]) ,NROW(lFirstBoutPoints[["NL"]][,1] ) ) )
         , pch=pchL,col=colourL)

dev.off()



plot(lFirstBoutPoints[["NL"]][,1], lFirstBoutPoints[["NL"]][,2],pch=pchL[3],col=colourP[3]);


######## Make Colour Idx For Each Of the Distances - Based on ncolBands #######
##
vUniqDist <- unique(round(datMotionBoutCombinedAll$vMotionBoutDistanceToPrey_mm*10))
ncolBands <- 15
vcolIdx <-  vector() ; ##Distances Rounded / Indexed 
vdistToPrey <- round(datMotionBoutCombinedAll$vMotionBoutDistanceToPrey_mm*10)
maxDistanceToPrey <- 50
vdistToPrey[vdistToPrey>maxDistanceToPrey] <- maxDistanceToPrey-0.1
vcolBands <- seq(min(vUniqDist),maxDistanceToPrey,length.out = ncolBands) 
for (j in 1:NROW(datMotionBoutCombinedAll$vMotionBoutDistanceToPrey_mm)) 
  vcolIdx[j] <- min(which(vcolBands >  vdistToPrey[j] ))


Polarrfc <- colorRampPalette(rev(brewer.pal(15,'Spectral')));
colR <- c(Polarrfc( ncolBands ));


#X11()
pdf(file= paste(strPlotExportPath,"/BoutTurnsToPreyWithPreyDist_",strGroupID,".pdf",sep=""))
plot(datMotionBoutCombined$OnSetAngleToPrey,datMotionBoutCombined$OnSetAngleToPrey-datMotionBoutCombined$OffSetAngleToPrey,
     main=paste("Turn Size Vs Bearing To Prey ",strGroupID," + Distance" ),
     xlab="Bearing To Prey prior to Bout",ylab="Bearing Change After Bout",xlim=c(-90,90),
     ylim=c(-90,90),col=colR[vcolIdx] ,pch=19) ##boutSeq The order In Which The Occurred Coloured from Dark To Lighter
points(datMotionBoutCombined$OnSetAngleToPrey,datMotionBoutCombined$OnSetAngleToPrey-datMotionBoutCombined$OffSetAngleToPrey,
     main=paste("Turn Size Vs Bearing To Prey G",strGroupID ),
     xlab="Bearing To Prey prior to Bout",ylab="Bearing Change After Bout",xlim=c(-90,90),
     ylim=c(-90,90),col="Black" ,pch=16,cex=0.2) ##boutSeq The order In Which The Occurred Coloured from Dark To Lighter
##Draw 0 Vertical Line
segments(0,-90,0,90); segments(-90,0,  90,0); segments(-90,-90,90,90,lwd=2);
##Add HeatMap Legend
points(1:ncolBands,rep(-90, ncolBands), col=colR[1:ncolBands],pch=15) ##Add Legend Head Map
text(-3,-87,labels = paste(min(vUniqDist)/10,"mm" )  ) ##Heatmap range min
text(ncolBands+4,-87,labels = paste(maxDistanceToPrey/10,"mm" )  )

#dev.copy(pdf,file= paste(strPlotExportPath,"/BoutTurnsToPreyWithPreyDist_",groupID,".pdf",sep=""))
dev.off()
################# #### # ##  ## #

######  BOUTS Distribute Between Turn Bouts / Translation Bouts #############
## Note Point Where Translation?motion Is Measured Is nOt the Centre Of Rotation, so a turn causes apparent motion too.
## Exclude Strike Bouts ##
for (gp in strGroupID)
{
  groupID <- which(levels(datTrackedEventsRegister$groupID) == gp)
  X11()
  #pdf(file= paste(strPlotExportPath,"/BoutRotationVsTranslation_",gp,".pdf",sep=""))
  Polarrfc <- colorRampPalette(rev(brewer.pal(9,'Blues')));
  colR <- c("#000000",Polarrfc(max(datMotionBoutCombinedAll$boutRank)-2 ) ,"#FF0000"); ##Make Colour Range for Seq
  ncolBands <- NROW(colR)
  
  datMotionBoutFiltered <- datMotionBoutCombinedAll[datMotionBoutCombinedAll$boutRank > 1 & ##Exclude Strike Bout (Last One)
                                                    #  datMotionBoutCombinedAll$boutSeq > 1 & ##Exclude 1st Turn To Prey
                                                   datMotionBoutCombinedAll$groupID == groupID,]
  plot(datMotionBoutFiltered$vMotionBoutDistanceTravelled_mm,datMotionBoutFiltered$vTurnBoutAngle,
       main=paste(" Bout Translation Vs Bout Rotation ",gp),
       ylab="Turn Angle (deg)",
      xlab="Distance Travelled (mm)", 
      xlim=c(0,2),
      ylim=c(-90,90),
      #col=colR[vcolIdx]
      col= colR[datMotionBoutFiltered$boutSeq],  #colourL[as.numeric(datBoutVsPreyDistance$groupID)],
      pch= pchL[as.numeric(datMotionBoutFiltered$groupID)]
  ) ##Distinguise The Captcha Strikes
  
  labelY <- -50
  points(1:ncolBands/100,rep(labelY, ncolBands), col=colR[1:ncolBands],pch=15) ##Add Legend Head Map
  text(0.01,labelY-4,labels = paste(min(datMotionBoutFiltered$boutRank) ,"#" )  ) ##Heatmap range min
  text((ncolBands+4)/100,labelY-4,labels = paste(max(datMotionBoutFiltered$boutRank) ,"#" )  )
  
  #dev.off()
} ##End oF For Each Group

#### 




X11()
#plot(as.numeric(datMotionBoutCombined$boutRank),datMotionBoutCombined$vMotionBoutDistanceToPrey_mm,
#     main="Distance From Prey",ylab="mm",xlab="Bout Number")
boxplot(datMotionBoutCombined$vMotionBoutDistanceToPrey_mm ~ as.numeric(datMotionBoutCombined$boutRank),
        main=paste("Distance From Prey ",strGroupID),
        ylab="mm",
        xlab="Bout Sequence (From Capture - Backwards)")


X11()
layout(matrix( c(1,2,3), 3, 1,byrow=TRUE ) ) 
for (i in 1:NROW(strGroupID) )
{
  
  boxplot(as.numeric(datMotionBoutCombinedAll[datMotionBoutCombinedAll$groupID==i,]$OnSetAngleToPrey) ~ as.numeric(datMotionBoutCombinedAll[datMotionBoutCombinedAll$groupID==i,]$boutRank),
          main=paste("Bearing To Prey",strGroupID[i]),
          ylab="(Deg)",
          xlab="Bout Sequence (From Capture - Backwards)",
          ylim=c(-80,80))
}


X11()
#plot(datMotionBoutCombined$boutRank,datMotionBoutCombined$vMotionBoutDistanceTravelled_mm,main="Distance Of Bout (power)",ylab="mm")
boxplot(datMotionBoutCombined$vMotionBoutDistanceTravelled_mm ~datMotionBoutCombined$boutRank,
        main=paste("Distance Of Bout (power)",strGroupID),
        ylab="mm",
        xlab="Bout Sequence (From Capture - Backwards)")


X11()
#plot(datMotionBoutCombined$boutRank,datMotionBoutCombined$vMotionBoutDuration,main=" Bout Duration",ylab="msec",xlab="Bout Sequence (From Capture - Backwards)")
boxplot(datMotionBoutCombined$vMotionBoutDuration ~ datMotionBoutCombined$boutRank,
        main=paste(" Bout Duration",strGroupID),
        ylab="msec",
        xlab="Bout Sequence (From Capture - Backwards)")

#



##What is the relationship between IBI and the next turn Angle?
pdf(file= paste(strPlotExportPath,"/IBIVsTurnAngle_",strGroupID,".pdf",sep=""))
plot(datMotionBoutCombined$vMotionBoutIBI,datMotionBoutCombined$vTurnBoutAngle,
     main=paste("  Turn Angle Vs IBI",strGroupID),
     ylab="Size of Turn On Next Bout (Deg)",
     xlab="IBI (msec)")
dev.off()

# IBI VS NEXT Bout Power
##What is the relationship Between the Length Of Pause (IBI) and the Power of the next Bout
#X11()
pdf(file= paste(strPlotExportPath,"/IBIVsNextBoutTravel_",strGroupID,".pdf",sep=""))
plot(datMotionBoutCombined$vMotionBoutIBI,datMotionBoutCombined$vMotionBoutDistanceTravelled_mm,main=" Interbout Interval Vs Next Bout Distance Travelled ",
     ylab="Distance Travelled By Next Bout(mm)",
     xlab="IBI (msec)",pch=19,
     col=colR[vcolIdx]
     ) ##Distinguise The Captcha Strikes
points(datMotionBoutCombined[datMotionBoutCombined$boutRank == 1, ]$vMotionBoutIBI,datMotionBoutCombined[datMotionBoutCombined$boutRank == 1,]$vMotionBoutDistanceTravelled_mm,
       pch=9,
       col="red"
      )
##Add HeatMap Legend
points((1:ncolBands)*3 + 300,rep(5, ncolBands), col=colR[1:ncolBands],pch=15) ##Add Legend Head Map
text(300,5.2,labels = paste(min(vUniqDist)/10,"mm" )  ) ##Heatmap range min
text(ncolBands*3+300,5.2,labels = paste(maxDistanceToPrey/10,"mm" )  )
dev.off()

# IBI VS Prey Angle Change
X11()
plot(datMotionBoutCombined$vMotionBoutIBI,abs(datMotionBoutCombined$IBIAngleToPreyChange)/(datMotionBoutCombined$vMotionBoutIBI/1000),main=" IBI Vs Prey Angle During Interval ",
     ylab=" Angular Speed of Bearing-to-Prey during Interval (deg/sec)",
     xlab="IBI (msec)",pch=19,
     col=colR[vcolIdx],
     ylim=c(0,200)
) ##Distinguise The Captcha Strikes
##Distinguise The Captcha Strikes
points(datMotionBoutCombined[datMotionBoutCombined$boutRank == 1, ]$vMotionBoutIBI,
       abs(datMotionBoutCombined[datMotionBoutCombined$boutRank == 1, ]$IBIAngleToPreyChange)/(datMotionBoutCombined[datMotionBoutCombined$boutRank == 1, ]$vMotionBoutIBI/1000),
       pch=9,
       col=colR[vcolIdx[which(datMotionBoutCombined$boutRank == 1)] ],
       ylim=c(0,200)
)

#X11()
pdf(file= paste(strPlotExportPath,"/IBIVsPreyAngularSpeed_",levels(groupID)[groupID],".pdf",sep=""))
plot(datMotionBoutCombined$vMotionBoutIBI,abs(datMotionBoutCombined$IBIAngleToPreyLength)/(datMotionBoutCombined$vMotionBoutIBI/1000),
     main=" IBI Vs Prey AngularSpeed (From Path Length)  During Interval ",
     ylab=" Angular Speed of Bearing-to-Prey during Interval (deg/sec)",
     xlab="IBI (msec)",pch=19,
     col=colR[vcolIdx],
     ylim=c(0,200)
) ##Distinguise The Captcha Strikes
##Distinguise The Captcha Strikes
points(datMotionBoutCombined[datMotionBoutCombined$boutRank == 1, ]$vMotionBoutIBI,
       abs(datMotionBoutCombined[datMotionBoutCombined$boutRank == 1, ]$IBIAngleToPreyLength)/(datMotionBoutCombined[datMotionBoutCombined$boutRank == 1, ]$vMotionBoutIBI/1000),
       pch=9,
       col=colR[vcolIdx[which(datMotionBoutCombined$boutRank == 1)] ],
       ylim=c(0,200),
       cex=1.5
)
##Add HeatMap Legend
points((1:ncolBands)*3 + 300,rep(100, ncolBands), col=colR[1:ncolBands],pch=15) ##Add Legend Head Map
text(300,105.2,labels = paste(min(vUniqDist)/10,"mm" )  ) ##Heatmap range min
text(ncolBands*3+300,105.2,labels = paste(maxDistanceToPrey/10,"mm" )  )


dev.off()


#dev.off()

X11()
##How does IBI change With Bouts as the fish approaches the Prey?
boxplot( datMotionBoutCombined$vMotionBoutIBI ~ datMotionBoutCombined$boutRank,
         main=" Inter Bout Intervals ",
         ylab="msec",
         xlab="Bout Sequence (From Capture - Backwards)") 
# for (i in1:20) #dev.off()

########################################################################################
###          On PREY AZIMUTH AND DISTANCE ANALYSIS                                  ####
########### PLOT Polar Angle to Prey Vs Distance With Eye Vergence HeatMap ############
idx <- sample(idxLLSet,3)
cnt = 0

for (idxH in idxLLSet )# idxTestSet NROW(datTrackedEventsRegister) #1:NROW(datTrackedEventsRegister)
{
  pdf(file= paste(strPlotExportPath,"/HuntPaths/PreyAngleVsDistance_EyeVColouredB_LL-",idxH,".pdf",sep=""))  
  
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
  
  datPlaybackHuntEvent <- filterEyeTailNoise(datPlaybackHuntEvent)
  polarPlotAngleToPreyVsDistance(datPlaybackHuntEvent,newPlot=TRUE)
  idx <- idxH  
  mtext(paste("",idx,sep="",collapse=",")  ,side=3,outer = FALSE,col="red")
  
  dev.off()
}


plot(datPlaybackHuntEvent$LEyeAngle - datPlaybackHuntEvent$REyeAngle,col=colR[datPlaybackHuntEvent$LEyeAngle - datPlaybackHuntEvent$REyeAngle])

############


lrecAzimuth_NL  <- list();lhistAzimuth_NL  <- list();
lrecAzimuth_NL <- getPreyAzimuthForHuntEvents(datTrackedEventsRegister,datHuntEventMergedFrames,idxNLSet)
datAzi_NL <- do.call(rbind,lrecAzimuth_NL)
dNLb <- density(datAzi_NL$distPX*DIM_MMPERPX,bw=0.2,na.rm=TRUE)

lrecAzimuth_LL  <- list();lhistAzimuth_LL  <- list();
lrecAzimuth_LL <- getPreyAzimuthForHuntEvents(datTrackedEventsRegister,datHuntEventMergedFrames,idxLLSet)
datAzi_LL <- do.call(rbind,lrecAzimuth_LL)
dLLb <- density(datAzi_LL$distPX*DIM_MMPERPX,bw=0.2,na.rm=TRUE)

lrecAzimuth_DL  <- list();lhistAzimuth_DL  <- list();
lrecAzimuth_DL <- getPreyAzimuthForHuntEvents(datTrackedEventsRegister,datHuntEventMergedFrames,idxDLSet)
datAzi_DL <- do.call(rbind,lrecAzimuth_DL)
dDLb <- density(datAzi_DL$distPX*DIM_MMPERPX,bw=0.2,na.rm=TRUE)

axisAzi <- seq(-60,60,2)
axisDist <- seq(0,5,0.1)
lhistAzimuth_NL <- getPreyAzimuthBinHist(lrecAzimuth_NL,axisAzi,axisDist)
lhistAzimuth_LL <- getPreyAzimuthBinHist(lrecAzimuth_LL,axisAzi,axisDist)
lhistAzimuth_DL <- getPreyAzimuthBinHist(lrecAzimuth_DL,axisAzi,axisDist)

rfHot <- colorRampPalette(rev(brewer.pal(11,'Spectral')));


pdf(file= paste(strPlotExportPath,"/PreyAngleVsDistance_BinHist_LL.pdf",sep=""))

hGroupbinDensityLL <- Reduce('+', lhistAzimuth_LL)
sampleSize_LL  <- NROW(lrecAzimuth_LL) #Number of Larvae Used 
hotMap <- c(rfHot(sampleSize_LL*1),"#FF0000")
image(axisDist,axisAzi,hGroupbinDensityLL,axes=TRUE,
      col=hotMap,xlab="Distance (mm)",ylab="Prey Azimuth")

dev.off()

pdf(file= paste(strPlotExportPath,"/PreyAngleVsDistance_BinHist_NL.pdf",sep=""))

hGroupbinDensityNL <- Reduce('+', lhistAzimuth_NL)
sampleSize_NL  <- NROW(lrecAzimuth_NL) #Number of Larvae Used 
hotMap <- c(rfHot(sampleSize_NL*2),"#FF0000");
image(axisDist,axisAzi,hGroupbinDensityNL,axes=TRUE,
      col=hotMap,xlab="Distance (mm)",ylab="Prey Azimuth")
dev.off()


pdf(file= paste(strPlotExportPath,"/PreyAngleVsDistance_BinHist_DL.pdf",sep=""))
hGroupbinDensityDL <- Reduce('+', lhistAzimuth_DL)
sampleSize_DL  <- NROW(lrecAzimuth_DL) #Number of Larvae Used 
hotMap <- c(rfHot(sampleSize_DL*2),"#FF0000");
image(axisDist,axisAzi,hGroupbinDensityDL,axes=TRUE,
      col=hotMap,xlab="Distance (mm)",ylab="Prey Azimuth")
dev.off()


## Distribution / Likelihood of prey distance / Plot Distance to Prey Distributions
## "Distance to Prey During Hunt" 
plot(dNLb,col=colourLegL[1],xlim=c(0,5),lwd=3,lty=1,ylim=c(0,1),
     main=NA, #"Density Inference of Turn-To-Prey Slope ",
     xlab=NA,ylab=NA) #expression(paste("slope ",gamma) ) )
lines(dLLb,col=colourLegL[2],xlim=c(0,5),lwd=3,lty=2)
lines(dDLb,col=colourLegL[3],xlim=c(0,5),lwd=3,lty=3)
legend("topright",
       legend=c(  expression (),
                  bquote(NF["e"] ~ '#' ~ .(sampleSize_NL)  ),
                  bquote(LF["e"] ~ '#' ~ .(sampleSize_LL)  ),
                  bquote(DF["e"] ~ '#' ~ .(sampleSize_DL)  )  ), ##paste(c("DL n=","LL n=","NL n="),c(NROW(lFirstBoutPoints[["DL"]][,1]),NROW(lFirstBoutPoints[["LL"]][,1]) ,NROW(lFirstBoutPoints[["NL"]][,1] ) ) )
       col=colourLegL,lty=c(1,2,3),lwd=3)
mtext(side = 1,cex=0.8, line = 2.2, expression(paste("Distance to prey (mm) ") ))
mtext(side = 2,cex=0.8, line = 2.2, expression("Density ") )
mtext("B",at="topleft",outer=outer,side=2,col="black",font=2,las=las,line=line,padj=padj,adj=adj,cex.main=cex)
###

## Explanatory Variable for Prey Dist could be Delta (PreyAzimuth) lower = c(0.1,0.1),
gammaLL <- fitdist( datAzi_LL[!is.na(datAzi_LL$distPX),]$distPX*DIM_MMPERPX,"gamma",start = list(scale = 2, shape = 1)) #,start = list(scale = 1, shape = 1)
gammaDL <- fitdist( datAzi_DL[!is.na(datAzi_DL$distPX),]$distPX*DIM_MMPERPX,"gamma",start = list(scale = 2, shape = 1)) #,start = list(scale = 1, shape = 1)
gammaNL <- fitdist( datAzi_NL[!is.na(datAzi_NL$distPX),]$distPX*DIM_MMPERPX,"gamma",start = list(scale = 2, shape = 1)) #,start = list(scale = 1, shape = 1)

plot(gammaLL)
plot(gammaDL)
plot(gammaNL)


plot(lrecAzimuth[[cnt]]$distPX*DIM_MMPERPX,lrecAzimuth[[cnt]]$azimuth)

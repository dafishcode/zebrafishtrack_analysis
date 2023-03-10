## Processing Of Tracker Eye TrackerData, Using R 
# Kostasl Nov 2017
# 10-12-17 : Fixed Error on counting number of hunting episodes
#            Converted to Adding A Row for empty data files such that larva That were tested but produced no data count towards the mean / The case that a fish is invalid should be actually handled when testing in empty conditions and reject a fish that does nothing
#            Otherwise, a non appearing fish counts towards the group mean since its tested for a fixed amount of time (10mins each fish)
# 14-12-17 :  Added MotionTrajectory Analysis - PathLengths/Speed/Ratio #frames(Speed>0) over All ANalysed Event Frames Of A Larva 
#            
# Consider What the Hunt Ratio Is On a No Show Larva? Currently Set To 0 - 
#TODO: Add Colour Marker of Hunting On Trajectories
# ## Pio Eykolo Na diaspasoume to Atomo Para mia prokatalipsi ##
library(tools)
library("MASS");
#library(data.table) ##Required for rBindList
#library(hexbin)


###### SABINA you can change the Following Label To choose the subset of events you wish to label 
## remove the # to UNCOMMENT
str_FilterLabel <- "NA"  #<< Choose this For The 
#str_FilterLabel <- "UnLabelled" ###<<-- Revert to this for Going Though New data

####################


# 
## Office PC
setwd("/home/sabina/zfishLabel/")
strVideoFilePath  <- "/media/LinuxDat/expDataKostas/AnalysisSetAlpha/" 
#strVideoFilePath  <- "/media/sabina/zfishDataAlpha/AnalysisSetAlpha/" 
#strTrackerPath    <- "/home/sabina/zfishLabel/build-zebraprey_track-Desktop_Qt_5_9_2_GCC_64bit-Release/"
strTrackerPath    <- "/home/sabina/zfishLabel/build-zebraprey_track-Desktop_Qt_5_11_1_GCC_64bit-Release/"
strTrackeroutPath <- "/home/sabina/zfishLabel/out/"
strTrackInputPath <- "/media/LinuxDat/TrackerOut/TrackASetRepeat/" ##Where to source the Tracker csv files from 
strDatDir        <- "./dat/" ##Where Are the Imported RData Stored
strDataExportDir <- "./out/"


DIM_PXRADIUS <- 790 #Is the Radius Of the dish In the Video
DIM_MMPERPX <- 35/DIM_PXRADIUS ##35mm Opening of The viewport Assumed
G_APPROXFPS              <- 420
G_THRESHUNTANGLE         <- 19 #Define Min Angle Both Eyes need for a hunting event to be assumed
G_THRESHUNTVERGENCEANGLE <- 45 ## When Eyes pointing Inwards Their Vergence (L-R)needs to exceed this value for Hunting To be considered
G_THRESHCLIPEYEDATA      <- 40 ##Limit To Which Eye Angle Data is filtered to lie within
G_MINGAPBETWEENEPISODES  <- 300
G_MINEPISODEDURATION     <- 100
G_MIN_BOUTSPEED          <- 0.05 ##px/frame - Need to be above to be considered A Motion Bout
PREY_COUNT_FRAMEWINDOW   <- 1600 ##Number oF Frames Over which to count Prey Stats at Beginning And End Of Experiments

nFrWidth                 <- 20 ## Sliding Window Filter Width - Reduced From 50 to 20 to improve Meanf sliding window speed estimation lags


strDataSetDirectories <- paste(strTrackInputPath, list(
                              "/Tracked12-10-17/", ##Dataset 1
                              "/Tracked26-10-17/",
                              "/Tracked02-11-17/",##MDataset 3 -NOTE: Does not Larva ID on File Name 
                              "Tracked08-11-17/", #4 350fps - Missing a condition WTDryFed3Roti - So removed One Set Larva of Data from other conditions to balance the dataset
                              "/Tracked16-11-17/",#5 400fps - Strict Timer Dataset
                              "/Tracked30-11-17/",#6 420fps
                              "/Tracked07-12-17/",#7
                              "/Tracked14-12-17/",#8
                              "Tracked21-12-17/",
                              "/Tracked11-01-18/",
                              "/Tracked18-01-18/",
                              "/Tracked25-01-18/",
                              "/Tracked01-02-18/",
                              "/Tracked08-02-18/",
                              "/Tracked15-02-18/",
                              "/Tracked22-02-18/",
                              "/Tracked_07-06-18/",##Dataset 17 
                              "/Tracked14-06-18/"##Dataset n ##Dataset n 
                              ),sep="/")
##Add Source Directory
strCondR  <- "*.csv"; 


### Set Colour Pallette Size from List Of Datasets
G_DATASETPALLETSIZE = NROW(strDataSetDirectories)

#source("HuntingEventAnalysis.r")
#source("TrajectoryAnalysis.r")
source("labelHuntEvents.r")


firstDataSet = NROW(strDataSetDirectories)-11
lastDataSet = NROW(strDataSetDirectories)
dataSetsToProcess = seq(from=firstDataSet,to=lastDataSet)


#message(paste(" Loading Hunt Event List to Validate... "))
#strDataFileName <- paste("setn",NROW(dataSetsToProcess),"HuntEvents","KL","ALL",sep="-") ##To Which To Save After Loading
#load(file=paste(strDatDir,"/LabelledSet/",strDataFileName,".RData",sep="" )) ##Save With Dataset Idx Identifier
#datHuntEventAllGroupToValidate <- datHuntEventAllGroup

##Load The List To process

#strProcDataFileName <-paste("setn",NROW(dataSetsToProcess),"-D",firstDataSet,"-",lastDataSet,"-","HuntEvents-Merged",sep="") ##To Which To Save After Loading
#strProcDataFileName <- paste("setn",NROW(dataSetsToProcess),"HuntEvents","SB","ALL",sep="-") ##To Which To Save After Loading
#strProcDataFileName <- "setn14-HuntEventsFixExpID-SB-Updated"
strProcDataFileName <- "setn15-HuntEvents-SB-Updated-Merged"
message(paste(" Loading Hunt Event List to Process... "))
#load(file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".RData",sep="" )) ##Save With Dataset Idx Identifier
datHuntEventAllGroupToLabel <- readRDS(file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".rds",sep="" ))
 ##<- datHuntEvent
groupsList <- c("DL","NL","LL") ##unique(datHuntEventAllGroupToLabel$groupID)

##Select Randomly From THe Already Labelled Set ##
##Main Sample Loop
Keyc <- 'n'
while (Keyc != 'q')
{
  Keyc <- readline(prompt="### Press q to exit, 'n' for next, or type event number you wish to label  :")
  
  if (Keyc == 'q')
    break

  TargetLabel = which(vHuntEventLabels == str_FilterLabel)-1;
  gc <- sample(groupsList,1)
  idx <- NA
  TargetLabels <- vHuntEventLabels
  
  if (Keyc == 'n')
  {
    ##Choose From THe Set Of Videos Already Labelled From Another User (Kostasl) So as to Verify The Label # Sample Only From THose ExpID that have not been already verified
    #datHuntEventPool <- datHuntEventAllGroupToValidate[datHuntEventAllGroupToValidate$huntScore != "UnLabelled" & datHuntEventAllGroupToValidate$eventID != 0
    #                                           & (datHuntEventAllGroupToValidate$expID %in% datHuntEventAllGroupToLabel[datHuntEventAllGroupToLabel$huntScore == TargetLabel,]$expID ),]
    
    datHuntEventPool <- datHuntEventAllGroupToLabel[datHuntEventAllGroupToLabel$eventID != 0 & datHuntEventAllGroupToLabel$groupID == gc,]
    datHuntEventPool <- datHuntEventPool[ datHuntEventPool$huntScore == TargetLabel,]
    expID <- resample(datHuntEventPool$expID,1)
    datHuntEventPool <- datHuntEventPool[datHuntEventPool$expID == expID ,]
    eventID <- resample(c(datHuntEventPool$eventID),1)
    ###
    TargetLabels <- vHuntEventLabels[vHuntEventLabels== str_FilterLabel]
  }
  ##Extract If Any Numbers In Input/ Then User Picked a specific Row
  if (!is.na(as.numeric(gsub("[^0-9]","",Keyc)) ) )
  {
    message(paste("Goto Event:",Keyc ) )
    idx <- as.character(Keyc) ##Note It acts as key only as string, numeric would just bring out the respective order idx record
    datHuntEventPool <- datHuntEventAllGroupToLabel[idx,]
    expID <- datHuntEventPool$expID
    eventID <- datHuntEventPool$eventID
    TargetLabels <- vHuntEventLabels
    
    if (is.na(datHuntEventAllGroupToLabel[idx,]$expID))
    {
      message("Event Not Found")
      next
    }
  }

  
  datHuntEventAllGroupToLabel <- labelHuntEvents(datHuntEventAllGroupToLabel,
                                                 strProcDataFileName,strVideoFilePath,
                                                 strTrackerPath,strTrackeroutPath,
                                                 TargetLabels,expID,eventID,idx)
  
  ##Saving is done in labelHuntEvent on Every loop - But repeated here
  save(datHuntEventAllGroupToLabel,file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".RData",sep="" )) 
  save(datHuntEventAllGroupToLabel,file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,"-backup.RData",sep="" )) ##Save With Dataset Idx Identifier
  saveRDS(datHuntEventAllGroupToLabel,file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".rds",sep="" ))
  message(paste("Saved :",strDatDir,"/LabelledSet/",strProcDataFileName,".rds",sep="") )
  message(paste("Saved :",strDatDir,"/LabelledSet/",strProcDataFileName,".RData",sep="") )
  
  
}

tblRes <- table(convertToScoreLabel(datHuntEventAllGroupToLabel$huntScore),datHuntEventAllGroupToLabel$groupID)
write.csv(tblRes,file=paste(strDatDir,"/LabelledSet/","tbLabelHuntEventSummary-SB.csv",sep="") )

lLabelSummary <- list()
nLabelledDL <- sum(tblRes[2:13,"DL"])
nLabelledLL <- sum(tblRes[2:13,"LL"])
nLabelledNL <- sum(tblRes[2:13,"NL"])


message(paste("HuntEvents Labelled (exclude NA) #DL:",nLabelledDL,"#LL:",nLabelledLL,"#NL:",nLabelledNL ) )
lLabelSummary$HuntEventCount <- list(DL=nLabelledDL,LL=nLabelledLL,NL=nLabelledNL)
lLabelSummary$Success <- list(DL=sum(tblRes[c(3,12),"DL"]),LL=sum(tblRes[c(3,12),"LL"]),NL=sum(tblRes[c(3,12),"NL"]) )
lLabelSummary$SuccessRatio <- list(DL=lLabelSummary$Success$DL/lLabelSummary$HuntEventCount$DL,LL=lLabelSummary$Success$LL/lLabelSummary$HuntEventCount$LL,NL=lLabelSummary$Success$NL/lLabelSummary$HuntEventCount$NL )

##   Can COMPARE Two Labelling Sets Using : ########
#huntComp <- compareLabelledEvents(datHuntEventsSB,datHuntEventsKL)
#huntComp$huntScore <- convertToScoreLabel(huntComp$huntScore) ##Convert to Labels
#huntComp$huntScoreB <- convertToScoreLabel(huntComp$huntScoreB)
#huntComp[huntComp$huntScore != huntComp$huntScoreB & huntComp$huntScore != "UnLabelled",] ##Bring Out The labelled Mismatches
##Compare:
#tblLabelCompare <- table(huntComp$huntScore, huntComp$huntScoreB) ##COlumns is HuntEventB scores
#write.csv(tblLabelCompare,file=paste(strDatDir,"/LabelledSet/","tblCompareLabellingSummary.csv",sep="") )
##########################
####

# 
# 
# ########################################## SUMMARY OF LABELLING #####################
# ##How to Summarize Success / Fail Scores :
# gc <- "LL"
# strDataFileName <- paste("setn",NROW(dataSetsToProcess),"HuntEvents",gc,sep="-") ##To Which To Save After Loading
# load(file=paste(strDatDir,"/",strDataFileName,".RData",sep="" )) ##Save With Dataset Idx Identifier
# datHuntEvent$huntScore <- convertToScoreLabel( datHuntEvent$huntScore)##Set To NoTHuntMode
# message(paste(NROW(datHuntEvent[datHuntEvent$huntScore != "UnLabelled",]),"/",NROW(datHuntEvent), " Data has already been labelled" ) )
# tblLLStat <- table(datHuntEvent$huntScore)
# write.csv(tblLLStat,file="tbLLHuntLabelStat.csv")
# 
# nFailLL <- tblLLStat[[4]]+tblLLStat[[5]]+tblLLStat[[10]]+tblLLStat[[11]]
# nSuccessLL <- tblLLStat[[3]]+tblLLStat[[12]]
# 
# 
# gc <- "NL"
# strDataFileName <- paste("setn",NROW(dataSetsToProcess),"HuntEvents",gc,sep="-") ##To Which To Save After Loading
# load(file=paste(strDatDir,"/",strDataFileName,".RData",sep="" )) ##Save With Dataset Idx Identifier
# datHuntEvent$huntScore <- convertToScoreLabel( datHuntEvent$huntScore)##Set To NoTHuntMode
# message(paste(NROW(datHuntEvent[datHuntEvent$huntScore != "UnLabelled",]),"/",NROW(datHuntEvent), " Data has already been labelled" ) )
# tblNLStat <- table(datHuntEvent$huntScore)
# write.csv(tblNLStat,file="tbNLHuntLabelStat.csv")
# 
# nFailNL <- tblNLStat[[4]]+tblNLStat[[5]]+tblNLStat[[10]]+tblNLStat[[11]]
# nSuccessNL <- tblNLStat[[3]]+tblNLStat[[12]]
# 
# 
# gc <- "DL"
# strDataFileName <- paste("setn",NROW(dataSetsToProcess),"HuntEvents",gc,sep="-") ##To Which To Save After Loading
# load(file=paste(strDatDir,"/",strDataFileName,".RData",sep="" )) ##Save With Dataset Idx Identifier
# datHuntEvent$huntScore <- convertToScoreLabel( datHuntEvent$huntScore)##Set To NoTHuntMode
# message(paste(NROW(datHuntEvent[datHuntEvent$huntScore != "UnLabelled",]),"/",NROW(datHuntEvent), " Data has already been labelled" ) )
# tblDLStat <- table(datHuntEvent$huntScore)
# write.csv(tblDLStat,file="tbDLHuntLabelStat.csv")
# 
# nFailDL <- tblDLStat[[4]]+tblDLStat[[5]]+tblDLStat[[10]]+tblDLStat[[11]]
# nSuccessDL <- tblDLStat[[3]]+tblDLStat[[12]]
# 
# message(paste("Rates:",nSuccessLL/nFailLL,nSuccessNL/nFailNL,nSuccessDL/nFailDL,sep="  "))
# ###
# 
# 
# ######## CALC Stat On Hunt Events ######
# ## Re-process Hunt Stat On Modified Events
# source("HuntingEventAnalysis.r")
# lHuntStat <- list()
# groupsrcdatList <- groupsrcdatListPerDataSet[[NROW(groupsrcdatListPerDataSet)]] ##Load the groupsrcdatListPerDataSetFile
# strCondTags <- names(groupsrcdatList)
# for (i in strCondTags)
# {
#   message(paste("#### ProcessGroup ",i," ###############"))
#   strDataFileName <- paste("out/setn",NROW(dataSetsToProcess),"HuntEvents",i,sep="-") ##To Which To Save After Loading
#   message(paste(" Loading Hunt Events: ",strDataFileName))
#   ##ExPORT 
#   load(file=paste(strDataFileName,".RData",sep="" )) ##Save With Dataset Idx Identifier
#   
#   datHuntEvent$huntScore <- factor(x=datHuntEvent$huntScore,levels=c(0,1,2,3,4,5,6,7,8,9,10,11,12,13),labels=vHuntEventLabels )##Set To NoTHuntMode
#   ##Filter Hunt Events ##
#   datHuntEventFilt <- datHuntEvent[datHuntEvent$huntScore != "NA" &
#                                    datHuntEvent$huntScore != "Not_HuntMode/Delete" &
#                                    datHuntEvent$huntScore != "Out_Of_Range" & 
#                                    datHuntEvent$huntScore != "Duplicate/Overlapping" &
#                                    datHuntEvent$huntScore != "Near-Hunt State" |
#                                    datHuntEvent$eventID   == 0 , ] ##Keep THose EventID 0 so as to identify All experiments - even those with no events
#   
#   
#   lHuntStat[[i]] <- calcHuntStat3(datHuntEventFilt)
# }
# 
# datHuntStat = do.call(rbind,lHuntStat)#
# ################
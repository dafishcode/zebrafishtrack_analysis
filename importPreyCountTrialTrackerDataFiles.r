## Author KL Nov. 2018 : Made for the analysis of feeding experiments with MSc. Student Dylan Feldner-Busztin.
## The experiment has the same rearing conditionas the NF, LF, DF and then takes short videos
## of 30 sec of individual fish 35mm at different time points 0,30,60,90min checking the rotifer count 
## as reported in the csv by the tracker .

source("TrackerDataFilesImport_lib.r")


### [plot the change in rotifer count / normalized to starting values for the data.frame]
## Assumes datGroupFrames contains frames with rotifer count for one specific group ##
## call par(new=TRUE) to add plots together ##
plotPreyCountConsumptionNorm <- function(datGroupFrames)
{
  groupID <- which(strGroupID == unique(datGroupFrames$group) )
  lLarvaRec <- getAggregateConsumptionDataList(datGroupFrames)
  
  ###[plot results]
  plot(lLarvaRec[[1]]$time,lLarvaRec[[1]]$normRec,type="l",ylim=c(0,1.1),xlim=c(0,140),
       xlab="time (min)",ylab="rotifer percentage",
       main="Normalized Consumption",
       col=colourP[groupID],add=T)
  for (lID in vLarvaID)
  {
    lines(lLarvaRec[[lID]]$time,lLarvaRec[[lID]]$normRec,type="l",col=colourP[groupID],
          ylim=c(0,1.1),xlim=c(0,140))
    points(lLarvaRec[[lID]]$time,lLarvaRec[[lID]]$normRec,pch=pchL[groupID])
  }
  
  
  
} ## end of plot function

## Organizes the Data frames from the Consumption experiment on a per larva basis
### Calculates norm and diff consumption 
getAggregateConsumptionDataList <- function(datGroupFrames)
{
  
  
  summaryDat <- aggregate(datGroupFrames$PreyCount~datGroupFrames$expID+datGroupFrames$time+datGroupFrames$larvaID,
                          FUN=median)
  vLarvaID <- unique(datGroupFrames$larvaID)
  datConsumption <- summaryDat
  names(datConsumption) <- c("expID","time","larvaID","PreyCount")
  lLarvaRec <- list()
  
  for (lID in vLarvaID)
  {
    LarvaRec <- datConsumption[datConsumption$larvaID == lID ,]
    InitRec <- LarvaRec[ LarvaRec$time == 0,]
    normRec <- LarvaRec$PreyCount / InitRec$PreyCount
    diffRec <- LarvaRec$PreyCount - InitRec$PreyCount
    LarvaRec <- cbind(LarvaRec,normRec,diffRec)
    
    lLarvaRec[[lID]] <- LarvaRec
    
  }
  
  return(lLarvaRec)
}

## Plot the change in rotifer Count
plotPreyCountConsumptionChange <- function(datGroupFrames)
{
  groupID <- which(strGroupID == unique(datGroupFrames$group) )
  lLarvaRec <- getAggregateConsumptionDataList(datGroupFrames)
  
  ###[plot  Change results]
  plot(lLarvaRec[[1]]$time,lLarvaRec[[1]]$diffRec,type="l",ylim=c(-25,10),xlim=c(0,140),
       xlab="time (min)",ylab="Change in prey count ",
       main="Consumption Change",
       col=colourP[groupID],add=T)
  for (lID in vLarvaID)
  {
    lines(lLarvaRec[[lID]]$time,lLarvaRec[[lID]]$diffRec,type="l",col=colourP[groupID],
          ylim=c(0,1.1),xlim=c(0,140))
    points(lLarvaRec[[lID]]$time,lLarvaRec[[lID]]$diffRec,pch=pchL[groupID])
  }
  

  
} ## end of  Changeplot function



#################IMPORT TRACKER FILES # source Tracker Data Files############################### 

##Add Source Directory
strDataSetDirectories <- paste(strTrackInputPath, list(
  "TrackedDylan/TrackedDylan_29-11-18/" ##Dataset 1
),sep="/")



groupsrcdatListPerDataSet <- list()
datAllSets <-list()
n <- 0
#### List Of Data files / and result label assuming organized in Directory Structure ###
for ( idxDataSet in 1:length(strDataSetDirectories) )
{
  n <- n +1
  d < strDataSetDirectories[[idxDataSet]]
  groupsrcdatList = list()
  nameDat <- list()
  strCondR  <- "*.csv"; 
  groupsrcdatList[["LL"]] <- list(getFileSet("LiveFed/",d),"-LiveFed")
  
  groupsrcdatList[["NL"]] <- list(getFileSet("NotFed/",d),"-NotFed")

  strTmp <- groupsrcdatList[["LL"]][[1]][1]
  #### Extract File Name Info ###
  message(paste(1,". Filtering Data :",  strTmp))

  #lNameFields<- extractFileNameParams_preycountExp(strTmp)
  
  ##Extract Larva ID - Identifies larva in group across food condition - ie which larva in Empty group is the same one in the fed group
  #NOTE: Only Available In files names of more Recent Experiments
  larvaID <- as.integer( gsub("[^0-9]","",brokenname[[1]][length(brokenname[[1]])-4]) )
  if(!is.numeric(larvaID)  ) ##Check As it Could Be missing
  {
    larvaID <- NA
    warning(paste("No LarvaID In Filename ",temp[[j]] ) )
  }
  
  #Filter Out Empty Files - ones with less than 300 frames ( ~1 sec of data )
  if (!is.numeric(expID) | !is.numeric(eventID) | is.na(expID) | is.na(eventID)  ) 
  {
    #expID <- j
    #message(paste("Auto Set To expID:",expID))
    stop(paste("Could not extract Larva ID and event ID from File Name ",temp[[j]]))
  }
  
  stopifnot(!is.na(expID))
  stopifnot(!is.na(eventID))
  
  
  
  ##OutPutFIleName
  strDataSetIdentifier <- strsplit(d,"/")
  strDataSetIdentifier <- strDataSetIdentifier[[1]][[ length(strDataSetIdentifier[[1]]) ]]
  strDataFileName <- paste(strDataExportDir,"/setn1_Dataset_", strDataSetIdentifier,".RData",sep="") ##To Which To Save After Loading
  strDataFileNameRDS <- paste(strDataExportDir,"/setn1_Dataset_", strDataSetIdentifier,".rds",sep="") ##To Which To Save After Loading
  message(paste(" Importing to:",strDataFileName))

  
  
  ##RUN IMPORT FUNCTION
  datAllFrames <-importTrackerFilesToFrame(groupsrcdatList,"extractFileNameParams_preycountExp")
  datAllFrames$dataSet <- idxDataSet ##Identify DataSet
  
  datAllSets[[n]] <- datAllFrames
  
  ##CHeck If Exp Ids not found 
  stopifnot(NROW(datAllFrames[which(is.na(datAllFrames$expID)), ]) == 0)
  
  groupsrcdatListPerDataSet[[idxDataSet]] <- groupsrcdatList 
  save(datAllFrames,groupsrcdatList,file=strDataFileName) ##Save With Dataset Idx Identifier
  saveRDS(datAllFrames, file = strDataFileNameRDS)
  
  #idxDataSet = idxDataSet + 1
} ##For Each DataSet Directory
#### END OF IMPORT TRACKER DATA ############

##Save the File Sources and all The Frames Combined - Just In case there are loading Problems Of the Individual RData files from each set
save(groupsrcdatListPerDataSet,file=paste(strDataExportDir,"/groupsrcdatListPerDataSet",strDataSetIdentifier,"_Ds-",1,"-",idxDataSet,".RData",sep=""))

#datAllFrames <- rbindlist(datAllSets);
datAllFrames = do.call(rbind,datAllSets);
save(datAllFrames,file=paste(strDataExportDir,"datAllFrames",strDataSetIdentifier,"_Ds-",1,"-",idxDataSet,".RData",sep=""))

## SHow/plot Summary ##
datLL <- datAllFrames[datAllFrames$group=="LL",]
datNL <- datAllFrames[datAllFrames$group=="NL",]
summaryDatNL <- aggregate(datNL$PreyCount~datNL$expID+datNL$time+datNL$larvaID,FUN=mean)
summaryDatLL <- aggregate(datLL$PreyCount~datLL$expID+datLL$time+datLL$larvaID,FUN=mean)

pdf(file= paste(strPlotExportPath,"/ConsumptionSampling_",strDataSetIdentifier,".pdf",sep=""))
plot(summaryDatNL$`datNL$time`,summaryDatNL$`datNL$PreyCount`,col="red",pch=9,
     xlab="time (min)",ylab="rotifer count",main="Consumption Sampling experiment")
points(summaryDatLL$`datLL$time`,summaryDatLL$`datLL$PreyCount`,col="black",pch=1)
legend("topright",legend=c("NL","LL"),pch=c(9,1),col=c("red","black") )
dev.off()

### [Plot Normalized Consumption Timeline]
pdf(file= paste(strPlotExportPath,"/ConsumptionSamplingNormalized_",strDataSetIdentifier,".pdf",sep=""))
plotPreyCountConsumptionNorm(datLL)
par(new=TRUE)
plotPreyCountConsumptionNorm(datNL)
legend("topright",legend=c("NL","LL"),pch=c(pchL[3],pchL[2])) # c(colourH[3],colourH[2])
par(new=FALSE)
dev.off()



### [Plot Change Consumption Timeline]
pdf(file= paste(strPlotExportPath,"/ConsumptionSamplingChange_",strDataSetIdentifier,".pdf",sep=""))
plotPreyCountConsumptionChange(datLL)
par(new=TRUE)
plotPreyCountConsumptionChange(datNL)
legend("topright",legend=c("NL","LL"),pch=c(pchL[3],pchL[2])) # c(colourH[3],colourH[2])
par(new=FALSE)
dev.off()

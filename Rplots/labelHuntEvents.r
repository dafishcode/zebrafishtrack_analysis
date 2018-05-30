## Used to Manually Label The hunt Events Stored In datHuntEvent ##
##strVideoFilePath = "/home/kostasl/workspace/build-zebraprey_track-Desktop-Debug"
## Kostas Lagogiagiannis 2018 Jan
## Run The tracker Specifically on video frames isolating the Hunt Events - let the user label if the event was succesful or not

##To Execute The QT tracker application We may need to give the QT library Path - (xcb error)
#Sys.setenv(LD_LIBR4ARY_PATH="/home/kostasl/Qt/5.9.2/gcc_64/lib/" )
##Check If Qt Is already Added To Exec Path
if (grepl("Qt",Sys.getenv("LD_LIBRARY_PATH") )  == FALSE) 
{
  Sys.setenv(LD_LIBRARY_PATH="")
  #Sys.setenv(LD_LIBRARY_PATH=paste(Sys.getenv("LD_LIBRARY_PATH"),"",sep=":" ) ) 
  Sys.setenv(LD_LIBRARY_PATH=paste(Sys.getenv("LD_LIBRARY_PATH"),"/opt/Qt/5.9/5.9/gcc_64/lib",sep=":" ) ) ##Home PC/
  Sys.setenv(LD_LIBRARY_PATH=paste(Sys.getenv("LD_LIBRARY_PATH"),"/home/kostasl/Qt/5.9.2/gcc_64/lib/",sep=":" ) ) ####Office
  Sys.setenv(LD_LIBRARY_PATH=paste(Sys.getenv("LD_LIBRARY_PATH"),"/usr/lib/x86_64-linux-gnu/",sep=":" ) )
}

vHuntEventLabels <- c("UnLabelled","NA","Success","Fail","No_Target","Not_HuntMode/Delete","Escape","Out_Of_Range","Duplicate/Overlapping","Fail-No Strike","Fail-With Strike",
                      "Success-SpitBackOut",
                      "Debri-Triggered","Near-Hunt State")

convertToScoreLabel <- function (huntScore) { 
  return (factor(x=huntScore,levels=c(0,1,2,3,4,5,6,7,8,9,10,11,12,13),labels=vHuntEventLabels ) )
}

huntLabels <- convertToScoreLabel(5) #factor(x=5,levels=c(0,1,2,3,4,5,6,7,8,9,10,11,12,13),labels=vHuntEventLabels )##Set To NoTHuntMode


labelHuntEvents <- function(datHuntEvent,strDataFileName,strVideoFilePath,strTrackerPath,strTrackOutputPath,factorLabelFilter)
{
  message(paste(NROW(datHuntEvent[datHuntEvent$huntScore >0,]),"/",NROW(datHuntEvent), " Data has already been labelled" ) )
  nLabelledSuccess <- NROW(datHuntEvent[datHuntEvent$huntScore == which(levels(huntLabels) == "Success") | datHuntEvent$huntScore == which(levels(huntLabels) == "Success-SpitBackOut"),])
  readline(prompt="-.Begin Data labelling.-")
  
  
  for (i in  (1:NROW(datHuntEvent)) )
  {
    rec <- datHuntEvent[i,] 
    
    ##Added Later To Struct Is  A Flag that a Hunt Event Has been Retracked - adding the food target
    if (any(names(datHuntEvent)=="markTracked")  ) ##This Marks Videos that have been Labelled and Retracked For anal
      if (!is.na(rec$markTracked))
        if (rec$markTracked == 1)
      next ##SKip Record if previously Labelled
    
    
    if (rec$huntScore != factorLabelFilter  ) ##&& rec$huntScore != (which(levels(huntLabels)=="NA")-1)
        next ##SKip Record if previously Labelled

    ##For Larva That Did not register any sufficient Hunting Events -  An Empty Record has been added To Acknowledge 
    if (rec$eventID == 0 & rec$huntScore == 0)
    {##Set To Not Hunt Event/Delete - So as to Ignore In Hunt Event Counts
      datHuntEvent[i,]$huntScore = huntLabels
      next
    }
      
    ##Get Respective Video  Filename / Path
    strVideoFile <- list.files(path =strVideoFilePath, pattern = rec$filenames , all.files = FALSE,
               full.names = TRUE, recursive = TRUE,
               ignore.case = FALSE, include.dirs = FALSE, no.. = FALSE)
    
    if (!file.exists(strVideoFile) )
      stop(paste("Could not find video file: ",strVideoFile ) )
    
    
    message(paste("\n",i,". Examining Hunt Event of Larva:",rec$expID," Event:",rec$eventID, "Video:",rec$filenames, " -s:",max(0,rec$startFrame-1)," -e:",rec$endFrame) )
    ##--
    strArgs = paste(" --ModelBG=0 --SkipTracked=0 --PolygonROI=1 --invideofile=",strVideoFile," --outputdir=",strTrackOutputPath," --startframe=",max(0,rec$startFrame-1)," --stopframe=",rec$endFrame," --startpaused=1",sep="")
    message(paste(strTrackerPath,"/zebraprey_track",strArgs,sep=""))
    execres <- base::system2(command=paste(strTrackerPath,"/zebraprey_track",sep=""),args =  strArgs,stdout="",stderr=TRUE)
    
    ## execres contains all of the stdout - so cant be used for exit code
    #stopifnot(execres == 0 ) ##Stop If Application Exit Status is not success
    ##Show Labels And Ask Uset input after video is examined
    Keyc = 1000 ##Start With Out Of Range Value
    failInputCount = 0
    flush(con=stdin())
    flush(con=stdout())
    
    ##Log Updates to Separate File ## 
    bColNames = FALSE
    ### MENU  LOOP ###
    while ( (Keyc != 'c' | Keyc != 's')  & failInputCount < 3 | nchar(Keyc) > 1) #is.na(factor(levels(huntLabels)[as.numeric(Keyc)] ) ) 
    {
      l <- 0
      
      setLabel <- factor(x=rec$huntScore,levels=c(0,1,2,3,4,5,6,7,8,9,10,11,12,13),labels=vHuntEventLabels )
      message(paste("### Event's ",i, " Current Label is :",setLabel," ####" ) )
      message(paste("### Set Options Hunt Event of Larva:",rec$expID," Event:",rec$eventID, "Video:",rec$filenames, " -s:",max(0,rec$startFrame-1)," -e:",rec$endFrame) )
      
      
      for (g in levels(huntLabels) )
      {
        message(paste(l,g,sep="-"))
        l=l+1
      }
      l=l+1
      message(paste("f","Fix Frame Range",sep="-"))
      l=l+1
      message(paste("c","End Labelling Process",sep="-"))
      l=l+1
      message(paste("n"," Add New Unlabelled Dublicate event",sep="-"))
      l=l+1
      message(paste("s"," Skip and proceeed to next",sep="-"))
      l=l+1
      message(paste("m"," Mark As Tracked (HuntEvent) ",sep="-"))
      l=l+1
      message(paste("u"," Mark As NOT Trackable (HuntEvent) ",sep="-"))
      
      
      failInputCount <- failInputCount + 1
      Keyc <- readline(prompt="### Was this Hunt Succesfull? (# / c to END) :")
      #message(paste(failInputCount,Keyc) )
      
      ##Check for Stop Loop Signal
      
      ##Add Copy of this Event
      if (Keyc == 's')## Unlabelled - Such that we can split / add new Hunting Event
      {
        
        break
      }
      
      if (Keyc == 'm') 
      {
        message(paste(Keyc,"~ Hunt Event ",i," Marked As Tracked for Detailed Analysis ~") )
        rec$markTracked <- 1 ##Reduntant But Here for consistency
        datHuntEvent[i,"markTracked"] <- 1
        break; ##Stop Menu Loop
        
      }
      
      if (Keyc == 'u') 
      {
        message(paste(Keyc,"~ Hunt Event ",i," Marked As *UnTrackable* for Detailed Analysis ~") )
        rec$markTracked <- -1 ##Reduntant But Here for consistency
        datHuntEvent[i,"markTracked"] <- -1
        break; ##Stop Menu Loop
        
      }
      
      
      if (Keyc == 'c') 
      {
        message(paste(Keyc,"~End Label Process Here") )
        rec$huntScore <- 0
        return(datHuntEvent)
        
      }
      if (is.numeric(Keyc))
      {
        rec$huntScore <- as.numeric(Keyc) ##factor(levels(huntLabels)[as.numeric(c)]
      }
      ##Fix Frame Range Manually
      if (Keyc == 'f')
      {
        rec$startFrame <- as.numeric(readline(prompt=paste(" Enter new start frame (",rec$startFrame, "):") ) )
        if (!is.na(rec$startFrame))
          if (rec$startFrame > 0)
            datHuntEvent[i,"startFrame"] <- rec$startFrame
          
        rec$endFrame <- as.numeric( readline(prompt=paste(" Enter new end frame (",rec$endFrame, "):") ) )
        if (!is.na(rec$endFrame))
          if (rec$endFrame > 0)
            datHuntEvent[i,"endFrame"] <- rec$endFrame
        Keyc = 1000
        
        message(paste("*New start:",datHuntEvent[i,"startFrame"]," end frame:", datHuntEvent[i,"endFrame"],"\n") )
      }
      
      ##Add Copy of this Event
      if (Keyc == 'n')## Unlabelled - Such that we can split / add new Hunting Event
      {
        rec <- datHuntEvent[i,]
        datHuntEvent<-rbind(rec,datHuntEvent)
        datHuntEvent[1,]$huntScore <- 0 ##Set To Unlabellled and let 
        message("-Event Cloned - Moved pointer to the Clone.");
        i <- 1 ##Start From Top Again
        next
      }
        
      ##User Has selected Label? Then Break From menu loop
      if (!is.na(factor(levels(huntLabels)[as.numeric(Keyc)+1] ) ) )
        break

    } ##End Menu Loop
    
    
      
    datHuntEvent[i,"huntScore"] <-rec$huntScore
    message(datHuntEvent[i,"huntScore"])
     if (rec$huntScore == (which(levels(huntLabels)=="Success")-1) )
     {
       message("~Mark Succesfull")
     }
    if (rec$huntScore == 0 || rec$huntScore == (which(levels(huntLabels)=="NA")-1) )
     {
       message("~Leave Unlabelled")
     }
    if (rec$huntScore == (which(levels(huntLabels)=="Fail")-1) )
     {
       message("~Failed To Capture Prey")
     }
    
    if (Keyc == 's')
    {
      message(" SKIP, and label next one " )
      next ##Skip To Next
    }
    
    if (Keyc == 'c')  ##Stop Event Loop Here if c was pressed
    {
      message(" Stop Labelling Loop Here " )
      return(datHuntEvent)
      #break
    }
    else
       message(paste(levels(huntLabels)[as.numeric(Keyc)+1] , "-Proceeding to Next Video.") )
     
     #####################################################################################################
    ##### Save With Dataset Idx Identifier On Every Labelling As An Error Could Lose Everything  ########
    save(datHuntEvent,file=paste(strDatDir,"/",strDataFileName,".RData",sep="" ))      
    
    strOutFileName <- paste(strDatDir,"/",strDataFileName,"-updates.csv",sep="")
    message(paste("Data Updated ",strDatDir,"/",strDataFileName,".RData",sep="" ))
    bColNames = FALSE
    if (!file.exists(strOutFileName) )
      bColNames = TRUE

    ##Need to Use write.table if you want to append down this list- I Found out after a lot of messing around
     write.table(datHuntEvent[i,],file=strOutFileName, append = TRUE,dec='.',sep=',',col.names = bColNames,quote=FALSE) ##Append Labelled records to a Log CSV File
    # }else ##Work Around Cause we cannot Append To Csvs!
    # {
    #   flogUpdates <- file(strOutFileName,'a',blocking = TRUE) ##Open File
    #   write((rec),file=flogUpdates,sep=",",append=TRUE,ncolumns=length(rec) )
    #   #writeChar('',con=flogUpdates)
    #   close(con=flogUpdates)
    # }
    ###########################################################################################
    
  } ## For Each Hunt Event Detected - 
  
  ##Return Modified Data Frame
  return(datHuntEvent)
  
}






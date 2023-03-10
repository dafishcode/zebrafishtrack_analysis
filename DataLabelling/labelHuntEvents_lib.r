## Used to Manually Label The hunt Events Stored In datHuntEvent ##
##strVideoFilePath = "/home/kostasl/workspace/build-zebraprey_track-Desktop-Debug"
## Kostas Lagogiagiannis 2018 Jan
## Run The tracker Specifically on video frames isolating the Hunt Events - let the user label if the event was succesful or not


##For Safe Sampling Of Vectors Of Size 1
resample <- function(x, ...) x[sample.int(length(x), ...)]

##To Execute The QT tracker application We may need to give the QT library Path - (xcb error)
#Sys.setenv(LD_LIBR4ARY_PATH="/home/kostasl/Qt/5.9.2/gcc_64/lib/" )
##Check If Qt Is already Added To Exec Path
if (grepl("Qt",Sys.getenv("LD_LIBRARY_PATH") )  == FALSE) 
{
  Sys.setenv(LD_LIBRARY_PATH="")
  
  #Sys.setenv(LD_LIBRARY_PATH=paste(Sys.getenv("LD_LIBRARY_PATH"),"",sep=":" ) ) 
  #Sys.setenv(LD_LIBRARY_PATH=paste(Sys.getenv("LD_LIBRARY_PATH"),"/opt/Qt/5.12.0/gcc_64/lib/",sep=":" ) ) ##Home PC/
  Sys.setenv(LD_LIBRARY_PATH=paste(Sys.getenv("LD_LIBRARY_PATH"),"/opt/Qt/5.15.0/gcc_64/lib/",sep=":" ) ) ##Home PC/
  Sys.setenv(LD_LIBRARY_PATH=paste(Sys.getenv("LD_LIBRARY_PATH"),"/media/kostasl/D445GB_ext4/opt/Qt3.0.1/5.10.0/gcc_64/lib/",sep=":" ) ) ##Home PC - OpenCV QT5 lib link/
  
  Sys.setenv(LD_LIBRARY_PATH=paste(Sys.getenv("LD_LIBRARY_PATH"),"/home/kostasl/Qt/5.15.1//gcc_64/lib/",sep=":" ) ) #### Office
  Sys.setenv(LD_LIBRARY_PATH=paste(Sys.getenv("LD_LIBRARY_PATH"),"/usr/lib/x86_64-linux-gnu/",sep=":" ) )
  
  Sys.setenv(DISPLAY=":1.0") #HOME<- If getting Errors with loading xcb check paths above and DISPLAY value  here
  Sys.setenv(DISPLAY=":0") #OFFICE
  Sys.setenv(PATH="/home/kostasl/Qt/5.15.1/gcc_64/bin:/opt/Qt/5.15.0/gcc_64/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin")
  Sys.setenv(QT_DIR="/opt/Qt/5.15.0/gcc_64")
  Sys.setenv(XDG_DATA_DIRS="/usr/share/ubuntu:/usr/local/share:/usr/share:/var/lib/snapd/desktop")
  Sys.setenv(XDG_RUNTIME_DIR="/run/user/1000")
  Sys.setenv(QT_DEBUG_PLUGINS=1)

}

vHuntEventLabels <- c("UnLabelled","NA","Success","Fail","No_Target","Not_HuntMode/Delete","Escape","Out_Of_Range","Duplicate/Overlapping","Fail-No Strike","Fail-With Strike",
                      "Success-SpitBackOut",
                      "Debri-Triggered","Near-Hunt State","Success-OnStrike","Success-OnStrike-SpitBackOut",
                      "Success-OnApproach", ##For Ones that either do not strike but simply push on to the prey, 
                      "Success-OnApproach-AfterStrike" #or those that strike but only capture prey after and not during the strike (Denotes lesser ability to judge distance)
                      )

convertToScoreLabel <- function (huntScore) { 
  return (factor(x=huntScore,levels=seq(0,NROW(vHuntEventLabels)-1),labels=vHuntEventLabels ) )
}

huntLabels <- convertToScoreLabel(5) #factor(x=5,levels=c(0,1,2,3,4,5,6,7,8,9,10,11,12,13),labels=vHuntEventLabels )##Set To NoTHuntMode



##Loads the Latest Labelled Hunt Events Set - Centralize Here so Changes Propagate To scripts
## Removes Thos Labelled As Dublicate OR Non Hunt Events
## Notes : Merged2 Contains the Fixed, Remerged EventID 0 files, so event Counts appear for all larvae recorded.
# For the 2020 publication the file used was "setn15-HuntEvents-SB-Updated-Merged3"
getLabelledHuntEventsSet <- function(strProcDataFileName = "HB_allHuntEvents.rds",vxCludeExpID=NA)
{
#  datHuntLabelledEventsSBMerged_fixed[datHuntLabelledEventsSBMerged_fixed$expID == 4491,] ##Is A lonely NL with no Matching NE
  bNewFile <- FALSE
  if (!dir.exists(paste0(strDatDir,"/LabelledSet/")))
  {
      message("Creating LabelledSet subdir to save labeled hunt events..")
      dir.create(paste0(strDatDir,"/LabelledSet/"))  
      file.copy(paste0(strDatDir,"/",strProcDataFileName), paste0(strDatDir,"/LabelledSet/",strProcDataFileName),overwrite=FALSE)
      bNewFile <- TRUE
     
  }
  
  #strProcDataFileName <-"setn3-D1-3-HuntEvents-140"
  assign("file_LabelledHuntEventsSet", paste(strDatDir,"/LabelledSet/",strProcDataFileName,sep="" ), envir = .GlobalEnv)
  message(paste(" Loading Hunt Event List to Analyse... ",strProcDataFileName))
  #load(file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".RData",sep="" )) ##Save With Dataset Idx Identifier
  datHuntLabelledEventsSB <- readRDS(file=paste0(strDatDir,"/LabelledSet/",strProcDataFileName))
  
  if (!("filename" %in% names(datHuntLabelledEventsSB)) )
    datHuntLabelledEventsSB$filename <- ""
  #datHuntLabelledEventsSB <- readRDS(file=paste(strDatDir,"/",strProcDataFileName,".rds",sep="" ))

  ##Attach Video file name to Each Hunt Event
  if (any(datHuntLabelledEventsSB$filename == "")){
    ## Attach File Names - TrackerFiles Have same basename as video file - Use this to locate Vid
    vAvailableVideoFiles <- list.files(path = strVideoFilePath, 
                                       pattern = ".avi|.mp4" , all.files = FALSE,
                                      full.names = TRUE, recursive = TRUE,
                                      ignore.case = FALSE, include.dirs = FALSE, no.. = FALSE)
    
    
    for (i in 1:NROW(datHuntLabelledEventsSB) )
    {
      rec <- datHuntLabelledEventsSB[i,] 
      ##Locate Via pattern of Exp/Group/Event Id In file name
      strFpatt <- paste0(rec$expID,"_.*",as.character(rec$groupID),".*",as.character(rec$testCond) )

      vMatchedFileNames <- vAvailableVideoFiles[which(grepl(strFpatt ,vAvailableVideoFiles))]
      if (NROW(vMatchedFileNames) == 1)
      {
          datHuntLabelledEventsSB[i,"filename"] <- (vMatchedFileNames) #basename
          message(i,datHuntLabelledEventsSB[i,"filename"])
      }else{
          message(i,"**No unique filename found : ", strFpatt, "Retrying with filter event ID:",as.character(rec$eventID))
          ##Retry with Event Number
          strFpatt <- paste0(rec$expID,"_.*",as.character(rec$groupID),".*",as.character(rec$testCond),"_.*",as.character(rec$eventID) )
          vMatchedFileNames <- vAvailableVideoFiles[which(grepl(strFpatt ,vAvailableVideoFiles))]
          if (NROW(vMatchedFileNames)> 0)
            datHuntLabelledEventsSB[i,"filename"] <- (vMatchedFileNames) #xbasename 
      }
      ## Another Way is to search in Saved Records of tracked File Names
      #rec$filename <- basename(groupsrcdatListPerDataSet[[1]][[rec$groupID]][[1]][rec$fileIdx])
      ##Remove csv extention 
      #rec$filename <- substr(rec$filename, 1, nchar(rec$filename)-4)
      
    }
    ##Save Updated
    message(" Added video file names to hunt-event records.")
    saveRDS(datHuntLabelledEventsSB,file=paste0(strDatDir,"/LabelledSet/",strProcDataFileName))
  }

  
  ##These Are Double/2nd Trials on LL, or Simply LL unpaired to any LE (Was checking Rates)
  #AutoSet420fps_14-12-17_WTNotFed2RotiR_297_003.mp4
  # 4491 <- Is a lonely NL - No Match NE
  #vxCludeExpID <- c(4421,4611,4541,4351,4481,4501,4411,4491)
  #vWeirdDataSetID <- c(11,17,18,19) ##These Dataset Have a total N  Experiments Less than 4(larvae)*2(cond)*3(groups)=24
  
  ##We Can Choose To Exclude The Fish That Produced No Hunting Events
  datHuntLabelledEventsSB <- datHuntLabelledEventsSB[ !(datHuntLabelledEventsSB$expID %in% vxCludeExpID) 
                                                      #& datHuntLabelledEventsSB$groupID %in% c("LL","NL","DL")
                                                      ,]
  
  ##Remove Dublicates - Choose Labels - Duration Needs To be > 5ms
  datHuntLabelledEventsSB_filtered <- datHuntLabelledEventsSB [
    with(datHuntLabelledEventsSB, ( convertToScoreLabel(huntScore) != "Not_HuntMode/Delete" &
                                    convertToScoreLabel(huntScore) != "Duplicate/Overlapping" &
                                    #(endFrame - startFrame) > 40 ) |  ## limit min event dur to ~100ms
                                    (endFrame - startFrame) > 40 ) |  ## limit min event dur to ~100ms
           eventID == 0), ] ## Add the 0 Event, In Case Larva Produced No Events
  
  
  #datHuntLabelledEventsSBMerged_fixed <- datHuntLabelledEventsSBMerged_filtered[!is.na(datHuntLabelledEventsSBMerged_filtered$groupID) & 
  #                                                                                !(datHuntLabelledEventsSBMerged_filtered$expID %in% vxCludeExpID),]
  
  ## Check Event Number in Strange List
  #for (dID in vWeirdDataSetID )
  #  print(NROW(unique(datHuntLabelledEventsSB_filtered[datHuntLabelledEventsSB_filtered$dataSetID ==  dID ,]$expID)))
  
  
  
  return(datHuntLabelledEventsSB_filtered)
}


### Used for running the tracker to score Hunt events, or to retrack a hunt event in supervised mode ##
### The retracked event are then used for analysis of sensorimotor differences/eye vergence information 
## Menu allows for events to be marked as tracked to avoid dublicates by  setting the param bskipMarked = TRUE  
## Meny made to stick to same event until User picks c to stop, or s to move to next event
labelHuntEvents <- function(datHuntEvent,strDataFileName,strVideoFilePath,strTrackerPath,strTrackOutputPath,factorLabelFilter,ExpIDFilter,EventIDFilter,idxFilter=NA,bskipMarked = TRUE)
{
  
  ##Save Backup Of Records
  saveRDS(datHuntEvent,file=paste(strDatDir,"/LabelledSet/",strDataFileName,"_backup.rds",sep="" )) ##Save With Dataset Idx Identifier
  message(paste("Saved Backup :",strDatDir,"/LabelledSet/",strDataFileName,"_backup.rds",sep="" ) )
  
  message(paste(NROW(datHuntEvent[datHuntEvent$huntScore >0,]),"/",NROW(datHuntEvent), " Data has already been labelled" ) )
  ##nLabelledSuccess <- NROW(datHuntEvent[datHuntEvent$huntScore == which(levels(huntLabels) == "Success") | datHuntEvent$huntScore == which(levels(huntLabels) == "Success-SpitBackOut"),])
  ## Detect Labels with Success In the Name -
  nLabelledSuccess <- NROW(datHuntEvent[grepl("Success",as.character(convertToScoreLabel(datHuntEvent$huntScore) ) ) ,])
  if (is.na(idxFilter))
  {
    nEventsToLabel <- NROW(datHuntEvent[datHuntEvent$expID   == ExpIDFilter &
                                          datHuntEvent$eventID == EventIDFilter &
                                          convertToScoreLabel(datHuntEvent$huntScore) %in% factorLabelFilter,])  
    message (paste("There are ",nEventsToLabel, " to label in this cycle.") )
  }
  
  readline(prompt="- Press Any key to Begin Data labelling.-")
  
  
  for (i in  (1:NROW(datHuntEvent)) )
  {
    ## If User Gave Specific Hunt Event, Then Look for it Specifically
    if (!is.na(idxFilter) )
      i <- as.character(idxFilter) ##Convert i into Specific str ID 
    
    
    rec <- datHuntEvent[i,] 
    stopifnot(!is.na(rec$expID ))
    
    ##A Noddy  Way of selecting Records
    if (!(convertToScoreLabel(rec$huntScore) %in% factorLabelFilter) )
      next ##SKip Record if previously Labelled
    if (rec$expID != ExpIDFilter | rec$eventID != EventIDFilter  ) ##&& rec$huntScore != (which(levels(huntLabels)=="NA")-1)
      next
    
    ##Added Later To Struct Is  A Flag that a Hunt Event Has been Retracked - adding the food target
    if (any(names(datHuntEvent)=="markTracked")  ) ##This Marks Videos that have been Labelled and Retracked For anal
      if (!is.na(rec$markTracked))
        if (rec$markTracked != 0 & is.na(idxFilter) ) ##Both Untrackable and Marked Tracked
        {
          message(paste("Already Marked as Tracked ",datHuntEvent$expID,datHuntEvent$eventID,"\n "  ) )
          if (bskipMarked == TRUE)
            next ##SKip Record if previously Labelled
        }
   
    
    ##For Larva That Did not register any sufficient Hunting Events -  An Empty Record has been added To Acknowledge 
    if (rec$eventID == 0 & rec$huntScore == 0)
    {##Set To Not Hunt Event/Delete - So as to Ignore In Hunt Event Counts
      datHuntEvent[i,]$huntScore = huntLabels
      next
    }
    
    ##Get Respective Video  Filename / Path
    strVideoFile <- list.files(path = strVideoFilePath, pattern = rec$filename , all.files = FALSE,
                               full.names = TRUE, recursive = TRUE,
                               ignore.case = FALSE, include.dirs = FALSE, no.. = FALSE)
    
    if (NROW(strVideoFile) == 0 | NROW(strVideoFile) > 1 )
      stop(paste("Could not find unique video file matching,",rec$filename, " ,in : ",strVideoFilePath ) )
    if (!file.exists(strVideoFile) )
      stop(paste("Video File ",strVideoFile, "does not exist" ) )
      
    
    
    message(paste("\n", row.names(rec) ,". Examining Hunt Event -start:",max(0,rec$startFrame-1)," -End:",rec$endFrame, "ExpID:",rec$expID ) )
    ##--
    strArgs = paste0(" --HideDataSource=0 --MeasureMode=1 --ModelBG=1 --SkipTracked=0 --PolygonROI=0 --invideofile=",strVideoFile,
                    " --outputdir=",strTrackOutputPath," --DNNModelFile=","/home/kostasl/workspace/zebrafishtrack/tensorDNN/savedmodels/fishNet_loc",
                    " --startframe=",max(0,rec$startFrame-1),
                    " --stopframe=",rec$endFrame," --startpaused=1")
    
    message(paste(strTrackerPath,"/zebraprey_track",strArgs,sep=""))
    
    if (!file.exists(paste(strTrackerPath,"/zebraprey_track",sep="")) )
      stop(paste("Tracker software not found in :",strTrackerPath ))
    
    execres <- base::system2(command=paste(strTrackerPath,"/zebraprey_track",sep=""),args =  strArgs,stdout=NULL,stderr =NULL) ## stdout=FALSE stderr = FALSE
    
    ## execres contains all of the stdout - so cant be used for exit code
    if (execres != 0)
      stop(execres) ##Stop If Application Exit Status is not success
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
      
      setLabel <- factor(x=rec$huntScore,levels=seq(0,NROW(vHuntEventLabels)-1),labels=vHuntEventLabels )
      message(paste("\n\n ### Event's ", row.names(rec) , " Current Label is :",setLabel," ####" ) )
      message(paste("### Set Options Hunt Event of Larva:",rec$expID," Event:",rec$eventID, "Video:",rec$filename, " -s:",max(0,rec$startFrame-1)," -e:",rec$endFrame) )
      
      
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
      message(paste("s"," NEXT - save and proceeed ",sep="-"))
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
        message(paste(Keyc,"~Save And Move To next *") ) 
        break ##Exit Menu Loop , Save Record And Move on to next
      }
      
      if (Keyc == 'm') 
      {
        message(paste(Keyc,"~ Hunt Event ",i," Marked As Tracked for Detailed Analysis ~") )
        rec$markTracked <- 1 ##Reduntant But Here for consistency
        datHuntEvent[i,"markTracked"] <- 1
        ##Do not End Menu Loop Here / Allow for more tags on event
        ##break; ##Stop Menu Loop
        
      }
      
      if (Keyc == 'u') 
      {
        message(paste(Keyc,"~ Hunt Event ",i," Marked As *UnTrackable* for Detailed Analysis ~") )
        rec$markTracked <- -1 ##Reduntant But Here for consistency
        datHuntEvent[i,"markTracked"] <- -1
        ##Do not End Menu Loop Here
        ##break; ##Stop Menu Loop
        
      }
      
      
      if (Keyc == 'c') 
      {
        message(paste(Keyc,"~End Label Process Here ") )
        ##rec$huntScore <- 0
        break ## c will be captured from Next Loop and Funct will return after save
        #return(datHuntEvent)
        
      }
      if (!is.na(as.numeric(Keyc)))
      {
        rec$huntScore <- as.numeric(Keyc) ##factor(levels(huntLabels)[as.numeric(c)]
        datHuntEvent[i,"huntScore"]  <- rec$huntScore
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
      
      ##Do not break From Menu Until s / Next is pressed
      ##User Has selected Label? Then Break From menu loop
      #if (!is.na(factor(levels(huntLabels)[as.numeric(Keyc)+1] ) ) )
      #  break
      
    } ##End Menu Loop
    
    
    datHuntEvent[i,"huntScore"]  <- rec$huntScore
    message(datHuntEvent[i,"huntScore"])
    
    
    if (grepl("Success", as.character (convertToScoreLabel(rec$huntScore)))  )
    {
      message("~Mark Succesfull")
    }
    if (rec$huntScore == 0 || grepl("NA", as.character (convertToScoreLabel(rec$huntScore)))  )
    {
      message("~Leave Unlabelled")
    }
    if (grepl("Fail", as.character (convertToScoreLabel(rec$huntScore))) )
    {
      message("~Failed To Capture Prey")
    }
    
    if (Keyc == 's')
    {
      message(" Moving to Next" )
     # next ##Skip To Next ##Loop Will complete and move to next event
    }
    
    ##########################################################################################
    ##### Save With Dataset Idx Identifier On Every Labelling As An Error Could Lose Everything  ########
    save(datHuntEvent,file=paste(strDatDir,"/LabelledSet/",strDataFileName,".RData",sep="" )) ##Save With Dataset Idx Identifier
    saveRDS(datHuntEvent,file=paste(strDatDir,"/LabelledSet/",strDataFileName,".rds",sep="" )) ##Save With Dataset Idx Identifier

    
    strOutFileName <- paste(strDatDir,"/LabelledSet/",strDataFileName,"-updates.csv",sep="")
    message(paste("Data Updated *",strOutFileName,sep="" ))
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
    
    ### CHECK for EXIT LOOP ###
    if (Keyc == 'c' | Keyc == 'q')  ##Stop Event Loop Here if c was pressed
    {
      message(" Stop Labelling Loop Here " )
      ##return(datHuntEvent)
      break 
    }
    else
      message(paste(ifelse(is.numeric(Keyc),levels(huntLabels)[as.numeric(Keyc)+1], Keyc  ) , "- Selected.") )
    
    ###########
    
  } ## For Each Hunt Event Detected - 
  
  ##Return Modified Data Frame
  
  return(datHuntEvent)
  
}


## Takes two labelled HuntEvent dataframes, and attemcpts to match the identified events between 
## the two and combines them in a new dataframe adding the score, start and end frames From B -
## only where a one to one matching is possible
compareLabelledEvents <- function(datHuntEventA,datHuntEventB)
{
  nMultiCollision <- 0
  nNonMatch <- 0
  ##Make Copy And Initialize new Comparison fields As NA
  datHuntEventComp <- datHuntEventA
  datHuntEventComp$huntScoreB <- NA
  datHuntEventComp$startFrameB <- NA
  datHuntEventComp$endFrameB <- NA
  
  for (i in 1:NROW(datHuntEventA) )
  {
    rec <- datHuntEventA[i,]
    
    
    res <- datHuntEventB[as.character(datHuntEventB$expID) == as.character(rec$expID) &
                           as.character(datHuntEventB$eventID) == as.character(rec$eventID) & 
                           convertToScoreLabel(datHuntEventB$huntScore) != "Duplicate/Overlapping" & ##Ignore Labels Set As Dublicate Already
                           (##Episode startFrame Should have some overlap within the region of the other 
                             (datHuntEventB$startFrame >= rec$startFrame & ## B Start Contained In A
                                datHuntEventB$startFrame <= rec$endFrame) | 
                               (datHuntEventB$endFrame >= rec$startFrame &  ## B End Contained in A
                                  datHuntEventB$endFrame <= rec$endFrame) |
                               (datHuntEventB$endFrame >= rec$endFrame & ## B contains A as a whole
                                  datHuntEventB$startFrame <= rec$startFrame) |
                               (datHuntEventB$endFrame <= rec$endFrame & ## A Contains B as A whole 
                                  datHuntEventB$endFrame >= rec$startFrame) 
                           ), ]
    if ( NROW(res) == 1)  
    {
      datHuntEventComp[i,]$huntScoreB  <- res$huntScore
      datHuntEventComp[i,]$startFrameB <- res$startFrame
      datHuntEventComp[i,]$endFrameB   <- res$endFrame
    }
    
    if ( NROW(res) == 0)
    {
      nNonMatch <- nNonMatch + 1
      warning(paste( " No Match For eventID:",rec$eventID, " expID:",rec$expID," sFrame:",rec$startFrame, " -endFrame:",rec$endFrame ) )
    }
    
    
    if ( NROW(res) > 1)  
    {
      nMultiCollision <- nMultiCollision + 1
      warning(paste("More than a single match for eventID:",rec$eventID, " expID:",rec$expID," sFrame:",rec$startFrame, " -endFrame:",rec$endFrame  ) )
    }
    
  }
  
  message(paste( " There were Multimatch (1 A -> MultiB) Collisions:",nMultiCollision, " and Not Matched events:",nNonMatch ) ) 
  
  return(datHuntEventComp)
  
  ##Matches
  ##huntComp[huntComp$huntScore == huntComp$huntScoreB & huntComp$huntScore != 0,]
  ##NonMatches 
  #huntComp[huntComp$huntScore != huntComp$huntScoreB & huntComp$huntScore != 0,]
  
  ##Find the the Mismaches 
  #huntComp$huntScore <- convertToScoreLabel(huntComp$huntScore) ##Convert to Labels
  #huntComp$huntScoreB <- convertToScoreLabel(huntComp$huntScoreB)
  #huntComp[huntComp$huntScore != huntComp$huntScoreB & huntComp$huntScore != "UnLabelled",] ##Bring Out The labelled Mismatches
  ##Compare:
  #table(huntComp$huntScore, huntComp$huntScoreB)
}


## USe it To Update a Labelled Set With The Changes Introduced from Another 
###- Only Merges Unlabelled Onto Target Set
##Finds labels from datSource for unlabelled events in datTarget 
digestHuntLabels <- function(datTarget,datSource)
{
  
  huntComp <- compareLabelledEvents(datTarget,datSource)
  
  ##Find which labels are new  - where the scores Differ and the Target Event List has these events unlabelled / OR / NA
  datNewLabels <- huntComp[huntComp$huntScore != huntComp$huntScoreB & !is.na(huntComp$huntScoreB) & !is.na(huntComp$huntScore) 
                           & (convertToScoreLabel(huntComp$huntScore)=="UnLabelled" | convertToScoreLabel(huntComp$huntScore)=="NA"),] ##Bring Out The labelled Mismatches##Compare:
  
  rowIDs <- row.names(datNewLabels) ## Get ID to match records between datasets
  ##Transfer Label And Start End Frame
  datTarget[row.names(datNewLabels),"huntScore"] <- datSource[row.names(datNewLabels),"huntScore"] 
  datTarget[row.names(datNewLabels),"startFrame"] <- datSource[row.names(datNewLabels),"startFrame"]
  datTarget[row.names(datNewLabels),"endFrame"] <- datSource[row.names(datNewLabels),"endFrame"]
  ##Return The dataframe with the Updated Scores that came from datSource
  return(datTarget)
}

## Analysis of Hunt Success 
### Makes Data frame With Number of Success Vs Failures From Labelled DatHuntEvent
getHuntSuccessPerFish <- function(datHuntLabelledEvents)
{
  #datHuntLabelledEvents <- datHuntLabelledEvents[datHuntLabelledEvents$eventID != 0,] ##Exclude the Artificial Event 0 Used such that all ExpID are In the DatHuntEvent
  tblResSB <- table(convertToScoreLabel(datHuntLabelledEvents$huntScore),datHuntLabelledEvents$groupID)
  tblFishScores <- table(datHuntLabelledEvents$expID, convertToScoreLabel(datHuntLabelledEvents$huntScore) )
  
  tblFishScoresLabelled<- tblFishScores[tblFishScores[,1] < 2, ] ##Pick Only THose ExpId (Fish) Whose Labelling Has (almost!) Finished
  ##Choose The Columns With the Scores Of Interest Success 3, Success-SpitBackOut 12 etc
  ##No_Targer is Column 5

  
  ## Find Tbl Indexes Indicating Success 
  tblIdxSuccess <- which (grepl("Success",row.names(tblResSB) ) ) 
  tblIdxFail <- which (grepl("Fail",row.names(tblResSB) ) ) 
  
  tblIdxNotHuntMode <- which (grepl("Out_Of_Range",row.names(tblResSB) ) | 
                              grepl("UnLabelled",row.names(tblResSB) ) | 
                              grepl("Duplicate",row.names(tblResSB) ) | 
                              grepl("Near-Hunt State",row.names(tblResSB) ) )  
  
  tblIdxEscape <- which (grepl("Escape",row.names(tblResSB) ) ) 
  tblIdxFail <- which (grepl("Fail",row.names(tblResSB) ) ) 
  

  
  datFishSuccessRate <- data.frame( cbind("Success" = rowSums(tblFishScoresLabelled[,tblIdxSuccess]),#tblFishScoresLabelled[,"Success"]+tblFishScoresLabelled[,"Success-SpitBackOut"]+tblFishScoresLabelled[,"Success-OnStrike"]+tblFishScoresLabelled[,"Success-OnStrike-SpitBackOut"]+tblFishScoresLabelled[,"Success-OnApproach"] +tblFishScoresLabelled[,"Success-OnApproach-AfterStrike"],
                                          "Fails_NS"= tblFishScoresLabelled[,"Fail-No Strike"],
                                          "Fails_WS"=tblFishScoresLabelled[,"Fail-With Strike"],
                                          "Fails"= rowSums(tblFishScoresLabelled[,tblIdxFail]),  #tblFishScoresLabelled[,"Fail"]+tblFishScoresLabelled[,"Fail-No Strike"]+tblFishScoresLabelled[,"Fail-With Strike"],
                                          "HuntEvents"=rowSums(tblFishScoresLabelled[, !(1:NCOL(tblFishScoresLabelled) %in% tblIdxNotHuntMode) ] ),  #rowSums(tblFishScoresLabelled[,c("Success","Success-SpitBackOut","Success-OnStrike","Success-OnStrike-SpitBackOut","Success-OnApproach","Success-OnApproach-AfterStrike","Fail","Fail-No Strike","Fail-With Strike","No_Target")]) , ##Ad The No Target To indicate Triggering Of Hunt Mode (Col 5)
                                          "CaptureEvents"=rowSums(tblFishScoresLabelled[,c(tblIdxSuccess,tblIdxFail)] ),  #rowSums(tblFishScoresLabelled[,c("Success","Success-SpitBackOut","Success-OnStrike","Success-OnStrike-SpitBackOut","Success-OnApproach","Success-OnApproach-AfterStrike","Fail","Fail-No Strike","Fail-With Strike","No_Target")]) , ##Ad The No Target To indicate Triggering Of Hunt Mode (Col 5)
                                          "expID"=NA,
                                          "groupID"=NA,
                                          "dataSetID"=NA) ) #

  vScoreIdx        <- ((datFishSuccessRate[,"Success"]*datFishSuccessRate[,"Success"])/(datFishSuccessRate[,"Success"]+datFishSuccessRate[,"Fails"]))
  vEfficiency      <- ((datFishSuccessRate[,"Success"])/(datFishSuccessRate[,"Success"]+datFishSuccessRate[,"Fails"]))  
  datFishSuccessRate <- cbind(datFishSuccessRate,HuntPower=vScoreIdx,Efficiency=vEfficiency)
  ##Add Group Label To the resulting Data Frame
  for (e in row.names(tblFishScoresLabelled) )
  {
    datFishSuccessRate[e,"expID"] <- unique( datHuntLabelledEvents[!is.na(datHuntLabelledEvents$expID) & datHuntLabelledEvents$expID == e,"expID"] )
    datFishSuccessRate[e,"groupID"] <- unique( datHuntLabelledEvents[!is.na(datHuntLabelledEvents$expID) & datHuntLabelledEvents$expID == e,"groupID"] )
    datFishSuccessRate[e,"dataSetID"] <- unique( datHuntLabelledEvents[!is.na(datHuntLabelledEvents$expID) & datHuntLabelledEvents$expID == e,"dataSetID"] )
  }
  
  return (datFishSuccessRate)
  
}

## Use it To Locate One Of the Detail Retracked HuntEvents In the Labelled Group
## You can the Use mainLabellingBlind, and give the rowID so as to replay the Video in the tracker
findLabelledEvent <- function (EventRegisterRec)
{
  
  ##Check for Funky Errors in huntScore labels (not recognized labels):
  
  #strDataFileName <- paste("setn14-D5-18-HuntEvents-Merged") ##To Which To Save After Loading
  #strDataFileName <-paste("setn14-HuntEventsFixExpID-SB-Updated-Merged",sep="") ##To Which To Save After Loading
  #  strDataFileName <-paste("setn15-HuntEvents-SB-Updated-Merged2",sep="") ##To Which To Save After Loading
  
  #  message(paste(" Loading Hunt Event List to Validate : ","/LabelledSet/",strDataFileName,".rds" ))
  #  datLabelledHuntEventAllGroups <-readRDS(file=paste(strDatDir,"/LabelledSet/",strDataFileName,".rds",sep="" )) ##Save With Dataset Idx Identifier
  
  datLabelledHuntEventAllGroups <- getLabelledHuntEventsSet()

  datErrorRecords <- datLabelledHuntEventAllGroups[is.na(convertToScoreLabel( datLabelledHuntEventAllGroups$huntScore)),]
  stopifnot(NROW(datErrorRecords) == 0 )
  
    
  if (is.na(EventRegisterRec$startFrame))
    warning("Missing startFrame from Event Register")
  
  
  recs <- datLabelledHuntEventAllGroups[as.character(datLabelledHuntEventAllGroups$groupID) == as.character(EventRegisterRec$groupID) &
                                         as.character(datLabelledHuntEventAllGroups$eventID) == as.character(EventRegisterRec$eventID) &
                                         as.character(datLabelledHuntEventAllGroups$expID) == as.character(EventRegisterRec$expID) & 
                                          !is.na(datLabelledHuntEventAllGroups$markTracked) ##If its in TrackedRegistry  then it must have been markedtraked
                                       ,]
  
  ##If Start Frame Is there - Check For Closest Match 
  if (any(names(EventRegisterRec) == "startFrame"))
  {
    ##Filter Down
    ##find the hunt event which contains the currect start frame ie ends before the start frame
    recs <- recs[   recs$endFrame >  EventRegisterRec$startFrame , ] 
    ##Calc Distance Based on Start and End Frame
    d <- (recs$startFrame - EventRegisterRec$startFrame + recs$endFrame - EventRegisterRec$endFrame) 
    ##Get The BEst Match FOr Start Frame- as the 1st hunt event starting after EventReg startframe (we usually rewind a little from the automatically detect start frame) 
    if (!any(is.na(d))) ## If startFrame is not NA
    {
      ##remove the -ve ones from the search by set to  max
      #d[d<0] <- max(d)+1
      ##Now retrieve the first event starting after our start frame , ending after our startframe* (filtered above)
      recs <- recs[which(abs(d) == min(abs(d)) ), ] 
    }
    
  }
  
  return(recs)
}




## This is the old method of validating individual Hunt Events 
scoreIndividualEventsRandomly <- function(datHuntEventAllGroupToLabel,str_FilterLabel = "UnLabelled")
{
  ##Select Randomly From THe Already Labelled Set ##
  ##Main Sample Loop
  Keyc <- 'n'
  while (Keyc != 'q')
  {
    Keyc <- readline(prompt="### Press q to exit, 'n' for next, or type event number you wish to label  :")
    
    if (Keyc == 'q')
      break
    
    TargetLabel = which(vHuntEventLabels == str_FilterLabel)-1; ##Convert to Number Score
    gc <- resample(groupsList,1)
    idx <- NA
    TargetLabels <- vHuntEventLabels
    
    #message(gc)
    
    if (Keyc == 'n')
    {
      ##Choose From THe Set Of Videos Already Labelled From Another User (Kostasl) So as to Verify The Label # Sample Only From THose ExpID that have not been already verified
      #datHuntEventPool <- datHuntEventAllGroupToValidate[datHuntEventAllGroupToValidate$huntScore != "UnLabelled" & datHuntEventAllGroupToValidate$eventID != 0
      #                                           & (datHuntEventAllGroupToValidate$expID %in% datHuntEventAllGroupToLabel[datHuntEventAllGroupToLabel$huntScore == TargetLabel,]$expID ),]
      
      datHuntEventPool <- datHuntEventAllGroupToLabel[datHuntEventAllGroupToLabel$eventID != 0 & datHuntEventAllGroupToLabel$groupID == gc,]
      datHuntEventPool <- datHuntEventPool[ datHuntEventPool$huntScore == TargetLabel ,] #& is.na(datHuntEventPool$markTracked)
      if (NROW(datHuntEventPool)  == 0)
      {
        message( paste("Finished with Hunt Events for group with label ",TargetLabels[TargetLabel+1], ". Try Again") )
        groupsList <- groupsList[which(groupsList != gc)]
        next
      }
      
      expID <- resample(datHuntEventPool$expID,1)
      datHuntEventPool <- datHuntEventPool[datHuntEventPool$expID == expID ,]
      eventID <- resample(datHuntEventPool$eventID,1)
      ###
      TargetLabels <- vHuntEventLabels[vHuntEventLabels==str_FilterLabel] ##Convert to Text Label Score to Use for Filtering OUt
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
    ##ExPORT 
    
    
    datHuntEventAllGroupToLabel <- labelHuntEvents(datHuntEventAllGroupToLabel,
                                                   strProcDataFileName,strVideoFilePath,
                                                   strTrackerPath,strTrackeroutPath,
                                                   TargetLabels,expID,eventID,idx)
    
    ##Saving is done in labelHuntEvent on Every loop - But repeated nhere
    save(datHuntEventAllGroupToLabel,file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".RData",sep="" )) 
    save(datHuntEventAllGroupToLabel,file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,"-backup.RData",sep="" )) ##Save With Dataset Idx Identifier
    saveRDS(datHuntEventAllGroupToLabel,file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".rds",sep="" ))
    message(paste("Saved :",strDatDir,"/LabelledSet/",strProcDataFileName,".RData",sep="") )
    
  }
  
  tblRes <- table(convertToScoreLabel(datHuntEventAllGroupToLabel[datHuntEventAllGroupToLabel$eventID != 0,]$huntScore),datHuntEventAllGroupToLabel[datHuntEventAllGroupToLabel$eventID != 0,]$groupID)
  write.csv(tblRes,file=paste(strDatDir,"/LabelledSet/","tbLabelHuntEventSummary.csv",sep="") )
  
  print(tblRes)
} ## Old Method of Scoring Events Individually

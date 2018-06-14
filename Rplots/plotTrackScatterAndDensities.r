rfHot <- colorRampPalette(rev(brewer.pal(11,'Spectral')));

histj<- function(x,y,x.breaks,y.breaks){
  c1 = as.numeric(cut(x,breaks=x.breaks));
  c2 = as.numeric(cut(y,breaks=y.breaks));
  mat<-matrix(0,ncol=length(y.breaks)-1,nrow=length(x.breaks)-1);
  mat[cbind(c1,c2)] = 1;
  return(mat)
}  


plotGroupMotion <- function(filtereddatAllFrames,groupStat,vexpID)
{
  yTop <- 500
  ##Note Y plotting is inverted to match video orientation ie. yTop - posY
  strDatGroup <- toString(unique(filtereddatAllFrames$group))
  
  message("PLOT Motion Tracks of each Larva noting Hunting Episodes")
  ### INDIVIDUAL TRAJECTORIES - With distinct colour for each larva ####
  for (i in vexpID)
  {
    strTrajectoryplotFileName <- paste("plots/scatter/Motion/larva/MotionTrajectories-Set-",strDatGroup,"-lID_",i,".pdf",sep="",collapse=NULL);
    message(strTrajectoryplotFileName)
    pdf(strTrajectoryplotFileName,width=8,height=8) #col=(as.integer(filtereddatAllFrames$expID))
    par(bg="black")
    par(fg="yellow")
    
    datLarvalAllFramesHunt <- filtereddatAllFrames[filtereddatAllFrames$expID == i & filtereddatAllFrames$LEyeAngle >=G_THRESHUNTANGLE & filtereddatAllFrames$REyeAngle <= -G_THRESHUNTANGLE,]
    datLarvalAllFramesAll <- filtereddatAllFrames[filtereddatAllFrames$expID == i,]
    vEvent <- unique(datLarvalAllFramesAll$fileIdx)
    #points(datLarvalAllFramesAll$posX,datLarvalAllFramesAll$posY,pch='.',col="white",xlim=c(80,565),ylim=c(0,500),col.axis="red")
    plot(datLarvalAllFramesAll$posX,yTop-datLarvalAllFramesAll$posY,type='p',pch='.',col="white",xlim=c(80,600),ylim=c(0,yTop),col.axis="red")
    points(datLarvalAllFramesHunt$posX,yTop-datLarvalAllFramesHunt$posY,pch='.',col="red",xlim=c(80,600),ylim=c(0,yTop),col.axis="red")
     
    for (j in vEvent)
    {
      datEvent <- datLarvalAllFramesAll[datLarvalAllFramesAll$fileIdx==j,]
      points(datEvent[1]$posX,yTop-datEvent[1]$posY,pch=12,col="red",xlim=c(80,600),ylim=c(0,500),col.axis="red")
      
    }
    
    sampleSize  <- length(unique(datLarvalAllFramesAll$fileIdx)) #Number of Larvae Used 
    strtitle = paste(strCond,"Motion",collapse=NULL)
    strsub = paste("#e=", sampleSize, " #F:",groupStat$totalFrames,collapse=NULL)
    title(strtitle, sub = strsub, cex.main = 1.5,   font.main= 1.5, col.main= "yellow", cex.sub = 1.0, font.sub = 2, col.sub = "red")
    #dev.copy(jpeg,filename=paste(strTrajectoryplotFileName,"-plot.jpg",sep=""));
    dev.off()
  }
  
  ##### Plot ALL Larvae In The group TOgether ##
  message("PLOT - Overlay All Larva of Group / noting Hunting Episodes")
  
  strTrajectoryplotFileName <- paste("plots/scatter/Motion/group/MotionTrajectories-Set-",strDatGroup,"-All.pdf",sep="",collapse=NULL);
  message(strTrajectoryplotFileName)
  pdf(strTrajectoryplotFileName,width=8,height=8) #col=(as.integer(filtereddatAllFrames$expID))
  par(bg="black")
  par(fg="yellow")
  
  colMap = colTraj(filtereddatAllFrames$expID);
  
  if (length(filtereddatAllFrames$expID) == 0)
  {
    #plot(filtereddatAllFrames$posX,yTop-filtereddatAllFrames$posY,type='p',pch='.',lwd=1,col="grey",xlim=c(80,600),ylim=c(0,500),col.axis="red")
    #plot.new()
    warning(paste("No Data To plot trajectories for :",strCond) )
    message(paste("No Data To plot trajectories for :",strCond) )
  }
  
  bFreshPlot = TRUE
  
  procMotFrames = 0;
  procHuntFrames = 0;
  hbinXY = list(); ##List Of Binarized Trajectories
  hbinHXY = list(); ##List Of Binarized Hunting Episode Trajectories
  
  ##Now PLot All Larval Tracks from the Group On the SAME PLOT ##
  idx = 0
  for (i in vexpID)
  {
    idx = idx + 1
    #message(i)
    datLarvalAllFramesHunt <- filtereddatAllFrames[filtereddatAllFrames$expID == i &
                                                     filtereddatAllFrames$REyeAngle <= -G_THRESHUNTANGLE &
                                                     filtereddatAllFrames$LEyeAngle >=G_THRESHUNTANGLE &
                                                     abs(filtereddatAllFrames$LEyeAngle-filtereddatAllFrames$REyeAngle) >= G_THRESHUNTVERGENCEANGLE,]

    procHuntFrames = procHuntFrames + NROW(datLarvalAllFramesHunt)
    
    datLarvalAllFramesAll <- filtereddatAllFrames[filtereddatAllFrames$expID == i,]
    
    procMotFrames = procMotFrames + NROW(datLarvalAllFramesAll)
    
    hbinHXY[[idx]] <- histj(datLarvalAllFramesHunt$posX,yTop-datLarvalAllFramesHunt$posY,seq(0,600,600),seq(0,yTop,20))
    hbinXY[[idx]] <- histj(datLarvalAllFramesAll$posX,yTop-datLarvalAllFramesAll$posY,seq(0,640,10),seq(50,yTop,10))
    
    #points(datLarvalAllFramesAll$posX,datLarvalAllFramesAll$posY,pch='.',col="white",xlim=c(80,565),ylim=c(0,500),col.axis="red")
    if (bFreshPlot)
    {
      plot(datLarvalAllFramesAll$posX,yTop-datLarvalAllFramesAll$posY,type='p',pch='.',col=colMap[which(vexpID == i)],xlim=c(80,600),ylim=c(0,500),col.axis="red")
      bFreshPlot = FALSE
    }else
    {
      points(datLarvalAllFramesAll$posX,yTop-datLarvalAllFramesAll$posY,pch='.',col=colMap[which(vexpID == i)],xlim=c(80,600),ylim=c(0,500),col.axis="red")
    }
    
    points(datLarvalAllFramesHunt$posX,yTop-datLarvalAllFramesHunt$posY,pch=1,lwd=2,col="red",xlim=c(80,600),ylim=c(0,500),col.axis="red")
  }##For Each Larva
  
  sampleSize  <- length(vexpID) #Number of Larvae Used 
  strtitle = paste(strCond,"Motion",collapse=NULL)
  strsub = paste("#n=", sampleSize, " #F:",groupStat$totalFrames,
                 "\n #Hunts:",groupStat$groupHuntEvents,
                 " (mu:", format(groupStat$meanHuntingEventsPerLarva,digits =3),
                 " sig:",format(groupStat$stdHuntingEventsPerLarva,digits=3),") #F_h:",groupStat$huntFrames,
                 "R_h:", format(groupStat$groupHuntRatio,digits=2),
                 "(mu:",format(groupStat$meanHuntRatioPerLarva,digits=3),"sd:",format(groupStat$stdHuntRatioPerLarva,digits=3),")" ,collapse=NULL)
  
  title(strtitle, sub = strsub, cex.main = 1.5,   font.main= 1.5, col.main= "yellow", cex.sub = 1.0, font.sub = 2, col.sub = "red")
  #dev.copy(device=jpeg,filename=paste(strTrajectoryplotFileName,"-plot.jpg"));
  dev.off()
  
  
  
  ###### BINARIZED HISTOGRAM PER GROUP ###
  ## Now Sum All LArva Binarized Trajectories and Display Heat Map
  hGroupbinDensity <- Reduce('+', hbinXY)
  strDensityplotFileName <- paste("plots/binDensity/MotionDensity-BINSet-",strCond,".pdf",collapse=NULL,sep="");
  pdf(strDensityplotFileName,width=8,height=8)
  sampleSize  <- length(vexpID) #Number of Larvae Used 
  hotMap <- c(rfHot(sampleSize),"#FF0000");
  image(seq(0,640,10),seq(50,yTop,10),hGroupbinDensity,axes=TRUE,col=hotMap,xlab="Pos X",ylab="Pos Y")
  title(paste(strCond,"Motion Trajectory Heatmap  #n=", sampleSize, " #F:",procMotFrames),collapse=NULL);
  #dev.copy(jpeg,filename=paste(strDensityplotFileName,"-plot.jpg"));
  dev.off()
  ###
  
  

  ## Now Sum All LArva Binarized Hunting Episode Trajectories and Display Heat Map
  hGroupbinDensity <- Reduce('+', hbinHXY)
  strDensityplotFileName <- paste("plots/binDensity/MotionHuntingDensity-BINSet-",strCond,".pdf",collapse=NULL,sep="");
  pdf(strDensityplotFileName,width=8,height=8)
  sampleSize  <- length(vexpID) #Number of Larvae Used 
  hotMap <- c(rfHot(sampleSize),"#FF0000");
  image(seq(0,600,600),seq(0,yTop,20),hGroupbinDensity,axes=TRUE,col=hotMap,xlab="Pos X",ylab="Pos Y")
  title(paste(strCond,"Motion Hunting Episode  Heatmap  #n=", sampleSize, " #F:",procHuntFrames),collapse=NULL);
  #dev.copy(jpeg,filename=paste(strDensityplotFileName,"-plot.jpg"));
  dev.off()
  ###
  
} ##End of Function



##Test  PlayBack Plot Hunt Event###
renderHuntEventPlayback <- function(datHuntEventMergedFrames,speed=1)
{

  frameWidth = 610
  frameHeight = 470
  
  iConeLength = 100
  ## (see Bianco et al. 2011) : "the functional retinal field as 163˚ after Easter and Nicola (1996)."
  iConeArc = 163/2 ##Degrees Of Assumed Half FOV of Each Eye
  ##Eye Distance taken By Bianco As 453mum, ie 0.5mm , take tracker
  EyeDist = 0.4/DIM_MMPERPX ##From Head Centre
  BodyArrowLength = 13
  LEyecolour = "#00FF00AA"
  REyecolour = "#FF0000AA"
  
  datRenderHuntEvent <- datRenderHuntEvent[datRenderHuntEvent$posX < frameWidth & datRenderHuntEvent$posY < frameHeight ,]
 
  X11()
  startFrame <- min(datHuntEventMergedFrames$frameN)
  endFrame <- max(datHuntEventMergedFrames$frameN)

  for (i in seq(startFrame,endFrame,speed) )
  {
    
    tR = (startFrame: min( c(i,endFrame ) ) )
    ##Multiple Copies Of Fish Can Exist As its Joined the Food Records, when tracking more than one Food Item.
    ## Thus When Rendering the fish Choose one of the food items that appears in the current frame range
    
    
    
    datFishFrames <- datHuntEventMergedFrames[datHuntEventMergedFrames$frameN %in% tR,] ##in Range
    vTrackedPreyIDs <- unique(datFishFrames$PreyID)
    preyTargetID <- min(datFishFrames[datFishFrames$frameN == i,]$PreyID) ##Choose A Prey ID found on the Last Frame The max Id F
    ##Now Isolate Fish Rec, Focus on Single Prey Item
    datFishFrames <- datFishFrames[datFishFrames$PreyID == preyTargetID ,]
    recLastFishFrame <- datFishFrames[datFishFrames$frameN == i,]
    
    
    
    posX = recLastFishFrame$posX
    posY = frameWidth-recLastFishFrame$posY
    bearingRad = pi/180*(recLastFishFrame$BodyAngle-90)##+90+180
    posVX = posX+cos(bearingRad)*BodyArrowLength
    posVY = posY-sin(bearingRad)*BodyArrowLength
    dev.hold()
    ##Plot Track
    plot(datFishFrames$posX,frameWidth-datFishFrames$posY,xlim=c(20,480),ylim=c(0,600),col="black",cex = .5,type='l',xlab="X",ylab="Y")
    ##Plot Current Frame Position
    points(posX,posY,col="black",pch=16)
    
    arrows(posX,posY,posVX,posVY)
    
    ##Draw Eyes 
    ##Left Eye - Requires Inversions due to differences in How Angles Are Calculated in Tracker and In R Plots
    LEyePosX <- posX-cos(bearingRad+pi/180*(45+90))*EyeDist
    LEyePosY <- posY+sin(bearingRad+pi/180*(45+90))*EyeDist
    
    LEyeConeX <- c(LEyePosX,
                   LEyePosX-cos(bearingRad+pi/180*(recLastFishFrame$LEyeAngle+90-iConeArc))*iConeLength,
                   LEyePosX-cos(bearingRad+pi/180*(recLastFishFrame$LEyeAngle+90+iConeArc))*iConeLength )
    
    LEyeConeY <- c(LEyePosY,
                   LEyePosY+sin(bearingRad+pi/180*(recLastFishFrame$LEyeAngle+90-iConeArc))*iConeLength,
                   LEyePosY+sin(bearingRad+pi/180*(recLastFishFrame$LEyeAngle+90+iConeArc))*iConeLength )
    polygon(LEyeConeX,LEyeConeY,col=REyecolour) #density=20,angle=45

    ##Right Eye
    REyePosX <- posX-cos(bearingRad+pi/180*(-45-90))*EyeDist
    REyePosY <- posY+sin(bearingRad+pi/180*(-45-90))*EyeDist
    
    REyeConeX <- c(REyePosX,
                   REyePosX-cos(bearingRad+pi/180*(recLastFishFrame$REyeAngle-90-iConeArc))*iConeLength,
                   REyePosX-cos(bearingRad+pi/180*(recLastFishFrame$REyeAngle-90+iConeArc))*iConeLength )
    
    REyeConeY <- c(REyePosY,
                   REyePosY+sin(bearingRad+pi/180*(recLastFishFrame$REyeAngle-90-iConeArc))*iConeLength,
                   REyePosY+sin(bearingRad+pi/180*(recLastFishFrame$REyeAngle-90+iConeArc))*iConeLength )
    polygon(REyeConeX,REyeConeY,col=LEyecolour) ##,density=25,angle=-45
    
        
    
    ###Draw Prey
    
    for (f in vTrackedPreyIDs)
    {
      lastPreyFrame <- datHuntEventMergedFrames[datHuntEventMergedFrames$frameN == i & datHuntEventMergedFrames$PreyID == f,]
      rangePreyFrame <- datHuntEventMergedFrames[datHuntEventMergedFrames$frameN >= startFrame & datHuntEventMergedFrames$frameN <= i & datHuntEventMergedFrames$PreyID == f,]
      
      if (NROW(lastPreyFrame$Prey_X) > 0 )
      {
        points(lastPreyFrame$Prey_X,frameWidth-lastPreyFrame$Prey_Y,col="red",pch=16)
        lines(rangePreyFrame$Prey_X,frameWidth-rangePreyFrame$Prey_Y,col="red")
        text(lastPreyFrame$Prey_X+5,frameWidth-lastPreyFrame$Prey_Y+10,labels=f,col="darkred",cex=0.5)
      }
    }
    
    dev.flush()
   }
}

############# PLot Heat Map of Movement Trajectories Across COnditions #####
# strTrajectoryDensityFileName <- paste("plots/densities/MotionDensity-Set-",strCond,".pdf",collapse=NULL);
# pdf(strTrajectoryDensityFileName,width=8,height=8)
# eGroupDens <- kde2d(filtereddatAllFrames$posX,filtereddatAllFrames$posY, n=60, lims=c(range(0,565),range(0,565)) )
# image(eGroupDens,col=r)
# #title(paste(strCond,"Group Motion Densities #n=", sampleSize, " #F:",procDatFrames),collapse=NULL);
# title(strtitle, sub = strsub, cex.main = 1.5,   font.main= 1.5, cex.sub = 1.0, font.sub = 2)
# dev.off()
#############################
########
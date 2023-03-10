## Konstantinos Lagogiannis 2018
## TODO Add Auto Success Label detect with datHuntEvent[grepl("Success",as.character(convertToScoreLabel(datHuntEvent$huntScore) ) ) ,]
###Plot Labelled Results ##
source("config_lib.R")
source("plotHuntStat_lib.r")
source("DataLabelling/labelHuntEvents_lib.r")
##source() Needs Plot Hunt Stat for PieChart
## We can update To The Latest DataLabelling by running auxFunctions 
## digestHuntLabels(datHuntLabelledEventsTarget,datHuntLabelledEventsSource)
############# PLOT LABELLED RESULTS ##########
#strProcDataFileName <-paste("setn14-HuntEventsFixExpID-SB-Updated",sep="") ## Latest Updated HuntEvent Labelled data that integrates new COming Labels
#strProcDataFileName <-paste("setn-12-HuntEvents-SB-ALL_19-07-18",sep="") ## Latest Updated HuntEvent Labelled data



### This is the Currently Used Labelled File - Updated and Verified Success
#strProcDataFileName <-paste("setn15-HuntEvents-SB-Updated-Merged",sep="") ## Latest Updated HuntEvent Labelled data that integrates new COming Labels
#message(paste(" Loading Hunt Event List to Process... "))
#load(file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".RData",sep="" )) ##Save With Dataset Idx Identifier
#datHuntLabelledEventsSB <- readRDS(file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".rds",sep="" ))
#datHuntLabelledEventsSB <- datHuntLabelledEventsSB[datHuntLabelledEventsSB$eventID != 0,]
##Using Centralized Function
strProcDataFileName <- "setn15-HuntEvents-SB-Updated-Merged3"
datHuntLabelledEventsSB <- getLabelledHuntEventsSet()
tblResSB <- table(convertToScoreLabel(datHuntLabelledEventsSB$huntScore),datHuntLabelledEventsSB$groupID)


##Load My partially labeled  (KL) Labelled data Merged  
strProcDataFileNameKL <-paste("setn14-D5-18-HuntEvents-Merged",sep="") ##This is the KL labelled data set
datHuntLabelledEventsKL <- readRDS(file=paste(strDatDir,"/LabelledSet/",strProcDataFileNameKL,".rds",sep="" ))
datHuntLabelledEventsKL <- datHuntLabelledEventsKL[datHuntLabelledEventsKL$eventID != 0,]
tblResKL <- table(convertToScoreLabel(datHuntLabelledEventsKL$huntScore),datHuntLabelledEventsKL$groupID)


## Find Tbl Indexes Indicating Success 
tblIdxSuccess <- which (grepl("Success",row.names(tblResSB) ) ) 
tblIdxFail <- which (grepl("Fail",row.names(tblResSB) ) ) 




##############################################
  ## Success / Strike Non Strike Percentage ##
  strPlotName = paste(strPlotExportPath,"/fig4-HuntEventsLabelling-Strike-NoStrike_NF.pdf",sep="")
  pdf(strPlotName,width=5,height=5,bg="white",
      compress=FALSE,onefile = FALSE, 
      title="Breakdown on Fast Vs Slow for Success Vs Failed hunt events - Manual data labels ") #col=(as.integer(filtereddatAllFrames$expID))
  
  outer = FALSE
  line = 3 ## SubFig Label Params
  cex = 1.1
  adj  = 0.5
  padj <- -0
  las <- 1
  lineGroupLabel <- line -  23##pie chart group label
  
  #layout(matrix(c(1,2,3,4,5,6), 1, 3, byrow = TRUE))
  ##c(bottom, left, top, right) 
  par(mar = c(3.0,3.5,3,3.2))
  
  colourL <- rev(brewer.pal(4,'Paired'))
  
  pieChartLabelledSuccessVsFails_StrikeBreakDown(tblResSB,"NL",NA ) ##colourLegE[1]
  mtext(c(expression(),  bquote(" ")),
        at="bottom",  outer=F,side=3,col="black",font=2,las=las,line=lineGroupLabel,padj=padj,adj=adj,cex=cex)
  
  par(fig=c(0, 1, 0, 1), oma=c(0, 0, 0, 0), mar=c(0, 0, 0, 0), new=TRUE)
  plot(0, 0, type='n', bty='n', xaxt='n', yaxt='n')
  
  legend(x=-1.08,y=0.5,legend=c("Success/Fast ","Success/Slow","Fail/Fast","Fail/Slow"),title="Outcome/Capture swim",
         fill=colourL,# c("#66C2A5FF","#66C2A5A1","#A3A3A3FF","#A3A3A3A1"), #c(colourLegL[1],colourL[2]),
         col = colourL,#c("#66C2A5FF","#66C2A5A1","#A3A3A3FF","#A3A3A3A1"), #c(rfc(NROW(ScoreLabels)),"#FF0000");,
         bg = "white",cex=cex,
         merge=FALSE,horiz=F,xpd=TRUE)
  
  ##Bottom Row
  
  dev.off()
  #  ############ END OF
  
  #mtext("A",at="topleft", side=3,col="black",font=2,las=0,line=0,padj=0,adj=0,cex=cex)
  ## Success / Strike Non Strike Percentage ##
  strPlotName = paste(strPlotExportPath,"/fig4-HuntEventsLabelling-Strike-NoStrike_LF.pdf",sep="")
  pdf(strPlotName,width=5,height=5,bg="white",
      compress=FALSE,onefile = FALSE, 
      title="Breakdown on Fast Vs Slow for Success Vs Failed hunt events - Manual data labels ") #col=(as.integer(filtereddatAllFrames$expID))
  par(mar = c(3.0,3.5,3,3.2))
  pieChartLabelledSuccessVsFails_StrikeBreakDown(tblResSB,"LL",NA)
  mtext(c(expression(),  bquote(" ")),
        at="bottom",  outer=F,side=3,col="black",font=2,las=las,line=lineGroupLabel,padj=padj,adj=adj,cex=cex)
  
  dev.off()
  #  ############ END OF
  
  #mtext("Proportions of labelled capture swim speed  per hunting outcome",
  #      at="top", outer=outer,side=3,col="black",font=2,las=las,line=line-2,padj=padj,adj=adj,cex=cex)
  strPlotName = paste(strPlotExportPath,"/fig4-HuntEventsLabelling-Strike-NoStrike_DF.pdf",sep="")
  pdf(strPlotName,width=5,height=5,bg="white",
      compress=FALSE,onefile = FALSE, 
      title="Breakdown on Fast Vs Slow for Success Vs Failed hunt events - Manual data labels ") #col=(as.integer(filtereddatAllFrames$expID))
  par(mar = c(3.0,3.5,3,3.2))
  pieChartLabelledSuccessVsFails_StrikeBreakDown(tblResSB,"DL",NA)
  mtext(c(expression(),  bquote(" ")),
        at="bottom",  outer=F,side=3,col="black",font=2,las=las,line=lineGroupLabel,padj=padj,adj=adj,cex=cex)
  dev.off()
  ### Strike  Vs Non Strike For Capture Swimss
  
  #pieChartLabelledStrikeBreakDown(tblResSB,"NL",c("black","white") )
  #mtext("Overall proportion of capture swim labels ",
  #      at="top",  outer=outer,side=3,col="black",font=2,las=las,line=line-3,padj=padj,adj=adj-4.0,cex=cex)
  
  #pieChartLabelledStrikeBreakDown(tblResSB,"LL",c("black","white"))
  #pieChartLabelledStrikeBreakDown(tblResSB,"DL",c("black","white"))
  
  #legend(x=-1.08,y=-0.1,legend=c("Fast swim","Slow swim"),title=NA,
  #       fill=c("black","white"), #c(colourLegL[1],colourL[2]),
  #       col = c(colourLegL[1],"white"),
  #       bg = "white",cex=cex,
  #       merge=FALSE,horiz=FALSE)
  
  
  
  dev.off()
#  ############ END OF FIG 4 Strike Labelling ###





###Label Summary  /No Target/Escapes /Success / Fail

#display.brewer.all() to see avaulable options
rfc <- colorRampPalette(rev(brewer.pal(11,'Set3')));
r <- c(rfc(30),"#FF0000");
strPlotName = paste(strPlotExportPath,"/HuntEventsLabellingSummary-Both.pdf",sep="")
pdf(strPlotName,width=16,height=8,title="Summary Of Manual Hunt Event Labelling for both SB and KL sets",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))
#X11()
#plot.new()
layout(matrix(c(1,2,3,4,5,6), 2, 3, byrow = TRUE))
#layout(matrix(c(1,2,3), 2, 3, byrow = TRUE))
ScoreLabels <- c("Success","Fail","No Target","Escape")
colourL <-   c(rfc(NROW(ScoreLabels)),"#FF0000");
pieChartLabelledEvents(tblResSB,"DL",colourL) #pieChartLabelledEvents(tblResSB,"DL")
pieChartLabelledEvents(tblResSB,"NL",colourL)
pieChartLabelledEvents(tblResSB,"LL",colourL)
text(x=1.4,y=-0.8,labels = "SB",cex=1.5)  
pieChartLabelledEvents(tblResKL,"DL",colourL) #pieChartLabelledEvents(tblResSB,"DL")
pieChartLabelledEvents(tblResKL,"NL",colourL)
pieChartLabelledEvents(tblResKL,"LL",colourL)
text(x=1.4,y=0.8,labels = "KL",cex=1.5)

legend(-1.55,0.2,legend=ScoreLabels,
       fill=colourL,
       col = colourL,
       bg = "white",cex=1.0,
       merge=FALSE,horiz=FALSE)

dev.off()
######################



###Label ##Sucess Fail Summary Only 
strPlotName = paste(strPlotExportPath,"/HuntEventsLabellingSuccessSummary-SB.pdf",sep="")
pdf(strPlotName,width=8,height=16,bg="white",
    compress=FALSE,onefile = FALSE, 
    title="Summary Of Manual Hunt Event Labelling Conditioning On Prey Tracking Being On") #col=(as.integer(filtereddatAllFrames$expID))

outer = FALSE
line = 1 ## SubFig Label Params
cex = 1.5
adj  = 0.5
padj <- -0
las <- 1

layout(matrix(c(1,2,3,4,4,4), 2, 3, byrow = TRUE))
##Margin: (Bottom,Left,Top,Right )
par(mar = c(3.9,4.4,8,2))

colourL <-  c("#B3B3B3","#66C2A5") #c(rfc(NROW(ScoreLabels)),"#FF0000");
## Get Number Of Larvae / 
nlNL <- NROW(table(datHuntLabelledEventsSB[datHuntLabelledEventsSB$groupID == "NL",]$expID))
nNL <- pieChartLabelledSuccessVsFails(tblResSB,"NL",colourL)
mtext(c(expression(),  bquote("NF"["e"] ~ "#"~ .(nNL) / .(nlNL) )  ),
      at="top",
      outer=outer,side=3,col="black",font=2,las=las,line=line,padj=padj,adj=adj,cex=cex)

legend("topleft",legend=c("Fail","Success"),
       fill=colourL,
       col = colourL,
       bg = "white",cex=3.0,
       merge=FALSE,horiz=FALSE)

## Get Number Of Larvae
nlLL <- NROW(table(datHuntLabelledEventsSB[datHuntLabelledEventsSB$groupID == "LL",]$expID))
nLL <- pieChartLabelledSuccessVsFails(tblResSB,"LL",colourL)
mtext(c(expression(),  bquote("LF"["e"] ~ "#"~ .(nLL) / .(nlLL) )  ),
      at="top",
      outer=outer,side=3,col="black",font=2,las=las,line=line,padj=padj,adj=adj,cex=cex)
## Get Number Of Larvae / 
nlDL <- NROW(table(datHuntLabelledEventsSB[datHuntLabelledEventsSB$groupID == "DL",]$expID))
##Returns Number of Hunt Events
nDL <- pieChartLabelledSuccessVsFails(tblResSB,"DL",colourL) #pieChartLabelledEvents(tblResSB,"DL")
mtext(c(expression(),  bquote("DF"["e"] ~ "#"~ .(nDL) / .(nlDL) )  ),
      at="top",
      outer=outer,side=3,col="black",font=2,las=las,line=line,padj=padj,adj=adj,cex=cex)
#text(x=1.4,y=-0.8,labels = "SB",cex=1.5)  

dev.off()
embed_fonts(strPlotName )


######## Plot Strike Vs No Strike Split In Success And Fail ###
## Find Tbl Indexes Indicating Success 
###Label ##Sucess Fail Summary Only 
strPlotName = paste(strPlotExportPath,"/HuntEventsLabellingSuccessStrikeBreakDown-SB.pdf",sep="")
pdf(strPlotName,width=8,height=16,bg="white",
    compress=FALSE,onefile = FALSE, 
    title="Summary Of Manual Hunt Event Labelling Conditioning On Prey Tracking Being On") #col=(as.integer(filtereddatAllFrames$expID))

colourL <-c(rfc(6),"#FF0000")
outer = FALSE
line = 1 ## SubFig Label Params
cex = 1.5
adj  = 0.5
padj <- -0
las <- 1



layout(matrix(c(1,2,3,4,4,4), 2, 3, byrow = TRUE))
nlNL <- NROW(table(datHuntLabelledEventsSB[datHuntLabelledEventsSB$groupID == "NL",]$expID))
nNL<-pieChartLabelledSuccessVsFails_StrikeBreakDown(tblResSB,"NL",colourL)
mtext(c(expression(),  bquote("NF"["e"] ~ "#"~ .(nNL) / .(nlNL) )  ),
      at="top",
      outer=outer,side=3,col="black",font=2,las=las,line=line,padj=padj,adj=adj,cex=cex)

nlLL <- NROW(table(datHuntLabelledEventsSB[datHuntLabelledEventsSB$groupID == "LL",]$expID))
nLL <- pieChartLabelledSuccessVsFails_StrikeBreakDown(tblResSB,"LL",colourL)
mtext(c(expression(),  bquote("LF"["e"] ~ "#"~ .(nLL) / .(nlLL) )  ),
      at="top",
      outer=outer,side=3,col="black",font=2,las=las,line=line,padj=padj,adj=adj,cex=cex)

nlDL <- NROW(table(datHuntLabelledEventsSB[datHuntLabelledEventsSB$groupID == "DL",]$expID))
nDL <-pieChartLabelledSuccessVsFails_StrikeBreakDown(tblResSB,"DL",colourL)
mtext(c(expression(),  bquote("DF"["e"] ~ "#"~ .(nDL) / .(nlDL) )  ),
      at="top",
      outer=outer,side=3,col="black",font=2,las=las,line=line,padj=padj,adj=adj,cex=cex)
legend("bottomright",legend=c("Success Noclass","Success Strike","Success No Strike","Fail Strike","Fail No Strike"),
       fill=colourL,
       col = colourL,
       bg = "white",cex=1.0,
       merge=FALSE,horiz=FALSE)
dev.off()

# 
# ## PLOT SCATTER Of Success Vs Fail For Each Group 
# strPlotName = paste(strPlotExportPath,"/HuntLabelsSuccessVsFailScatter-SB.pdf",sep="")
# pdf(strPlotName,width=8,height=8,title="Labelled Success Vs Fails Hunt Events For Each Fish ",onefile = TRUE) #col=(as.integer(filtereddatAllFrames$expID))
#   strProcDataFileName <-paste("setn12-HuntEvents-SB-Updated",sep="") ## Latest Updated HuntEvent Labelled data that integrates new COming Labels
#   strProcDataFileName <- "setn14-HuntEventsFixExpID-SB-Updated"
# #strProcDataFileName <-paste("setn-12-HuntEvents-SB-ALL_19-07-18",sep="") ## Latest Updated HuntEvent Labelled data
#   message(paste(" Loading Hunt Event List to Analyse... "))
# #load(file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".RData",sep="" )) ##Save With Dataset Idx Identifier
#   datHuntLabelledEventsSB <- readRDS(file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".rds",sep="" ))
#   datFishSuccessRate <- getHuntSuccessPerFish(datHuntLabelledEventsSB)
# ###PLOT
#   #layout()
#   plot(datFishSuccessRate[datFishSuccessRate$groupID == "DL",]$Fails,datFishSuccessRate[datFishSuccessRate$groupID == "DL",]$Success,
#      pch=pchL[1],col=colourD[1],
#      main="Hunt performance per larva",
#      xlab="#Capture Failures",
#      ylab="#Capture Success",ylim=c(0,max(datFishSuccessRate$Success)+1) )  
#   points(datFishSuccessRate[datFishSuccessRate$groupID == "LL",]$Fails,datFishSuccessRate[datFishSuccessRate$groupID == "LL",]$Success,pch=pchL[2],col=colourD[2])
#   points(datFishSuccessRate[datFishSuccessRate$groupID == "NL",]$Fails,datFishSuccessRate[datFishSuccessRate$groupID == "NL",]$Success,pch=pchL[3],col=colourD[3])
#   legend("topleft",legend=c("DL","LL","NL"), pch=pchL,col=colourL)
#   
# dev.off()


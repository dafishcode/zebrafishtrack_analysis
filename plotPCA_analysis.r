### Oct 2019 : utility plot scripts produced during pCA analysis - Saved here for reference
#### PCA Analysis ##


## NOTE "Load required data as in main_GenerateMSFigures.r , Before Calling any plot section

#######################################
########## PCA  - FACTOR ANALYSIS ####
#######################################

source("DataLabelling/labelHuntEvents_lib.r")
source("plotPCA_lib.r")

########### LOAD DATA ANd Prepare Structures ####
datTrackedEventsRegister <- readRDS( paste(strDataExportDir,"/setn_huntEventsTrackAnalysis_Register_ToValidate.rds",sep="") ) ## THis is the Processed Register File On 
#lMotionBoutDat <- readRDS(paste(strDataExportDir,"/huntEpisodeAnalysis_MotionBoutData_SetC.rds",sep="") ) #Processed Registry on which we add )
#lEyeMotionDat <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_EyeMotionData_SetC",".rds",sep="")) #
lFirstBoutPoints <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_wCapFrame_Validated.rds",sep="")) ##Original :huntEpisodeAnalysis_FirstBoutData_Validated

#### Plot Raw Capture Data Indicating Low/High Speed Clustering for each
### Load Pre Calc RJAgs Model Results
##   stat_CaptSpeedVsDistance_RJags.RData ##stat_CaptSpeedCluster_RJags.RData
load(file =paste(strDataExportDir,"stat_CaptSpeedVsDistance_RJags.RData",sep=""))

## The scriptlet to run the labelling process on a set of expID is found in auxFunctions.r
datFlatPxLength <- read.csv(file= paste(strDataExportDir,"/FishLength_Updated2.csv",sep=""))
message(paste(" Loading Measured fish length in pixels data ... "))


#### LOAD Capture First-Last Bout hunting that include the cluster classification - (made in stat_CaptureSpeedVsDistanceToPrey)
datCapture_NL <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_wCapFrame_NL_clustered.rds",sep="")) 
datCapture_LL <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_wCapFrame_LL_clustered.rds",sep="")) 
datCapture_DL <- readRDS(file=paste(strDataExportDir,"/huntEpisodeAnalysis_FirstBoutData_wCapFrame_DL_clustered.rds",sep="")) 

datHuntLabelledEventsSB <- getLabelledHuntEventsSet()
datFishSuccessRate <- getHuntSuccessPerFish(datHuntLabelledEventsSB)

## Load the Model Based Larvae Behaviour Estimation
## datHunterStat_Model
load(file = paste0(strDataExportDir,"stat_Larval3DGaussianBehaviourModelPerLarva.RData"))

# Check Correlation Of UNdershoot With Hunt POwer
##Take all expID from the successful hunt Events we have extracted hunt variables from 
vexpID <- list(LF = datTrackedEventsRegister[datCapture_LL$RegistarIdx,]$expID,
               NF=datTrackedEventsRegister[datCapture_NL$RegistarIdx,]$expID,
               DF=datTrackedEventsRegister[datCapture_DL$RegistarIdx,]$expID)

#datFishSuccessRate[datFishSuccessRate$expID %in% vexpID$LF, ]$HuntPower

## Add Exp ID Column - Signifying Which Larvae Executed the Capture Success Hunt- 
datCapture_LF_wExpID <- cbind(datCapture_LL,expID=vexpID$LF)
datCapture_NF_wExpID <- cbind(datCapture_NL,expID=vexpID$NF)
datCapture_DF_wExpID <- cbind(datCapture_DL,expID=vexpID$DF)


##Merge Hunt Power To Hunt-Capture Variables 
datMergedCapAndSuccess_LF <- merge(x=datCapture_LF_wExpID,y=datFishSuccessRate,by="expID",all.x=TRUE)
datMergedCapAndSuccess_NF <- merge(x=datCapture_NF_wExpID,y=datFishSuccessRate,by="expID",all.x=TRUE)
datMergedCapAndSuccess_DF <- merge(x=datCapture_DF_wExpID,y=datFishSuccessRate,by="expID",all.x=TRUE)

## Merge 
mergedCapDat <- rbind(datMergedCapAndSuccess_LF,datMergedCapAndSuccess_DF,datMergedCapAndSuccess_NF)

mergedCapDat$groupID <- as.factor(mergedCapDat$groupID)
groupLabels <- levels(mergedCapDat$groupID)
## Now Compile  Behaviour data Per Larvae
mergedCapDat$groupID <- as.numeric(mergedCapDat$groupID)
mergedCapDat_mod<-mergedCapDat ##Temp Copy
mergedCapDat_mod$expID <- as.numeric(as.character(mergedCapDat_mod$expID))
##Empirical Estimates Of behaviour Per Larvae
datHunterStat <- aggregate(mergedCapDat_mod,by=list(mergedCapDat_mod$expID),mean)

##Recover Group ID Factor
datHunterStat$groupIDF <- levels(datTrackedEventsRegister$groupID)[datHunterStat$groupID]
##Error Check Assert - Check IDs Have been Matched
stopifnot(datHunterStat[datHunterStat$groupIDF == 'DL',]$expID %in% unique(datTrackedEventsRegister[datTrackedEventsRegister$groupID == 'DL',]$expID))
stopifnot(datHunterStat[datHunterStat$groupIDF == 'LL',]$expID %in% unique(datTrackedEventsRegister[datTrackedEventsRegister$groupID == 'LL',]$expID))


## Fix Model HUntStat With Efficiency and Hunt Power (These Do not change by Modelling) ..
datHunterStat_Model <- merge(x=datHunterStat,y=datHunterStat_Model,by="expID",all.x=TRUE)
datHunterStat_Model$CaptureSpeed <- datHunterStat_Model$CaptureSpeed.y #datHunterStat[datHunterStat$expID %in% datHunterStat_Model$expID, ]$Efficiency
datHunterStat_Model$Undershoot <- datHunterStat_Model$Undershoot.y #datHunterStat[datHunterStat$expID %in% datHunterStat_Model$expID, ]$Efficiency
datHunterStat_Model$DistanceToPrey <- datHunterStat_Model$DistanceToPrey.y #datHunterStat[datHunterStat$expID %in% datHunterStat_Model$expID, ]$Efficiency
#datHunterStat_Model$HuntPower <- datHunterStat[datHunterStat$expID %in% datHunterStat_Model$expID, ]$HuntPower
#datHunterStat_Model$FramesToHitPrey <- datHunterStat[datHunterStat$expID %in% datHunterStat_Model$expID, ]$FramesToHitPrey
#datHunterStat_Model$groupID <- datHunterStat[datHunterStat$expID %in% datHunterStat_Model$expID, ]$groupID

### Standardize Data - Ready for PCA
datHunterStatModel_norm <- standardizeHuntData(datHunterStat_Model) ##Model Based Mean Larva Behaviour 
datHunterStat_norm <- standardizeHuntData(datHunterStat) ##Mean Larva Behaviour
mergedCapDat <- standardizeHuntData(mergedCapDat) ##Independent Hunt Events
# Show Stdandardized Efficiency Distribution 
#hist(datHunterStat$Efficiency_norm )

### PCA ANalysis Of Variance - Finding the Factors That contribute to efficiency
strfilename_model <- "/stat/stat_PCAHuntersBehaviourModelPC1_2_GroupColour_ALL.pdf"
strfilename_empirical <- "/stat/stat_PCAHuntersBehaviourPC1_2_GroupColour_ALL.pdf"


## PCA Regression ##
## Choose Optimal Set of Component that yield best prediction of Efficiency
datHunterStatModel_norm_filt <- datHunterStatModel_norm[datHunterStatModel_norm$CaptureEvents > MIN_CAPTURE_EVENTS_PCA,]

######### Show PCA For Hunter / MODEL '#####
pca_Model <- plotPCAPerHunter(datHunterStatModel_norm_filt,strfilename_model)
######### Show PCA For Hunter / Empirical '#####
plotPCAPerHunter(datHunterStat_norm[datHunterStat_norm$CaptureEvents > MIN_CAPTURE_EVENTS_PCA,],strfilename_empirical)

datHuntsWithEfficiency_norm_filt <- standardizeHuntData(mergedCapDat_mod[mergedCapDat_mod$CaptureEvents > 2,])
pca_Model_hunts <- plotPCAPerHunter(datHuntsWithEfficiency_norm_filt,"/stat/testpca.pdf")

##Make Regression With Covariate Products Speed-Distance
datPCAHunter_norm_Cov <- data.frame( with(datHunterStatModel_norm_filt,{ #,'DL','NL' mergedCapDat$HuntPower < 5
  cbind(Efficiency=Efficiency, #1
        Attempts=CaptureAttempts_norm, ##Efficiency is fraction of Succsss/Attempts <- Include it so as to remove this variance
        #HuntPower=HuntPower_norm, #2 ## Does not CoVary With Anyhting 
        #Group=groupID, #3
        DistanceToPrey=DistanceToPrey_norm, #4
        CaptureSpeed_norm, #5
        Undershoot_norm, #6
        DistSpeedProd=DistSpeed_norm, #7
        DistSpeedUnderProd=DistSpeedUnder_norm, #8
        SpeedUnderhoot=SpeedUnder_norm, #9
        TimeToHitPrey=TimeToHitPrey_norm #10
        #Cluster=Cluster#11
  )                                   } )          )

## Regression Only  Speed-Distance Covariate Added
datPCAHunter_norm_distSpeed <- data.frame( with(datHunterStatModel_norm_filt,{ #,'DL','NL' mergedCapDat$HuntPower < 5
  cbind(Efficiency=Efficiency, #1
        Attempts=CaptureAttempts_norm, ##Efficiency is fraction of Succsss/Attempts <- Include it so as to remove this variance
        #HuntPower=HuntPower_norm, #2 ## Does not CoVary With Anyhting 
        #Group=groupID, #3
        DistanceToPrey=DistanceToPrey_norm, #4
        CaptureSpeed_norm, #5
        Undershoot_norm, #6
        DistSpeedProd=DistSpeed_norm, #7
        #DistSpeedUnderProd=DistSpeedUnder_norm, #8
        #SpeedUnderhoot=SpeedUnder_norm, #9
        TimeToHitPrey=TimeToHitPrey_norm #10
        #Cluster=Cluster#11
  )                                   } )          )

## Regression WithOUT Covariate Products Speed-Distance
datPCAHunter_norm <- data.frame( with(datHunterStatModel_norm_filt,{ #,'DL','NL' mergedCapDat$HuntPower < 5
  cbind(Efficiency=Efficiency, #1
        Attempts=CaptureAttempts_norm, ##Efficiency is fraction of Succsss/Attempts <- Include it so as to remove this variance
        #HuntPower=HuntPower_norm, #2 ## Does not CoVary With Anyhting 
        #Group=groupID, #3
        DistanceToPrey=DistanceToPrey_norm, #4
        CaptureSpeed_norm, #5
        Undershoot_norm, #6
        #DistSpeedProd=DistSpeed_norm, #7
        #DistSpeedUnderProd=DistSpeedUnder_norm, #8
        #SpeedUnderhoot=SpeedUnder_norm, #9
        TimeToHitPrey=TimeToHitPrey_norm #10
        #Cluster=Cluster#11
  )                                   } )          )


datPCAHuntEvents_norm <-  data.frame( with(datHuntsWithEfficiency_norm_filt,{ #,'DL','NL' mergedCapDat$HuntPower < 5
  cbind(Efficiency=Efficiency, #1
        Attempts=CaptureAttempts_norm, ##Efficiency is fraction of Succsss/Attempts <- Include it so as to remove this variance
        #HuntPower=HuntPower_norm, #2 ## Does not CoVary With Anyhting 
        #Group=groupID, #3
        DistanceToPrey=DistanceToPrey_norm, #4
        CaptureSpeed_norm, #5
        Undershoot_norm, #6
        #DistSpeedProd=DistSpeed_norm, #7
        #DistSpeedUnderProd=DistSpeedUnder_norm, #8
        #SpeedUnderhoot=SpeedUnder_norm, #9
        TimeToHitPrey=TimeToHitPrey_norm #10
        #Cluster=Cluster#11
  )                                   } )          )


####### MODEL ####
### Using Package to Do PCA Regression to Find how much we can explain Efficiency
require(pls)
set.seed (20000)
#datPCAHunter_norm$EfficiencyV <- datHunterStatModel_norm_filt$Efficiency
## PCR Concentrates on the Variance X
pcr_model_prod <- pcr(Efficiency~., data = datPCAHunter_norm_Cov, scale = FALSE, validation = "CV",segments=10)
pcr_model <- pcr(Efficiency~ Attempts + DistanceToPrey + CaptureSpeed_norm + Undershoot_norm + TimeToHitPrey ,
                 data = datPCAHunter_norm, scale = FALSE, validation = "CV",segments=10)
###Check Out PLSR - Uses Info of Both Efficiency And X - Describes as much as possile of the covariance between Y and X
plsr_model <- plsr(Efficiency~., data = datPCAHunter_norm, scale = FALSE, validation = "CV",segments=4)

summary(pcr_model_prod)
summary(pcr_model)
summary(plsr_model)

plot(pcr_model,plottype="validation",ylim=c(0.1,0.2))

plot(pcr_model_prod,plottype="validation",ylim=c(0.1,0.2))

pcr_model_prod      <- pcr(Efficiency~., data = datPCAHunter_norm_Cov, scale = FALSE, validation = "CV")
pcr_model_distSpeed <- pcr(Efficiency~., data = datPCAHunter_norm_distSpeed, scale = FALSE, validation = "CV")

##This one is used on MS 
pcr_model <- pcr(Efficiency~., data = datPCAHunter_norm, scale = FALSE, validation = "CV")
err_model <- RMSEP(pcr_model,estimate="CV")

plsr_model <- plsr(Efficiency~., data = datPCAHunter_norm, scale = FALSE, validation = "CV")




summary(pcr_model_prod) ##With All Covariates
summary(pcr_model_distSpeed) ## With Speed-Dist Covariates
summary(pcr_model) ## With No Covariates

summary(plsr_model)

## Originally We assume Mean Behaviour should predict a larva's capture efficiency
## What about individual successful hunt event behaviours, do they predict the efficiency of the larva they came from?
##Hunt Events Indepently
pcr_model_Hunts     <- cppls(Efficiency ~  CaptureEvents +  CaptureSpeed + DistanceToPrey + Undershoot + CaptureEvents + TimeToHitPrey_norm  
                           ,data = datHuntsWithEfficiency_norm_filt, scale = TRUE, validation = "CV")##No Mean Beahviour Just associate Individual Successful Hunt with effiency
summary(pcr_model_Hunts)
plot(pcr_model_Hunts)
predplot(pcr_model_Hunts,asp=1,ncomp=5,line=TRUE,xlim=c(0.0,1.0),ylim=c(0,1),
         main="Efficiency Prediction based on Hunt Event",cex=cex,xlab="Measured",ylab="Predicted")

##Prediction Plot - Very Weak relationship
#"PC Regression - Efficiency Prediction"
pdf(file= paste(strPlotExportPath,"/stat/efficiency/stat_PCARegPredictEfficiency.pdf",sep=""),width=7,height=7)
## bottom, left,top, right
  par(mar = c(4.3,4.3,2,1))
  predplot(pcr_model,asp=1,ncomp=5,line=TRUE,xlim=c(0.0,0.8),ylim=c(0,0.8),
           main=NA,cex=cex,cex.axis=cex,xlab=NA,ylab=NA)
  #predplot(pcr_model,asp=1,ncomp=4,line=TRUE,xlim=c(0,1.0),ylim=c(0,1))
  
  points(cbind(datPCAHunter_norm$Efficiency,predict(pcr_model,ncomp=2) ),xlim=c(0.0,1.0),ylim=c(0,1),
         col="red",pch=2,cex=cex,asp=1 ,xlab="Measured",ylab="Predicted")
  legend("topright",c(paste("5 PCs RMSEP CV",prettyNum(err_model$val[6],digits=2)),
                         paste( "2 PCs RMSEP CV",prettyNum(err_model$val[3],digits=2))),
                         pch=c(1,2),col=c("black","red"),cex=cex )
  
  mtext(side = 1,cex=cex, line = lineXAxis, expression(paste("Measured larval capture efficiency" ) ) ,cex.main=cex )
  mtext(side = 2,cex=cex, line = lineAxis, expression("Predicted larval capture efficiency"  ))
  
dev.off()

  ###The validation results here are root mean squared error of prediction (RMSEP).
  plot(RMSEP(pcr_model_prod), legendpos = "topright",ylim=c(0.1,0.5))
  plot(RMSEP(pcr_model), legendpos = "topright",ylim=c(0.1,0.5),add=T)
  
  plot(pcr_model, plottype = "scores", comps = 1:3)
  explvar(pcr_model)
  explvar(pcr_model_prod)
  
  
plot(pcr_model_prod,ncomp = 1:7,plottype = "coef")

plot(datPCAHunter_norm$Efficiency)


##
##cite("pls",bib)

plotPCAPerHunter(datHunterStatModel_norm_filt,strfilename_model)

pca_Hunter_norm <- prcomp(datHunterStatModel_norm_filt,scale.=FALSE)
biplot(pca_Hunter_norm,choices=c(1,4))











### Old Way Follows

##Get Eigen Matrix
Ei_LF_norm=eigen(cov(datPCAHunter_norm))
pca_Hunter_norm <- prcomp(datPCAHunter_norm,scale.=FALSE)
biplot(pca_Hunter_norm,choices=c(1,4))
#Principal Component Analysis and Linear Regression
p1 <- Ei_LF_norm$vectors[1,1]*datPCAHunter_norm$DistanceToPrey + Ei_LF_norm$vectors[2,1]*datPCAHunter_norm$CaptureSpeed_norm + Ei_LF_norm$vectors[3,1]*datPCAHunter_norm$Undershoot_norm + Ei_LF_norm$vectors[4,1]*datPCAHunter_norm$TimeToHitPrey
p2 <- Ei_LF_norm$vectors[1,2]*datPCAHunter_norm$DistanceToPrey + Ei_LF_norm$vectors[2,2]*datPCAHunter_norm$CaptureSpeed_norm + Ei_LF_norm$vectors[3,2]*datPCAHunter_norm$Undershoot_norm + Ei_LF_norm$vectors[4,2]*datPCAHunter_norm$TimeToHitPrey
p3 <- Ei_LF_norm$vectors[1,3]*datPCAHunter_norm$DistanceToPrey + Ei_LF_norm$vectors[2,3]*datPCAHunter_norm$CaptureSpeed_norm + Ei_LF_norm$vectors[3,3]*datPCAHunter_norm$Undershoot_norm + Ei_LF_norm$vectors[4,3]*datPCAHunter_norm$TimeToHitPrey
p4 <- Ei_LF_norm$vectors[1,4]*datPCAHunter_norm$DistanceToPrey + Ei_LF_norm$vectors[2,4]*datPCAHunter_norm$CaptureSpeed_norm + Ei_LF_norm$vectors[3,3]*datPCAHunter_norm$Undershoot_norm + Ei_LF_norm$vectors[4,4]*datPCAHunter_norm$TimeToHitPrey
y <- datHunterStatModel_norm$Efficiency_norm

##PCA Reegression
linRPCA <- lm(formula = y ~ p1 + p2 + p3 + p4 + p1*p2*p3*p4)
summary(linRPCA)

##PCA Reegression
linRPCA_M <- lm(formula = y ~ p1 + p2 + p3 + p4 + p1*p2*p3*p4)
summary(linRPCA)


##MakeNew Model
gammaU <- cbind( Ei_LF_norm$vectors[,1],Ei_LF_norm$vectors[,2],0,0)
Ei_LF_norm$vectors*gammaU
plot(linRPCA$coefficients[1]
     #     +linRPCA$coefficients[2]*p1
     #     +linRPCA$coefficients[3]*p2
     #     +linRPCA$coefficients[4]*p3
     #     +linRPCA$coefficients[5]*p4
     #     +linRPCA$coefficients[6]*p1*p2
     +linRPCA$coefficients[9]*p1*p4 
     ,y)

plot(linRPCA)


###Make/Test a linear Prediction Model
X1 <- datPCAHunter_norm$DistanceToPrey
X2 <- datPCAHunter_norm$CaptureSpeed_norm
X3 <- datPCAHunter_norm$Undershoot_norm
X4 <- datPCAHunter_norm$TimeToHitPrey
X5 <- datPCAHunter_norm$Attempts
y <- datPCAHunter_norm$Efficiency
##Std Regression
linR <- lm(formula = y ~ X1 + X2 + X3 + X4+X5+X1*X2*X3)
summary(linR)

plot(y,linR$coefficients[1]+ linR$coefficients[2]*X1+ linR$coefficients[3]*X2 + linR$coefficients[3]*X3 + linR$coefficients[4]*X4 + linR$coefficients[5]*X5 +
       X1*X2*X3*linR$coefficients[10],
     xlab="measured Efficiency",ylab="Linear mod. Predicted")

##Add Significant Factors Onaly
plot(y,linR$coefficients[1]+ linR$coefficients[5]*X5 +
       X1*X2*X3*linR$coefficients[10],
     xlab="measured Efficiency",ylab="Linear mod. Predicted")


###Change The Filter Here, Do PCA again and then Locate and plto group Specific
mergedCapDat_filt <- mergedCapDat #mergedCapDat[mergedCapDat$groupID == 'NL',]

datpolyFactor_norm <- data.frame( with(mergedCapDat_filt,{ #,'DL','NL' mergedCapDat$HuntPower < 5
  cbind(Efficiency=Efficiency_norm, #1
        #HuntPower, #2 ## Does not CoVary With Anyhting 
        #Group=groupID, #3
        DistanceToPrey=DistanceToPrey_norm, #4
        CaptureSpeed_norm, #5
        Undershoot_norm, #6
        DistSpeedProd=DistSpeed_norm, #7
        #DistUnderProd=DistUnder_norm, #8
        #SpeedUnderProd=SpeedUnder_norm, #9
        TimeToHitPrey=TimeToHitPrey_norm, #10
        Cluster=Cluster#11
  )                                   } )          )


###
pca_norm <- prcomp(datpolyFactor_norm,scale.=FALSE)
summary(pca_norm)
pcAxis <- c(1,2,1)
rawd <- pca_norm$x[,pcAxis]

biplot(pca_norm,choices=c(1,2))




###Change The Filter Here, Do PCA again and then Locate and plto group Specific
mergedCapDat_filt <- mergedCapDat #mergedCapDat[mergedCapDat$groupID == 'NL',]

datpolyFactor_norm <- data.frame( with(mergedCapDat_filt,{ #,'DL','NL' mergedCapDat$HuntPower < 5
  cbind(Efficiency=Efficiency_norm, #1
        #HuntPower, #2 ## Does not CoVary With Anyhting 
        #Group=groupID, #3
        DistanceToPrey=DistanceToPrey_norm, #4
        CaptureSpeed_norm, #5
        Undershoot_norm, #6
        DistSpeedProd=DistSpeed_norm, #7
        #DistUnderProd=DistUnder_norm, #8
        #SpeedUnderProd=SpeedUnder_norm, #9
        TimeToHitPrey=TimeToHitPrey_norm, #10
        Cluster=Cluster#11
  )                                   } )          )


###
pca_norm <- prcomp(datpolyFactor_norm,scale.=FALSE)
summary(pca_norm)
pcAxis <- c(1,2,1)
rawd <- pca_norm$x[,pcAxis]

biplot(pca_norm,choices=c(1,2))


pchLPCA <- c(15,17,16)

pdf(file= paste(strPlotExportPath,"/stat/stat_PCAHuntVariablesAndEfficiencyPC1_2_GroupColour_ALL.pdf",sep=""),width=7,height=7)
  ## bottom, left,top, right
  par(mar = c(4.2,4.3,1,1))
  
  plot(rawd[,1], rawd[,2],
       ######col=colClass[1+as.numeric(mergedCapDat$Undershoot > 1)], pch=pchL[4+datpolyFactor_norm$Group], 
       #col=colEfficiency[round(mergedCapDat_filt$Efficiency*10)], pch=pchL[4+as.numeric(mergedCapDat_filt$groupID) ],
       #col=colClass[as.numeric(mergedCapDat_filt$Cluster)], pch=pchLPCA[as.numeric(mergedCapDat_filt$groupID)],
       col=colourGroup[mergedCapDat_filt$groupID ], pch=pchLPCA[as.numeric(mergedCapDat_filt$groupID)],
       #xlab="PC1",ylab="PC2",
       xlim=c(-2.5,2.5),ylim=c(-2,2.5),
       xlab=NA,ylab=NA,
       cex=cex,cex.axis=cex ) #xlim=c(-4,4),ylim=c(-4,4)
  mtext(side = 1,cex=cex, line = lineXAxis,  "PC1"   ,cex.main=cex )
  mtext(side = 2,cex=cex, line = lineAxis, "PC2" ,cex.main=cex)
  
  
  scaleV <- 2
  ##Distance to Prey Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],lwd=3)
  text(0.7*scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.2*scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],labels="Distance")
  ##CaptureSpeed  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[2],lwd=2,lty=3)
  text(0.8*scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+0.8*scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[2],labels="Speed")
  
  ##Undershoot Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2)
  #  text(0.4*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.1*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Overshoot")
  arrows(0,0,-scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2,lwd=2)
  text(-1.5*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-1.0*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",labels="Undershoot")
  
  ##TimeToHit Prey Prod Axis  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],lty=5,lwd=2)
  text(0.8*scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.2*scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],labels="t Prey")
  
  ##DistXSpeed Prod Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[5,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[5,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="purple",lty=5)
  
  ##EFFICIENCY Prod Axis  Component Projection
  scaleVE <- scaleV
  arrows(0,0,scaleVE*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleVE*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",lty=2,lwd=2)
  text(0.4*scaleV*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+1.0*scaleV*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",labels="Efficiency")
  
  # ##Heat Map Scale
  # points(seq(1,2,1/10),rep(-2,11),col=colEfficiency,pch=15,cex=3)
  # text(1,-1.8,col="black",labels= prettyNum(min(mergedCapDat_filt$Efficiency),digits=1,format="f" ),cex=cex)
  # text(1+0.5,-1.8,col="black",labels= prettyNum(max(mergedCapDat_filt$Efficiency)/2,digits=1,format="f" ),cex=cex)
  # text(2,-1.8,col="black",labels= prettyNum(max(mergedCapDat_filt$Efficiency),digits=1,format="f" ),cex=cex)
  # max(mergedCapDat_filt$Efficiency)/2
  # 
  
  legend("bottomleft",legend=c( paste0(groupLabels[3],' #',table(mergedCapDat_filt$groupID)[3]),
                                paste0(groupLabels[2],' #',table(mergedCapDat_filt$groupID)[2]),
                                paste0(groupLabels[1],' #',table(mergedCapDat_filt$groupID)[1]) 
  ),
  pch=c(pchLPCA[3],pchLPCA[2],pchLPCA[1]),
  col=c(colourGroup[3],colourGroup[2],colourGroup[1]) )## c(colourLegL[2],colourLegL[3],colourLegL[1])) # c(colourH[3],colourH[2])
  #legend("bottomright",legend=c("Slow","Fast"),fill=colClass, col=colClass,title="Cluster")## c(colourLegL[2],colourLegL[3],colourLegL[1])) # c(colourH[3],colourH[2])
  
  #Percentage of Efficiency Variance Explained
  nComp <- length(pca_norm$sdev)
  pcEffVar <- ((pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]])^2 + (pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]])^2)
  EffVar <- sum((pca_norm$rotation[1,][1:nComp]*pca_norm$sdev[1:nComp])^2)
  
  title(NA,sub=paste(" Efficiency variance captured: ",prettyNum( 100*pcEffVar/EffVar,digits=3), " Coeff. variation:",prettyNum(sd(mergedCapDat_filt$Efficiency)/mean(mergedCapDat_filt$Efficiency) ,digits=2)) )
  message("Captured Variance ",prettyNum( (pca_norm$sdev[pcAxis[1]]^2 + pca_norm$sdev[pcAxis[2]]^2) /sum( pca_norm$sdev ^2),digits=3,format="f" ) )
  message(paste(" Efficiency variance captured: ",prettyNum( 100*pcEffVar/EffVar,digits=3), " Coeff. variation:",prettyNum(sd(mergedCapDat_filt$Efficiency)/mean(mergedCapDat_filt$Efficiency) ,digits=2)))

dev.off()


pdf(file= paste(strPlotExportPath,"/stat/stat_PCAHuntVariablesAndEfficiencyPC1_2_EfficiencyColour_DF.pdf",sep=""),width=7,height=7)
  
  plot(rawd[,1], rawd[,2],
       #col=colClass[1+as.numeric(mergedCapDat$Undershoot > 1)], pch=pchL[4+datpolyFactor_norm$Group], 
       #col=colEfficiency[round(mergedCapDat_filt$Efficiency*10)], pch=pchL[4+as.numeric(mergedCapDat_filt$groupID) ],
       col=colClass[as.numeric(mergedCapDat_filt$Cluster)], pch=pchLPCA[as.numeric(mergedCapDat_filt$groupID)],
       #col=colourLegL[datpolyFactor_norm$Group], pch=pchL[4+as.numeric(mergedCapDat_filt$groupID)],
       #xlab="PC1",ylab="PC2",
       xlim=c(-2.5,2.5),ylim=c(-2,2.5),
       xlab=NA,ylab=NA,
       cex=cex,cex.axis=cex ) #xlim=c(-4,4),ylim=c(-4,4)
  mtext(side = 1,cex=cex, line = lineXAxis,  "PC1"   ,cex.main=cex )
  mtext(side = 2,cex=cex, line = lineAxis, "PC2" ,cex.main=cex)
  
  
  scaleV <- 2
  ##Distance to Prey Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],lwd=3)
  text(0.8*scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.5*scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],labels="Distance")
  ##CaptureSpeed  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[2],lwd=2,lty=3)
  text(0.8*scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+0.8*scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[2],labels="Speed")
  
  ##Undershoot Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2)
  #  text(0.4*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.1*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Overshoot")
  arrows(0,0,-scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2,lwd=2)
  text(-1.5*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-1.0*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",labels="Undershoot")
  
  ##TimeToHit Prey Prod Axis  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],lty=5,lwd=2)
  text(0.8*scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.2*scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],labels="t Prey")
  
  ##DistXSpeed Prod Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[5,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[5,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="purple",lty=5)
  
  ##EFFICIENCY Prod Axis  Component Projection
  scaleVE <- scaleV
  arrows(0,0,scaleVE*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleVE*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",lty=2,lwd=2)
  text(0.4*scaleV*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.0+1.0*scaleV*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",labels="Efficiency")
  
  legend("bottomleft",legend=c("NF","LF","DF"),pch=c(pchLPCA[3],pchLPCA[2],pchLPCA[1]),
         col="black")## c(colourLegL[2],colourLegL[3],colourLegL[1])) # c(colourH[3],colourH[2])
  legend("bottomright",legend=c("Slow","Fast"),fill=colClass, col=colClass,title="Cluster")## c(colourLegL[2],colourLegL[3],colourLegL[1])) # c(colourH[3],colourH[2])
  
  #Percentage of Efficiency Variance Explained
  nComp <- length(pca_norm$sdev)
  pcEffVar <- ((pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]])^2 + (pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]])^2)
  EffVar <- sum((pca_norm$rotation[1,][1:nComp]*pca_norm$sdev[1:nComp])^2)
  title(NA,sub=paste("% of Efficiency Variance Explained : ",prettyNum( 100*pcEffVar/EffVar) ))
  

dev.off()








pdf(file= paste(strPlotExportPath,"/stat/stat_PCAHuntVariablesAndEfficiencyPC1_2_EfficiencyColour_LF.pdf",sep=""),width=7,height=7)
  
  plot(rawd[,1], rawd[,2],
       #col=colClass[1+as.numeric(mergedCapDat$Undershoot > 1)], pch=pchL[4+datpolyFactor_norm$Group], 
       col=colEfficiency[round(mergedCapDat_filt$Efficiency*10)], pch=pchLPCA[as.numeric(mergedCapDat_filt$groupID) ],
       #col=colClass[as.numeric(mergedCapDat_filt$Cluster)], pch=pchL[4+datpolyFactor_norm$Group],
       #col=colourLegL[datpolyFactor_norm$Group], pch=pchL[4+datpolyFactor_norm$Group],
       #xlab="PC1",ylab="PC2",
       xlim=c(-2.5,2.5),ylim=c(-2,2.5),
       xlab=NA,ylab=NA,
       cex=cex,cex.axis=cex ) #xlim=c(-4,4),ylim=c(-4,4)
  mtext(side = 1,cex=cex, line = lineXAxis,  "PC1"   ,cex.main=cex )
  mtext(side = 2,cex=cex, line = lineAxis, "PC2" ,cex.main=cex)
  
  
  scaleV <- 2
  ##Distance to Prey Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],lwd=3)
  text(0.8*scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.5*scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],labels="Distance")
  ##CaptureSpeed  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lwd=2,lty=3)
  text(1.5*scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+0.8*scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Speed")
  
  ##Undershoot Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2)
  #  text(0.4*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.1*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Overshoot")
  arrows(0,0,-scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2)
  text(-0.6*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-1.4*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Undershoot")
  
  ##TimeToHit Prey Prod Axis  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],lty=5,lwd=2)
  text(-0.06*scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.8*scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],labels="t Prey")
  
  ##DistXSpeed Prod Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[5,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[5,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="purple",lty=5)
  
  ##EFFICIENCY Prod Axis  Component Projection
  scaleVE <- scaleV
  arrows(0,0,scaleVE*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleVE*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",lty=2,lwd=2)
  text(0.4*scaleV*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+1.1*scaleV*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",labels="Efficiency")
  
  legend("bottomleft",legend=c("LF","NF","DF"),pch=c(pchLPCA[2],pchLPCA[3],pchLPCA[1]),
         col="black")## c(colourLegL[2],colourLegL[3],colourLegL[1])) # c(colourH[3],colourH[2])
  ##Heat Map Scale
  points(seq(1,2,1/10),rep(-2,11),col=colEfficiency,pch=15,cex=3)
  text(1,-1.8,col="black",labels= prettyNum(min(mergedCapDat_filt$Efficiency),digits=1,format="f" ),cex=cex)
  text(1+0.5,-1.8,col="black",labels= prettyNum(max(mergedCapDat_filt$Efficiency)/2,digits=1,format="f" ),cex=cex)
  text(2,-1.8,col="black",labels= prettyNum(max(mergedCapDat_filt$Efficiency),digits=1,format="f" ),cex=cex)
  max(mergedCapDat_filt$Efficiency)/2
  #Percentage of Efficiency Variance Explained
  nComp <- length(pca_norm$sdev)
  pcEffVar <- ((pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]])^2 + (pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]])^2)
  EffVar <- sum((pca_norm$rotation[1,][1:nComp]*pca_norm$sdev[1:nComp])^2)
  title(NA,sub=paste("% of Efficiency Variance Explained : ",prettyNum( 100*pcEffVar/EffVar) ))
  


dev.off()

###DF Specific Text Plot Text tuninng
pdf(file= paste(strPlotExportPath,"/stat/stat_PCAHuntVariablesAndEfficiencyPC3_5_EfficiencyColour_DF.pdf",sep=""),width=7,height=7)
  
  plot(rawd[,1], rawd[,2],
       #col=colClass[1+as.numeric(mergedCapDat$Undershoot > 1)], pch=pchL[4+datpolyFactor_norm$Group], 
       col=colEfficiency[round(mergedCapDat_filt$Efficiency*10)], pch=pchLPCA[as.numeric(mergedCapDat_filt$groupID) ],
       #col=colClass[as.numeric(mergedCapDat_filt$Cluster)], pch=pchL[4+datpolyFactor_norm$Group],
       #col=colourLegL[datpolyFactor_norm$Group], pch=pchL[4+datpolyFactor_norm$Group],
       #xlab="PC1",ylab="PC2",
       xlim=c(-2.5,2.5),ylim=c(-2,2.5),
       xlab=NA,ylab=NA,
       cex=cex,cex.axis=cex ) #xlim=c(-4,4),ylim=c(-4,4)
  mtext(side = 1,cex=cex, line = lineXAxis,  "PC3"   ,cex.main=cex )
  mtext(side = 2,cex=cex, line = lineAxis, "PC5" ,cex.main=cex)
  
  
  scaleV <- 2
  ##Distance to Prey Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],lwd=3)
  text(0.8*scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.5*scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],labels="Distance")
  ##CaptureSpeed  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lwd=2,lty=3)
  text(1.5*scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+0.8*scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Speed")
  
  ##Undershoot Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2)
  #  text(0.4*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.1*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Overshoot")
  arrows(0,0,-scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2)
  text(-0.6*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+1.7*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Undershoot")
  
  ##TimeToHit Prey Prod Axis  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],lty=5,lwd=2)
  text(1.2*scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.8*scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],labels="t Prey")
  
  ##DistXSpeed Prod Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[5,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[5,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="purple",lty=5)
  
  ##EFFICIENCY Prod Axis  Component Projection
  scaleVE <- scaleV
  arrows(0,0,scaleVE*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleVE*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",lty=2,lwd=2)
  text(0.4*scaleV*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+1.1*scaleV*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",labels="Efficiency")
  
  legend("bottomleft",legend=c("LF","NF","DF"),pch=c(pchLPCA[2],pchLPCA[3],pchLPCA[1]),
         col="black")## c(colourLegL[2],colourLegL[3],colourLegL[1])) # c(colourH[3],colourH[2])
  ##Heat Map Scale
  points(seq(1,2,1/10),rep(-2,11),col=colEfficiency,pch=15,cex=3)
  text(1,-1.8,col="black",labels= prettyNum(min(mergedCapDat_filt$Efficiency),digits=1,format="f" ),cex=cex)
  text(1+0.5,-1.8,col="black",labels= prettyNum(max(mergedCapDat_filt$Efficiency)/2,digits=1,format="f" ),cex=cex)
  text(2,-1.8,col="black",labels= prettyNum(max(mergedCapDat_filt$Efficiency),digits=1,format="f" ),cex=cex)
  max(mergedCapDat_filt$Efficiency)/2
  #Percentage of Efficiency Variance Explained
  nComp <- length(pca_norm$sdev)
  pcEffVar <- ((pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]])^2 + (pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]])^2)
  EffVar <- sum((pca_norm$rotation[1,][1:nComp]*pca_norm$sdev[1:nComp])^2)
  title(NA,sub=paste("% of Efficiency Variance Explained : ",prettyNum( 100*pcEffVar/EffVar) ))
  


dev.off()


pdf(file= paste(strPlotExportPath,"/stat/stat_PCAHuntVariablesAndEfficiencyPC2_3_EfficiencyColour_NF.pdf",sep=""),width=7,height=7)
  
  plot(rawd[,1], rawd[,2],
       #col=colClass[1+as.numeric(mergedCapDat$Undershoot > 1)], pch=pchL[4+datpolyFactor_norm$Group], 
       col=colEfficiency[round(mergedCapDat_filt$Efficiency*10)], pch=pchLPCA[as.numeric(mergedCapDat_filt$groupID) ],
       #col=colClass[as.numeric(mergedCapDat_filt$Cluster)], pch=pchL[4+datpolyFactor_norm$Group],
       #col=colourLegL[datpolyFactor_norm$Group], pch=pchL[4+datpolyFactor_norm$Group],
       #xlab="PC1",ylab="PC2",
       xlim=c(-2.5,2.5),ylim=c(-2,2.5),
       xlab=NA,ylab=NA,
       cex=cex,cex.axis=cex ) #xlim=c(-4,4),ylim=c(-4,4)
  mtext(side = 1,cex=cex, line = lineXAxis,  "PC2"   ,cex.main=cex )
  mtext(side = 2,cex=cex, line = lineAxis, "PC3" ,cex.main=cex)
  
  
  scaleV <- 2
  ##Distance to Prey Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],lwd=3)
  text(0.8*scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.5+1.5*scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],labels="Distance")
  ##CaptureSpeed  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lwd=2,lty=3)
  text(1.5*scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+0.8*scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Speed")
  
  ##Undershoot Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2)
  #  text(0.4*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.1*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Overshoot")
  arrows(0,0,-scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2)
  text(-0.6*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-1.2*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Undershoot")
  
  ##TimeToHit Prey Prod Axis  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],lty=5,lwd=2)
  text(-0.2*scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.8*scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],labels="t Prey")
  
  ##DistXSpeed Prod Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[5,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[5,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="purple",lty=5)
  
  ##EFFICIENCY Prod Axis  Component Projection
  scaleVE <- scaleV
  arrows(0,0,scaleVE*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleVE*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",lty=2,lwd=2)
  text(0.4*scaleV*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+1.1*scaleV*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",labels="Efficiency")
  
  legend("bottomleft",legend=c("LF","NF","DF"),pch=c(pchLPCA[2],pchLPCA[3],pchLPCA[1]),
         col="black")## c(colourLegL[2],colourLegL[3],colourLegL[1])) # c(colourH[3],colourH[2])
  ##Heat Map Scale
  points(seq(1,2,1/10),rep(-2,11),col=colEfficiency,pch=15,cex=3)
  text(1,-1.8,col="black",labels= prettyNum(min(mergedCapDat_filt$Efficiency),digits=1,format="f" ),cex=cex)
  text(1+0.5,-1.8,col="black",labels= prettyNum(max(mergedCapDat_filt$Efficiency)/2,digits=1,format="f" ),cex=cex)
  text(2,-1.8,col="black",labels= prettyNum(max(mergedCapDat_filt$Efficiency),digits=1,format="f" ),cex=cex)
  max(mergedCapDat_filt$Efficiency)/2
  #Percentage of Efficiency Variance Explained
  nComp <- length(pca_norm$sdev)
  pcEffVar <- ((pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]])^2 + (pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]])^2)
  EffVar <- sum((pca_norm$rotation[1,][1:nComp]*pca_norm$sdev[1:nComp])^2)
  title(NA,sub=paste("% of Efficiency Variance Explained : ",prettyNum( 100*pcEffVar/EffVar) ))
  


dev.off()

##%*%pca_norm$rotation[1,]
sum(pca_norm$rotation[1,]^2) #Unit vectors

### Calc the Projection of Efficiency on the variance captured by each  PC
s = 0
tIdx <- 3 ##Choose Which Variable to Calc The  COntribution to Variance from Each PC 
Ve <- vector()
for (i in 1:9)
{
  ##Total Efficiency Vairance 
  s = s + (pca_norm$sdev[i]^2)*sum( ( pca_norm$rotation[,i]*pca_norm$rotation[tIdx,])^2  ) ### * pca_norm$sdev[i
  ##Efficiency COntribution to Var Of Each PC 
  Ve[i] <- (pca_norm$sdev[i]^2)*sum( ( pca_norm$rotation[,i]*pca_norm$rotation[tIdx,])^2  )##sum( (pca_norm$rotation[,i]%*%pca_norm$rotation[1,])^2 * pca_norm$sdev[i])^2
}
##Now Choose a PC

##CHeck Contribution Of PC to Efficiency Variance
sum(Ve/s)
###PLot Relative COntrib To Variance 
plot((100*Ve/s) ) 



pdf(file= paste(strPlotExportPath,"/stat/stat_PCAHuntVariablesAndEfficiencyPC1_2_GroupColour_ALL.pdf",sep=""),width=7,height=7)
  ## bottom, left,top, right
  par(mar = c(4.2,4.3,1,1))
  
  plot(rawd[,1], rawd[,2],
       ######col=colClass[1+as.numeric(mergedCapDat$Undershoot > 1)], pch=pchL[4+datpolyFactor_norm$Group], 
       #col=colEfficiency[round(mergedCapDat_filt$Efficiency*10)], pch=pchL[4+as.numeric(mergedCapDat_filt$groupID) ],
       #col=colClass[as.numeric(mergedCapDat_filt$Cluster)], pch=pchLPCA[as.numeric(mergedCapDat_filt$groupID)],
       col=colourGroup[mergedCapDat_filt$groupID ], pch=pchLPCA[as.numeric(mergedCapDat_filt$groupID)],
       #xlab="PC1",ylab="PC2",
       xlim=c(-2.5,2.5),ylim=c(-2,2.5),
       xlab=NA,ylab=NA,
       cex=cex,cex.axis=cex ) #xlim=c(-4,4),ylim=c(-4,4)
  mtext(side = 1,cex=cex, line = lineXAxis,  "PC1"   ,cex.main=cex )
  mtext(side = 2,cex=cex, line = lineAxis, "PC2" ,cex.main=cex)
  
  
  scaleV <- 2
  ##Distance to Prey Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],lwd=3)
  text(0.7*scaleV*pca_norm$rotation[2,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.2*scaleV*pca_norm$rotation[2,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[1],labels="Distance")
  ##CaptureSpeed  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[2],lwd=2,lty=3)
  text(0.8*scaleV*pca_norm$rotation[3,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+0.8*scaleV*pca_norm$rotation[3,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[2],labels="Speed")
  
  ##Undershoot Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2)
  #  text(0.4*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.1*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,labels="Overshoot")
  arrows(0,0,-scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",lty=2,lwd=2)
  text(-1.5*scaleV*pca_norm$rotation[4,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,-1.0*scaleV*pca_norm$rotation[4,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="black",labels="Undershoot")
  
  ##TimeToHit Prey Prod Axis  Component Projection
  arrows(0,0,scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],lty=5,lwd=2)
  text(0.8*scaleV*pca_norm$rotation[6,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,1.2*scaleV*pca_norm$rotation[6,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col=colFactrAxes[6],labels="t Prey")
  
  ##DistXSpeed Prod Axis  Component Projection
  #arrows(0,0,scaleV*pca_norm$rotation[5,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleV*pca_norm$rotation[5,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="purple",lty=5)
  
  ##EFFICIENCY Prod Axis  Component Projection
  scaleVE <- scaleV
  arrows(0,0,scaleVE*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,scaleVE*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",lty=2,lwd=2)
  text(0.4*scaleV*pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]]^2,0.1+1.0*scaleV*pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]]^2,col="blue",labels="Efficiency")
  
  # ##Heat Map Scale
  # points(seq(1,2,1/10),rep(-2,11),col=colEfficiency,pch=15,cex=3)
  # text(1,-1.8,col="black",labels= prettyNum(min(mergedCapDat_filt$Efficiency),digits=1,format="f" ),cex=cex)
  # text(1+0.5,-1.8,col="black",labels= prettyNum(max(mergedCapDat_filt$Efficiency)/2,digits=1,format="f" ),cex=cex)
  # text(2,-1.8,col="black",labels= prettyNum(max(mergedCapDat_filt$Efficiency),digits=1,format="f" ),cex=cex)
  # max(mergedCapDat_filt$Efficiency)/2
  # 
  
  legend("bottomleft",legend=c( paste0(groupLabels[3],' #',table(mergedCapDat_filt$groupID)[3]),
                                paste0(groupLabels[2],' #',table(mergedCapDat_filt$groupID)[2]),
                                paste0(groupLabels[1],' #',table(mergedCapDat_filt$groupID)[1]) 
  ),
  pch=c(pchLPCA[3],pchLPCA[2],pchLPCA[1]),
  col=c(colourGroup[3],colourGroup[2],colourGroup[1]) )## c(colourLegL[2],colourLegL[3],colourLegL[1])) # c(colourH[3],colourH[2])
  #legend("bottomright",legend=c("Slow","Fast"),fill=colClass, col=colClass,title="Cluster")## c(colourLegL[2],colourLegL[3],colourLegL[1])) # c(colourH[3],colourH[2])
  
  #Percentage of Efficiency Variance Explained
  nComp <- length(pca_norm$sdev)
  pcEffVar <- ((pca_norm$rotation[1,][pcAxis[1]]*pca_norm$sdev[pcAxis[1]])^2 + (pca_norm$rotation[1,][pcAxis[2]]*pca_norm$sdev[pcAxis[2]])^2)
  EffVar <- sum((pca_norm$rotation[1,][1:nComp]*pca_norm$sdev[1:nComp])^2)
  
  title(NA,sub=paste(" Efficiency variance captured: ",prettyNum( 100*pcEffVar/EffVar,digits=3), " Coeff. variation:",prettyNum(sd(mergedCapDat_filt$Efficiency)/mean(mergedCapDat_filt$Efficiency) ,digits=2)) )
  message("Captured Variance ",prettyNum( (pca_norm$sdev[pcAxis[1]]^2 + pca_norm$sdev[pcAxis[2]]^2) /sum( pca_norm$sdev ^2),digits=3,format="f" ) )
  message(paste(" Efficiency variance captured: ",prettyNum( 100*pcEffVar/EffVar,digits=3), " Coeff. variation:",prettyNum(sd(mergedCapDat_filt$Efficiency)/mean(mergedCapDat_filt$Efficiency) ,digits=2)))

dev.off()






biplot(pca_norm,choices=c(1,2))


theta <- function (a,b){ return( (180/pi)   *acos( sum(a*b) / ( sqrt(sum(a * a)) * sqrt(sum(b * b)) ) )) }

pcAxis <- c(3,5)
theta(pca_norm$rotation[1,pcAxis], pca_norm$rotation[1,pcAxis]) #Efficiency
theta(pca_norm$rotation[1,pcAxis], pca_norm$rotation[2,pcAxis]) #Group
theta(pca_norm$rotation[1,pcAxis], pca_norm$rotation[3,pcAxis]) #DistanceToPrey
theta(pca_norm$rotation[1,pcAxis], pca_norm$rotation[4,pcAxis]) #CaptureSpeed_norm
theta(pca_norm$rotation[1,pcAxis], pca_norm$rotation[5,pcAxis]) #Undershoot_norm
theta(pca_norm$rotation[1,pcAxis], pca_norm$rotation[6,pcAxis]) #DistSpeedProd
theta(pca_norm$rotation[1,pcAxis], pca_norm$rotation[7,pcAxis]) #DistUnderProd
theta(pca_norm$rotation[1,pcAxis], pca_norm$rotation[8,pcAxis]) #SpeedUnderProd
theta(pca_norm$rotation[1,pcAxis], pca_norm$rotation[9,pcAxis]) #All
##PCA

theta(pca_norm$rotation[,1], pca_norm$rotation[,2])


library(rgl)

open3d()##mergedCapDat$groupID
rgl::plot3d( x=rawd[,1], z=rawd[,2], y=rawd[,3], col = colourLegL[datpolyFactor_norm$Group] , type = "s", radius = 0.5,
             xlab="PC1", zlab="PC2",ylab="PC3",
             xlim=c(-8.,8), ylim=c(-8,8), zlim=c(-8,8),
             box = FALSE ,aspect = TRUE
             #,expand = 1.5
)
###END PCA PLOT ##



Ei_LF_norm=eigen(cov(datpolyFactor_norm))
symnum(cov(datpolyFactor_norm))
Ei_LF_norm
## ##Make MAtrix
datpolyFactor <- with(mergedCapDat[mergedCapDat$groupID == 'NL',],{
  cbind(Efficiency, #1
        #HuntPower, # ## Does not CoVary With Anyhting 
        DistanceToPrey, #2
        CaptureSpeed, #3
        Undershoot, #4
        DistanceToPrey*CaptureSpeed, #5
        DistanceToPrey*Undershoot, #6
        CaptureSpeed*Undershoot, #7
        DistanceToPrey*CaptureSpeed*Undershoot #8
  )
  
})

Ei_NL<-eigen(cov(datpolyFactor))
Ei_NL

datpolyFactor <- with(mergedCapDat[mergedCapDat$groupID == 'LL',],{
  cbind(Efficiency, #1
        #HuntPower, # ## Does not CoVary With Anyhting 
        DistanceToPrey, #2
        CaptureSpeed, #3
        Undershoot, #4
        DistanceToPrey*CaptureSpeed, #5
        DistanceToPrey*Undershoot, #6
        CaptureSpeed*Undershoot, #7
        DistanceToPrey*CaptureSpeed*Undershoot #8
  )
})


##Ei_LF=eigen(cov(datpolyFactor))
pca_LL <- prcomp(datpolyFactor,scale.=TRUE)
summary(pca_LL)
biplot(pca_LL)

Ei_LF
plot(pca_LL)

## ##Make MAtrix
datpolyFactor <- with(mergedCapDat[mergedCapDat$groupID == 'LL',],{
  cbind(Efficiency, #1
        #HuntPower, # ## Does not CoVary With Anyhting 
        DistanceToPrey, #2
        CaptureSpeed, #3
        Undershoot, #4
        DistanceToPrey*CaptureSpeed, #5
        DistanceToPrey*Undershoot, #6
        CaptureSpeed*Undershoot, #7
        DistanceToPrey*CaptureSpeed*Undershoot #8
  )
  
})

Ei_DL <- eigen(cov(datpolyFactor))

### Print Eugen MAtrix
Ei_LL
Ei_NL
Ei_DL

col<- colorRampPalette(c("blue", "white", "red"))(20)
heatmap(x=cov(datpolyFactor), col=col,symm = F)

#library(corrplot)

lm(Efficiency ~ (DistanceToPrey+CaptureSpeed+Undershoot)^3,data=mergedCapDat[mergedCapDat$groupID == 'NL',])




huntPowerColour <- rfc(8)
open3d()##mergedCapDat$groupID
rgl::plot3d( x=mergedCapDat$CaptureSpeed, z=mergedCapDat$DistanceToPrey, y=mergedCapDat$HuntPower, col = huntPowerColour[round(mergedCapDat$HuntPower)] , type = "s", radius = 1.3,
             xlab="Capture Speed (mm/sec)", zlab="Hunt Power",ylab="Distance to prey (mm)",
             xlim=c(0.,80), ylim=c(0,0.6), zlim=c(0,10),
             box = FALSE ,aspect = TRUE
             #,expand = 1.5
)

open3d()##mergedCapDat$groupID
rgl::plot3d( x=datMergedCapAndSuccess_LF$CaptureSpeed, z=datMergedCapAndSuccess_LF$DistanceToPrey, y=datMergedCapAndSuccess_LF$HuntPower, col = huntPowerColour[round(mergedCapDat$HuntPower)] , type = "s", radius = 1.3,
             xlab="Capture Speed (mm/sec)", ylab="Hunt Power",zlab="Distance to prey (mm)",
             xlim=c(0.,80), zlim=c(0,0.6), ylim=c(0,10),
             box = FALSE ,aspect = TRUE
             #,expand = 1.5
)


rgl::rgl.viewpoint(60,10)


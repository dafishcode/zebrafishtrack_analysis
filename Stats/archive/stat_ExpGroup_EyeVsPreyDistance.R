##15-10-2018
### Model how Eye Angle reports distance from prey 
## Used to compare differences in distance estimation between rearing groups 

##Model Each Hunt Event Individually / And obtain Group Statistic and Regresion of eye vergence vs Distance To Prey
source("DataLabelling/labelHuntEvents_lib.r") ##for convertToScoreLabel
source("TrackerDataFilesImport_lib.r")
### Hunting Episode Analysis ####
source("HuntingEventAnalysis_lib.r")



##The Eye Angle Vs Distance Model
## Regression of an exponential Function for EyeAngle Vs Distance Fitting Each Hunt Event
## Independently , and obtaining statistics over params of each fit
## H : Number of Hunt Events in Data
## N : vector of number of points in Hunt Event
modelExpInd  <- "model{
  ##Prior
  limDist <- max(distMax)

  # Priors / Independent for each event 
  for(i in 1:max(hidx) ) { 
    phi_0[i] ~ dnorm(5,2) # Idle Eye Position
    phi_max[i] ~ dnorm(60,20) # Max Eye Vergence Angle
    lambda[i] ~ dgamma(1, 1) # RiseRate of Eye Vs Prey Distance
    u1[i] ~ dunif(0, limDist) ## End Hunt Distance - Close to prey
    u0[i] ~ dunif(1, limDist) ##Start Hunt Distance -Far 

  # Sigma On Eye Angle when  In Or Out of hunt region 
   for(j in 1:2){
    sigma[i,j] ~ dgamma(0.01, 0.01) ##Draw 
    }
  }

  # Likelihood / Separate for each Hunt Event
  for(i in 1:N){
  ##Make indicator if hunt event is within sampled Range 
  #if (u1[hidx[i]] < distP[i]  & distP[i] < u0) 
  s[hidx[i],i] <- step( distP[i]-u1[hidx[i]]) #*step(u0[ hidx[i] ] - distP[i]  )   

  phi_hat[ hidx[i],i] <- (phi_max[hidx[i]] - phi_0[hidx[i]])* (1 - exp( -lambda[ hidx[i] ]*( u0[ hidx[i] ]- distP[i] ) ) ) 
  phi[i] ~ dnorm(phi_0[hidx[i]]+s[hidx[i],i]*phi_hat[ hidx[i],i], sigma[hidx[i],s[hidx[i],i]+1] ) ##choose sigma 

#phi_hat[ hidx[i],i] <- step(2*s[hidx[i],i]-1)*phi_0[hidx[i]] + s[hidx[i],i]*(phi_max[hidx[i]])* (1-exp(-lambda[ hidx[i] ]*(distMax[i] - distP[i] ) )) 
#phi[i] ~ dnorm( step( 2*s[hidx[i],i] -1)*phi_0[hidx[i]] + s[hidx[i],i]*phi_hat[ hidx[i],i], sigma[hidx[i],s[hidx[i],i]+1] ) ##choose sigma
#phi[i] ~ dnorm( step(phi_hat[ hidx[i],i] < 40)*phi_max[hidx[i]] +step(phi_hat[ hidx[i],i] >= 35)*phi_hat[ hidx[i],i], sigma[hidx[i],s[hidx[i],i]+1] ) ##choose sigma 
  

##step(phi_hat[ hidx[i],i] < 40)*phi_0[hidx[i]] + step(phi_hat[ hidx[i],i] >= 40)*
  }
}"



## Plot The Inferened Exponantial Curves / Group and individual
plotExpRes <- function (drawS,dataSubset,n=NA,groupID){
  ## compute 2D kernel density, see MASS book, pp. 130-131
  max_x <- 5
  nlevels <- 12
  
  if (is.na(n))
    n <- NROW(unique(dataSubset$hidx) )
  
  vsampleP <- sample(unique(dataSubset$hidx),n)
  vsub <- which (dataSubset$hidx %in% vsampleP)
  
  z <- kde2d(dataSubset$distP, dataSubset$phi, n=80)
  
  plot(dataSubset$distP[vsub],dataSubset$phi[vsub],pch=21,xlim=c(0,max_x),ylim=c(0,80),main=strGroupID[groupID], bg=colourP[2],col=colourP[1],cex=0.5)
  #points(dataSubset$distToPrey[vsub],dataSubset$vAngle[vsub],pch=21,xlim=c(0,5),ylim=c(0,80),main="LL", bg=colourP[4],col=colourP[1],cex=0.5)
  contour(z, drawlabels=FALSE, nlevels=nlevels,add=TRUE)
  
  
  
  for (pp in vsampleP)
  {
    vX  <- seq(drawS$u1[pp],drawS$u0[pp],by=0.01)
    vX_l <- seq(quantile(drawS$u1[pp,,])[2],quantile(drawS$u0[pp,,])[2],by=0.01)
    #vY  <-    (drawS$phi_0[pp] ) - ( (drawS$lambda[pp]))*(((drawS$gamma[pp])^( (drawS$u0[pp] ) - (vX) ) ) ) # 
    vY  <-    (drawS$phi_0[pp] )+ ( (drawS$phi_max[pp]-drawS$phi_0[pp]  ) )*(1-exp(- (drawS$lambda[pp])*( (drawS$u0[pp] ) - (vX) ) ) ) #   
    vY_u <-  quantile(drawS$phi_0[pp,,])[4]+(quantile(drawS$phi_max[pp,,])[4] - quantile(drawS$phi_0[pp,,])[4]) *(1-exp(-quantile(drawS$lambda[pp,,])[4]*( quantile(drawS$u0[pp,,])[4] - (vX) ) ) )
    vY_l <-  quantile(drawS$phi_0[pp,,])[2]+ ( quantile(drawS$phi_max[pp,,])[2] - quantile(drawS$phi_0[pp,,])[2] )*(1-exp(- quantile(drawS$lambda[pp,,])[2]*( quantile(drawS$u0[pp,,])[2] - (vX) ) ) )
    lines( vX ,vY,xlim=c(0,max_x),ylim=c(0,80),type="l",col="red",lwd=2,sub=paste(strGroupID[groupID],pp))
    lines( vX ,vY_u,xlim=c(0,max_x),ylim=c(0,80),type="l",col="blue",lwd=1)
    lines( vX ,vY_l,xlim=c(0,max_x),ylim=c(0,80),type="l",col="blue",lwd=1)
    
    ## Fit Using STD nls
    #pp1 <- which (dataSubset$hidx %in% pp)
    #x<- dataSubset$distP[pp1]
    #y<- dataSubset$phi[pp1]
    #nlm2 <- nls(y ~ (phi0 + (phimax-phi0)*(1-exp(-lambda*(u0-x))) ), start=c(phi0=1,phimax=50, lambda=0.5, u0=3))
    
    
  }
  
}

####Select Subset Of Data To Analyse

strRegisterDataFileName <- paste(strDataExportDir,"/setn_huntEventsTrackAnalysis_Register",".rds",sep="") #Processed Registry on which we add 
message(paste(" Importing Retracked HuntEvents from:",strRegisterDataFileName))
datTrackedEventsRegister <- readRDS(strRegisterDataFileName) ## THis is the Processed Register File On 

lEyeMotionDat <- readRDS(paste(strDataExportDir,"/huntEpisodeAnalysis_EyeMotionData.rds",sep="") ) #Processed Registry on which we add )

datEyeVsPreyCombinedAll <-  data.frame( do.call(rbind,lEyeMotionDat ) )

strGroupID <- levels(datTrackedEventsRegister$groupID)


##Add The Empty Test Conditions
#strProcDataFileName <-paste("setn14-D5-18-HuntEvents-Merged",sep="") ##To Which To Save After Loading
#datHuntLabelledEventsKL <- readRDS(file=paste(strDatDir,"/LabelledSet/",strProcDataFileName,".rds",sep="" ))
#datHuntStatE <- makeHuntStat(datHuntLabelledEventsKL)
#datHuntLabelledEventsKLEmpty <- datHuntLabelledEventsKL[datHuntLabelledEventsKL$groupID %in% c("DE","LE","NE"),]
lRegIdx <- list()
ldatsubSet <-list()

## Get Event Counts Within Range ##
ldatREyePoints <- list()
ldatLEyePoints <- list()
ldatVEyePoints <- list()
lnDat          <- list()
sampleFraction  <- 0.3
##Do all this processing to add a sequence index To The hunt Event + make vergence angle INdex 
for (g in strGroupID) {
  lRegIdx[[g]] <- unique(datEyeVsPreyCombinedAll[datEyeVsPreyCombinedAll$groupID == which(strGroupID == g),"RegistarIdx"])
  ldatLEyePoints[[g]] <- list()
  
  for (h in 1:NROW(lRegIdx[[g]]) )
  {
    ldatsubSet[[g]] <- datEyeVsPreyCombinedAll[datEyeVsPreyCombinedAll$groupID == which(strGroupID == g) &
                                        datEyeVsPreyCombinedAll$RegistarIdx %in% lRegIdx[[g]][h] ,]  
    
    ldatsubSet[[g]] <- ldatsubSet[[g]][sample(NROW(ldatsubSet[[g]]),sampleFraction*NROW(ldatsubSet[[g]] ) ) ,] ##Sample Points 
    
    ldatLEyePoints[[g]][[h]] <- cbind(ldatsubSet[[g]]$LEyeAngle,
                             as.numeric(ldatsubSet[[g]]$DistToPrey),
                             as.numeric(ldatsubSet[[g]]$DistToPreyInit ),
                             ldatsubSet[[g]]$RegistarIdx,
                             h)
    
    ldatREyePoints[[g]][[h]] <- cbind(ldatsubSet[[g]]$REyeAngle,
                             as.numeric(ldatsubSet[[g]]$DistToPrey),
                             as.numeric(ldatsubSet[[g]]$DistToPreyInit ),
                             ldatsubSet[[g]]$RegistarIdx,
                             h)
    
    ldatVEyePoints[[g]][[h]] <- cbind(vAngle=ldatsubSet[[g]]$LEyeAngle-ldatsubSet[[g]]$REyeAngle,
                             distToPrey=as.numeric(ldatsubSet[[g]]$DistToPrey),
                             initDistToPrey=as.numeric(ldatsubSet[[g]]$DistToPreyInit ),
                             RegistarIdx=ldatsubSet[[g]]$RegistarIdx,
                             seqIdx=h)
    
    ldatLEyePoints[[g]][[h]] <- ldatLEyePoints[[g]][[h]][!is.na(ldatLEyePoints[[g]][[h]][,2]),]
    ldatREyePoints[[g]][[h]] <- ldatREyePoints[[g]][[h]][!is.na(ldatREyePoints[[g]][[h]][,2]),]
    ldatVEyePoints[[g]][[h]] <- ldatVEyePoints[[g]][[h]][!is.na(ldatVEyePoints[[g]][[h]][,2]),]
    
    lnDat[[g]][[h]] <- NROW(ldatLEyePoints[[g]][[h]]) ##Not Used Anymore
  }
}
datVEyePointsLL <- data.frame( do.call(rbind,ldatVEyePoints[["LL"]] ) ) 
datVEyePointsNL <- data.frame( do.call(rbind,ldatVEyePoints[["NL"]] ) ) 
datVEyePointsDL <- data.frame( do.call(rbind,ldatVEyePoints[["DL"]] ) ) 


##For the 3 Groups 
colourH <- c(rgb(0.01,0.01,0.9,0.8),rgb(0.01,0.7,0.01,0.8),rgb(0.9,0.01,0.01,0.8),rgb(0.00,0.00,0.0,1.0)) ##Legend
colourP <- c(rgb(0.01,0.01,0.8,0.5),rgb(0.01,0.6,0.01,0.5),rgb(0.8,0.01,0.01,0.5),rgb(0.00,0.00,0.0,1.0)) ##points DL,LL,NL
colourR <- c(rgb(0.01,0.01,0.9,0.4),rgb(0.01,0.7,0.01,0.4),rgb(0.9,0.01,0.01,0.4),rgb(0.00,0.00,0.0,1.0)) ##Region (Transparency)
pchL <- c(16,2,4)
#
#Thse RC params Work Well to Smooth LF And NF
burn_in=100;
steps=1000;
thin=1;


##Larva Event Counts Slice
nDatLL <- NROW(datVEyePointsLL)
nDatNL <- NROW(datVEyePointsNL)
nDatDL <- NROW(datVEyePointsDL)

##Test limit data
## Subset Dat For Speed
datVEyePointsLL_Sub <- datVEyePointsLL[datVEyePointsLL$seqIdx %in% sample(NROW(lRegIdx[["LL"]]),NROW(lRegIdx[["LL"]])*0.4) ,] #
dataLL=list(phi=datVEyePointsLL_Sub$vAngle,
            distP=datVEyePointsLL_Sub$distToPrey ,
            N=NROW(datVEyePointsLL_Sub),
            distMax=datVEyePointsLL_Sub$initDistToPrey,
            hidx=datVEyePointsLL_Sub$seqIdx );


##Test limit data
## Subset Dat For Speed


datVEyePointsNL_Sub <- datVEyePointsNL[datVEyePointsNL$seqIdx %in% sample(NROW(lRegIdx[["NL"]]),NROW(lRegIdx[["NL"]])*1),] 
dataNL=list(phi=datVEyePointsNL_Sub$vAngle,
            distP=datVEyePointsNL_Sub$distToPrey ,
            N=NROW(datVEyePointsNL_Sub),
            distMax=datVEyePointsNL_Sub$initDistToPrey,
            hidx=datVEyePointsNL_Sub$seqIdx );

##Test limit data
## Subset Dat For Speed
datVEyePointsDL_Sub <- datVEyePointsDL[datVEyePointsDL$seqIdx %in% sample(NROW(lRegIdx[["DL"]]),NROW(lRegIdx[["DL"]])*0.7),] 
dataDL=list(phi=datVEyePointsDL_Sub$vAngle,
            distP=datVEyePointsDL_Sub$distToPrey ,
            N=NROW(datVEyePointsDL_Sub),
            distMax=datVEyePointsDL_Sub$initDistToPrey,
            hidx=datVEyePointsDL_Sub$seqIdx );



varnames=c("u0","u1","phi_0","phi_max","lambda","sigma","s")


library(rjags)
fileConn=file("model.tmp")
#writeLines(modelGPV1,fileConn);
writeLines(modelExpInd,fileConn);
close(fileConn)

mLL=jags.model(file="model.tmp",data=dataLL);
update(mLL,burn_in);#update(mNL,burn_in);update(mDL,burn_in)
drawLL=jags.samples(mLL,steps,thin=thin,variable.names=varnames)
#sampLL <- coda.samples(mLL,                      variable.names=varnames,                      n.iter=steps, progress.bar="none")

X11();plotExpRes(drawLL,dataLL,n=1,groupID = 2)

X11()
plotExpRes(drawLL,dataLL,groupID = 2)

## compute 2D kernel density, see MASS book, pp. 130-131
nlevels <- 12
z <- kde2d(dataLL$distP, dataLL$phi, n=80)

## Plot the infered function
datVEyePointsLL_SubP <- datVEyePointsLL[datVEyePointsLL$seqIdx %in% vsampleP[1],] 
vsampleP <- unique(datVEyePointsLL_Sub$seqIdx)
X11()
#pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_LL_F.pdf",sep="")) quantile(drawLL$phi_0[,,])[4] 
vX <- seq(0,5,by=0.01)
vY <-    mean(drawLL$phi_0[vsampleP] )+ ( mean(drawLL$phi_max[vsampleP] ) + 35 )*(1-exp(-  mean(drawLL$lambda[vsampleP])*( mean(drawLL$u0[vsampleP] ) - (vX) ) ) ) # 
vY_u <-  quantile(drawLL$phi_0[vsampleP])[4]+(quantile(drawLL$phi_max[vsampleP])[4]+35)*(1-exp(-quantile(drawLL$lambda[vsampleP])[4]*( quantile(drawLL$u0[vsampleP])[4] - (vX) ) ) )
vY_l <-  quantile(drawLL$phi_0[vsampleP])[2]+(quantile(drawLL$phi_max[vsampleP])[2] +35 )*(1-exp(- quantile(drawLL$lambda[vsampleP])[2]*( quantile(drawLL$u0[vsampleP])[2] - (vX) ) ) )
plot(dataLL$distP,dataLL$phi,pch=21,xlim=c(0,5),ylim=c(40,80),main="LL", bg=colourP[2],col=colourP[2],cex=0.5)
points(datVEyePointsLL_SubP$distToPrey,datVEyePointsLL_SubP$vAngle,pch=21,xlim=c(0,5),ylim=c(0,80),main="LL", bg=colourP[4],col=colourP[2],cex=0.5)
contour(z, drawlabels=FALSE, nlevels=nlevels,add=TRUE)
lines( vX ,vY,xlim=c(0,5),ylim=c(0,80),type="l",col="red",lwd=3)
lines( vX ,vY_u,xlim=c(0,5),ylim=c(0,80),type="l",col="blue",lwd=2)
lines( vX ,vY_l,xlim=c(0,5),ylim=c(0,80),type="l",col="blue",lwd=2)
#dev.off()

#pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_Rate_lambda_LL_E.pdf",sep=""))
X11()
hist(drawLL$lambda[,,],main="LL")

X11()
hist(drawLL$phi_max[3,,],main="LL")
#plot(drawLL$phi_max[3,,])

X11()
hist(drawLL$phi_0[,,],main="LL")
X11()
hist(drawLL$sigma[,,],main="LL")



X11()
#pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_StartEnd_u0_NL_E.pdf",sep=""))
hist(drawLL$u1[,,],breaks=50,xlim=c(0,7),col=colourH[2])
hist(drawLL$u0[,,],breaks=50,xlim=c(0,7),add=TRUE,col=colourH[2])

#dev.off()
########################
## NL ###
mNL=jags.model(file="model.tmp",data=dataNL);
drawNL=jags.samples(mNL,steps,thin=thin,variable.names=varnames)

## Plot the infered function NL

## compute 2D kernel density, see MASS book, pp. 130-131
nlevels <- 12
z <- kde2d(dataNL$distP, dataNL$phi, n=80)

pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_NL_F.pdf",sep=""))
datVEyePointsNL_SubP <- datVEyePointsNL[datVEyePointsLL$seqIdx %in% vsampleP[1],] 
vsampleP <- unique(datVEyePointsNL_Sub$seqIdx)
#X11()
vX <- seq(0,5,by=0.01)
vY <-    mean(drawNL$phi_0[vsampleP] )+ ( mean(drawNL$phi_max[vsampleP] ) )*(1-exp(-  mean(drawNL$lambda[vsampleP] )*( mean(drawNL$u0[vsampleP] ) - (vX) ) ) ) # 
vY_u <-  quantile(drawNL$phi_0[vsampleP])[4]+(quantile(drawNL$phi_max[vsampleP])[4])*(1-exp(-quantile(drawNL$lambda[vsampleP])[4]*( quantile(drawNL$u0[vsampleP])[4] - (vX) ) ) )
vY_l <-  quantile(drawNL$phi_0[vsampleP])[2]+quantile(drawNL$phi_max[vsampleP])[2]*(1-exp(- quantile(drawNL$lambda[vsampleP])[2]*( quantile(drawNL$u0[vsampleP])[2] - (vX) ) ) )
plot(dataNL$distP,dataNL$phi,pch=21,xlim=c(0,5),ylim=c(0,80),main="NL", bg=colourP[3],col=colourP[3],cex=0.5)
points(datVEyePointsNL_SubP$distToPrey,datVEyePointsNL_SubP$vAngle,pch=21,xlim=c(0,5),ylim=c(0,80),main="NL", bg=colourP[4],col=colourP[3],cex=0.5)
contour(z, drawlabels=FALSE, nlevels=nlevels,add=TRUE)
lines( vX ,vY,xlim=c(0,5),ylim=c(0,80),type="l",col="red",lwd=3)
lines( vX ,vY_u,xlim=c(0,5),ylim=c(0,80),type="l",col="blue",lwd=2)
lines( vX ,vY_l,xlim=c(0,5),ylim=c(0,80),type="l",col="blue",lwd=2)
dev.off()

X11()
#pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_Rate_lambda_NL_E.pdf",sep=""))
hist(drawNL$lambda[1,,1],main="NL")
#dev.off()

X11()
#pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_StartEnd_u0_NL_E.pdf",sep=""))
hist(drawNL$u1[1,,1],breaks=50,xlim=c(0,7),col="red")
hist(drawNL$u0[1,,1],breaks=50,xlim=c(0,7),add=TRUE,col="red")
#dev.off()

############
### DL ###
mDL=jags.model(file="model.tmp",data=dataDL);
drawDL=jags.samples(mDL,steps,thin=thin,variable.names=varnames)


# Plot the infered function DL

## compute 2D kernel density, see MASS book, pp. 130-131
nlevels <- 12
z <- kde2d(dataDL$distP, dataDL$phi, n=80)

#pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_DL_E.pdf",sep=""))
#pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_DL_F.pdf",sep="")) ## quantile(drawLL$phi_0[,,])[4] 
X11()
plot(dataDL$distP,dataDL$phi,pch=21,xlim=c(0,5),ylim=c(0,80),main="DL", bg=colourP[2],col=colourP[1],cex=0.5)
points(datVEyePointsDL_SubP$distToPrey,datVEyePointsDL_SubP$vAngle,pch=21,xlim=c(0,5),ylim=c(0,80),main="LL", bg=colourP[4],col=colourP[1],cex=0.5)
contour(z, drawlabels=FALSE, nlevels=nlevels,add=TRUE)

vX  <- seq(0,5,by=0.01)
for (pp in vsampleP)
{
  vY  <-    (drawDL$phi_0[pp] )+ ( (drawDL$phi_max[pp] +40 ) )*(1-exp(- (drawDL$lambda[pp])*( (drawDL$u0[pp] ) - (vX) ) ) ) # 
  vY_u <-  quantile(drawDL$phi_0[pp])[4]+(quantile(drawDL$phi_max[pp])[4])*(1-exp(-quantile(drawDL$lambda[pp])[4]*( quantile(drawDL$u0[pp])[4] - (vX) ) ) )
  vY_l <-  quantile(drawDL$phi_0[pp])[2]+quantile(drawDL$phi_max[pp])[2]*(1-exp(- quantile(drawDL$lambda[pp])[2]*( quantile(drawDL$u0[pp])[2] - (vX) ) ) )
  lines( vX ,vY,xlim=c(0,5),ylim=c(0,80),type="l",col="red",lwd=2)
  lines( vX ,vY_u,xlim=c(0,5),ylim=c(0,80),type="l",col="blue",lwd=1)
  lines( vX ,vY_l,xlim=c(0,5),ylim=c(0,80),type="l",col="blue",lwd=1)
}

dev.off()

X11()
#pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_Rate_lambda_DL_E.pdf",sep=""))
hist(drawDL$lambda[1,,1],main="DL")
#dev.off()

X11()
#pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_StartEnd_u0_DL_E.pdf",sep=""))
hist(drawDL$u1[1,,1],breaks=50,xlim=c(0,7),col="red")
hist(drawDL$u0[1,,1],breaks=50,xlim=c(0,7),add=TRUE,col="red")
#dev.off()




X11()
hist(drawLL$sigma[2,,1],breaks=10000,xlim=c(0,2),col=colourH[1],
     xlab=paste(""),main=paste("During hunt Sigma  ") )

X11()
hist(drawLL$sigma[1,,1],breaks=100,col=colourH[1],
     xlab=paste(" "),main=paste("Outside hunt Sigma ") )


X11()
hist(drawLL$phi_max[1,,1])

X11()
hist(drawLL$phi_0[1,,1])

X11()
hist(drawLL$u0[1,,1],breaks=100,xlim=c(0,5))
hist(drawNL$u0[1,,1],breaks=100,xlim=c(0,5),add=TRUE)
hist(drawDL$u0[1,,1],breaks=100,xlim=c(0,5),add=TRUE)

X11()
hist(drawLL$u1[1,,1],breaks=50,xlim=c(0,5))
hist(drawNL$u1[1,,1],breaks=50,xlim=c(0,5),add=TRUE,col="red")
hist(drawDL$u1[1,,1],breaks=50,xlim=c(0,5),col="blue",add=TRUE)
#########


## Plot the infered function DL

pdf(file= paste(strPlotExportPath,"/stat/stat_EyeVsDistance_DL.pdf",sep=""))
X11()
vX <- seq(0,5,by=0.01)
vY <- median(drawDL$phi_0 ) + median(drawDL$phi_max )*(1-exp(-  median(drawDL$lambda)*( mean(datLEyePointsDL[vsamplesDL,3]) - (vX) ) ) )
vY_u <- median(drawDL$phi_0 ) + median(drawDL$phi_max )*(1-exp(-quantile(drawDL$lambda[1,,1])[4]*( mean(datLEyePointsDL[vsamplesDL,3]) - (vX) ) ) )
vY_l <- median(drawDL$phi_0 ) + median(drawDL$phi_max )*(1-exp(- quantile(drawDL$lambda[1,,1])[2]*( mean(datLEyePointsDL[vsamplesDL,3]) - (vX) ) ) )
plot(dataDL$distP,dataDL$phi,pch=20,xlim=c(0,6),ylim=c(0,55),main="DL")
lines( vX ,vY,xlim=c(0,5),ylim=c(0,55),type="l",col="red",lwd=3)
lines( vX ,vY_u,xlim=c(0,5),ylim=c(0,55),type="l",col="blue",lwd=2)
lines( vX ,vY_l,xlim=c(0,5),ylim=c(0,55),type="l",col="blue",lwd=2)
dev.off()
X11()
hist(drawDL$lambda[1,,1],main="DL")



ind = 100
##Save the Mean Slope and intercept
##quantile(drawNL$beta[,(steps-ind):steps,1][2,])[2]
muLLa=mean(drawLL$beta[,(steps-ind):steps,1][1,]) 
muLLb=mean(drawLL$beta[,(steps-ind):steps,1][2,])
muNLa=mean(drawNL$beta[,(steps-ind):steps,1][1,])
muNLb=mean(drawNL$beta[,(steps-ind):steps,1][2,])
muDLa=mean(drawDL$beta[,(steps-ind):steps,1][1,])
muDLb=mean(drawDL$beta[,(steps-ind):steps,1][2,])
sig=mean(drawLL$sigma[,(steps-ind):steps,1])
###Plot Density of Slope
dLLb<-density(drawLL$beta[,(steps-ind):steps,1][2,])
dNLb<-density(drawNL$beta[,(steps-ind):steps,1][2,])
dDLb<-density(drawDL$beta[,(steps-ind):steps,1][2,])


pdf(file= paste(strPlotExportPath,"/stat/stat_densityolinregressionslope.pdf",sep=""))
plot(dDLb,col=colourH[1],xlim=c(0.5,1.2),lwd=3,lty=1,ylim=c(0,20),main="Density Inference of Turn-To-Prey Slope ")
lines(dLLb,col=colourH[2],xlim=c(0.5,1.2),lwd=3,lty=2)
lines(dNLb,col=colourH[3],xlim=c(0.5,1.2),lwd=3,lty=3)
legend("topleft",legend=paste(c("DL n=","LL n=","NL n="),c(NROW(lFirstBoutPoints[["DL"]][,1]),NROW(lFirstBoutPoints[["LL"]][,1]) ,NROW(lFirstBoutPoints[["NL"]][,1] ) ) )
       ,fill=colourL,lty=c(1,2,3))
dev.off()

### PLot Scatter with regression lines with Conf intervals##
#X11()

pdf(file= paste(strPlotExportPath,"/stat/stat_TurnToPrey_LinearRegression.pdf",sep=""))
plot(lFirstBoutPoints[["DL"]][,1], lFirstBoutPoints[["DL"]][,2],
     main=paste("Turn Size Vs Bearing To Prey ", sep=""),
     xlab="Bearing To Prey prior to Bout",ylab="Bearing Change After Bout",xlim=c(-100,100),
     ylim=c(-100,100),
     col=colourP[1] ,pch=pchL[1]) ##boutSeq The order In Which The Occurred Coloured from Dark To Lighter
##Draw 0 Vertical Line
segments(0,-90,0,90); segments(-90,0,90,0); segments(-90,-90,90,90,lwd=1,lty=2);
#text(lFirstBoutPoints[["DL"]][,1]+2,lFirstBoutPoints[["DL"]][,2]+5,labels=lFirstBoutPoints[["DL"]][,3],cex=0.8,col="darkblue")
abline(lm(lFirstBoutPoints[["DL"]][,2] ~ lFirstBoutPoints[["DL"]][,1]),col=colourH[4],lwd=1.0) ##Fit Line / Regression
abline(a=muDLa,b=muDLb,col=colourH[1],lwd=1.5) ##Fit Line / Regression
abline(a=quantile(drawDL$beta[,(steps-ind):steps,1][1,])[2],b=quantile(drawDL$beta[,(steps-ind):steps,1][2,])[2],col=colourR[1],lwd=4.0) ##Fit Line / Regression
abline(a=quantile(drawDL$beta[,(steps-ind):steps,1][1,])[3],b=quantile(drawDL$beta[,(steps-ind):steps,1][2,])[3],col=colourR[1],lwd=4.0) ##Fit Line / Regression

#abline( lsfit(lFirstBoutPoints[["DL"]][,2], lFirstBoutPoints[["DL"]][,1] ) ,col=colourH[1],lwd=2.0)
##LL
points(lFirstBoutPoints[["LL"]][,1], lFirstBoutPoints[["LL"]][,2],pch=pchL[2],col=colourP[2])
#text(lFirstBoutPoints[["LL"]][,1]+2,lFirstBoutPoints[["LL"]][,2]+5,labels=lFirstBoutPoints[["LL"]][,3],cex=0.8,col="darkgreen")
abline(lm(lFirstBoutPoints[["LL"]][,2] ~ lFirstBoutPoints[["LL"]][,1]),col=colourH[4],lwd=1.0)
abline(a=muLLa,b=muLLb,col=colourH[2],lwd=1.5) ##Fit Line / Regression
abline(a=quantile(drawLL$beta[,(steps-ind):steps,1][1,])[2],b=quantile(drawLL$beta[,(steps-ind):steps,1][2,])[2],col=colourR[2],lwd=4.0) ##Fit Line / Regression
abline(a=quantile(drawLL$beta[,(steps-ind):steps,1][1,])[3],b=quantile(drawLL$beta[,(steps-ind):steps,1][2,])[3],col=colourR[2],lwd=4.0) ##Fit Line / Regression

#abline(lsfit(lFirstBoutPoints[["LL"]][,2], lFirstBoutPoints[["LL"]][,1] ) ,col=colourH[2],lwd=2.0)
##NL
points(lFirstBoutPoints[["NL"]][,1], lFirstBoutPoints[["NL"]][,2],pch=pchL[3],col=colourP[3])
#text(lFirstBoutPoints[["NL"]][,1]+2,lFirstBoutPoints[["NL"]][,2]+5,labels=lFirstBoutPoints[["NL"]][,3],cex=0.8,col="darkred")
abline(lm(lFirstBoutPoints[["NL"]][,2] ~ lFirstBoutPoints[["NL"]][,1]),col=colourH[4],lwd=1.0)
abline(a=muNLa,b=muNLb,col=colourH[3],lwd=1.5) ##Fit Line / Regression
abline(a=quantile(drawNL$beta[,(steps-ind):steps,1][1,])[2],b=quantile(drawNL$beta[,(steps-ind):steps,1][2,])[2],col=colourR[3],lwd=4.0) ##Fit Line / Regression
abline(a=quantile(drawNL$beta[,(steps-ind):steps,1][1,])[3],b=quantile(drawNL$beta[,(steps-ind):steps,1][2,])[3],col=colourR[3],lwd=4.0) ##Fit Line / Regression
#abline( lsfit(lFirstBoutPoints[["NL"]][,2], lFirstBoutPoints[["NL"]][,1] ) ,col=colourH[3],lwd=2.0)
legend("topleft",legend=paste(c("DL n=","LL n=","NL n="),c(NROW(lFirstBoutPoints[["DL"]][,1]),NROW(lFirstBoutPoints[["LL"]][,1]) ,NROW(lFirstBoutPoints[["NL"]][,1] ) ) )
       , pch=pchL,col=colourL)

dev.off()





##Plot Densities Summary

sampNL <- coda.samples(mNL,                      variable.names=c("beta","sigma"),                      n.iter=20000, progress.bar="none")
sampDL <- coda.samples(mDL,                      variable.names=c("beta","sigma"),                      n.iter=20000, progress.bar="none")
X11()
plot(sampLL)
X11()
plot(sampNL)
X11()
plot(sampDL,main="DL")











## N : vector of number of points in Hunt Event
modelExpInd  <- "model{
##Prior

# Prior Sigma On Eye Angle when  In Or Out of hunt region 
for(i in 1:max(hidx)) {
for(j in 1:2){
#inv.var[j] ~ dgamma(0.01, 0.01)  ##Prior for inverse variance
sigma[i,j] ~ dgamma(0.01, 0.01) ##Draw 
}
}

# Likelihood / Separate for each Hunt Event
for(i in 1:N){
phi_0[hidx[i]] ~ dnorm(10,2) # Idle Eye Position
phi_max[hidx[i]] ~ dnorm(15,5) # Max Eye Vergence Angle
lambda[hidx[i]] ~ dgamma(1, 1) # RiseRate of Eye Vs Prey Distance
limDist[hidx[i]] <- max(distMax)
u1[hidx[i]] ~ dunif(0, limDist[hidx[i]]) ## End Hunt Distance - Close to prey
u0[hidx[i]] ~ dunif(u1, limDist[hidx[i]]) ##Start Hunt Distance -Far 


##Make indicator if hunt event is within sampled Range 
#if (u1[hidx[i]] < distP[i]  & distP[i] < u0) 
s[hidx[i],i] <- step( distP[i]-u1[hidx[i]])*step(u0[ hidx[i] ]-distP[i]  ) 

phi_hat[hidx[i],i] <- phi_0[hidx[i]] + s[hidx[i],i] * phi_max[hidx[i]]* (1-exp(-lambda[ hidx[i] ]*(distMax[i] - distP[i] ) )) 
phi[hidx[i],i] ~ dnorm( phi_hat[hidx[i],i], sigma[s[hidx[i],i]+1] ) ##choose sigma 

}"


# 
# 
# # Step 1
# # Reading the the data
# FathersLoveData <- read.csv("C:/Users/zzo1/Dropbox/PBnRTutorial/lovedata.csv")
# # Visual check data of the data
# head(FathersLoveData) 
# # the unnamed column shows the row number: each participant's data corresponds to one row
# # Y1-Y4 are the love scores for each person
# # 'Positivity' shows the positivity categories: 1: low, 2: medium, 3: high
# # X1 takes value 1 for low positivity, otherwise 0
# # X2 takes value 1 for high positivity, otherwise 0
# 
# # Checking the number of rows (i.e., 2nd dimension) of `FathersLoveData' data 
# N <- dim(FathersLoveData)[1] # count number of rows to get number of subjects
# # Creating a matrix with only the love scores: Y1-Y4 (columns 1-4):
# # We `unlist' all N rows of selected columns 1:4 from the data set, 
# # then we transform these values into numeric entries of a matrix
# data <- matrix(as.numeric(unlist(FathersLoveData[,1:4])), nrow = N)
# # Creating a variable that saves the number of time points
# nrT <- 4
# # Saving X1 and X2 as separate variables (same unlisting etc. as explained above)
# grouping <- matrix(as.numeric(unlist(FathersLoveData[,6:7])), nrow = N)
# X1 <- grouping[,1] # 1 when person had low positivity before baby
# X2 <- grouping[,2] # 1 when person had high positivity before baby
# # Creating a time vector for the measurement waves
# time <- c(-3, 3, 9, 36) # time vector (T) based on the time of the measurements
# # Now we have all the data needed to be passed to JAGS
# # Creating a list of all the variables that we created above
# jagsData <- list("Y"=data,"X1"=X1,"X2"=X2,"N"=N,"nrT"=nrT,"time"=time)
# 
# # Step 2
# LinearGrowthCurve = cat("
#                         model {
#                         # Starting loop over participants
#                         for (i in 1:N) { 
#                         # Starting loop over measurement occasions
#                         eps[i,1] <- Y[i, 1] - (betas[i,1] + betas[i,2]*time[1])
#                         Y[i, 1] ~ dnorm(betas[i,1] + betas[i,2]*time[1], precAC)
#                         for (t in 2:nrT) {  
#                         # The likelihood function, corresponding to Equation 1:
#                         
#                         eps[i,t] <- Y[i,t] - (betas[i,1] + betas[i,2]*time[t] + acorr*eps[i,t-1])
#                         Y[i, t] ~ dnorm(betas[i,1] + betas[i,2]*time[t] + acorr*eps[i,t-1], precAC)} 
#                         # end of loop for the observations
#                         
#                         # Describing the level-2 bivariate distribution of intercepts and slopes
#                         betas[i,1:2] ~ dmnorm(Level2MeanVector[i,1:2], interpersonPrecisionMatrix[1:2,1:2])
#                         # The mean of the intercept is modeled as a function of positivity group membership
#                         Level2MeanVector[i,1] <- MedPInt + betaLowPInt*X1[i] + betaHighPInt*X2[i]
#                         Level2MeanVector[i,2] <- MedPSlope + betaLowPSlope*X1[i] + betaHighPSlope*X2[i]
#                         } # end of loop for persons
#                         # Specifying priors  distributions
#                         MedPInt ~ dnorm(0, 0.01)
#                         MedPSlope ~ dnorm(0, 0.01)
#                         betaLowPInt ~ dnorm(0, 0.01)
#                         betaHighPInt ~ dnorm(0, 0.01)
#                         betaLowPSlope ~ dnorm(0, 0.01)
#                         betaHighPSlope ~ dnorm(0, 0.01)
#                         
#                         sd1 ~ dunif(0, 100)
#                         precAC <- 1/pow(sd1,2)*(1-acorr*acorr)
#                         acorr ~ dunif(-1,1)
#                         
#                         sdIntercept  ~ dunif(0, 100)
#                         sdSlope  ~ dunif(0, 100)
#                         corrIntSlope ~ dunif(-1, 1)
#                         # Transforming model parameters
#                         ## Defining the elements of the level-2 covariance matrix
#                         interpersonCovMatrix[1,1] <- sdIntercept * sdIntercept
#                         interpersonCovMatrix[2,2] <- sdSlope * sdSlope
#                         interpersonCovMatrix[1,2] <- corrIntSlope * sdIntercept* sdSlope
#                         interpersonCovMatrix[2,1] <- interpersonCovMatrix[1,2]
#                         ## Taking the inverse of the covariance to get the precision matrix
#                         interpersonPrecisionMatrix <- inverse(interpersonCovMatrix)
#                         ## Creating a variables representing
#                         ### low positivity intercept
#                         LowPInt <- MedPInt + betaLowPInt 
#                         ### high positivity intercept
#                         HighPInt <- MedPInt + betaHighPInt 
#                         ### low positivity slope
#                         LowPSlope <- MedPSlope + betaLowPSlope
#                         ### high positivity slope
#                         HighPSlope <- MedPSlope + betaHighPSlope
#                         ### contrasts terms between high-low, medium-low, high-medium intercepts and slopes
#                         HighLowPInt <- HighPInt - LowPInt
#                         MedLowPInt <- MedPInt - LowPInt
#                         HighMedPInt <- HighPInt - MedPInt
#                         HighLowPSlope <- HighPSlope- LowPSlope
#                         MedLowPSlope <- MedPSlope - LowPSlope
#                         HighMedPSlope <- HighPSlope - MedPSlope
#                         }
#                         ",file = "GCM.txt")
# 
# 
# # Step 3
# # Collecting the model parameters of interest
# parameters  <- c("MedPSlope","betaLowPInt",
#                  "betaHighPInt","betaLowPSlope", 
#                  "betaHighPSlope", "MedPInt", 
#                  "sdIntercept", "sdSlope", 
#                  "corrIntSlope", "betas",
#                  "LowPInt","HighPInt","LowPSlope", "HighPSlope",
#                  "HighLowPInt","HighMedPInt","MedLowPInt",
#                  "HighLowPSlope","HighMedPSlope","MedLowPSlope",
#                  "acorr", "sd1")
# # Sampler settings
# adaptation  <- 2000 # Number of steps to "tune" the samplers
# chains  <- 6    # Re-start the exploration "chains" number of times
# #  with different starting values
# burnin  <- 1000 # Number of steps to get rid of the influence of initial values
# # Define the number of samples drawn from the posterior in each chain
# thinning <- 20
# postSamples <- 60000
# nrOfIter <- ceiling((postSamples * thinning)/chains)
# 
# 
# fixedinits<- list(list(.RNG.seed=5,.RNG.name="base::Mersenne-Twister"),list(.RNG.seed=6,.RNG.name="base::Mersenne-Twister"),list(.RNG.seed=7,.RNG.name="base::Mersenne-Twister"),list(.RNG.seed=8,.RNG.name="base::Mersenne-Twister"),list(.RNG.seed=9,.RNG.name="base::Mersenne-Twister"),list(.RNG.seed=10,.RNG.name="base::Mersenne-Twister"))
# 
# # Step 4
# # loading the rjags package
# library(rjags)            
# # creating JAGS model object
# jagsModel<-jags.model("GCM.txt",data=jagsData,n.chains=chains,n.adapt=adaptation,inits=fixedinits)
# # running burn-in iterations
# update(jagsModel,n.iter=burnin)
# # drawing posterior samples
# codaSamples<-coda.samples(jagsModel,variable.names=parameters,thin = thinning, n.iter=nrOfIter,seed=5)
# 
# source("C:/Users/zzo1/Dropbox/PBnRTutorial/posteriorSummaryStats.R")
# # Part 1: Check convergence
# resulttable <- summarizePost(codaSamples)
# saveNonConverged <- resulttable[resulttable$RHAT>1.1,]
# if (nrow(saveNonConverged) == 0){
#   print("Convergence criterion was met for every parameter.")
# }else{ 
#   print("Not converged parameter(s):")
#   show(saveNonConverged)
# }
# # Part 2: Display summary statistics for selected parameters (regexp)
# show(summarizePost(codaSamples, filters =  c("^Med","^Low","^High","^sd","^corr", "sd1", "acorr"))) 
# 
# save.image(sprintf("GCMPBnR%s.Rdata", Sys.Date()))
# 



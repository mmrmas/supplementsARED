# R-script for ananlysis of SquaredAnt plates
# For plate design SA20191111
# This script is designed for 2 96well plates recorded in one recording station and assumes the orginal output 
# from the Supplementary_file_3.zip ImageJ2 macro archive.
# written by Sam, 20191111, last modified on 20210821

##First read in the arguments listed at the command line
data_file <-""
args <- commandArgs(trailingOnly = TRUE)
data_file <- args[1]

#load lib PNG for the logo, install if not there?
#library(png)
#img <- readPNG(args[2])


skiplines <- 241
if (length(args) >2){
	skiplines <- as.numeric(args[3])
}

#for non-command line testing purposes
#setwd("/Users/samlinsen/Dropbox/SquaredAnt_company/SquaredAnt_Private/4.company_docs/8.Directions/paper_XJTLU/progress/20210302/")
#data_file <- '20200710_OTC25_50.IJ.txt'

#get all the info from the imageJ output
input <- read.delim(file = data_file, header = F, skip = skiplines, nrows = 7, blank.lines.skip = FALSE) 
sample_names <- strsplit(as.character(input[1,]),",")[[1]]
batch <- input[2,]
run_date <- input[3,]
comments <- input[4,]
persons <- input[5,]
timestamp <- date()
platform <- input[6,]
rec_station <- input[7,] 


#get directory
directory <- data_file
if (grepl ('c:',directory, ignore.case = T)){
	pattern <- sub("c:.+\\\\","",directory, fixed = F, ignore.case = T)
	directory <- sub(pattern,"",directory)
} else {
	pattern <- sub("^.+/","",directory, perl = T)
	directory <- sub(pattern,"",directory)
}

#setwd
setwd(directory)

#strain names. Assumed is a plate layout where the first 2 columns are copied 6 times over one 96 well plate. A1 is a positive control; H2 is a negative (empty) control. 
#Then, non-treated samples are in the first 2 columns (1,2), treated in the second (3,4), and again for column (5,6 vs 7,8) and (9,10 vs 11,12)
strains <- c('P1 MG1655','P1 L04','P1 B14','P1 K01','P1 C12','P1 H17','P1 I03','P1 A05','P1 F20','P1 N10','P1 C19','P1 C14','P1 F21','P1 G19','P1 A18','P1 NC','P2 MG1655','P2 L04','P2 B14','P2 K01','P2 C12','P2 H17','P2 I03','P2 A05','P2 F20','P2 N10','P2 C19','P2 C14','P2 F21','P2 G19','P2 A18','P2 NC')

#open file
data <- read.delim(file = data_file, h = T, nrows = skiplines - 1, blank.lines.skip = FALSE)
if (dim(data)[2] == 97 || dim(data)[2] == 193){														
	data<- data[,(2:193)]																			#if only one plate, change to 97
}
data <- na.exclude(data)
length_block <- dim(data)[1]
blocks <- seq(0,length_block,by=(length_block/3))
block <- blocks[2]

#open pdf
date_now <- strsplit(timestamp," ")[[1]]
output <- paste(date_now[1], date_now[2], date_now[3],pattern,"pdf", sep = '.')
pdf (file = output, width = 8, height = 8, bg = 'white')

#build frontpage
sample_names_fp<-c("Samples:", "", "Plate 1", as.character(sample_names[1:6]),"", "Plate 2", as.character(sample_names[7:12]))
sample_names_fp<- paste(sample_names_fp, sep = " ", collapes = "\n")
sample_names_fp <- toString(sample_names_fp)
sample_names_fp <- gsub(',','',sample_names_fp)
###plot it
plot (0,0, xlim = c(0,1), ylim = c(0,1), type = 'n', axes = F, xlab ="", ylab = "")
text(0.5,1,"SquaredAnt ABright WATER Sample Report", cex = 1, pos = 1)
text(0.5,0.95,paste("Created on:", timestamp, sep = " "), cex = 0.8, pos = 1)
text(0.5,0.9,paste("by:", persons, "with", rec_station, sep = " "), cex = 0.8, pos = 1)
text(0.2,0.7, sample_names_fp, cex = 0.7, pos = 1, adj = 0)
text(0.8,0.7,paste("Platform ID", platform, "; batch no", batch, sep = " "), cex = 0.7, pos = 1)
text(0.8,0.65,paste("Run on", run_date, sep = " "), cex = 0.7, pos = 1)
text(0.8,0.6, paste(strwrap(comments, width = 50), collapse = "\n"), cex = 0.7, pos = 1, adj = 0)
rasterImage(img, 0.65, 0.2, 0.65+0.3, 0.2+0.087)

#colors 
blue <- data[1:blocks[2],]
green <- data[(blocks[2]+1):blocks[3],]
red <- data[(blocks[3]+1):length_block,]

#normalized differene
ndif <- (red - blue) / (red + green + blue)
colnames(ndif) <- NULL

#line colors from high to low
colors <- c('blue', 'red','yellow','green','brown','light blue')

#prepare legend text
legend_text <-c()
for (i in seq(1,96)){
	legend_text <- cbind(legend_text, as.character(sample_names[1:6]))
}
for (i in seq(97,192)){
	legend_text <- cbind(legend_text, as.character(sample_names[7:12]))
}

#plot time-series curves for each cell strain (=well)
par(mfrow = c(2,2))
#plot every 16th column
column_select <- rep(1:16, each = 2)
strain_title <- column_select
column_add <- rep(c(0,96),8)
column_select <- column_select + column_add
strain_title <- strain_title + rep(c(0,16),8)
strain_title <- strains[strain_title]
strain_title_no <- 0
for (i in column_select){
	strain_title_no <- strain_title_no + 1
	ylim <- c(min(ndif),max(ndif))
	plot (0,0, xlim = c(0,block), ylim = ylim, type = 'n', axes = F, xlab = "measure point (nr)", ylab = 'signal strength, normalized', main = strain_title[strain_title_no], cex.main = 0.8, cex.lab = 0.8)
	axis(side = 1, at = seq(1:block),labels = seq(1:block), cex.axis = .7, las = 3)
	axis(side = 2, at = seq(ylim[1],ylim[2], by = 0.1 ),labels = round (seq(ylim[1],ylim[2], by = 0.1 ), 2), cex.axis = .7, las = 2)
	legend(block, ylim[1], legend_text[,i], col = colors, fill = colors, cex = 0.5 , yjust = 0, xjust = 1)
	for (j in seq(1:6)){
		lines (ndif[,i + (16*(j-1))], col = colors[j])	
	}
}


#calculate Euclidian distances
#===
#get the median of the control values
majority<-function(x){
	maxval <-10000
	positions <-c()
	for (i in c(1:(length(x)-1))){
		for (j in c((i+1):length(x))){
			if (abs(x[i]-x[j]) < maxval){
				maxval <- abs(x[i]-x[j])
				positions <- c(i,j)
			}
		}
	}
	return(mean(x[positions]))
}

																								# here we are taking the most alike control values and produce a matrix with 16 columns ("majority mean" of column 
																								#	1, 3, 5 and column 2,4,6)
nontreated_p1 <- c()
treated_p1 <- c()
block <- dim(ndif)[1]
for (i in seq(1:16)){
	nontreated_p1 <- cbind(nontreated_p1,apply(ndif[c(1:block),seq(i,80+i, by = 32)],1, majority))	 #these are noon-treated samples
	treated_p1 <- cbind(treated_p1,apply(ndif[c(1:block),seq(i+16,80+i, by = 32)],1, majority)) 		 #these are treated samples	
}

																									#...and repeat for plate 2
nontreated_p2 <- c()
treated_p2 <- c()
block <- dim(ndif)[1]
for (i in seq(1:16)){
	nontreated_p2 <- cbind(nontreated_p2,apply(ndif[c(1:block),seq(i+96,80+96+i,by = 32)],1, majority))	
	treated_p2 <- cbind(treated_p2,apply(ndif[c(1:block),seq(i+96+16,80+96+i, by = 32)],1, majority)) 		 
}


																									#make a table that will be used to subtract and calculate distance. This is an array of 6 times the 
																									#nontreated_p1 and then nontreated_p2 and can be normlized and subtracted from the whole table to give a liniear 																									#distance between ctl and sample
pcsweep <- c()  # all the "majority" non-treated values
for (i in seq(1:6)){
	pcsweep <-cbind(pcsweep,nontreated_p1)
	}
for (i in seq(1:6)){
	pcsweep <-cbind(pcsweep,nontreated_p2)
}


ncsweep <- c()																					 #each value represents the "majority" value of the negative control. 
ncNontreated_p1<- c()
ncTreated_p1<- c()
for (i in seq(1:16)){
	ncNontreated_p1 <-cbind(ncNontreated_p1, nontreated_p1[,16])											 #treated
	ncTreated_p1 <-cbind(ncTreated_p1, treated_p1[,16]) 													 #non-treated
}

for (i in seq(1:3)){
	ncsweep <- cbind(ncsweep, ncNontreated, ncTreated)
	}
	

ncNontreated_p2<- c()
ncTreated_p2<- c()
for (i in seq(1:16)){
	ncNontreated_p2 <-cbind(ncNontreated_p2, nontreated_p2[,16])											 #treated
	ncTreated_p2 <-cbind(ncTreated_p2, treated_p2[,16]) 													 #non-treated
}
for (i in seq(1:3)){
	ncsweep <- cbind(ncsweep, ncNontreated_p2, ncTreated_p2)
	}





	


ndif_ed <- as.matrix(ndif)-ncsweep		   						#normalize the data against empty controls. Basically we set the reference values to 0 ( as in the raw data, values may be negative)

																#now we are going to find the maximum values of the non-treated samples and set these to 100%
sweep_row_p1 <- as.numeric(nontreated_p1[dim(nontreated_p1)[1],]) - ncNontreated_p1[dim(ncNontreated_p1)[1],]		#maximum "majority" values minus negative control at the latest time point plate 1
sweep_row_p2 <- as.numeric(nontreated_p2[dim(nontreated_p2)[1],]) - ncNontreated_p2[dim(ncNontreated_p2)[1],]		#maximum "majority" values minus negative control at the latest time point plate 2
sweep_row_p1[16] <- 1											#we set the NC well to 1, as we cannot divide by 0. These values are ignored later
sweep_row_p2[16] <- 1											#we set the NC well to 1, as we cannot divide by 0. These values are ignored later
sweep_row <- c(rep(sweep_row_p1,6),	 rep(sweep_row_p2,6))		#C1: comment out in order to use the biggest value in this plate as 100%. This reduces the impact of cells with a low signal. 	
#get the maximum value of the sweep row
#maxsweep_p1 <- max(sweep_row_p1[sweep_row_p1 != 1])				#C2: alternatively this can be commented out instead of C1. Get the maximum difference between a NC and non-treated control			
#maxsweep_p2 <- max(sweep_row_p2[sweep_row_p2 != 1])				#C2: alternatively this can be commented out instead of C1. Get the maximum difference between a NC and non-treated control			



ndif_ed2 <- ndif_ed
ndif_ed <- sweep(ndif_ed,2,sweep_row,"/") 						#C1: comment out in order to use the biggest value in this plate as 100%. This reduces the impact of cells with a low signal. 
#ndif_ed[,1:96] 		<- ndif_ed[,1:96]  / maxsweep_p1			#C2: alternatively this can be commented out instead of C1	
#ndif_ed[,97:192] 	<- ndif_ed[,97:192] / maxsweep_p2			#C2: alternatively this can be commented out instead of C1	
																#now we have got a matrix that has been normalized against the NC values and divided by the maximal values of the non-treated samples




																#it is time to calculate the distances
																#first give the pcsweep the same treatment as ndif_ed (pcsweep is "majority" non-treated values, repeated 6x)
pcsweep <- pcsweep-ncsweep							
pcsweep <- sweep(pcsweep,2,sweep_row,"/")						#C1: comment out in order to use the biggest value in this plate as 100%. This reduces the impact of cells with a low signal. 
#pcsweep[,1:96]  <- pcsweep[,1:96] / maxsweep_p1				#C2: alternatively this can be commented out instead of C1	
#pcsweep[,97:192]  <- pcsweep[,97:192] / maxsweep_p2																	
																#now pcsweep is a table with 6 repeats of the non-treated controls, normalized against the negative controls and divided by the maximum distance
																#and ndif_ed is the original table, normalized and divided identically.
																#if we substract pcsweep from ndif_ed, we find the differences between treated and non-treated, and we can also find variation witin the data


ndif_ed <- ndif_ed - pcsweep

																#then we summarize all and get the Euclidian Distance
ndif_sum <- apply(ndif_ed, 2, sum)
ndif_ed_sq <- ndif_ed^2
ndif_ed_sq_sum <- apply(ndif_ed_sq, 2, sum)
ndif_ed_sq_sum_sqrt <- sqrt(ndif_ed_sq_sum)
ndif_ed_sq_sum_sqrt[ndif_sum>0]<-ndif_ed_sq_sum_sqrt[ndif_sum>0] * -1   #we assign a "negative" distance if the linear distance is > 0: then the signal in "treated" was higher

																
																
																 #last checks to get rid of low intensity 
#ndif_ed_sq_sum_sqrt[sweep_row < 0.1] <- 0 						 # no growth		
																 #here we take the first quartile of the values of each sample among the first measure points and create a matrix 192 
																 #entries
		
firstMeasurement_p1 <- c()
firstMeasurement_p2 <- c()
for (i in seq(1:16)){
	firstMeasurement_p1 <- c(firstMeasurement_p1 ,apply(ndif[1,seq(i,80+i,by = 16)],1,function(x){summary(x)[2]})) # 2 is the first quantile
	firstMeasurement_p2 <- c(firstMeasurement_p2 ,apply(ndif[1,seq(i+96,80+96+i,by = 16)],1,function(x){summary(x)[2]}))
}
firstMeasurement_p1Columns <- c()
firstMeasurement_p2Columns <- c()
for (i in seq(1:6)){											#create table with all quartiles
	firstMeasurement_p1Columns <-c(firstMeasurement_p1Columns,firstMeasurement_p1 )
	firstMeasurement_p2Columns <-c(firstMeasurement_p2Columns,firstMeasurement_p2)
}

firstMeasurementsColumns <-c(firstMeasurement_p1Columns,firstMeasurement_p2Columns)
firstMeasurementsColumns <- as.numeric(firstMeasurementsColumns)
l<- as.numeric(ndif[1,]) < firstMeasurementsColumns - 0.1 
ndif_ed_sq_sum_sqrt[l] <- 0	

# in case the non-treated is below that level, we need to remove all the Eucliadian distances
for (i in c(seq(1,16))){	
	if (l[i] == T){
		m <- i+ seq(0,80, by = 16)
#		ndif_ed_sq_sum_sqrt[m] <- 0	
	}
}



sd_ed <- sd(abs(ndif_ed_sq_sum_sqrt[ndif_ed_sq_sum_sqrt!=0]))									#set some sort of threshold to show higher_then_expected EDs 
																								#(assume positive ed value as this is per definition the case)
thresh <- round (mean(abs(ndif_ed_sq_sum_sqrt[ndif_ed_sq_sum_sqrt!=0]))+2*sd_ed ,digits = 2)
print(thresh)

#plot it
layout(matrix(c(1,1,1,1,1,2), nrow = 1, ncol = 6, byrow = TRUE))
plot (0,0, xlim = c(0,15), ylim = c(0,6), type = 'n', axes = F, xlab ="", ylab = "", main = "Euclidian Distance Measure from Blank")
par(mgp = c(0, -2, 0))
for (i in seq(1,15)){
	for (j in seq(0,5)){
		plotcex <- ndif_ed_sq_sum_sqrt[i+(16*j)]
		if (plotcex > 0){
			points (i,6-j,pch = 25, cex = plotcex, bg = 'black' )
		}
		if (plotcex < 0){
			points (i,6-j,pch = 24, cex = plotcex * -1, bg = 'black' )
		}	
		axis(1,at = seq(1,15), labels = strains[1:15], las = 2, cex.axis = .5, lwd = 0, font = 3)
		axis(2,at = seq(1,6), labels = rev(sample_names[1:6]), las = 2, cex.axis = .5, lwd = 0)
	}
}


#pot legend 																								
plot (0,0, xlim = c(0,4), ylim = c(0,25), type = 'n', axes = F, xlab ="", ylab = "", main = "ED Legend")
cexlegend <- seq(0.5,4,by = 0.5)
cexlegend <- sort(c(cexlegend, thresh))
collegend <- rep('white', 9)
for (i in seq(1,9)){
	thiscex <- cexlegend[i]
	if (thiscex >= thresh){
		points (1, 25-i+1, pch = 25, cex = thiscex, bg = 'red' )
	}
	if (thiscex < thresh){
		points (1, 25-i+1, pch = 25, cex = thiscex , bg = 'black' )
	}	
	text (2.5, 25-i+1 , cexlegend[i])
}	


#summarize the data
block <- c(1:16)
ctl_plate1 <- rbind(ndif_ed_sq_sum_sqrt[block], ndif_ed_sq_sum_sqrt[block+32], ndif_ed_sq_sum_sqrt[block+64])
sam_plate1 <- rbind(ndif_ed_sq_sum_sqrt[block+16], ndif_ed_sq_sum_sqrt[block+32+16], ndif_ed_sq_sum_sqrt[block+64+16])
ctl_plate2 <- rbind(ndif_ed_sq_sum_sqrt[block+96], ndif_ed_sq_sum_sqrt[block+128], ndif_ed_sq_sum_sqrt[block+160])
sam_plate2 <- rbind(ndif_ed_sq_sum_sqrt[block+96+16], ndif_ed_sq_sum_sqrt[block+128+16], ndif_ed_sq_sum_sqrt[block+160+16])


ctl_plate1_avg <- apply (ctl_plate1,2,majority)
ctl_plate1_sd  <- apply (abs(ctl_plate1),2,sd)
sam_plate1_avg <- apply (sam_plate1,2,majority)
sam_plate1_sd  <- apply (abs(sam_plate1),2,sd)
ctl_plate2_avg <- apply (ctl_plate2,2,majority)
ctl_plate2_sd  <- apply (abs(ctl_plate2),2,sd)
sam_plate2_avg <- apply (sam_plate2,2,majority)
sam_plate2_sd  <- apply (abs(sam_plate2),2,sd)


cat(data_file,file="outfile.txt", sep="\n", append=TRUE)
cat(sam_plate1_avg,file="outfile.txt", sep="\t", append=TRUE) 
cat('',file="outfile.txt", sep="\n", append=TRUE)
cat(sam_plate1_sd ,file="outfile.txt", sep="\t", append=TRUE)
cat('',file="outfile.txt", sep="\n", append=TRUE)


avg_sd_data <- c(ctl_plate1_avg,ctl_plate1_sd,sam_plate1_avg,sam_plate1_sd,ctl_plate2_avg,ctl_plate2_sd,sam_plate2_avg,sam_plate2_sd)
#avg_sd_data <- c(ctl_plate1_avg,ctl_plate1_sd,sam_plate1_avg,sam_plate1_sd)

#plot the averages and the SDs
plot (0,0, xlim = c(0,15), ylim = c(0,8), type = 'n', axes = F, xlab ="", ylab = "", main = "Average and SD Euclidian Distance Measure from Blank")
par(mgp = c(0, -2, 0))
for (i in seq(1,15)){
	for (j in seq(0,6,by = 2)){
	#for (j in seq(0,2,by = 2)){
		plotcex <- avg_sd_data[i+(16*j)]
		if (plotcex > 0){
			points (i,8-j,pch = 25, cex = plotcex, bg = 'black' )
		}
		if (plotcex < 0){
			points (i,8-j,pch = 24, cex = plotcex * -1, bg = 'black' )
		}
		meanval <- avg_sd_data[i+(16*j)]
		text (i,8-j-0.5,labels = round(meanval,2))	
		sdval <- avg_sd_data[i+(16*(j+1))]
		text (i,8-j-1,labels = round(sdval,2))	
		axis(1,at = seq(1,15), labels = strains[1:15], las = 2, cex.axis = .5, lwd = 0, font = 3)
		axis(2,at = seq(2,8, by = 2), labels = rev(sample_names[c(1,2,7,8)]), las = 2, cex.axis = .5, lwd = 0)
		axis(2,at = seq(1.5,7.5, by = 2), labels = c("mean", "mean","mean","mean"), las = 2, cex.axis = .5, lwd = 0)
		axis(2,at = seq(1,7, by = 2), labels = c("SD", "SD","SD","SD"), las = 2, cex.axis = .5, lwd = 0)
	}
}

dev.off()


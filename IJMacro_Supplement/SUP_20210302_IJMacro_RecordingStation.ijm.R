// a macro to analyze two plates in the SquaredAnt Analytics Box by ImageJ2
// written by Sam Linsen
// IJ webcam plugin required (https://imagej.nih.gov/ij/plugins/webcam-capture/index.html)
// Leave the ROIs in this zip document in the same directory as this macro script. These ROIs may have to be adjusted according to your set-up by modifying them in imageJ2 directly.
// Variables that may be adjusted to operate this file are below the comment "//CHANGE ACCORDING TO CONTEXT"
//  Assumed is a plate layout where the first 2 columns are copied 6 times over one 96 well plate. A1 is a positive control; H2 is a negative (empty) control.
//Then, non-treated samples are in the first 2 columns (1,2), treated in the second (3,4), and again for column (5,6 vs 7,8) and (9,10 vs 11,12)
//The output of this macro is a text document with RGB data. The normalized B-R data time series and Euclidian Distance can be analyzed and visualized by running the SUP_20210302_IJOutputAnalysis.R with the command in the end of this script's output file. 

// Variables #############################################
// This macro station id
//CHANGE ACCORDING TO CONTEXT
Recording_station_id = "Recording Station 1"; 



//Preparations #########################################

// close ROI
if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}
// close results
if (isOpen("Results")) {	
	run("Clear Results"); 	
}

// close images
run("Close All");



// get input data strings ####################################

samples = "comma-separated sample IDs in plate and column order";
Dialog.create("New Image");
Dialog.addString("Filename", 'YYYYMMDD_description_no_spaces',100);
Dialog.addString("Samples:", samples, 100);
Dialog.addString("batchdate", 'YYYYMMDD');
Dialog.addString("rundate",'YYYYMMDD');
Dialog.addString("comments",'10 words max', 30);
Dialog.addString("persons",'', 20);
Dialog.addChoice("Platform:", newArray("SA20191111_water","Other")); // STILL NEEDS ADJUSTMENTS FOR OTHER PLATFORMS (See below file opening)
Dialog.show();
filename = Dialog.getString();
samples = Dialog.getString();
batchdate = Dialog.getString();
rundate = Dialog.getString();
comments = Dialog.getString();
persons = Dialog.getString();
platform = Dialog.getChoice();
platform_file = '';

//CHANGE ACCORDING TO CONTEXT
if (platform == 'SA20191111_water'){
	//CHANGE ACCORDING TO CONTEXT
	platform_file = 'SA20191111-water/20191111_SA20191111_analysis.R';
}
savedir = getDirectory("Create a directory to save the file"); 
// get the dropbox shared folder, assume that the image is also in there

//CHANGE ACCORDING TO CONTEXT
anchor_dir_index = indexOf(savedir,"SquaredAnt_shared");   // this anchor generates a "root" wher to store the new file
anchor_dir= substring(savedir, 0 , (anchor_dir_index + 17));

// set measurement variables
run("Set Measurements...", "mean redirect=None decimal=3");





// start the image captures stream. ############################################# 

// We measure every minute and check from 40 minutes if the control "red" values have surpassed their "blue" values.
waitForUser("start the IJ webcam plugin\n -select the camera\n -custom width=1700 height=1050\n unit=µm pixel_size=1.00000000 \n 8-bit number = 4 \n\npress OK when you are ready to start measuring");
// capture name of the stream
stream = getImageID();

setBatchMode(true);
slides = 60;
endslide = 0;
for (s=1; s<=slides; s++) {
	selectImage(stream); 
	saveAs("Jpeg", savedir+s+"_"+filename+".jpg");
	rename(stream);
	// open that file
	open(savedir+s+"_"+filename+".jpg");
	endslide = s;
	if (s >39){
		// check the color in the first 16 wells
		run("Size...", "width=1700 height=1050 depth=endslide average interpolation=Bilinear");
		run("ROI Manager...");
		roiManager("Open", anchor_dir+"/4. Tools/Macro_Station1/20191111_colorcheck_RoiSet_Station1.zip"); 
		// split the colors in RGB
		run("Split Channels");
		// measure the color intensities
 		selectWindow(s+"_"+filename+".jpg (blue)");
		roiManager("measure");
 		selectWindow(s+"_"+filename+".jpg (red)");
		roiManager("measure");
		roiManager("reset");
 		selectImage(stream); 
		close(s+"_"+filename+".jpg (blue)");
		close(s+"_"+filename+".jpg (green)");
		close(s+"_"+filename+".jpg (red)");
		close(s+"_"+filename+".jpg");
		// read measurement red and blue
		selectWindow("Results");
		b1 = getResult("Mean",0);
		b2 = getResult("Mean",1);
		r1 = getResult("Mean",2);
		r2 = getResult("Mean",3);
		run("Clear Results"); 	
		// stop if the color intensity crosses a certain threshold		
		if ((r1 > b1) & (r2 > b2)){
			s = slides + 1;
		}
	}
	wait (60000);  // repeat every minute
}

//to continue from the previous loop
s = endslide +1;
//add 20 slides for the slow growers F20, N10
for (t=s; t<=s+19; t++) {
	selectImage(stream); 
	saveAs("Jpeg", savedir+t+"_"+filename+".jpg");
	rename(stream);
	// open that file
	open(savedir+t+"_"+filename+".jpg");
	endslide = endslide + 1;
	wait (60000);
}

//Now we combine all images into an AVI, save it, and then reopen it
setBatchMode(false);

// get the stack
run("Image Sequence...", "open=["+savedir+"] number=endslide file="+filename+" sort");
savefile = savedir+filename+".avi";
run("AVI... ", "compression=JPEG frame=1 save=["+savefile+"]");

// close images again
run("Close All");

// delete the orifinal files
for (s=1; s<=endslide; s++) {
	File.delete(savedir+s+"_"+filename+".jpg");
}

// close Log after deleting
selectWindow("Log");
run("Close");


// open the avi
open(savefile);



// get BGR values #############################################

run("Size...", "width=1700 height=1050 depth=endslide average interpolation=Bilinear");

// set output name
dir = getDirectory("image"); 
name_ori = getTitle; 
index = lastIndexOf(name_ori, "."); 
if (index!=-1){ 
	name = substring(name_ori, 0, index);
}   
name = name + ".IJ.txt";



// get the dropbox shared folder, assume that the image is also in there
//CHANGE ACCORDING TO CONTEXT
anchor_dir_index = indexOf(dir,"SquaredAnt_shared");
anchor_dir= substring(dir, 0 , (anchor_dir_index + 17));


//lets correct the background first
setTool("rectangle");
run("ROI Manager...");
//CHANGE ACCORDING TO CONTEXT
roiManager("Open", anchor_dir+"/4. Tools/Macro_Station1/20191127_whitebalance_RoiSet_Station1.roi");
setBatchMode(true);
run("Split Channels");
list = getList("image.titles");
// get the RGB values
for (i=0; i<list.length; i++){
	selectWindow(list[i]);
	run("Restore Selection");
	val = newArray(endslide);
	for (s=1;s<=endslide;s++){
		Stack.setSlice(s);
		roiManager("Measure");
		val[s-1] = getResult("Mean");
	}

	Array.getStatistics(val, min, max, mean);
	run("Select None");
	for (s=1; s<=endslide; s++) {
		Stack.setSlice(s);
		run("Add Slice");
		run("Make Substack...", "delete slices="+s);
		selectWindow("Substack ("+s+")");
		dR = val[s-1] - mean;
		if (dR < 0) {
			run("Add...", "value="+ abs(dR));
		} else if (dR > 0) {
			run("Subtract...", "value="+ abs(dR));
		}
		run("Copy");
		run("Close"); 
		selectWindow(list[i]);
		Stack.setSlice(s);
		run("Paste");
	}
	selectWindow("Results");
	run("Close");
}
selectWindow("ROI Manager");
run("Close");

run("Merge Channels...", "c1=["+name_ori+" (red)] c2=["+name_ori+" (green)] c3=["+name_ori+" (blue)]");
setBatchMode(false);


// start to work on the corrected image
Stack.setSlice(10)


//rotate and resize to standard 
waitForUser("make sure plate 1 is left, plate 2 is right");
run("Rotate... "); 

// Get the ROIs and align them
run("ROI Manager...");
//CHANGE ACCORDING TO CONTEXT
roiManager("Open", anchor_dir+"/4. Tools/Macro_Station1/20191106_RoiSet_Station1.zip");
waitForUser("Show all ROIs. Perform translation and size to align ROIs (press ok here)");
selectWindow("ROI Manager");
roiManager("Show All");
run("Translate...");
run("Size...");

waitForUser("adjust via image-transform-translate and image-adjust-size if still needed, after this there is no turning back!");

// split the colors in RGB
run("Split Channels");
list = getList("image.titles");
Array.sort (list); 

// measure the color intensities
 for (i=0; i<list.length; i++){
 	//assume Blue, Green, Red in this order when sorted!!!
	selectWindow(list[i]);
	roiManager("multi-measure measure_all one append");
	selectWindow(list[i]);
	close();
}




//save the file  #############################################
Table.save(dir+name);
for (i = endslide; i < 80; i++){
	File.append("", dir+name);
	File.append("", dir+name);
	File.append("", dir+name);
}
File.append(samples, dir+name);
File.append(batchdate, dir+name);
File.append(rundate, dir+name);
File.append(comments, dir+name);
File.append(persons, dir+name);
File.append(platform, dir+name);
File.append(Recording_station_id,dir+name);


// add the R script with the new file, this line can later be copy-pasetd from the text file to run the R script from the command line
//CHANGE ACCORDING TO CONTEXT
Rlocation = anchor_dir + '/4. Tools/'+ platform_file;
RlocationMac = replace(Rlocation, "\\ ", "\\\\\ ");

//CHANGE ACCORDING TO CONTEXT if you need your logo on your report 
Logolocation = anchor_dir +'/4. Tools/SA20191111-water/SA_logo.png';
LogolocationWin = replace(Logolocation, "/", "\\\\");
LogolocationMac = replace(Logolocation, "\\ ", "\\\\\ ");
dirMac = replace(dir, "\\ ", "\\\\\ ");
nameMac = replace(name, "\\ ", "\\\\\ ");
command_str_Mac = RlocationMac +" "+ dirMac + nameMac + " " + LogolocationMac;
command_str_Win = "\"" + Rlocation + "\"" +" "+ "\"" + dir + name + "\"" + " " + "\"" + LogolocationWin + "\"";
command_str_Win = replace(command_str_Win , "\\\\", "\\\\\\\\");


File.append("#MAC",dir+name);
File.append("Rscript "+ command_str_Mac, dir+name);
File.append("#WINDOWS", dir+name);
File.append("Rscript "+ command_str_Win, dir+name);


//close everything
selectWindow("Results");
run("Close");
selectWindow("ROI Manager");
run("Close");


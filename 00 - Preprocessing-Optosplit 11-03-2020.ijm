macro "Batch Measure" {


	//Initialization Parameters (can make a dialog box instead)

	rect_para = newArray(20, 25, 595, 685);
 	rect_perp = newArray(650, 25, 590, 685);
	numberOfColours = 2;
	namesArray = newArray("T2", "Venus");
	anisotropyArray = newArray(1,1);  //1 if anisotropy, 0 if fluorescence - was 1,1 for time series exp
	channelsPerColour = newArray(1,1); //Channels per colour, for splitting (Cahnge to two if only using para and perp) was 3,3 for time series exp
	alignment = 1; //1 if cells or object in field of view // 0 if a fluid or nothing in the field of view to align with

	setBatchMode(true);

	dir = getDirectory("Choose a Directory ");
    list = getFileList(dir);

    InitialRegistration(dir);

          
    for (i=0; i<list.length; i++) {
        path = dir+list[i];
		sub_path = list[i];
		
        showProgress(i, list.length);
        
        if (endsWith(path,"/") && (list[i] != "Calibration/") && (endsWith(path, "Processed/") != 1))		// If path is a directory, recurse into the directory
            {
        		makeDirectories(dir, numberOfColours, namesArray, "");
            	RecurseDirectory(dir, sub_path);
            }

  
	//waitForUser("Done!", "Done upper loop!");
 	while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
}

waitForUser("Done", "Done Processing Images");
}



function InitialRegistration(dir)
{
	// Initial registration with a landmark in the image field	
	// Purpose of this is to come up with initial transforms for Para and Perp registration
	base_folder = dir + "Calibration\\AlignmentImages\\";
	list1 = getFileList(base_folder);
	path2 = base_folder + list1[0];
	open(path2);
	run("Enhance Contrast", "saturated=0.35"); // Registration does not work if contrast is bad

	

	source_folder = base_folder + "Original\\";
	File.makeDirectory(source_folder); 

	FileName=getTitle();
	FileName=replace (FileName, ".ome.tif", "");


	//makeRectangle(584, 10, 530, 720);
	makeRectangle(rect_perp[0], rect_perp[1], rect_perp[2], rect_perp[3]);
	run("Duplicate...", " "); // perp
	rename(FileName + "_Perp");	
	saveAs ("tiff", source_folder + "Perp.tif");
	close(FileName + "_Perp.ome.tif");


	selectWindow(FileName + ".ome.tif"); // need to make more general
	//makeRectangle(10, 10, 530, 720);
	makeRectangle(rect_para[0], rect_para[1], rect_para[2], rect_para[3]);
	run("Duplicate...", " "); // para
	rename(FileName + "_Para");
	saveAs ("tiff", source_folder + "Para.tif");
	close(FileName + "_Para.ome.tif");
	close(FileName + ".ome.tif");	
	
	output_folder = base_folder + "Ouput\\";
	transform_folder = base_folder + "Transforms\\";
	File.makeDirectory(output_folder); 
	File.makeDirectory(transform_folder); 

	run("Register Virtual Stack Slices", "source=[" + source_folder + "] output=[" + output_folder + "] feature=Rigid registration=[Rigid                -- translate + rotate                  ] save");
	close("Para.tif");
	close("Perp.tif");
	close("Registered AlignmentImages");	

	
	}
}


function RecurseDirectory (dir, sub_path)
{
	dir2 = dir+sub_path;
	listR = getFileList(dir2);
    
    for (i=0; i<listR.length; i++) {
        path2 = dir2+listR[i];
        sub_path2 = sub_path + listR[i];
        showProgress(i, listR.length);

        if (endsWith(path2,"/") && (listR[i] != "Calibration/"))		// If path is a directory, recurse into the directory
            {
            	makeDirectories(dir, numberOfColours, namesArray, sub_path);
            	RecurseDirectory(dir, sub_path2);
            }

        //else if (endsWith(path2,"Pos0.ome.tif") || endsWith(path2,"Pos_000_000.ome.tif")) 
        else if (endsWith(path2,".ome.tif"))
		{
			//open(path2);
			//waitForUser(path2);
        	//if (nImages>=1) {
			PreprocessImages(dir, sub_path, path2); //}  
		}
    }
    
    
	//waitForUser("Done!", "Done!");
 	while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
}



//note: Import the required arrays if necessary
function PreprocessImages(dir, sub_path, filename_path){

open(filename_path);
FileName=getTitle();
getDimensions(width, height, channels, slices, frames);
close(FileName);

//waitForUser("Channels: " + channels + " Slices: " + slices + " Frames: " + frames); 

//waitForUser(slices, frames);
//Stitch Images if Required
//if (endsWith(FileName, "Pos_000_000.ome.tif"))
//run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by image metadata] browse=[" + dir + FileName + "] multi_series_file=[" + dir + FileName +"] fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 increase_overlap=0 computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
	            
FileName=replace (FileName, ".ome.tif", "");



upperDir = sub_path;
upperDir = substring(upperDir, 0, lengthOf(upperDir)-1); //remove the first slash // remove if only one level down(ie Experiment/Sample/Picture, but keep if you want files saved two levels down (Experiment/Treatment/Sample/Picture)
//waitForUser("Filename: " + FileName + " UpperDir: " + upperDir);

while (!endsWith(upperDir, "\\") & !endsWith(upperDir, "/"))
	{
	//upperDir = Array.slice(upperDir, 0, upperDir.length-1);
	upperDir = substring(upperDir, 0, lengthOf(upperDir)-1); // -1 for 2 levels down, -2 for 1 level down
	}

currentSlice = 0;
slicestring = "";
currentFrame = 0;

	for (i=0; i<numberOfColours; i++)
	{
		for(currentFrame=1; currentFrame<(frames+1); currentFrame++)
		{
			open(filename_path);
		
			//File.makeDirectory(dir + "/" + namesArray[i] + "/" + sub_path);
			currentSlice = i;
			firstSlice = currentSlice + 1;  //starts at the beginning
			for (j=0; j<channelsPerColour[i]; j++)
			{
				lastSlice = currentSlice + 1;
		
				currentSlice = currentSlice+1;  //increment the counter
			}
		
			if (channels == 1 && frames == 1)
			{
				//run("Make Substack...", "channels=" + firstSlice + "-" + lastSlice);
				//waitForUser("In channels=1");
				//run ("Make Substack...", "channels=" + firstSlice);
				//saveString =  upperDir + FileName + "_" + namesArray[i];
				//saveString = dir + namesArray[i] + "_Processed" + File.separator + upperDir + FileName;
			}
			else
			{
				run ("Make Substack...", "channels=" + firstSlice + "-" + lastSlice + " frames=" + currentFrame + "-" + currentFrame);
				//saveString =  upperDir + namesArray[i] + "/" + FileName + "_" + namesArray[i];
				//saveString =  dir + namesArray[i] + "_Processed" + File.separator + upperDir + File.separator + FileName + "_" + namesArray[i];
			}

			//waitForUser("colour: " + i + ", frame: " + currentFrame + "firstslice: " + firstSlice + ", lastslice: " + lastSlice);
			if (frames > 1)
				saveString =  dir + namesArray[i] + "_Processed" + File.separator + upperDir + File.separator + FileName + "_" + namesArray[i] + "F" + IJ.pad(currentFrame,2);
			else
				saveString =  dir + namesArray[i] + "_Processed" + File.separator + upperDir + File.separator + FileName + "_" + namesArray[i];
				
			if(anisotropyArray[i])
				saveString = saveString + "_A";
		
			if(anisotropyArray[i] == 0)
			{
				saveString = saveString + "_I";
			}
		
			//Optosplit additional preprocessing
			transform_folder = dir + "Calibration\\AlignmentImages\\Transforms";
			source_folder = dir + namesArray[i] + "_Processed" + File.separator + upperDir + File.separator + "TempRegister";
			output_folder = dir + namesArray[i] + "_Processed" + File.separator + upperDir + File.separator + "TempOutput";
			File.makeDirectory(source_folder);
			File.makeDirectory(output_folder); 
			
		
			//makeRectangle(584, 10, 530, 720);
			id = getImageID();
			makeRectangle(rect_perp[0], rect_perp[1], rect_perp[2], rect_perp[3]);
			run("Duplicate...", " "); // perp
			rename("Perp");	
			saveAs ("tiff", source_folder + "\\Perp.tif");
			close("Perp.ome.tif");

			selectImage(id);
			makeRectangle(rect_para[0], rect_para[1], rect_para[2], rect_para[3]);
			run("Duplicate...", " "); // para
			rename("Para");
			saveAs ("tiff", source_folder + "\\Para.tif");
			close("Para.ome.tif");
			close(FileName + ".ome.tif");
			close(FileName + ".ome-1.tif");
			
			
			if(alignment == 1)	
			{
				run("Transform Virtual Stack Slices", "source=[" + source_folder + "] output=[" + output_folder + "] transforms=[" + transform_folder + "] interpolate");		
				close("Para.tif");
				close("Perp.tif");
				selectWindow("Registered TempRegister");
				saveAs("tiff", saveString+ "_Preprocessed.tif");		
			}
			else {
				run("Images to Stack");
				saveAs ("tiff", saveString + "_Preprocessed.tif");
			}	
		
			// Delete temp folders
			deleteTempFiles(source_folder, output_folder);
			close();
		}
	}

	
//Close all open images
 	while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 

}

function deleteTempFiles(source_folder, output_folder)
{
	ok = File.delete(source_folder + "\\Para.tif");
	ok = File.delete(source_folder + "\\Perp.tif");
	ok = File.delete(source_folder);
	ok = File.delete(output_folder + "\\Para.tif");
	ok = File.delete(output_folder + "\\Perp.tif");
	ok = File.delete(output_folder);
	
}	

   
//You need to make the directories before you can save to them...   
function makeDirectories(dir, numberOfColours, namesArray, sub_path)
{
	for (i=0; i<numberOfColours; i++)
	{
		newDirectory = dir + namesArray[i] + "_Processed" + File.separator + sub_path;
		File.makeDirectory (newDirectory);

	}

	
}

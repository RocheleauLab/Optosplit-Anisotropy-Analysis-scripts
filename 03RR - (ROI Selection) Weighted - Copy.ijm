var recdir = 1;
var results_filename;

var manualMode = 1 // select 1 for manual selection (Romario)  Select 2 for automatic boxes  Select 3 for first in stack
var persistentROIs = 0 // select 0 for new ROIs.  Select 1 for persistent
var currentFrame = "001"
setBatchMode(false);	

macro "ROI_Selection" {
	// Select a directory and recurse through it, working on .lsm images

	if (manualMode == 2)
	{
		setBatchMode(true);		// Batch mode: don't show any image windows
	}
	
	dir = getDirectory("Choose a Directory ");

	truncationCount = 0;
	dirName = substring(dir, 0, lengthOf(dir)-1);
	while (!endsWith(dirName, "\\"))
	{
	truncationCount = truncationCount + 1;
	//upperDir = Array.slice(upperDir, 0, upperDir.length-1);
	dirName = substring(dirName, 0, lengthOf(dirName)-1);
	//waitForUser("Filename i uppers", upperDir);
	}
	dirName = substring(dir, lengthOf(dir)-truncationCount-1, lengthOf(dir)-1);
	//waitForUser("", dirName);
		//results_filename = "statistics.fritter";
	results_filename = dirName + ".fritter";

	// Append headings to results file

	//File.append("New Window\n\n\n",results_filename);

	File.append(dir,results_filename);

	File.append("Anis\tPerp\tPara\tAreaRO1\tX_Centroid\tY_Centroid\tpreWeight\tweightedAnisotropy\tr",results_filename);
	//File.append("\tMean\tStd. Dev.\tn\tI_para_min\tI_para_max\tParallel_Avg\tPerpendicular_Avg",results_filename);
	
	// Recurse through selected directory
	openFiles(dir, 0);

	// Done
	waitForUser("Finished analyzing images.");
}


function openFiles(dir, recursion_count) {
	firstFileCheck = 0;
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		path = dir+list[i];

		if (recursion_count == 0)
		{
			first_colour_checker = 0;  //reset the colour checker everytime you go back to the root directory
		} 

		
		//waitForUser("Got To Here", path);
		showProgress(i, list.length);
		showStatus(path);
		//waitForUser("Current Path", path);
		if (endsWith(path,"/"))	{	// If path is a directory, recurse into the directory
			//File.append("New Window\n\n\n",results_filename);

			if (endsWith(path, "_Processed/") && recursion_count == 0)
			{
				File.append("New Colour\n\n\n\n", results_filename);
			}
			
			recdir = 1;
			//waitForUser ("Recursing into the directory", "Recursion Count: " + recursion_count + " firstColourChecker = " + first_colour_checker);
			openFiles(path, (recursion_count+1));

			
			//waitForUser("In the Subdirectory", path);
		}
		// If path is a processed image, open and work on the file
		file2 = "";
		if (endsWith(path,"A_Preprocessed_processed.tif"))
		{
			open(path);
			if(firstFileCheck == 0)
			{
				File.append("New Window\n" + getTitle() + "\n\n",results_filename);
				firstFileCheck = 1;  //Don't add again for the rest of the list
			}

			
						// process image
			if (nImages>=1) {
				if (recdir == 1) {
					//File.append("\n\n" + dir,results_filename);
					recdir = 0;	
				}
				selectWindow(list[i]);
				// prepare image
				setSlice(2);
				//run("Median...", "radius=2 stack");
				//run("Median...", "radius=1 stack");
				run("Hi Lo Indicator");
				
				selectAnisotropyROIs(path);
				}
			
		}

		else if (endsWith(path,"I_Preprocessed.tif")) //If it's in intensity image
		{
			open(path);
			if(firstFileCheck == 0)
			{
				File.append("New Window\n" + getTitle() + "\n\n",results_filename);
				firstFileCheck = 1;  //Don't add again for the rest of the list
			}

						// process image
			if (nImages>=1) {
				if (recdir == 1) {
					//File.append("\n\n" + dir,results_filename);
					recdir = 0;	
				}
				selectWindow(list[i]);
				// prepare image
				//run("Median...", "radius=2 stack");
				//run("Median...", "radius=1 stack");
				run("Hi Lo Indicator");
				selectIntensityROIs(path);
			}
			
		}

	}

}



function selectAnisotropyROIs(path)
{

	upperThreshold = 68000; // was 40000
	//lowerThreshold = 500;

	lowerThreshold = 1000; // was 3000

	//run("Add Slice");
		WindowName = getTitle();
		getDimensions(width, height, channels, slices, frames);
		newImage("Intensity", "32-bit black", width, height, 1);
		newImage("Anisotropy", "32-bit black", width, height, 1);
		
		
		selectWindow(WindowName);
		setSlice(2);
		
		run("Select All");
		run("Copy");
		selectWindow("Intensity");
		run("Paste");
		run("Select None");
		
		
		selectWindow(WindowName);
		setSlice(5);
		
		run("Select All");
		run("Copy");
		selectWindow("Anisotropy");
		run("Paste");
		run("Select None");
		
		
		
		imageCalculator("Multiply create", "Intensity","Anisotropy");
		selectWindow("Result of Intensity");
		run("Select All");
		run("Copy");
		selectWindow(WindowName);
		setSlice(5);
		run("Add Slice");
		setSlice(6);
		run("Paste");
		
		
		selectWindow("Result of Intensity");
		close();
		selectWindow("Intensity");
		close();
		selectWindow("Anisotropy");
		close();
		selectWindow(WindowName);

		if (substring(WindowName, 1, 4) != currentFrame)
		{
			File.append("New Window\n" + getTitle() + "\n\n",results_filename);
			currentFrame = substring(WindowName, 1, 4);
		}
		//waitForUser("Filename", substring(WindowName, 1,4));
		//


			//run("Add Slice");
			setSlice(1);

			// prepare ROI manager
			if (isOpen("ROI Manager")==0)
				run("ROI Manager...");

			if (persistentROIs == 0)
			{
				roiManager("reset");
			}

			roiManager("Show All");
			pathROI = replace(path, "_processed.tif", "");
			roiFile = pathROI+"--ROI.zip";
			//waitForUser("", roiFile);
			if (File.exists(roiFile))
			{
				//waitForUser("Roi File Exists", roiFile);
				roiManager("open",roiFile);
			}
			// wait for user

			if (manualMode == 1)
			{
				waitForUser("Select cells and add the selections to the ROI manager (ctrl+T)."
				+ "\n\nPress OK when done.");
			}

			else if (manualMode == 2)
			{
				makeRectangle(68, 116, 142, 113);
				roiManager("Add");
				makeRectangle(290, 110, 156, 132);
				roiManager("Add");
				makeRectangle(154, 289, 215, 113);
				roiManager("Add");
				makeRectangle(89, 497, 167, 120);
				roiManager("Add");
				makeRectangle(328, 496, 140, 136);
				roiManager("Add");
								
			}

			//else if (manualMode == 3 && endsWith(WindowName, "F001S001_A_Preprocessed_processed.tif"))
			else if (manualMode == 3 && (endsWith(WindowName, "F01_A_Preprocessed_processed.tif") || endsWith(WindowName, "T2_A_Preprocessed_processed.tif") || endsWith(WindowName, "Venus_A_Preprocessed_processed.tif")))
			{
				waitForUser("Select cells and add the selections to the ROI manager (ctrl+T)."
				+ "\n\nPress OK when done.");

			}
			

			
			
			// save & process user input
			if ( roiManager("count")!=0 )
				roiManager("save",roiFile);
			selectWindow(WindowName);
			//print(otsu);
			File.append("\n\n" + "New Dataset",results_filename);
			File.append(dir,results_filename);
			File.append(getTitle(),results_filename);

/*			File.append("Anisotropy\tPerpendicular\tParallel",results_filename);
			setSlice(5);
			run("Median...", "radius=2 slice");
			setSlice(6);
			run("Median...", "radius=2 slice");
*/
			
			if ( roiManager("count")!=0 )
				{
				roiManager("save",roiFile);
				for(j=0; j<roiManager("count"); j++)
					{
						
						roiManager("Select", j);
						setSlice(5);
					
						List.setMeasurements;
						Anis = List.getValue ("Mean");
						

						roiManager("Select", j);
						setSlice(1);
					
						List.setMeasurements;
						Weight = List.getValue ("Mean");

						roiManager("Select", j);
						setSlice(3);
					
						List.setMeasurements;
						Para = List.getValue ("Mean");
						
					//waitForUser("Perp", Perp);
						roiManager("Select", j);
						setSlice(4);
					
						List.setMeasurements;
						Perp = List.getValue ("Mean");
						AreaROI = List.getValue ("Area");
						X_Centroid = List.getValue("X");
						Y_Centroid = List.getValue("Y");

						G_Factor = 1;
						r = (Para-G_Factor*Perp)/(Para+2*G_Factor*Perp);
						
						
						roiManager("Select", j);
						setSlice(6);
					
						List.setMeasurements;
						preWeight = List.getValue ("Mean");
						weightedAnisotropy = preWeight/(Weight);
						
					//waitForUser("Perp", Para);
					//waitForUser("UpperThreshold:",upperThreshold);
					//waitForUser("  Para ", Para);
					//waitForUser(" lower ",lowerThreshold);
					if ( upperThreshold > Para && Para > lowerThreshold)
					//waitForUser("Anisotropy",Anis);
					
					File.append(Anis + "\t" + Perp + "\t" + Para + "\t" + AreaROI + "\t" + X_Centroid + "\t" + Y_Centroid + "\t" + preWeight + "\t" + weightedAnisotropy + "\t" + r,results_filename);
					//else
					//File.append(" " + "\t" + "\t" +  Para + "\t" + "\t" + " " + "\t" + "\t" + "\t" + Anis + "\t" + r,results_filename);

					
					}

				
				}


			if (isOpen(WindowName))
				{
					selectWindow(WindowName);
					close();
				}



		}
	}
}










function selectIntensityROIs(path)
{

	upperThreshold = 40000; // was 40000
	//lowerThreshold = 500;

	lowerThreshold = 1000; // was 3000

	//run("Add Slice");
	WindowName = getTitle();
		getDimensions(width, height, channels, slices, frames);
	
	

			// prepare ROI manager
			if (isOpen("ROI Manager")==0)
				run("ROI Manager...");

			if (persistentROIs == 0)
			{
				roiManager("reset");
			}

			roiManager("Show All");
			pathROI = replace(path, "Preprocessed.tif", "");
			roiFile = pathROI+"--ROI.zip";
			//waitForUser("", roiFile);
			if (File.exists(roiFile))
				roiManager("open",roiFile);
			// wait for user
			if (manualMode == 1)
			{
				waitForUser("Select cells and add the selections to the ROI manager (ctrl+T)."
				+ "\n\nPress OK when done.");
			}
			// save & process user input
			if ( roiManager("count")!=0 )
				roiManager("save",roiFile);
			selectWindow(WindowName);
			//print(otsu);
			File.append("\n\n" + "New Dataset",results_filename);
			File.append(dir,results_filename);
			File.append(getTitle(),results_filename);


			if ( roiManager("count")!=0 )
				{
				roiManager("save",roiFile);
				for(j=0; j<roiManager("count"); j++)
					{
						
						roiManager("Select", j);
						setSlice(1);
					
						List.setMeasurements;
						Anis = List.getValue ("Mean");
						

						roiManager("Select", j);
						setSlice(1);
					
						List.setMeasurements;
						Weight = List.getValue ("Mean");

						roiManager("Select", j);
						setSlice(1);
					
						List.setMeasurements;
						Perp = List.getValue ("Mean");
						
					//waitForUser("Perp", Perp);
						roiManager("Select", j);
						setSlice(1);
					
						List.setMeasurements;
						Para = List.getValue ("Mean");
						AreaROI = List.getValue ("Area");
						X_Centroid = List.getValue("X");
						Y_Centroid = List.getValue("Y");

						G_Factor = 1;
						r = (Para-G_Factor*Perp)/(Para+2*G_Factor*Perp);
						
						
						roiManager("Select", j);
						setSlice(1);
					
						List.setMeasurements;
						preWeight = List.getValue ("Mean");
						weightedAnisotropy = preWeight/(Weight);
						
					//waitForUser("Perp", Para);
					if ( upperThreshold > Para && Para > lowerThreshold)
					//waitForUser("SECONDARY CODE, Anis:",Anis);
					File.append(Anis + "\t" + Perp + "\t" + Para + "\t" + AreaROI + "\t" + X_Centroid + "\t" + Y_Centroid + "\t" + preWeight + "\t" + weightedAnisotropy + "\t" + r,results_filename);
					//else
					//File.append(" " + "\t" + "\t" +  Para + "\t" + "\t" + " " + "\t" + "\t" + "\t" + Anis + "\t" + r,results_filename);

					
					}

				
				}


			if (isOpen(WindowName))
				{
					selectWindow(WindowName);
					close();
				}

		}
	}
}








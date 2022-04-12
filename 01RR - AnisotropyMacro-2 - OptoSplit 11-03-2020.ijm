var manualBackgroundCheck = 0; //0 for automatic, 1 for manual, 2 for no background, 3 for fluid backsub
	rect_para = newArray(20, 25, 595, 685);
 	rect_perp = newArray(650, 25, 590, 685);
 	
macro "Anisotropy_Calculation" {
	//run("Show LSMToolbox","ext")
dir = getDirectory("Choose a Directory ");
    list = getFileList(dir);
setBatchMode(true);


	// Calculate G-factor map before proceeding
	if (manualBackgroundCheck == 3)	BackgroundCalculator(dir);
	background_path = dir + "Calibration\\Background\\";
	GfactorCalculator(dir, background_path);
	gfactor_path = dir + "Calibration\\GFactorImages\\Gfactor.tif";
	
           
    for (i=0; i<list.length; i++) {
        path = dir+list[i];

        showProgress(i, list.length);
        if (endsWith(path,"/"))		// If path is a directory, recurse into the directory
            RecurseDirectory(path, gfactor_path, background_path);
        if (endsWith(path,"A_Preprocessed.tif")) 
		{
			open (path);
	        if (nImages>=1) {
	            AnisotropyMeasurement(dir, gfactor_path, background_path); }          
	    }
	}
	waitForUser("Done!", "Done!");
 	while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
}

function RecurseDirectory (dir2, gfactor_path, background_path)
{
	listR = getFileList(dir2);
       
    for (i=0; i<listR.length; i++) {
        path2 = dir2+listR[i];
        //waitForUser("Done!", path2);
        showProgress(i, listR.length);
        if (endsWith(path2,"/") && (listR[i] != "Calibration/"))		// If path is a directory, recurse into the directory
            RecurseDirectory(path2, gfactor_path, background_path);
        if (endsWith(path2,"A_Preprocessed.tif")) 
	{	
		open (path2);
        if (nImages>=1) {
            AnisotropyMeasurement(dir2, gfactor_path, background_path); }          
        }
    }
	//waitForUser("Done!", "Done!");
 	while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
}


function AnisotropyMeasurement (dir, gfactor_path, background_path)
{
	substackCheck = 0;
	FileName=getTitle();
	FileName=replace (FileName, ".tif", "");
	rename(FileName);
	getDimensions(width, height, channels, slices, frames);
	//waitForUser("slices: " + slices + " frames: " + frames);
	if (frames>1)
	{
		substackCheck = 1;
	}
	calculateAnisotropy(dir, gfactor_path, background_path);

//Close all open images
 	while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 

}



function calculateAnisotropy (dir, gfactor_path, background_path)
{
	if (manualBackgroundCheck == 1)
	{
		subBack();
	}
	else if (manualBackgroundCheck == 2)
	{
		nullVariable = 0;  //do Nothing
	}
	else if (manualBackgroundCheck == 3)
	{
		FileNameTemp=getTitle();
		run("Stack to Images");
		open(background_path + "back_exp_para.tif");
		imageCalculator("Subtract create", "Para","back_exp_para.tif");
		selectWindow("Result of Para");
		close("Para");
		rename("Para");
		selectWindow("back_exp_para.tif");
		close();

		open(background_path + "back_exp_perp.tif");
		imageCalculator("Subtract create", "Perp","back_exp_perp.tif");
		selectWindow("Result of Perp");
		close("Perp");
		rename("Perp");
		selectWindow("back_exp_perp.tif");
		close();
		run("Images to Stack");	
		rename(FileNameTemp);
	}
	else
	{
		run("Subtract Background...", "rolling=100 stack");
	}

	FileName=getTitle();
	getDimensions(width, height, channels, slices, frames);	

	// Add GFactor as the third slice (but will be removed after homoFRET macro)
	open(gfactor_path);
	run("Copy");	
	selectWindow(FileName);
	setSlice(2);
	run("Add Slice");	
	run("32-bit");
	setSlice(3);	
	run("Paste");

	
	rename(FileName + "_processed");
	//run("HomoFRET Ver6 ", "lens=1.40 index=1.518 g-factor=0.4375");
  //Zeiss Objective (63X)
	//run("HomoFRET Ver7 plus GFactor", "lens=1.43 index=1.518 g-factor=1.000"); // 60x Oil Objective
	run("HomoFRET Ver7 plus GFactor", "lens=0.6 index=1.00 g-factor=1.000");  //40x Air Objective
	//run("HomoFRET Ver7", "lens=0.6 index=1.00 g-factor=1.000");  //40x Air Objective

	saveAs ("tiff", dir + FileName + "_processed.tif");
	close(); 

}

function BackgroundCalculator(dir)
{
	base_folder = dir + "Calibration\\Background\\";
	path_back_gfactor = base_folder + "back_gfactor.ome.tif";
	path_back_exp = base_folder + "back_exp.ome.tif";	
	open(path_back_exp);
	
	source_folder = base_folder + "Original\\";
	File.makeDirectory(source_folder);

	FileName=getTitle();
	FileName=replace (FileName, ".ome.tif", "");

	waitForUser("Before first rect");
	makeRectangle(rect_perp[0], rect_perp[1], rect_perp[2], rect_perp[3]);
	waitForUser("after first rect");
	
	run("Duplicate...", " "); // perp
	rename(FileName + "_Perp");	
	saveAs ("tiff", source_folder + "Perp.tif");
	close(FileName + "_Perp.ome.tif");

	
	selectWindow(FileName + ".ome.tif"); // need to make more general
	waitForUser("before rect");
	makeRectangle(rect_para[0], rect_para[1], rect_para[2], rect_para[3]);
	waitForUser("after rect");
	run("Duplicate...", " "); // para
	rename(FileName + "_Para");
	saveAs ("tiff", source_folder + "Para.tif");
	close(FileName + "_Para.ome.tif");
	close(FileName + ".ome.tif");	
	
	output_folder = base_folder + "Ouput\\";
	transform_folder = dir + "Calibration\\AlignmentImages\\Transforms\\";
	File.makeDirectory(output_folder); 

	run("Transform Virtual Stack Slices", "source=[" + source_folder + "] output=[" + output_folder + "] transforms=[" + transform_folder + "] interpolate");		
	close("Para.tif");
	close("Perp.tif");
	selectWindow("Registered Original");
	run("Stack to Images");
	selectWindow("Para");
	run("Gaussian Blur...", "sigma=10");
	saveAs("Tiff", base_folder + "back_exp_para.tif");
	selectWindow("Perp");
	run("Gaussian Blur...", "sigma=10");
	saveAs("Tiff", base_folder + "back_exp_perp.tif");
	close();
	
	open(path_back_gfactor);
	
	source_folder = base_folder + "Original\\";
	File.makeDirectory(source_folder);

	FileName=getTitle();
	FileName=replace (FileName, ".ome.tif", "");
	
	makeRectangle(rect_perp[0], rect_perp[1], rect_perp[2], rect_perp[3]);
	run("Duplicate...", " "); // perp
	rename(FileName + "_Perp");	
	saveAs ("tiff", source_folder + "Perp.tif");
	close(FileName + "_Perp.ome.tif");

	
	selectWindow(FileName + ".ome.tif"); // need to make more general
	makeRectangle(rect_para[0], rect_para[1], rect_para[2], rect_para[3]);
	run("Duplicate...", " "); // para
	rename(FileName + "_Para");
	saveAs ("tiff", source_folder + "Para.tif");
	close(FileName + "_Para.ome.tif");
	close(FileName + ".ome.tif");	
	
	output_folder = base_folder + "Ouput\\";
	transform_folder = dir + "Calibration\\AlignmentImages\\Transforms\\";
	File.makeDirectory(output_folder); 

	run("Transform Virtual Stack Slices", "source=[" + source_folder + "] output=[" + output_folder + "] transforms=[" + transform_folder + "] interpolate");		
	close("Para.tif");
	close("Perp.tif");
	selectWindow("Registered Original");
	run("Stack to Images");
	selectWindow("Para");
	run("Gaussian Blur...", "sigma=2");
	saveAs("Tiff", base_folder + "back_gfactor_para.tif");
	close();
	selectWindow("Perp");
	run("Gaussian Blur...", "sigma=2");
	saveAs("Tiff", base_folder + "back_gfactor_perp.tif");	
	close();
	

	
}

function GfactorCalculator(dir, background_path)
{
	base_folder = dir + "Calibration\\GFactorImages\\";
	list1 = getFileList(base_folder);
		if(list1.length == 1){
		path2 = base_folder + list1[0];
	}
	else if (list1[0] == "Gfactor.tif" && list1[1] == "Original"){
		path2 = base_folder + list1[3]; 
	}
	else if (list1[0] == "Gfactor.tif"){
		path2 = base_folder + list1[1]; 
	}
	else {
		path2 = base_folder + list1[0];
	}
	open(path2);
	

	source_folder = base_folder + "Original\\";
	File.makeDirectory(source_folder);

	FileName=getTitle();
	FileName=replace (FileName, ".ome.tif", "");
	
	makeRectangle(rect_perp[0], rect_perp[1], rect_perp[2], rect_perp[3]);
	run("Duplicate...", " "); // perp
	rename(FileName + "_Perp");	
	saveAs ("tiff", source_folder + "Perp.tif");
	close(FileName + "_Perp.ome.tif");

	if (manualBackgroundCheck == 3)
	{
		open(background_path + "back_gfactor_perp.tif");
		imageCalculator("Subtract create", "Perp.tif","back_gfactor_perp.tif");
		selectWindow("Result of Perp.tif");
	    close("Perp.tif");
		saveAs ("tiff", source_folder + "Perp.tif");
	    selectWindow("back_gfactor_perp.tif");
		close();
	}
	

	selectWindow(FileName + ".ome.tif"); // need to make more general
	makeRectangle(rect_para[0], rect_para[1], rect_para[2], rect_para[3]);
	run("Duplicate...", " "); // para
	rename(FileName + "_Para");
	saveAs ("tiff", source_folder + "Para.tif");
	close(FileName + "_Para.ome.tif");
	close(FileName + ".ome.tif");	


	if (manualBackgroundCheck == 3)
	{
		open(background_path + "back_gfactor_para.tif");
		imageCalculator("Subtract create", "Para.tif","back_gfactor_para.tif");
		selectWindow("Result of Para.tif");
		close("Para.tif");
		saveAs ("tiff", source_folder + "Para.tif");
		selectWindow("back_gfactor_para.tif");
		close();
	}
	
	
	output_folder = base_folder + "Ouput\\";
	transform_folder = dir + "Calibration\\AlignmentImages\\Transforms\\";
	File.makeDirectory(output_folder); 

	run("Transform Virtual Stack Slices", "source=[" + source_folder + "] output=[" + output_folder + "] transforms=[" + transform_folder + "] interpolate");		
	close("Para.tif");
	close("Perp.tif");
	selectWindow("Registered Original");
	run("Stack to Images");


	
	imageCalculator("Divide create 32-bit", "Para","Perp");
	selectWindow("Result of Para");	
	run("Gaussian Blur...", "sigma=2");
	saveAs("tiff", base_folder + "GFactor");	
	close();
	close("Para");
	close("Perp");
}



function subBack()
{
	setBatchMode(false);
	setSlice(1);
	makeRectangle(18, 39, 112, 89);
	waitForUser("Select Background", "Select a sample of the background then click \"OK\".");
	
	//setBatchMode(true);
	setSlice(3);
	List.setMeasurements;
	PerpBG = List.getValue ("Mean");
	
	setSlice(2);
	List.setMeasurements;
	ParaBG = List.getValue ("Mean");
	
	run("Select None");
	
	setSlice(3);
	run("Subtract...", "value=" + PerpBG + " slice");
	
	setSlice(2);
	run("Subtract...", "value=" + ParaBG + " slice"); 
	setBatchMode(true);
}
   


function deconvolveImage()
{
	//40X Objective
	run("Diffraction PSF 3D", "index=1.00 numerical=0.60 wavelength=515 longitudinal=0 image=151 slice=90 width,=696 height,=520 depth,=5 normalization=[Sum of pixel values = 1] title=PSF");

	//63X Objective
	//run("Diffraction PSF 3D", "index=1.518 numerical=1.40 wavelength=400 longitudinal=0 image=22 slice=90 width,=1024 height,=1024 depth,=5 normalization=[Sum of pixel values = 1] title=PSF");
}
 


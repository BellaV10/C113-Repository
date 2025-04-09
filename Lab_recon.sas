	libname raw "C:\Users\VWaghmare\Git\C113\Data";run;

	data sample;
	length VISIT $16. VISITNUM $4.;
	format Sample_collection_date date11.;
	set raw.sample(where=(spstat = '1') rename=(visit = folder visitnum = visnum));
	label spstat = 'Was sample collected'
		  sptypg = 'Fluid aspirate'
		  sptyps = 'Sputum'
		  spmat4 = 'Lithum Heparin tubes'
		  spmat6 = 'Serum Separating tubes';
	Visit = strip(folder);
	Sample_collection_date = input(substr(SPDTTM, 1, 11), date11.);
	if visnum = 'D1' then VISITNUM = 'V2';
	else if visnum = 'D3' then VISITNUM = 'V3';
	if visnum = 'D8' then VISITNUM = 'V4';
	keep subjid spstat /*sptypg sptyps spmat4 spmat6 sptypw*/ visit visitnum  SPDTTM Sample_collection_date ;
	run;

	data visit;
	length VISITNUM $4.;
	set raw.visit(where=(dvstat = '1' and visit not in( 'Screening' 'Screen Fail')) rename=(visitnum = visnum));
	if visnum = 'D1' then VISITNUM = 'V2';
	else if visnum = 'D3' then VISITNUM = 'V3';
	if visnum = 'D8' then VISITNUM = 'V4';
	keep subjid dvstat visit visitnum visnum;
	run;

	proc sort data=sample;by subjid visit visitnum;run;
	proc sort data=visit;by subjid visit visitnum;run;

	data EDC;
	merge sample(in=a) visit(in=b);
	by subjid visit visitnum;
	if a and b;
	EDC_VISIT = visitnum;
	keep subjid Sample_collection_date visit visitnum EDC_VISIT;
	run;



/**get the lab data***/
	options validvarname=v7;

	proc import datafile="C:\Users\VWaghmare\Git\C113\LabRecon\lab_data_11Mar2025.csv"
	out=lab
	dbms=csv
	replace;
	run;

	data lab_(drop=date_drawn count Subject_ID study_id rename=(VISIT = LAB_VISIT));
	length SUBJID $11.;
	format Lab_Draw_date date11.;
	length VISITNUM $4.;
	set lab;
	VISITNUM = VISIT;
	Lab_Draw_date = date_drawn;
	SUBJID = strip(Subject_ID);
	run;

	proc sort data=EDC;by subjid visitnum;run;
	proc sort data=lab_;by subjid visitnum;run;

	data all;
	retain  subjid visit visitnum Sample_collection_date lab_draw_date material_Type Material_Modifiers; 
	length Flag $100.;
	merge edc(in=a) lab_(in=b);
	by subjid visitnum;
	if a and not b then flag = 'Not in Lab';
	else if b and not a then flag = 'Not in EDC';
	else if a and b and sample_collection_date ne lab_draw_date then flag = 'Dates Mismatch';
	else flag = ' ';
/*	if flag ne ' ';*/
	label subjid = 'Subject Identifier'
		  Visit = 'Visit'
		  Visitnum = 'Visitnum'
		  material_type = 'Material Type'
		  material_modifiers = 'Material Modifiers'
		  Sample_collection_date = 'Sample Collection Date';
	run;

	%let tdt = &sysdate.;



	proc export data=all outfile="C:\Users\VWaghmare\Git\C113\LabRecon\output\Lab_Reconciliation_&tdt..xlsx"
	dbms=xlsx
	label
	replace;
	run;


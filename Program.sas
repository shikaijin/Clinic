data _null_; 
      rc=dlgcdir(":\Idata-global\Clinic\Project");
      put rc=;
   run;
libname idata 'D:\Idata-global\Clinic\Project';
filename aids 'D:\Idata-global\Clinic\AIDS.csv';

proc import datafile=aids dbms=CSV out=idata.aids replace;
	getnames=yes;
RUN;

proc  format library=idata;
	value trt 0 = 'ZDV only'
		1 = 'ZDV + ddI' 
		2 = 'ZDV + Zal'
		3 = 'ddI only'
	;
run;

data idata.aids;
	set idata.aids;
	format trt trt.;
	
run;

ods graphics on;

proc lifetest data=idata.aids method=km;
	time time*cid(0);
	strata trt;
run;

ods graphics off;

proc format library=idata;
	value treat 0='ZDV only' 1='others';
run;

data idata.aids;
	set idata.aids;
	logtime = log(time);
run;

proc sort data = idata.aids;
	by strat treat;
run;

proc univariate data = idata.aids noprint NEXTROBS=3 NEXTRVAL=2 /*for some students*/
	;
	by strat treat;
	var logtime;
	output out = idata.stats mean = mean;
run;

data idata.aids;
	merge idata.aids idata.stats;
	by strat treat;
run;

data idata.aids;
	set idata.aids;

	if treat = 0 then
		plotstrat = strat - .1;
	else plotstrat = strat + .1;
run;

**** DEFINE GRAPHICS OPTIONS: SET DEVICE DESTINATION TO MS **** OFFICE CGM FILE, REPLACE ANY EXISTING CGM FILE, RESET ANY **** SYMBOL DEFINITIONS, AND DEFINE DEFAULT FONT TYPE.;
goptions device = gif gsfmode = replace reset = symbol colors = (black) chartype = 6;

**** SET SYMBOL DEFINITIONS. **** SET LINE THICKNESS WITH WIDTH AND BOX WIDTH WITH BWIDTH. **** ACTIVE DRUG IS DEFINED AS A SOLID BLACK LINE IN SYMBOL1 **** AND PLACEBO GETS A DASHED GRAY LINE IN SYMBOL2. **** VALUE = NONE SUPPRESSES THE ACTUAL DATA POINTS. **** BOXJT00 MEANS TO CREATE BOX PLOTS WITH BOXES (25TH AND 75TH **** PERCENTILES - THE INTERQUARTILE RANGE) JOINED (J) AT THE **** MEDIANS WITH WHISKERS EXTENDING TO THE MINIMUM AND MAXIMUM **** VALUES (00) AND TOPPED/BOTTOMED (T) WITH A DASH. **** MODE = INCLUDE OPTION ENSURES THAT VALUES THAT MIGHT FALL **** OUTSIDE OF THE EXPLICITLY STATED AXIS ORDER WOULD BE **** INCLUDED IN THE BOX AND WHISKER DEFINITION.;
symbol1 width = 28 bwidth = 3 color = black line = 1 value = none interpol = BOXJT00 mode = include;
symbol2 width = 28 bwidth = 3 color = gray line = 2 value = none interpol = BOXJT00 mode = include;

**** ADD TWO NEW SYMBOL STATEMENTS TO PLOT THE MEAN VALUES.;
symbol3 color = black value = dot;
symbol4 color = gray value = dot;

**** DEFINE THE LEGEND FOR THE BOTTOM CENTER OF THE PAGE.;
legend1 frame value = (height = 1.5) label = (height = 1.5 justify = right 'Treatment:' ) position = (bottom center outside);

**** DEFINE VERTICAL AXIS OPTIONS.;
axis1 label = (h = 1.5 r = 0 a = 90 "Seizures per Hour") value = (h = 1.5 ) minor = (n = 3);

**** DEFINE HORIZONTAL AXIS OPTIONS. **** THE HORIZONTAL AXIS MUST GO FROM 0 TO 4 HERE BECAUSE OF THE **** OFFSET APPLIED TO VISIT. NOTICE THAT THE VALUE FOR VISIT **** OF 0 AND 4 IS SET TO BLANK.;
axis2 label = (h = 1.5 "strat") value = (h = 1.5 " " "Antiretroviral Naive" "> 1 but <= 52 weeks of prior antiretroviral therapy" "> 52 weeks" " ") order = (0 to 4 by 1) minor = none;

**** ADD NEW AXIS FOR PLOT2 STATEMENT BELOW. WHITE IS USED TO **** MAKE THE AXIS INVISIBLE ON THE PLOT.;
axis3 color = white label = (color = white h = .3 " " ) value = (color = white h = .3) order = (1 to 4 by 1);

**** CREATE BOX PLOT. VISIT IS ON THE X AXIS, SEIZURES ARE ON **** THE Y AXIS, AND THE VALUES ARE PLOTTED BY TREATMENT. THE **** PLOT2 STATEMENT IS RESPONSIBLE FOR PLACING THE MEAN VALUES **** ON THE PLOT.;
options fmtsearch=(idata.formats);

proc gplot data = idata.aids;
	plot logtime * plotstrat = treat /noframe;

	/*	plot2 mean * plotstrat = treat /nolegend;*/
	format treat treat.;
	title1 h = 2 font = "TimesRoman" "Figure 6.5";
	title2 h = 2 font = "TimesRoman" "Box plot of Seizures per Hour By Treatment";

	/*	footnote1 h = 1.5 j = l font = "TimesRoman" "Box extends to 25th and 75th percentile. Whiskers" " extend to";*/
	/*	footnote2 h = 1.5 j = l font = "TimesRoman" "minimum and maximum values. Mean values are" " represented by";*/
	/*	footnote3 h = 1.5 j = l font = "TimesRoman" "a dot while medians are connected by the line.";*/
	/*	footnote4 h = .5 " ";*/
run;

quit;

proc sgplot data=idata.aids noautolegend;
	title 'Log time by weight';
	scatter y=logtime x=wtkg / group=cid 
		markerattrs=(symbol=circlefilled 
		size=5px) groupdisplay=overlay;
	xaxis offsetmin=0.05 offsetmax=0.05 label='Class weight';
	yaxis offsetmin=0.05 offsetmax=0.05 label='Class logtime';
run;

proc sgplot data=idata.aids;
	title 'Log time by treatment and censoring indicator';
	vbox logtime / category=trt group=cid;
	xaxis label="Treatment";
	yaxis label="Log Time";
run;

proc sgplot data=idata.aids;
	title 'Log time by antiretroviral history stratification and censoring indicator';
	vbox logtime / category=strat group=cid;
	xaxis label="Antiretroviral history stratification";
	yaxis label="Log Time";
run;

proc sgplot data=idata.aids noautolegend;
	title 'Weight by Height';
	histogram wtkg / fill 
		FILLTYPE=/*SOLID |*/
	GRADIENT /*binstart= binwidth=50 */
	fillattrs=(color="lightgray" );
	density wtkg/ type=normal/*(mu=80 sigma=1) /*Kernel*/
	lineattrs=(color="Blue" pattern=4 thickness=2);
	;
	KEYLEGEND 'Para' / Title='Para' titleattrs=(Size=8 Style=Italic Weight=Bold) location=outside;
	;
run;

/*N¡ÁP association*/
proc freq data=idata.aids;
	table cid*strat/chisq;
		output out=idata.pvalue mhchi;
run;

**** GET ADJUSTED ODDS RATIOS FROM PROC LOGISTIC AND PLACE **** THEM IN DATA SET WALD.;
ods output CloddsWald = idata.odds;

proc logistic data = idata.aids descending;
	class trt;
	model cid = trt / clodds = wald;
run;

ods output close;

***** RECATEGORIZE EFFECT FOR Y AXIS FORMATING PURPOSES.;
data idata.odds;
	set idata.odds;
	select(effect);
		when("trt ZDV + Zal vs ddI only") y = 1;
		when("trt ZDV + ddI vs ddI only" ) y = 2;
		when("trt ZDV only  vs ddI only ") y = 3;
		otherwise;
	end;
run;

**** FORMAT FOR EFFECT;
proc format;
	value effect 1 = "trt ZDV + Zal vs ddI only"
	2 = "trt ZDV + ddI vs ddI only"
	3 = 'trt ZDV only vs ddI only'
	;
run;

proc format;
	value gender 1 = "Male" 2 = "Female";
	value race 1 = "White" 2 = "Black" 3 = "Other*";
run;

**** ANNOTATE DATA SET TO DRAW THE HORIZONTAL LINE, ESTIMATE, AND **** WHISKER.;
data idata.annotate;
	set idata.odds;
	length function $ 8 position xsys ysys $ 4;
	i = 0.1;

	**** whisker width.;
	basey = y;

	**** hang onto row position.;
	**** set coordinate system and positioning.;
	position = '5';
	xsys = '2';
	ysys = '2';
	line = 1;

	**** plot estimates on right part of the graph.;
	if oddsratioest ne . then
		do;
			*** place a DOT at OR estimate.;
			function = 'SYMBOL';
			text = 'DOT';
			size = 1.5;
			x = oddsratioest;
			output;

			*** move to LCL.;
			function = 'MOVE';
			x = lowercl;
			output;

			*** draw line to UCL.;
			function = 'DRAW';
			x = uppercl;
			output;

			*** move to LCL bottom of tickmark.;
			function = 'MOVE';
			x = lowercl;
			y = basey - i;
			output;

			*** draw line to top of tickmark.;
			function = 'DRAW';
			x = lowercl;
			y = basey + i;
			output;

			*** move to UCL bottom of tickmark.;
			function = 'MOVE';
			x = uppercl;
			y = basey - i;

			*** draw line to top of tickmark.;
			output;
			function = 'DRAW';
			x = uppercl;
			y = basey + i;
			output;
		end;
run;

**** DEFINE GRAPHICS OPTIONS: SET DEVICE DESTINATION TO MS **** OFFICE CGM FILE, REPLACE ANY EXISTING CGM FILE, RESET ANY **** SYMBOL DEFINITIONS, AND DEFINE DEFAULT FONT TYPE.;
goptions device = gif gsfmode = replace reset = all colors = (black) chartype = 6;

**** DEFINE SYMBOL TO MAKE THE GRAPH SPACE THE PROPER SIZE BUT **** NOT TO ACTUALLY PLOT ANYTHING.;
symbol color = black interpol = none value = none repeat = 2;
axis1 label = (h = 1.5 "Odds Ratio and 95% Confidence Interval") value = (h = 1.2) logbase = 2 logstyle = expand order = (0.125,0.25,0.5,1,2,4,8,16) offset = (2,2);

**** DEFINE VERTICAL AXIS OPTIONS.;
axis2 label = none value = (h = 1.2) order = (1 to 12 by 1) minor = none offset = (2,2);

**** CREATE THE ODDS RATIO PLOT. THIS IS DONE PRIMARILY THROUGH **** THE INFORMATION IN THE ANNOTATION DATA SET. PUT A HORIZONTAL **** REFERENCE LINE AT 1 WHICH IS THE LINE OF SIGNIFICANCE.;
proc gplot data = idata.odds;
	plot y * lowercl y * uppercl / anno = idata.annotate overlay 
	;
	format y effect.;
	title1 h = 2 font = "TimesRoman" "Figure 6.6";
	title2 h = 2.5 font = "TimesRoman" "Odds Ratios for Clinical Success";
run;

quit;


proc format library=idata; 
value gender 0='F' 1='M'; 
value race 0='White' 1='non-white'; 
run;
**** DUPLICATE THE INCOMING DATA SET FOR OVERALL COLUMN **** CALCULATIONS SO NOW TRT HAS VALUES 0 = PLACEBO, 1 = ACTIVE, **** AND 2 = OVERALL.;
data idata.aids2;
	set idata.aids;
	output;
	trt = 4;
	output;
run;

**** AGE STATISTICS PROGRAMMING ********************************;
**** GET P VALUE FROM NON PARAMETRIC COMPARISON OF AGE MEANS.;
proc npar1way data = idata.aids2 wilcoxon noprint;
	where trt in (0, 1, 2, 3);
	class trt;
	var age;
	output out = idata.pvalue wilcoxon;
run;

proc sort data = idata.aids2;
	by trt;
run;

***** GET AGE DESCRIPTIVE STATISTICS N, MEAN, STD, MIN, AND MAX.;
proc univariate data = idata.aids2 noprint;
	by trt;
	var age;
	output out = idata.age n = _n mean = _mean std = _std min = _min max = _max;
run;

**** FORMAT AGE DESCRIPTIVE STATISTICS FOR THE TABLE.;
data idata.age;
	set idata.age;
	format n mean std min max $14.;
	drop _n _mean _std _min _max;
	n = put(_n,4.);
	mean = put(_mean,7.1);
	std = put(_std,8.2);
	min = put(_min,7.1);
	max = put(_max,7.1);
run;

**** TRANSPOSE AGE DESCRIPTIVE STATISTICS INTO COLUMNS.;
proc transpose data = idata.age out = idata.age prefix = col;
	var n mean std min max;
	id trt;
run;

**** CREATE AGE FIRST ROW FOR THE TABLE.;
data idata.label;
	set idata.pvalue(keep = P_KW rename = (P_KW = pvalue));
	length label $ 85;
	label = "Age (years)";
run;

**** APPEND AGE DESCRIPTIVE STATISTICS TO AGE P VALUE ROW AND **** CREATE AGE DESCRIPTIVE STATISTIC ROW LABELS.;
data idata.age;
	length label $ 85 col0 col1 col2 col3 col4 $ 25;
	set idata.label idata.age;
	keep label col0 col1 col2 col3 col4 pvalue;

	if _n_ > 1 then
		select;
	when(_NAME_ = 'n') label = " N";
	when(_NAME_ = 'mean') label = " Mean";
	when(_NAME_ = 'std') label = " Standard Deviation";
	when(_NAME_ = 'min') label = " Minimum";
	when(_NAME_ = 'max') label = " Maximum";
	otherwise;
end;
run;

**** END OF AGE STATISTICS PROGRAMMING *************************;

proc npar1way data = idata.aids2 wilcoxon noprint;
	where trt in (0, 1, 2, 3);
	class trt;
	var wtkg;
	output out = idata.pvalue wilcoxon;
run;

proc sort data = idata.aids2;
	by trt;
run;

proc univariate data = idata.aids2 noprint;
	by trt;
	var wtkg;
	output out = idata.weight n = _n mean = _mean std = _std min = _min max = _max;
run;

**** FORMAT AGE DESCRIPTIVE STATISTICS FOR THE TABLE.;
data idata.weight;
	set idata.weight;
	format n mean std min max $14.;
	drop _n _mean _std _min _max;
	n = put(_n,4.);
	mean = put(_mean,7.1);
	std = put(_std,8.2);
	min = put(_min,7.1);
	max = put(_max,7.1);
run;

**** TRANSPOSE AGE DESCRIPTIVE STATISTICS INTO COLUMNS.;
proc transpose data = idata.weight out = idata.weight prefix = col;
	var n mean std min max;
	id trt;
run;

**** CREATE AGE FIRST ROW FOR THE TABLE.;
data idata.label;
	set idata.pvalue(keep = P_KW rename = (P_KW = pvalue));
	length label $ 85;
	label = "Weright (kg)";
run;

**** APPEND AGE DESCRIPTIVE STATISTICS TO AGE P VALUE ROW AND **** CREATE AGE DESCRIPTIVE STATISTIC ROW LABELS.;
data idata.weight;
	length label $ 85 col0 col1 col2 col3 col4 $ 25;
	set idata.label idata.weight;
	keep label col0 col1 col2 col3 col4 pvalue;

	if _n_ > 1 then
		select;
	when(_NAME_ = 'n') label = " N";
	when(_NAME_ = 'mean') label = " Mean";
	when(_NAME_ = 'std') label = " Standard Deviation";
	when(_NAME_ = 'min') label = " Minimum";
	when(_NAME_ = 'max') label = " Maximum";
	otherwise;
end;
run;

**** END OF AGE STATISTICS PROGRAMMING *************************;
**** GENDER STATISTICS PROGRAMMING *****************************;
**** GET SIMPLE FREQUENCY COUNTS FOR GENDER.;
proc freq data = idata.aids2 noprint;
	where trt ne .;
	tables trt * gender / missing outpct out = idata.gender;
run;

**** FORMAT GENDER N(%) AS DESIRED.;
data idata.gender;
	set idata.gender;
	where gender ne .;
	length value $25;
	value = put(count,4.) || ' (' || put(pct_row,5.1)||'%)';
run;

proc sort data = idata.gender;
	by gender;
run;

**** TRANSPOSE THE GENDER SUMMARY STATISTICS.;
proc transpose data = idata.gender out = idata.gender(drop = _name_) prefix = col;
	by gender;
	var value;
	id trt;
run;

**** PERFORM CHI-SQUARE ON GENDER COMPARING ACTIVE VS PLACEBO.;
proc freq data = idata.aids2 noprint;
	where gender ne . and trt not in (.,2);

	table gender * trt / chisq;
		output out = idata.pvalue pchi;
run;

**** CREATE GENDER FIRST ROW FOR THE TABLE.;
data idata.label;
	set idata.pvalue(keep = p_pchi rename = (p_pchi = pvalue));
	length label $ 85;
	label = "Gender";
run;

options fmtsearch=(idata.formats);
**** APPEND GENDER DESCRIPTIVE STATISTICS TO GENDER P VALUE ROW **** AND CREATE GENDER DESCRIPTIVE STATISTIC ROW LABELS.;
data idata.gender;
	length label $ 85 col0 col1 col2 col3 col4 $ 25;
	set idata.label idata.gender;
	keep label col0 col1 col2 col3 col4 pvalue;

	if _n_ > 1 then
		label= " " || put(gender, gender.);
run;

**** END OF GENDER STATISTICS PROGRAMMING **********************;
**** RACE STATISTICS PROGRAMMING *******************************;
**** GET SIMPLE FREQUENCY COUNTS FOR RACE;
proc freq data = idata.aids2 noprint;
	where trt ne .;
	tables trt * race / missing outpct out = idata.race;
run;

**** FORMAT RACE N(%) AS DESIRED;
data idata.race;
	set idata.race;
	where race ne .;
	length value $25;
	value = put(count,4.) || ' (' || put(pct_row,5.1)||'%)';
run;

proc sort data = idata.race;
	by race;
run;

**** TRANSPOSE THE RACE SUMMARY STATISTICS;
proc transpose data = idata.race out = idata.race(drop = _name_) prefix=col;
	by race;
	var value;
	id trt;
run;

**** PERFORM FISHER'S EXACT ON RACE COMPARING ACTIVE VS PLACEBO.;
proc freq data = idata.aids2 noprint;
	where race ne . and trt not in (.,2);

	table race * trt / exact;
		output out =idata.pvalue exact;
run;

**** CREATE RACE FIRST ROW FOR THE TABLE.;
data idata.label;
	set idata.pvalue(keep = xp2_fish rename = (xp2_fish = pvalue));
	length label $ 85;
	label = "Race";
run;

**** APPEND RACE DESCRIPTIVE STATISTICS TO RACE P VALUE ROW AND **** CREATE RACE DESCRIPTIVE STATISTIC ROW LABELS.;
data idata.race;
	length label $ 85 col0 col1 col2 col3 col4 $ 25;
	set idata.label idata.race;
	keep label col0 col1 col2 col3 col4 pvalue;

	if _n_ > 1 then
		label= " " || put(race,race.);
run;

**** END OF RACE STATISTICS PROGRAMMING ************************;
**** CONCATENATE AGE, GENDER, AND RACE STATISTICS AND CREATE **** GROUPING GROUP VARIABLE FOR LINE SKIPPING IN PROC REPORT.;
data idata.forreport;
	set idata.age(in = in1) idata.weight(in = in2) idata.gender(in = in3) idata.race(in = in4);
	group = sum(in1 * 1, in2 * 2, in3 * 3, in4 * 4);
run;

**** DEFINE THREE MACRO VARIABLES &N0, &N1, AND &NT THAT ARE USED **** IN THE COLUMN HEADERS FOR "PLACEBO," "ACTIVE" AND "OVERALL" **** THERAPY GROUPS.;
data _null_;
	set idata.aids2 end = eof;
	WHERE TRT IN (0,1,2,3);

	**** CREATE COUNTER FOR N0 = PLACEBO, N1 = ACTIVE.;
	if trt = 0 then
		n0 + 1;
	else if trt = 1 then
		n1 + 1;
	else if trt  = 2 then
	    n2 + 1;
	else if trt  = 3 then
	    n3 + 1;

	**** CREATE OVERALL COUNTER NT.;
	nt + 1;

	**** CREATE MACRO VARIABLES &N0, &N1, AND &NT.;
	if eof then
		do;
			call symput("n0",compress('(N='||put(n0,4.) || ')'));
			call symput("n1",compress('(N='||put(n1,4.) || ')'));
			call symput("n2",compress('(N='||put(n2,4.) || ')'));
			call symput("n3",compress('(N='||put(n3,4.) || ')'));
			call symput("nt",compress('(N='||put(nt,4.) || ')'));
		end;
run;

**** USE PROC REPORT TO WRITE THE TABLE TO FILE.;
options nonumber nodate ls=84 missing = " " formchar="|----|+|---+=|-/\<>*";
proc report data = idata.forreport out=idata.forreport nowindows spacing=1 headline headskip split = "|";
	columns ("--" group label col1 col0 col2 col3 col4 pvalue);
	define group /order order = internal noprint;
	define label /display width=23 " ";
	define col0 /display center width = 14 "ZDV only|&n0";
	define col1 /display center width = 14 "ZDV + ddI|&n1";
	define col2 /display center width = 14 "ZDV + Zal|&n2";
    define col3 /display center width = 14 "ddI only|&n3";
	define col4 /display center width = 14 "Overall|&nt";
	define pvalue /display center width = 14 " |P-value**" f = pvalue6.4;
	break after group / skip;
	title1 "Company " " ";
	title2 "Protocol Name " " ";
	title3 "Table ";
	title4 "Demographics";
	footnote1 "------------------------------------------" "-----------------------------------------";
	footnote2 "** P-values: Age = Wilcoxon rank-sum, Weight = Wilcoxon rank-sum, Gender " "= Pearson's chi-square, ";
	footnote3 " Race = Fisher's exact test. " " ";
	
run;

/*set working environment*/

data _null_; 
      rc=dlgcdir("D:\Idata-global\Clinic\Project");
      put rc=;
   run;
/*create idata library*/
libname idata 'D:\Idata-global\Clinic\Project';

/*create aids file*/
filename aids 'D:\Idata-global\Clinic\AIDS.csv';

/*load aids dataset*/
proc import datafile=aids dbms=CSV out=idata.aids replace;
	getnames=yes;
RUN;

/*create log time, cd40 change and cd80 change, and drop treat*/
data idata.aids; 
set idata.aids (drop=treat);
logtime= log(time);
cd40change= cd420-cd40;
cd80change= cd820-cd80;
run;


proc format library= idata;
value cid 1 = "failure"
          0 = "censoring";

value trt 0= "ZDV only"
		  1= "ZDV+ddl"
		  2= "ZDV + Zal"
		  3= "ddI only";

value yon 0= "no"
           1= "yes";
		  
value race 0="White"
           1="non-white";

value gender 0="F"
             1="M";
			 
value str   0="naive"
             1="experienced";

value strat  1='Antiretroviral Naive'
             2='> 1 but <= 52 weeks of prior antiretroviral therapy'
             3='> 52 weeks';

value symptom 0='asymp'
              1='symp';

value treat  0='ZDV only'
             1='other';
run;

data idata.aids_cat; 
set idata.aids;
options fmtsearch= (idata.formats);
format trt trt.
       cid cid.
	   hemo homo drugs oprior z30 zprior offtrt yon.
	   race race.
	   gender gender.
	   str2 str.
	   strat strat.
	   symptom symptom.
	   treat treat.
;
run;

%let categorical_ovariates= trt hemo homo drugs oprior z30 zprior race gender str2 strat symptom offtrt;
/*create km estimated plots*/
ods graphics on;

%macro kmplots;
%DO I = 1 %TO 13;
%let cat_var= %scan(&categorical_ovariates=,&i);
ods graphics on;
proc lifetest data=idata.aids_cat method=km;
	time time*cid(0);
	strata &cat_var;
run;
ods graphics off;
%end;
%MEND kmplots;
%kmplots;




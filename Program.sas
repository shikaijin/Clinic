libname idata 'D:\Idata-global\Clinic\Project';

filename aids 'D:\Idata-global\Clinic\AIDS.csv';

proc import datafile=aids dbms=CSV out=idata.aids;
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
options fmtsearch=(idata.formats);
format trt trt.;
run;



ods graphics on;

proc lifetest data=idata.aids method=km;
	time time*cid(0);
	strata trt;
run;

ods graphics off;
data demog;
	input subject $ race $ treatment $ age GENDER $ ae bp_base bp bp_change ae_day @@;
	datalines;
101 white active 
25 F 0 90 95 5 100 102 chinese placebo 60 M 1 85 89 4 53 103 white active 45 F 0 83 86 3 121 104 black placebo 56 M 0 92 92 0 79 105 white placebo 33 F 1 87 97 10 89 106 chinese active 34 F 0 81 79 -2 90 107 chinese active 49 F 1 78 88 10 73 108 black active 28 F 0 89 92 3 46 109 black placebo 44 M 0 86 87 1 67 110 chinese active 61 M 1 93 100 7 73 111 chinese old_drug 45 F 0 90 93 3 68
112 black old_drug 33 M 1 88 93 5 88 113 white old_drug 62 F 0 76 80 4 131 114 chinese old_drug 37 M 0 89 89 0 105 115 black old_drug 74 M 0 83 82 -1 111 116 chinese old_drug 66 M 1 79 83 4 103 117 white old_drug 55 M 0 82 85 3 150 118 white active 63 F 1 91 95 4 95 119 black active 63 F 0 92 94 2 83 120 chinese old_drug 31 F 0 85 88 3 74 
;
run;

ods graphics on;

proc lifetest data=demog plots=(survival logsurv);
	time ae_day*ae(0);
	strata Treatment;
run;

ods graphics off;
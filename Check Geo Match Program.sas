/*Simple program to test and see if the patients match the same FIPS county as the agency performing the services
I am doing this to check as to what will be the best way for me to treat geographic areas in my research project
due to being a simple test program simple variable names were used and not too many notes were taken*/

libname cmsa '****************************';

%include '****************************';

data oasis_a;
	set cmsa.combined_oasis;
run;

data mbsf_file;
	set cmsa.mbsf_abcd_summary;
	if STATE_CODE in ('54', '55','56', '57','58','59','60','61','62','63','97','98','99') then delete;
run;
/*merging all data to get full sample size*/
%sort(mbsf_file, bene_id)
%sort(oasis_a, bene_id)

data test (compress = yes);
	merge oasis_a (in = a) mbsf_file (in = b);
	by bene_id;
run;

data test_2;
set test;
	keep bene_id fips fips_state STATE_CNTY_FIPS_CD_01 M0010_MEDICARE_ID;

		fips = substr(STATE_CNTY_FIPS_CD_01, 1, 2);
	if fips = 99 then delete;
	fips_state = fipstate(fips);
	rename M0010_MEDICARE_ID = provider_id;
run;
/*need to import my fips data for the agency providers*/
proc import datafile = "****************************"
dbms = xlsx out= provder replace;
run;
/*ZIP to FIPS crosswalk. I wonder if maybe AHRF is a better way to match this data?*/
proc import datafile = "****************************"
dbms = xlsx out = cross replace;
run;
data provider;
	set provder;

	zip = put(zipper, z5.);
	provider_id = put(prov_convert, z6.);
run;


%sort(provider, zip)
%sort(cross, zip)

data provider_2;
	merge provider (in = a) cross (in = b);
	by zip;

run;

%sort(test_2, provider_id)
%sort(provider_2, provider_id)

data test_3;
	merge test_2 (in = a) provider_2 (in = b);
	by provider_id;
	if a;
	if b;
	run;

data test4;
set test_3;
	if STATE_CNTY_FIPS_CD_01 = County then match = 1;
		else match = 0;
	run;
/*drop duplicate patient observations because i have checked and patients always reside in same area*/
proc sort nodupkey;
by bene_id;
run;


proc freq;
table match;
run;



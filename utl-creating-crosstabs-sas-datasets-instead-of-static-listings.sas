%let pgm=utl-creating-crosstabs-sas-datasets-instead-of-static-listings;

Creating crosstab sas datasets instead of static listings

All the solutiions require only one proc to produce crosstab datasets not
static listings. In some cases a additiional 'ods output' macro is needed.
SAS does not provide output that matches the listing output for most of these.

For some reason only 'proc corresp' is ods output compliant.

  Solutions
            1. ODS output from proc corresp
            2. proc report across and column rename
            3. macro utl_odstab wrapper on proc tabulate
            4. macro utl_odsrpt wrapper on proc report
            5. macro utl_odsfrq wrapper on proc freq
            6. single datastepq
               Laura Daniel
               https://stackoverflow.com/users/11504401/laura-daniel

Because this is such a simple crosstab, it is easy to add a final additional proc transpose
usig the output datasets from proc freq and tabulate, hower not so easy for other more complex
crosstables. Sme of these solutions are more flexible for nested crosstabs, especially 'proc corresp;.

Latest macros are on end. I do update macros, use included code in old repos.

github
https://tinyurl.com/2fejt4e6
https://github.com/rogerjdeangelis/utl-creating-crosstabs-sas-datasets-instead-of-static-listings

relataed repos
https://tinyurl.com/56srnwy6
https://github.com/rogerjdeangelis?tab=repositories&q=crosstab&type=&language=&sort=

Stackoverflow (related)
https://tinyurl.com/yc2sfnwm
https://stackoverflow.com/questions/71450536/sas-proc-freq-of-multiple-tables-into-a-single-one

/*                   _
(_)_ __  _ __  _   _| |_
| | `_ \| `_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
*/

data have;
input City $ grade1 $ grade2 $ grade3 $;
cards4;
CA B A C
CO A B B
NY A A A
;;;;
run;quit;

*normalize;
proc transpose data=have out=hav1st(drop=_name_ rename=col1=grade);
by City;
var grade1-grade3;
run;

/*****************************************************************/
/*                                                               */
/*  Up to 40 obs WORK.HAV1ST total obs=9 15MAR2022:06:59:46      */
/*                                                               */
/*  Obs    CITY    GRADE                                         */
/*                                                               */
/*   1      CA       B                                           */
/*   2      CA       A                                           */
/*   3      CA       C                                           */
/*   4      CO       A                                           */
/*   5      CO       B                                           */
/*   6      CO       B                                           */
/*   7      NY       A                                           */
/*   8      NY       A                                           */
/*   9      NY       A                                           */
/*                                                               */
/*****************************************************************/

/*
 _
/ |     ___ ___  _ __ _ __ ___  ___ _ __
| |    / __/ _ \| `__| `__/ _ \/ __| `_ \
| |_  | (_| (_) | |  | | |  __/\__ \ |_) |
|_(_)  \___\___/|_|  |_|  \___||___/ .__/
                                   |_|
*/
* using corrresp;
ods exclude all;
ods output observed=want_cor;
proc corresp data=hav1st observed;
  table city, grade;
run;quit;
ods select all;

/****************************************************************/
/*                                                              */
/* Up to 40 obs WORK.WANT_COR total obs=4 15MAR2022:09:37:09    */
/*                                                              */
/* Obs    LABEL    A    B    C    SUM                           */
/*                                                              */
/*  1      CA      1    1    1     3                            */
/*  2      CO      1    2    0     3                            */
/*  3      NY      3    0    0     3                            */
/*  4      Sum     5    3    1     9                            */
/*                                                              */
/*                                                              */
/****************************************************************/

/*___                                                       _
|___ \     _ __  _ __ ___   ___   _ __ ___ _ __   ___  _ __| |_    __ _  ___ _ __ ___  ___ ___
  __) |   | `_ \| `__/ _ \ / __| | `__/ _ \ `_ \ / _ \| `__| __|  / _` |/ __| `__/ _ \/ __/ __|
 / __/ _  | |_) | | | (_) | (__  | | |  __/ |_) | (_) | |  | |_  | (_| | (__| | | (_) \__ \__ \
|_____(_) | .__/|_|  \___/ \___| |_|  \___| .__/ \___/|_|   \__|  \__,_|\___|_|  \___/|___/___/
          |_|                             |_|
*/
* using proc report;
options missing='0'; /* note this yeildsa numeric 0 in our output */
proc report data=hav1st out=want_rpt(
     rename= (%utl_renamel(old=_C2_ _c3_ _c4_, new=A B C)))
     nowd;
col city grade;
define city /group;
define grade /sum across;
run;quit;

/*************************************************************/
/*                                                           */
/* Up to 40 obs from WANT_RPT total obs=3 15MAR2022:09:40:55 */
/*                                                           */
/* Obs    CITY    A    B    C    _BREAK_                     */
/*                                                           */
/*  1      CA     1    1    1                                */
/*  2      CO     1    2    0                                */
/*  3      NY     3    0    0                                */
/*                                                           */
/*************************************************************/

/*____          _   _              _     _        _       _        _           _       _
|___ /    _   _| |_| |    ___   __| |___| |_ __ _| |__   | |_ __ _| |__  _   _| | __ _| |_ ___
  |_ \   | | | | __| |   / _ \ / _` / __| __/ _` | `_ \  | __/ _` | `_ \| | | | |/ _` | __/ _ \
 ___) |  | |_| | |_| |  | (_) | (_| \__ \ || (_| | |_) | | || (_| | |_) | |_| | | (_| | ||  __/
|____(_)  \__,_|\__|_|___\___/ \__,_|___/\__\__,_|_.__/   \__\__,_|_.__/ \__,_|_|\__,_|\__\___|

*/
* using proc tabulate;

%utl_odstab(setup);
proc tabulate data=hav1st;
title "|CITY|A|B|C|";
class city grade;
table city, grade(n);
run;quit;
%utl_odstab(want_tab,datarow=5); /* you may have to try diff datarow */
options FORMCHAR='|----|+|---+=|-/\<>*'; * use this;

/*************************************************************/
/*                                                           */
/* Up to 40 obs from WANT_TAB total obs=3 15MAR2022:09:41:38 */
/*                                                           */
/* Obs    CITY    A    B    C                                */
/*                                                           */
/*  1      CA     1    1    1                                */
/*  2      CO     1    2    0                                */
/*  3      NY     3    0    0                                */
/*                                                           */
/*                                                           */
/*************************************************************/

/*  _            _   _              _                _                                _
| || |     _   _| |_| |    ___   __| |___ _ __ _ __ | |_    _ __ ___ _ __   ___  _ __| |_
| || |_   | | | | __| |   / _ \ / _` / __| `__| `_ \| __|  | `__/ _ \ `_ \ / _ \| `__| __|
|__   _|  | |_| | |_| |  | (_) | (_| \__ \ |  | |_) | |_   | | |  __/ |_) | (_) | |  | |_
   |_|(_)  \__,_|\__|_|___\___/ \__,_|___/_|  | .__/ \__|  |_|  \___| .__/ \___/|_|   \__|
                     |_____|                  |_|                   |_|
*/

%utl_odsrpt(setup);
options FORMCHAR='|';
proc report data=hav1st nowd missing formchar="|" noheader box;
title "|CITY|A|B|C|";
col city grade;
define city /group;
define grade /sum across;
run;quit;
%utl_odsrpt(want_odsrpt);
options FORMCHAR='|----|+|---+=|-/\<>*'; * use this;

/****************************************************************/
/*                                                              */
/* Up to 40 obs from WANT_ODSRPT total obs=3 15MAR2022:10:11:06 */
/*                                                              */
/* Obs    CITY    A    B    C                                   */
/*                                                              */
/*  1      CA     1    1    1                                   */
/*  2      CO     1    2    0                                   */
/*  3      NY     3    0    0                                   */
/*                                                              */
/****************************************************************/

/*___           _   _              _      __                                     __
| ___|    _   _| |_| |    ___   __| |___ / _|_ __ __ _   _ __  _ __ ___   ___   / _|_ __ ___  __ _
|___ \   | | | | __| |   / _ \ / _` / __| |_| `__/ _` | | `_ \| `__/ _ \ / __| | |_| `__/ _ \/ _` |
 ___) |  | |_| | |_| |  | (_) | (_| \__ \  _| | | (_| | | |_) | | | (_) | (__  |  _| | |  __/ (_| |
|____(_)  \__,_|\__|_|___\___/ \__,_|___/_| |_|  \__, | | .__/|_|  \___/ \___| |_| |_|  \___|\__, |
                    |_____|                         |_| |_|                                     |_|
*/

%utl_odsfrq(setup);
proc freq data=hav1st;
 tables city * grade /norow nocol nopercent;
run;quit;
%utl_odsfrq(outdsn=want_frq );
options FORMCHAR='|----|+|---+=|-/\<>*'; * use this;

/*****************************************************************/
/*                                                               */
/* Up to 40 obs from WANT_FRQ total obs=3 15MAR2022:10:23:35     */
/*                                                               */
/* Obs    ROWNAM     LEVEL    FREQUENCY    A    B    C    TOTAL  */
/*                                                               */
/*  1     COUNT        0         CA        1    1    1      3    */
/*  2     PERCENT      0         CO        1    2    0      3    */
/*  3     ROW PCT      0         NY        3    0    0      3    */
/*                                                               */
/*****************************************************************/
/*__          _       _            _
 / /_      __| | __ _| |_ __ _ ___| |_ ___ _ __
| `_ \    / _` |/ _` | __/ _` / __| __/ _ \ `_ \
| (_) |  | (_| | (_| | || (_| \__ \ ||  __/ |_) |
 \___(_)  \__,_|\__,_|\__\__,_|___/\__\___| .__/
                                          |_|
*/

data want_datastep (drop= i grade1-grade3);
    set have;
     * create an array of all your grades;
    array grade(3) 3 grade1-grade3;
    by city;
     *set the count to zero for each city;
    if first.city then do;
        A = 0;
        B = 0;
        C = 0;
    end;
    * use a do loop to count the grades;
    do i = 1 to 3;
        if grade(i) = 'A' then A + 1;
        else if grade(i) = 'B' then B + 1;
        else if grade(i) = 'C' then C + 1;
    end;
run;

/******************************************************************/
/*                                                                */
/* Up to 40 obs WORK.WANT_DATASTEP total obs=3 15MAR2022:10:21:47 */
/*                                                                */
/* Obs    CITY    A    B    C                                     */
/*                                                                */
/*  1      CA     1    1    1                                     */
/*  2      CO     1    2    0                                     */
/*  3      NY     3    0    0                                     */
/*                                                                */
/******************************************************************/
/*
 _ __ ___   __ _  ___ _ __ ___  ___
| `_ ` _ \ / _` |/ __| `__/ _ \/ __|
| | | | | | (_| | (__| | | (_) \__ \
|_| |_| |_|\__,_|\___|_|  \___/|___/

*/
%macro utl_odsrpt(outdsn);


   %if %qupcase(&outdsn)=SETUP %then %do;

        %put @@@@ &=sysindex.;

        %let _tmp1_=a&sysindex.;

        %put xxxx &=_tmp1_;

        filename &_tmp1_ clear;  * just in case;

        %utlfkil(%sysfunc(pathname(work))/&_tmp1_..txt);

        filename &_tmp1_ "%sysfunc(pathname(work))/&_tmp1_..txt";

        %let _ps_= %sysfunc(getoption(ps));
        %let _fc_= %sysfunc(getoption(formchar));

        OPTIONS ls=max ps=32756  FORMCHAR='|'  nodate nocenter;

        title; footnote;

        proc printto print=&_tmp1_;
        run;quit;

   %end;
   %else %do;

        /* %let outdsn=tst;  */
        %put @@@ &=sysindex.;

        %let _tmp2_=b&sysindex.;
        %let _tmp1_=a%eval(&sysindex - 2);

        %put xxxx  &=_tmp1_;
        %put xxxx  &=_tmp2_;

        proc printto;
        run;quit;

        filename &_tmp2_ clear;

        %utlfkil(%sysfunc(pathname(work))/&_tmp2_.txt);

        proc datasets lib=work nolist;  *just in case;
         delete &outdsn;
        run;quit;

        filename &_tmp2_ "%sysfunc(pathname(work))/&_tmp2_.txt";

        data _null_;
          infile &_tmp1_ length=l;
          input lyn $varying32756. l;
          if countc(lyn,'|')>1;
          lyn=compress(lyn);
          putlog lyn;
          file &_tmp2_;
          put lyn;
        run;quit;

        proc import
           datafile=&_tmp2_
           dbms=dlm
           out=&outdsn(drop=VAR:)
           replace;
           delimiter='|';
           getnames=yes;
        run;quit;

        filename &_tmp1_ clear;
        filename &_tmp2_ clear;

        %utlfkil(%sysfunc(pathname(work))/&_tmp1_.txt);
        %utlfkil(%sysfunc(pathname(work))/&_tmp2_.txt);

   %end;

%mend utl_odsrpt;


%macro utl_odsfrq(outdsn);

   %if %qupcase(&outdsn)=SETUP %then %do;

        filename _tmp1_ clear;  * just in case;

        %utlfkil(%sysfunc(pathname(work))/_tmp1_.txt);

        filename _tmp1_ "%sysfunc(pathname(work))/_tmp1_.txt";

        %let _ps_= %sysfunc(getoption(ps));
        %let _fc_= %sysfunc(getoption(formchar));

        OPTIONS ls=max ps=32756  FORMCHAR='|'  nodate nocenter;

        title; footnote;

        proc printto print=_tmp1_;
        run;quit;

   %end;
   %else %do;

        proc printto;
        run;quit;

        filename _tmp2_ clear;

        %utlfkil(%sysfunc(pathname(work))/_tmp2_.txt);

        filename _tmp2_ "%sysfunc(pathname(work))/_tmp2_.txt";

        proc datasets lib=work nolist;  *just in case;
         delete &outdsn;
        run;quit;

        data _null_;
          infile _tmp1_ length=l;
          input lyn $varying32756. l;
          if index(lyn,'Col Pct')>0 then substr(lyn,1,7)='LEVELN   ';
          lyn=compbl(lyn);
          if countc(lyn,'|')>1;
          putlog lyn;
          file _tmp2_;
          put lyn;
        run;quit;

        proc import
           datafile=_tmp2_
           dbms=dlm
           out=_temp_
           replace;
           delimiter='|';
           getnames=yes;
        run;quit;

        data &outdsn(rename=(_total=TOTAL));
          length rowNam $8 level $64;
          retain rowNam level ;
          set _temp_;
          select (mod(_n_-1,4));
            when (0) do; level=cats(leveln); rowNam="COUNT";end;
            when (1) rowNam="PERCENT";
            when (2) rowNam="ROW PCT";
            when (3) rowNam="COL PCT";
          end;
          drop leveln;
        run;quit;

        filename _tmp1_ clear;
        filename _tmp2_ clear;

        %utlfkil(%sysfunc(pathname(work))/_tmp1_.txt);
        %utlfkil(%sysfunc(pathname(work))/_tmp2_.txt);

   %end;

%mend utl_odsfrq;


%macro utl_odstab(outdsn,datarow=1);

   %if %qupcase(&outdsn)=SETUP %then %do;

        filename _tmp1_ clear;  * just in case;

        %utlfkil(%sysfunc(pathname(work))/_tmp1_.txt);

        filename _tmp1_ "%sysfunc(pathname(work))/_tmp1_.txt";

        %let _ps_= %sysfunc(getoption(ps));
        %let _fc_= %sysfunc(getoption(formchar));

        OPTIONS ls=max ps=32756  FORMCHAR='|'  nodate nocenter;

        title; footnote;

        proc printto print=_tmp1_;
        run;quit;

   %end;
   %else %do;

        /* %let outdsn=tst; %let datarow=3; */

        proc printto;
        run;quit;

        %utlfkil(%sysfunc(pathname(work))/_tmp2_.txt);

        *filename _tmp2_  "%sysfunc(pathname(work))/_tmp2_.txt";

        proc datasets lib=work nolist;  *just in case;
         delete &outdsn;
        run;quit;

        proc printto print="%sysfunc(pathname(work))/_tmp2_.txt";
        run;quit;

        data _null_;
          retain n 0;
          infile _tmp1_ length=l;
          input lyn $varying32756. l;
          if _n_=1 then do;
              file print titles;
              putlog lyn;
              *put lyn;
          end;
          else do;
             if countc(lyn,'|')>2;
             n=n+1;
             if n ge %eval(&datarow + 1) then do;
                file print;
                putlog lyn;
                put lyn;
             end;
          end;
        run;quit;

        proc printto;
        run;quit;

        proc import
           datafile="%sysfunc(pathname(work))/_tmp2_.txt"
           dbms=dlm
           out=&outdsn(drop=var:)
           replace;
           delimiter='|';
           getnames=yes;
        run;quit;

        filename _tmp1_ clear;
        filename _tmp2_ clear;

        %utlfkil(%sysfunc(pathname(work))/_tmp1_.txt);
        %utlfkil(%sysfunc(pathname(work))/_tmp2_.txt);

   %end;

%mend utl_odstab;

%macro utl_renamel ( old , new ) ;
    /* Take two cordinated lists &old and &new and  */
    /* return another list of corresponding pairs   */
    /* separated by equal sign for use in a rename  */
    /* statement or data set option.                */
    /*                                              */
    /*  usage:                                      */
    /*    rename = (%renamel(old=A B C, new=X Y Z)) */
    /*    rename %renamel(old=A B C, new=X Y Z);    */
    /*                                              */
    /* Ref: Ian Whitlock <whitloi1@westat.com>      */

    %local i u v warn ;
    %let warn = Warning: RENAMEL old and new lists ;
    %let i = 1 ;
    %let u = %scan ( &old , &i ) ;
    %let v = %scan ( &new , &i ) ;
    %do %while ( %quote(&u)^=%str() and %quote(&v)^=%str() ) ;
        &u = &v
        %let i = %eval ( &i + 1 ) ;
        %let u = %scan ( &old , &i ) ;
        %let v = %scan ( &new , &i ) ;
    %end ;

    %if (null&u ^= null&v) %then
        %put &warn do not have same number of elements. ;

%mend  utl_renamel ;


/*              _
  ___ _ __   __| |
 / _ \ `_ \ / _` |
|  __/ | | | (_| |
 \___|_| |_|\__,_|

*/

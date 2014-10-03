;+
; NAME:
;   GET_EPH
; PURPOSE:
;   Generate an ephemeris from HORIZONS. This can be used for BJD
;   calculations accurate to 1 ms.
;
;   If you make use of this program, please cite our paper:
;   http://adsabs.harvard.edu/abs/2010PASP..122..935E
;
; DESCRIPTION
;   Calls an expect script to generate an ephemeris file via
;   HORIZONS. We use a step size of 250 minutes because, with
;   quadratic interpolation, we there is no noticable difference
;   between this and the smallest step size allowed (1 minute). The
;   benefits of a larger step size is smaller file size, faster
;   runtime, and a longer allowed baseline. Since the TELNET interface
;   will not return more than 90,024 lines per call, at 1 minute steps,
;   we're limited to 62.5 days. At 250 minutes, we can do 42.8 years.
;
; CALLING SEQUENCE
;   GET_EPH, jd_tdb, object [stepsize=stepsize,outfile='name.eph',/helio]
;
; INPUTS:
;   JD_TDB     - A scalar or array of JDs in TDB. Must be double
;                precision. 
;   OBJECT     - A string specifying the object name for which to get
;                the ephemeris. A full list of objects is here: 
;                http://www-int.stsci.edu/~sontag/spicedocs/req/naif_ids.html
;
; OPTIONAL INPUTS:
;   OUTFILE    - The name of a file generated by HORIZONS in CSV
;                format. The default is OBJECT + '.bary.eph'.
;   STEPSIZE   - The stepsize, in minutes, of the returned
;                ephemeris. This will effect the accuracy of the
;                result, the speed of the program, the size of the
;                ephemeris, and the maximum duration you can query,
;                since HORIZONS cannot return more than 90,024 lines. 
;                Keep the following accuracies and date ranges in mind
;                when picking a stepsize:
;                1 minute     -  5 ns, 62.5 days
;                10 minutes   -  5 ns, 1.7 years 
;                100 minutes  - 60 ns, 17 years
;                1000 minutes - 60 us, 170 years
;                Default is 100 minutes. stepsizes of less than 1
;                minute are not allowed (will be set to 1 minute)
; OPTIONAL KEYWORDS:
;   HELIO      - If set, the ephemeris will be relative to the
;                heliocenter instead of the Solar System Barycenter.
;                The default filename will be OBJECT + 'helio.eph'
; OUTPUTS:
;   OUTFILE    - This is the ephemeris file read generated by HORIZONS
;
; DEPENDENCIES 
;  spawns an expect script (horizons.exp) to automate the telnet
;  session to HORIZONS. This script must be in your path.
;  READCOL
;
; REVISION HISTORY:
; 2010/04/12: Added stepsize input
;             removed X, Y, Z interpolation (exclusively in get_bjdtdb) 
; 2010/03/30: Written by Jason Eastman (OSU)

pro get_eph, jd_tdb, object, stepsize=stepsize, outfile=outfile, helio=helio

;; default is the Barycenter
if keyword_set(helio) then center = 10 $
else center = 0

;; set the stepsize
if n_elements(stepsize) eq 0 then stepsize = 100
if stepsize lt 1 then stepsize = 1
stepsize = strtrim(stepsize,2)

if n_elements(outfile) eq 0 then outfile = object + '.eph'

months = ['Jan','Feb','Mar','Apr','May','Jun',$
          'Jul','Aug','Sep','Oct','Nov','Dec']

;; specify a start time 3*stepsize before the first jd (for interpolation)
starttime = min(jd_tdb) - 3.d0*stepsize/1440.d0 
caldat, starttime, month, day, year, hour, min, sec
startstr = string(year, months[month-1], day, hour, min, sec, $
                  format='(i04,"-",a,"-",i02," ",i02,":",i02,":",f5.2)')

;; specify an end time 3*stepsize past the last jd (for interpolation)
endtime = max(jd_tdb) + 3.d0*stepsize/1440.d0 
caldat, endtime, month, day, year, hour, min, sec
endstr = string(year, months[month-1], day, hour, min, sec, $
                  format='(i04,"-",a,"-",i02," ",i02,":",i02,":",f5.2)')

;; spawn an expect script
if object lt 0 then object = '\\' + object 
cmd = 'horizons.exp ' + object + ' "' + startstr + $
  '" "' + endstr + '" ' + stepsize + 'm ' + strtrim(center,2) + ' ' + outfile
print, cmd
spawn, cmd

end

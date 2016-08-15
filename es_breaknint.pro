PRO es_breaknint, file
;+
; NAME:
;
;
; PURPOSE:
;       Separate a 'nominal' NIRCam exposure of NINTS packed into a 
;       cube into separate FITS files for each integration. 
;
; CATEGORY:
;       Data analysis, NIRCam 
;
;
; CALLING SEQUENCE:
;       
;
; INPUTS:
;
;
; OUTPUTS:
;      
;
; RESTRICTIONS:
;         
;
; DESCRIPTION:
;       A nominal NIRCam exposure will consist of NINT individual
;       ramps. For some reason, someone though it's a good idea to
;       make the exposure into a DATA CUBE of size (NX,NY,NZ) where NZ
;       is NINT*NGROUP.  A CUBE.  Not extensions, not single files, A
;       CUBE. So this code breaks up the exposure into individual FITS
;       files, one for each integration. 
;
; EXAMPLE:
;       
;
; REQUIRES: 
;        
;
; MODIFICATION HISTORY:
;       Spring 2012 - Created; putridmeat (misselt@as.arizona.edu)

; instantiate a FITSIMAGE object 
if Obj_Valid(indata) then Obj_Destroy,indata
indata = Obj_New('FITSIMAGE',file)

; Get data axes
nx=indata->NX()
ny=indata->NY()
nr=indata->NZ()

; Check nint
nint = indata->getKeyword('NINT',status)
if (status) then begin ; non-zero status from getKeyword means not found
    print,'Keyword NINT not found; can''t split data up.'
    goto, BAIL
endif else begin 
    if (nint eq 1) then begin ; not a packed data cube
        print,'NINT is ',strtrim(nint,2),'; ',strtrim(file,2),' is not a packed data cube.'
        goto, BAIL
    endif
endelse 

; check ngroup
ngroup = indata->getKeyword('NGROUP',status)
if (status) then begin ; ngroup not found...
    print,'Keyword NGROUP not found.  Assuming NGROUP = NREAD/NINT'
    print,'NREAD: ',strtrim(nr,2)
    print,'NINT:  ',strtrim(nint,2)
    if (nr mod nint) then begin 
        print,'NREAD is not an even multiple of NINT. Can''t proceed'
        goto, BAIL
    endif else begin 
        ngroup = nr/nint
        print,'Setting NGROUP to ',strtrim(ngroup,2)
    endelse
endif else begin ; ngroup found make sure number work
    if (nr ne ngroup*nint) then begin 
        print,'Counting doesn''t work out. NREAD must equal NGROUP*NINT'
        print,'NINT:  ',strtrim(nint,2)
        print,'NGROUP: ',strtrim(ngroup,2)
        print,'NGROUP*NINT: ',strtrim(ngroup*nint,2)
        print,'NREAD: ',strtrim(nr,2)
        goto, BAIL
    endif
endelse

; start your engines. 
FullHeader=indata->Header()
BaseName=strmid(file,0,strlen(file)-5) ; trim off .fits
print,file
print,BaseName
z0=0
z1=z0+ngroup-1
for i=0,nint-1 do begin  ; Loop over nints 
    tmpStr=string(i,format='(I03)')
    ; Get this block on nint
    _thisint = indata->SubSection(z0=z0,z1=z1)
    _thisheader = FullHeader
    _thisfile = BaseName + '_I' + tmpStr + '.fits'
    sxaddpar,_thisHeader,'NINT',1   ; set nint to 1
    sxaddpar,_thisHeader,'ON_NINT',i+1,'This is INT of TOT_NINT',AFTER='NINT'
    sxaddpar,_thisHeader,'TOT_NINT',nint,'Total number of NINT in original file',AFTER='ON_NINT'
    sxaddpar,_thisHeader,'COMMENT','Extracted from a multi-integration file by ParseIntegration.pro'
    fits_write,_thisfile,_thisint,_thisheader
    z0 += ngroup
    z1 = z0+ngroup-1
endfor 

BAIL:

if Obj_Valid(indata) then Obj_Destroy,indata

END

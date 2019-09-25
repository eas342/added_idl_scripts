function NCViewDia::GetName, id=id

Catch, theError
if theError ne 0 then begin 
    Catch, /Cancel
    ok = Dialog_Message(!Error_State.Msg + ' Returning from NCVIEWDIA::INIT...', $
                        /Error)
    return, 0
endif 

if n_elements(id) eq 0 then return,(*self.PlaneName)
if _id lt 0 or _id ge self.nz then Message, "Incorrect argument to number of planes in DIAGNOSTIC image..."
return, (*self.PlaneName)[id]

end

function NCViewDia::getCurFrame
return, self.CurFrame
end

pro NCViewDia::setCurFrame, id
if id ge self.nz then id=0
if id lt 0 then id=self.nz-1
self.CurFrame=id
end

function NCViewDia::getNPlane
return, self.nz
end

function NCViewDia::getNamedPlane,x,y,name
Catch, theError
if theError ne 0 then begin 
    Catch, /Cancel
    ok = Dialog_Message(!Error_State.Msg, $
                        /Error)
    return, 0
endif 

name=strtrim(STRUPCASE(name),2)
_idx=where(*self.PlaneName eq name,_count)
if _count eq 1 then return, self->Pixel(x,y,id=_idx) else Message, 'Unable to find named plane in diagnostic image'
end

function NCViewDia::Init, filename, buffer=buffer

Catch, theError
if theError ne 0 then begin 
    Catch, /Cancel
    ok = Dialog_Message(!Error_State.Msg + ' Returning from NCVIEWDIA::INIT...', $
                        /Error)

    return, 0
endif 

; never buffer the slope image.  If there's not enough RAM to hold 
; the slope image (2048x2048x2), we have bigger problems.
buffer=0

; Init the fitsimage object for the slope image
if not self->FITSImage::Init(filename,buffer=buffer) then Message, "Failed in instantiate DIAGNOSTIC image from FITS"

; Any locate variables to populate...
; PlaneName will hold a string identifier for what is contained in
; the diagnostic image.  Depends on the keyword "DIATYPXX" to be
; defined in the header of the diagnostic frame by ncdhas.
if self.nz gt 99 then Message, "Too many planes in DIAGNOSTIC image..."
_thisName = strarr(self.nz)
_base = "DIATYP"
_unkownStr = 'UNKNOWN'
for _i=1,self.nz do begin 
    if (_i lt 10) then _key=_base+'0'+strtrim(_i,2) else _key=_base+strtrim(_i,2)
    _thisName[_i-1] = STRUPCASE(self->getKeyword(_key,_status))
    ;print,_status
    ;print,_unkownStr
    if (_status) then _thisName[_i-1] = _unkownStr
endfor
self.PlaneName = Ptr_New(_thisName)

; Check for 'old style' diagnostic image, ie where no DIATYP keywords
; have been set.  Then assume that the planes are: 
; PLANE 1 = MASK
; PLANE 2 = SATURATION
; PLANE 3 = INTERCEPT
; PLANE 4 = EINTERCEPT
; PLANE 5 = CHISQ
_idx = where(*(self.PlaneName) eq _unkownStr,count) 
if (count eq self.nz) then begin ; all planes unkown/undefined
    _defaultNames = ['MASK','SATURATION','INTERCEPT','EINTERCEPT','CHISQ']
    _nDefault = n_elements(_defaultNames)
    if Ptr_Valid(self.PlaneName) then Ptr_Free, self.PlaneName
    self.PlaneName=Ptr_new(_defaultNames)
endif 

self.CurFrame = 0 ; default to first frame.     

return, 1

end

;  Most cleanup will be handled by FITSImage::Cleanup
pro NCViewDia::Cleanup
if Ptr_Valid(self.PlaneName) then Ptr_Free, self.PlaneName
self->FITSImage::Cleanup
end

pro ncviewdia__define

struct = { NCVIEWDIA, $
           INHERITS FITSImage,  $
           CurFrame:  0,        $
           PlaneName: Ptr_New() $
         }

end

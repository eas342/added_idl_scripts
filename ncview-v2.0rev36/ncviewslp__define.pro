; Get the slope part of the fit, ie. slope*x.  The intercept is in the
; diagnostic file (who designed this crap anyway?), so it will have to
; accounted for outside of the slope object
function NCViewSlp::Fit, px, py, ordinate
_slp = self->FITSImage::Pixel(px,py,id=0)
return, ordinate*_slp
end

function NCViewSlp::getCurFrame
return, self.CurFrame
end

pro NCViewSlp::setCurFrame, id
if id ge self.nz then id=0
if id lt 0 then id=self.nz-1
self.CurFrame=id
end

function NCViewSlp::DropFrame
return, self.DropFrame
end

function NCViewSlp::NPlane 
return, self.nz
end

function NCViewSlp::IsWFS
return, self.WFS
end

; Wrap around FITS image pixel function
; function NCViewRamp::Pixel,x,y,id=id
; if n_elements(id) eq 0 then $
;   return, self->FITSImage::Pixel(x,y) $
; else $
;   return, self->FITSImage::Pixel(x,y,id=id)
; end

; wfs is a "boolean" flag.  if set (/wfs) then 
; we set wfs=1 (true) otherwise, we set wfs=0 (false)
; CAVEAT: if you send wfs=0 (nominally you want wfs false,
; we will set wfs=1 (true) since n_elements(wfs) != 0
; So just treat it as a flag. 
function NCViewSlp::Init, filename, wfs=wfs

Catch, theError
if theError ne 0 then begin 
    Catch, /Cancel
    ok = Dialog_Message(!Error_State.Msg + ' Returning from Image::Init...', $
                        /Error)
    return, 0
endif 

; never buffer the slope image.  If there's not enough RAM to hold 
; the slope image (2048x2048x2), we have bigger problems.
buffer=0

; toggle our wfs flag
if n_elements(wfs) eq 0 then $
  self.WFS = 0B $
else $
  self.WFS = 1B

; Init the fitsimage object for the slope image
if not self->FITSImage::Init(filename,buffer=buffer) then return, 0

; Any locate variables to populate...
self.CurFrame=0  ; default to first frame == slope image

; Get the drop frame from the header. Should be stored as IDRPFRM
_drpfrme = self->getKeyword('IDRPFRM',_status)
if (_status) then _drpfrme=1 ; assume a single frame was dropped... FFE
self.DropFrame = _drpfrme

return, 1

end

; Cleanup will be handled by FITSImage::Cleanup
pro NCViewSlp::Cleanup

self->FITSImage::Cleanup

end

pro ncviewslp__define

struct = { NCVIEWSLP, $
           INHERITS FITSImage, $
           DropFrame: 0,       $
           WFS:       0B,      $
           CurFrame:  0        $
         }

end

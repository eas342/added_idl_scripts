function NCViewRamp::getTime
return, (*self.Time)
end

function NCViewRamp::NPlane
return, self.nz
end

function NCViewRamp::FrameTime
return, self.FrameTime
end

function NCViewRamp::getDataMode
return, self.DataMode
end

function NCViewRamp::getCurFrame
return, self.CurFrame
end

pro  NCViewRamp::setCurFrame,id
if id ge self.nz then id=0
if id lt 0 then id=self.nz-1
self.CurFrame=id
end

; Wrap around FITS image pixel function
; function NCViewRamp::Pixel,x,y,id=id
; if n_elements(id) eq 0 then $
;   return, self->FITSImage::Pixel(x,y) $
; else $
;   return, self->FITSImage::Pixel(x,y,id=id)
; end


function NCViewRamp::Init, filename, buffer=buffer

; Catch, theError
; if theError ne 0 then begin 
;     Catch, /Cancel
;     ok = Dialog_Message(!Error_State.Msg + ' Returning from NCViewRamp::Init...', $
;                         /Error)
;     return, 0
; endif 

; If requesting an on disk buffer, make it so.
if n_elements(buffer) eq 0 then begin 
    buffer=0 
endif else begin 
    buffer=buffer
endelse 

; Init the fitsimage object for the red (intermediate) image
if not self->FITSImage::Init(filename,buffer=buffer) then return, 0

; Populate variables local to the NCVIEWRED object
; In some cases, subarray frame time is not properly defined 
; in the header.  So for subarray, just compute an estimate of the
; frame time assuming a 10.11 microsec/pixel readtime. 10.11 is
; arrived at from the nominal of 10.0 by ASSUMING a full frame read
; time of 10.6 sec (2048x2048) and calculating what pixel read time is
; required to get 10.6 sec.  Completely ass-backwards. 
_subarrmd = self->getKeyword('SUBARRMD',_status)
if (_status) then begin ; Unable to find SUBARRMD keyword. 
    self.FrameTime = self->getKeyword('TFRAME',_status)
    if (_status) then self.FrameTime = float(self.nx+12)*float(self.ny+1)*10.0e-6
endif else begin 
    if _subarrmd eq 'T' then $
      self.FrameTime = float(self.nx+12)*float(self.ny+1)*10.0e-6 $
    else begin 
        self.FrameTime = self->getKeyword('TFRAME',_status)
        if (_status) then self.FrameTime = float(self.nx/4. + 12)*float(self.ny+1)*10.0e-6
    endelse 
endelse 

; Error handling for not found keywords needed
_groupgap = self->getKeyword('GROUPGAP',_status)
_nframe = self->getKeyword('NFRAME',_status)
_ngroup = self->getKeyword('NGROUP',_status)
_nint = self->getKeyword('NINT',_status)
_telescope = strtrim(self->getKeyword('TELESCOP',_status),2)

; Need to bypass DATAMODE stuff for Teledyne since they aren't using 
; an official datamode. 
if strupcase(_telescope) ne 'TELEDYNE' then begin 
    ; Get the data mode - if not defined, figure it out
    _datamode = self->getKeyword('DATAMODE',_status)
    _guessDatamode=0
    if (_status) then begin 
        _guessDatamode=1
    endif else begin 
        ; Check against supported datamodes
        ;                   DEEP8,DEEP2,MEDIUM8,MEDIUM2,SHALLOW4,SHALLOW2,BRIGHT2,BRIGHT1,RAPID
        _allowedDatamode = [25,   26,   27,     28,     29,      30,      31,     32,     33]
        _idx = where(_datamode eq _allowedDatamode,count)
        if count ne 1 then begin 
            print,'Found datamode ',_datamode,' that doesn''t correspond to allowed mode.' 
            print,'Trying to determine datamode from frame/group/nf counts.'
            _guessDatamode=1
        endif else self.DataMode=_datamode
    endelse

    if (_guessDatamode) then begin ; Guessing datamode
        case 1 of
            (_groupgap eq 12) AND (_nframe eq 8) : self.DataMode=25 ; deep 8
            (_groupgap eq 18) AND (_nframe eq 2) : self.DataMode=26 ; deep 2
            (_groupgap eq 2)  AND (_nframe eq 8) : self.DataMode=27 ; medium 8
            (_groupgap eq 8)  AND (_nframe eq 2) : self.DataMode=28 ; medium 2
            (_groupgap eq 1)  AND (_nframe eq 4) : self.DataMode=29 ; shallow 4
            (_groupgap eq 3)  AND (_nframe eq 2) : self.DataMode=30 ; shallow 2
            (_groupgap eq 0)  AND (_nframe eq 2) : self.DataMode=31 ; bright 2
            (_groupgap eq 1)  AND (_nframe eq 1) : self.DataMode=32 ; bright 1
            (_groupgap eq 0)  AND (_nframe eq 1) : self.DataMode=33 ; rapid
            else : begin 
                print,'Unsupported DATAMODE; assuming RAPID.'
                self.DataMode=33
            end
        endcase
    endif
endif else begin 
    ; For Teledyne, put the datamode in 'undefined' status 
    ; The following logic for coaddition will still work. 
    self.DataMode = -1
endelse 

; Presumably, we have a DATAMODE, now figure out if it's coadded...
; RAPID is never coadded: 
if self.DataMode ne 33 then begin 
    ; For non-rapid, coadded data, nz==ngroup
    ; For non-rapid, un-coadded data, nz=ngroup*nframe
    case 1 of
        self.nz eq _ngroup*_nint         : _coadded=1
        self.nz eq _ngroup*_nframe*_nint : _coadded=0
        else : begin
            _msgStr = 'Unable to determine observing modes for '+strtrim(filename,2)
            Message,_msgStr
        end 
    endcase
endif else _coadded=0


; Three cases to handle:
; 1) RAPID MODE
; 2) NON RAPID, coadded
; 3) NON RAPID, not coadded
; For all cases, we need a time point for every frame.
if self.DataMode eq 33 then begin  ; 1) 
    _tmpTime = self.FrameTime*(1+findgen(self.nz))
endif else begin 
    _tmpTime = fltarr(self.nz) 
    _inttime = _ngroup*(_nframe+_groupgap)*self.FrameTime
    if not _coadded then begin     ; 3)
        for i=0,nint-1 do begin 
            _ioffset = i*_inttime
            _iidx = i*(_ngroup*_nframe)
            for g=0,_ngroup-1 do begin
                _goffset=float(g)*(float(_groupgap+_nframe))*self.FrameTime
                for f=0,_nframe-1 do _tmpTime[_iidx+g*_nframe+f] = _ioffset+_goffset+(f+1)*self.FrameTime
            endfor
        endfor
    endif else begin               ; 2)
        ; take midpoint of each group to be time
        _grouptime=_nframe*self.FrameTime
        for i=0,_nint-1 do begin 
            _ioffset = i*_inttime
            for g=0,_ngroup-1 do begin 
                _idx = i*_ngroup+g
                _goffset=float(g)*(float(_groupgap+_nframe))*self.FrameTime
                _tmpTime[_idx] = _ioffset+_goffset+_grouptime/2.0
            endfor
        endfor
    endelse
endelse 

self.Time=Ptr_New(_tmptime)
self.CurFrame=0 ; default to first frame

return, 1

end

; Most Cleanup will be handled by FITSImage::Cleanup
pro NCViewRamp::Cleanup
if Ptr_Valid(self.Time) then Ptr_Free, self.Time
self->FITSImage::Cleanup
end


pro ncviewramp__define

struct = { NCVIEWRAMP, $
           INHERITS FITSImage,  $
           FrameTime: 0.0,      $
           DataMode:  0,        $
           CurFrame:  0,        $   
           Time:      Ptr_New() $
         }

end

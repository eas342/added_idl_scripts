;+
; NAME:
;       FITSIMAGE
;
; PURPOSE:
;       IDL class to wrap FITS functionality.
;
; CATEGORY:
;       Data analysis, FITS
;
;
; CALLING SEQUENCE:
;       MyObject = Obj_New('FITSIMAGE',filename)
;       
; INPUTS:
;       filename: a valid FITS file.  File can be 2 or 3D.
;       buffer:  optional to buffer input file in RAM.  If 
;                set, entire FITS data is loaded into RAM. 
;                Otherwise, data is retrieved from disk as 
;                needed.
;
; OUTPUTS:
;       Reference to an object containing the FITS data
;
; RESTRICTIONS:
;         
;
; DESCRIPTION:
;
; EXAMPLE:
;       
;
; REQUIRES: 
;        
;
; MODIFICATION HISTORY:
;       19 May 2012 - Fixed 'BUFFERED' mode 
;       12 May 2012 - added 3rd dimension to SubSection member
;                     function (PM)
;       Fall 2011   - Created; putridmeat (misselt@as.arizona.edu)
;
function FITSImage::Filename
return, self.filename
end 

function FITSImage::NX
return, self.nx
end

function FITSImage::NY
return, self.ny
end 

function FITSImage::NZ
return, self.nz
end

function FITSImage::NPlane
return, self.nz
end

function FITSImage::SpatialDimension
return, self.SpatialDimension
end

function FITSImage::Dimension
return, self.Dimension
end

function FITSImage::SubSection,x0=x0,x1=x1,y0=y0,y1=y1,z0=z0,z1=z1

; maybe be able to specify a range of id as well.... id0:id1? 

; Specify default bounds.  If no bounds set, return the full image. 
if n_elements(id) eq 0 then id=self.nz else begin 
    if id ge self.nz or id lt 0 then $
      Message,'requested plane out of bounds'
endelse 

if n_elements(x0) eq 0 then x0=0
if n_elements(x1) eq 0 then x1=self.nx-1
if n_elements(y0) eq 0 then y0=0
if n_elements(y1) eq 0 then y1=self.ny-1
if n_elements(z0) eq 0 then z0=0
if n_elements(z1) eq 0 then z1=self.nz-1

if x1 ge self.nx or x0 lt 0 then $
  Message,'requested x0,x1 region out of bounds'
if y1 ge self.ny or y0 lt 0 then $
  Message,'requested y0,y1 region out of bounds'
if z1 ge self.nz or z0 lt 0 then $
  Message,'requested z0,z1 region out of bounds'

if self.InRAM then begin 
    _data = reform((*self.Image)[x0:x1,y0:y1,z0:z1]) 
endif else begin  ; read in frame by frame
    first=(self.ImageSz)*z0
    last=first+self.ImageSz-1
    fits_read,self.Filename,_tmp,_hdr,first=first,last=last
    _tmp = _tmp*self.BScale+self.BZero
    _tmp=reform(_tmp,self.nx,self.ny)
    _data = _tmp[x0:x1,y0:y1]
    for i=1,z1 do begin 
        first += self.ImageSz 
        last += self.ImageSz
        fits_read,self.Filename,_tmp,_hdr,first=first,last=last
        _tmp = _tmp*self.BScale+self.BZero
        _tmp=float(_tmp)
        _tmp=reform(_tmp,self.nx,self.ny)
        _tmp=_tmp[x0:x1,y0:y1]
        _data=[[[_data]],[[_tmp]]]
    endfor
endelse

; if id eq self.nz then begin ; returning the specified subsection for all frames. 
;     if self.InRAM then _data=reform((*self.Image)[x0:x1,y0:y1,*]) else begin 
;         first=0
;         last=first+self.ImageSz-1
;         fits_read,(*self.fcb),_tmp,_hdr,first=first,last=last
;         _tmp=reform(_tmp,self.nx,self.ny)
;         _data=_tmp[x0:x1,y0:y1]
;         for i=1,self.nz-1 do begin 
;             first += self.ImageSz
;             last += self.ImageSz
;             fits_read,(*self.fcb),_tmp,_hdr,first=first,last=last
;             _tmp=reform(_tmp,self.nx,self.ny)
;             _data = [[[_data]],[[_tmp]]]
;         endfor
;     endelse
; endif else begin ; returning subsection for a single frame. 
;     if self.InRAM then _data=reform((*self.Image)[x0:x1,y0:y1,id]) else begin 
;         ; Get the plane first since we can't read subsection in x,y

;         first=self.ImageSz*id
;         last=first+self.ImageSz-1
;         fits_read,(*self.fcb),_tmp,_hdr,first=first,last=last
;         _tmp=reform(_tmp,self.nx,self.ny)
;         _data = _tmp[x0:x1,y0:y1]
;     endelse
; endelse

return, _data

end

function FITSImage::Plane,id=id

if n_elements(id) eq 0 then id=0

if id lt self.nz AND id ge 0 then begin 
    if self.InRAM then return, (*self.Image)[*,*,id] else begin 
        ; Retrieve this plane from disk
        first=self.ImageSz*id
        last=first+self.ImageSz-1
        ;fits_read,(*self.fcb),_tmp,_hdr,first=first,last=last
        fits_read,self.Filename,_tmp,_hdr,first=first,last=last
        _tmp = _tmp*self.BScale+self.BZero
        _tmp=reform(_tmp,self.nx,self.ny)
        return, _tmp
    endelse 
endif else begin 
    ; Bad input - return a bad value, depend on calling
    ; program to handle it
    return, !VALUES.F_NAN
endelse

end 

; Get min/max of a pixel
function FITSImage::PixelMinMax,x,y

; Make sure its a real pixel
if x ge 0 AND x lt self.nx AND y ge 0 AND y lt self.ny then begin 
    if self.InRAM then begin 
        _tmp=(*self.Image)[x,y,*]
    endif else begin
        ; get the pixel
        _tmp=fltarr(self.nz)
        first=self.nx*y+x
        last=first
        for i=0,self.nz-1 do begin
            fits_read,self.Filename,_a,first=first,last=last,/data_only,exten_no=0
            _tmp[i]=_a*self.BScale+self.BZero
            first += self.ImageSz
            last = first
        endfor 
    endelse
    _min=min(_tmp,max=_max)
    mnmx=[_min,_max]
endif else mnmx=[!VALUES.F_NAN,!VALUES.F_NAN]

return, mnmx

end


; return a pixel. x,y, and id are 0-indexed
function FITSImage::Pixel,x,y,id=id

if x ge 0 AND x lt self.nx AND y ge 0 AND y lt self.ny then begin 
    if n_elements(id) eq 0 then begin ; return the pencil
        if self.InRAM then begin
            return, (*self.Image)[x,y,*] 
        endif else begin 
            _tmp=fltarr(self.nz)
            first=self.nx*y+x
            last=first
            for i=0,self.nz-1 do begin
                fits_read,self.Filename,_a,first=first,last=last,/data_only,exten_no=0
                _tmp[i]=_a*self.BScale+self.BZero
                first += self.ImageSz
                last = first
            endfor
            return, _tmp
        endelse
    endif else begin
        if id ge 0 and id lt self.nz then begin
            if self.InRAM then return, (*self.Image)[x,y,id] else begin 
                first=self.ImageSz*id+self.nx*y+x
                last=first
                fits_read,self.Filename,_tmp,first=first,last=last,/data_only,exten_no=0
                _tmp = _tmp*self.BScale+self.BZero
                return, _tmp
            endelse 
        endif else return, !VALUES.F_NAN
    endelse
endif else begin 
    ; Bad input - return a bad value, depend on calling
    ; program to handle it
    return, !VALUES.F_NAN
endelse 

end

function FITSImage::getImage

if self.InRAM then begin 
    return, (*self.Image)
endif else begin 
    fits_read,self.Filename,_tmp,0,/noscale
    return, _tmp
endelse

end

function FITSImage::Header 
return, (*self.ImgHdr)
end

function FITSImage::getKeyword, keyword, status
; How do we handle keywords not found... Complicated by typing. 
keyvalue = sxpar((*self.ImgHdr),keyword,count=count)
if count le 0 then status=1 else status=0 ; 0 for not found, else the number of parameters
return, keyvalue
end

function FITSImage::Init,filename,buffer=buffer

Catch, theError
if theError ne 0 then begin 
    Catch, /Cancel
    ok = Dialog_Message(!Error_State.Msg + ' Returning from Image::Init...', $
                        /Error)
    return, 0
endif 

if n_elements(buffer) eq 0 then begin 
    _buffer=0 
endif else begin 
    _buffer=buffer
endelse

; Check that the file exists...
if FILE_SEARCH(filename) eq '' then Message,'Specified filename does not exist.',/NoName

;fits_open,filename,_fcb

;self.fcb=Ptr_New(_fcb)

; If buffer is requested, simply get a reference to the opened image,
; otherwise, read the full image into RAM. 
; In both cases, the full header is stored in RAM

if _buffer eq 0 then begin
    fits_read,filename,_tmp,_hdr,/noscale
    self.Image=Ptr_New(_tmp)
    self.ImgHdr=Ptr_New(_hdr)
    self.InRAM=1
endif else begin
    fits_read,filename,0,_hdr,/header_only,exten_no=0,/noscale
    self.ImgHdr=Ptr_New(_hdr)
    self.InRAM=0
endelse

self.naxis = sxpar((*self.ImgHdr),'NAXIS')
if self.naxis lt 2 then $
  Message, 'Image must be at least 2-dimenstional.',/NoName
if self.naxis gt 3 then $
  Message, 'Image must be a cube at mode (3d).', /NoName

self.nx = sxpar((*self.ImgHdr),'NAXIS1')
self.ny = sxpar((*self.ImgHdr),'NAXIS2')
if self.naxis eq 2 then self.nz = 1 else self.nz =  sxpar((*self.ImgHdr),'NAXIS3')

self.BScale = self->getKeyword('BSCALE',_status)
if (_status) then self.BScale=1.0
self.BZero = self->getKeyword('BZERO',_status)
if (_status) then self.BZero=0.0
self.ImageSz=self.nx*self.ny
self.SpatialDimension=[self.nx,self.ny]
self.Dimension=[self.nx,self.ny,self.nz]
self.Filename = filename

return,1 

end

pro FITSImage::Cleanup

; Clean up pointers
if Ptr_Valid(self.Image) then Ptr_Free, self.Image
if Ptr_Valid(self.ImgHdr) then Ptr_Free, self.ImgHdr
if Ptr_Valid(self.fcb) then begin 
    fits_close,(*self.fcb)
    Ptr_Free, self.fcb
endif

end

pro FITSImage__Define 

struct = {FITSIMAGE, $
          Filename         : '',         $
          naxis            : 0L,         $
          nx               : 0L,         $
          ny               : 0L,         $
          nz               : 0L,         $
          ImageSz          : 0L,         $
          BScale           : 0L,         $
          BZero            : 0L,         $
          SpatialDimension : [0L,0L],    $
          Dimension        : [0L,0L,0L], $
          InRAM            : 0B,         $
          ImgHdr           : Ptr_New(),  $
          Image            : Ptr_New(),  $
          fcb              : Ptr_New()   $
         }
        
end




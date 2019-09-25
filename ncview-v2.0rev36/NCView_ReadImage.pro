pro NCView_ReadImage,infoP

Filter=['*.fits;*.fit;*.FIT;*.FITS;']

FileName = Dialog_PickFile(filter=Filter,Dialog_Parent=(*infoP).IDs.TopLevelID, $
                           /Must_Exist, /Read, Title='Select NIRCam ramp FITS file', $
                           Path=(*infoP).State.FilePath,Get_Path=NewPath)

if (FileName eq '') then return

(*infoP).State.FilePath=NewPath

; Get the base file name
_basename = strmid(FileName,0,strlen(FileName)-5)
; did we load a raw, red, slp, dia image? 
_suffix = strmid(_basename,strlen(_basename)-4,strlen(_basename))
if ( (_suffix eq '.red') OR $
     (_suffix eq '.slp') OR $
     (_suffix eq '.dia') OR $
     (_suffix eq '.wfs') ) then _basename = strmid(_basename,0,strlen(_basename)-4)
(*infoP).DataObj.BaseName = _basename

; Destroy any existing old instances
if Obj_Valid((*infoP).DataObj.Data[0]) then Obj_Destroy,(*infoP).DataObj.Data[0]
if Obj_Valid((*infoP).DataObj.Data[1]) then Obj_Destroy,(*infoP).DataObj.Data[1]
if Obj_Valid((*infoP).DataObj.Data[2]) then Obj_Destroy,(*infoP).DataObj.Data[2]
if Obj_Valid((*infoP).DataObj.Data[3]) then Obj_Destroy,(*infoP).DataObj.Data[3]

; Get the raw image if it exists 
_filename = _basename+'.fits'
ImageObject,infoP,0,'NCViewRamp',_filename

; Get the processed (red) image if it exists
_filename = _basename+'.red.fits'
ImageObject,infoP,1,'NCViewRamp',_filename
  
; Get the slope image if it exists
_filename = _basename+'.slp.fits'
ImageObject,infoP,2,'NCViewSlp',_filename

; Get the WFS image if it exists - only if we haven't already gotten a
;                                  slope image
if (not (*infoP).State.ImageLoaded[2]) then begin 
    _filename = _basename+'.wfs.fits'
    ImageObject,infoP,2,'NCViewSlp',_filename
endif 

; Get the HDR image if it exists - only if we haven't already gotten a
;                                  slope image
if (not (*infoP).State.ImageLoaded[2]) then begin 
    _filename = _basename+'.hdr.fits'
    ImageObject,infoP,2,'NCViewSlp',_filename
endif 

; Get the CDS image if it exists - only if we haven't already gotten a
;                                  slope image
if (not (*infoP).State.ImageLoaded[2]) then begin 
    _filename = _basename+'.cds.fits'
    ImageObject,infoP,2,'NCViewSlp',_filename
endif 

; Get the diagnostic image if it exists
_filename = _basename+'.dia.fits'
ImageObject,infoP,3,'NCViewDia',_filename
   
; Prioritize display image
; order is: Slope, Processed, Raw, Diagnostic
case 1 of
    (*infoP).State.ImageLoaded[2] : (*infoP).State.CurrentImageTypeIndex=2
    (*infoP).State.ImageLoaded[1] : (*infoP).State.CurrentImageTypeIndex=1
    (*infoP).State.ImageLoaded[0] : (*infoP).State.CurrentImageTypeIndex=0
    (*infoP).State.ImageLoaded[3] : (*infoP).State.CurrentImageTypeIndex=3
    else : begin
        ; I don't know how we could get here...
    end
endcase
;print,(*infoP).State.CurrentImageTypeIndex 
;if Obj_Valid((*infoP).DataObj.Data[(*infoP).State.CurrentImageTypeIndex]) then print,'VALID' else print,"CRAP"
; Set up display ratios
ImageDisplayRatio = float((*infoP).State.ImageWindowSize[0])/ $
                    float(max((*infoP).DataObj.Data[(*infoP).State.CurrentImageTypeIndex]->SpatialDimension()))                        
(*infoP).State.ZoomLevel = fix(alog(ImageDisplayRatio)/alog(2.0d0))
(*infoP).State.ZoomFactor = 2.0^((*infoP).State.ZoomLevel)
(*infoP).State.ImageSize = [(*infoP).DataObj.Data[(*infoP).State.CurrentImageTypeIndex]->nx(), $
                            (*infoP).DataObj.Data[(*infoP).State.CurrentImageTypeIndex]->ny()]

(*infoP).State.CenterPixel = round((*infoP).State.ImageSize/2.)

TmpString = (*infoP).DataObj.Data[(*infoP).State.CurrentImageTypeIndex]->FileName()

Parts=strsplit(TmpString,'/',/extract)
Widget_Control, (*infoP).IDs.FileNameID, Set_Value=Parts[n_elements(Parts)-1]
_sca=(*infoP).DataObj.Data[(*infoP).State.CurrentImageTypeIndex]->getKeyword('PARTNAME',_status)
; Make sure _sca is a string...
if (_status) then _sca='UNKOWN' else _sca=strtrim(_sca,2)
Widget_Control, (*infoP).IDs.SCAID, Set_Value=_sca

(*infoP).State.ImageMode = (*infoP).State.ImageModeList[(*infoP).State.CurrentImageTypeIndex]
Widget_Control,(*infoP).IDs.ImageModeID, Set_DropList_Select=(*infoP).State.CurrentImageTypeIndex

(*infoP).State.ImageRead=1B

end

; An ImageObject wrapper to fascilitate reading of newly created
; images during processing. 
pro ImageObject, infoP, index, objectName, filename

; Tag all data types as not loaded. 
(*infoP).State.ImageLoaded[index]=0B

filename = FILE_SEARCH(filename)

if (filename ne "") then begin  ; We have data file
    objectName=strtrim(objectName,2)
    if (index eq 2) then begin ; differentiate between slp and wfs images. 
        _tmpstr = strmid(filename,7,3,/reverse_offset)
        if (_tmpstr eq 'slp') then $ 
          (*infoP).DataObj.Data[index] = Obj_New(objectName,filename) $
        else $
          (*infoP).DataObj.Data[index] = Obj_New(objectName,filename,/wfs)
    endif else begin 
        (*infoP).DataObj.Data[index] = Obj_New(objectName,filename,buffer=(*infoP).State.Buffer)
    endelse 
    if Obj_Valid((*infoP).DataObj.Data[index]) then begin 
        (*infoP).State.ImageLoaded[index]=1B
    endif else begin            ; no data destroy any old instances. 
        (*infoP).State.ImageLoaded[index]=0B
        if Obj_Valid((*infoP).DataObj.Data[index]) then Obj_Destroy,(*infoP).DataObj.Data[index]
    endelse
endif 

end

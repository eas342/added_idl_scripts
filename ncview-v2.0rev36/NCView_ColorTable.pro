pro NCView_GetCT, id, infoP 

loadct, id, /silent, bottom=8
tvlct, r, g, b, 8, /get

r = r[0:(*infoP).Colors.NColors-2]
g = g[0:(*infoP).Colors.NColors-2]
b = b[0:(*infoP).Colors.NColors-2] 

(*(*infoP).Colors.RVect) = r
(*(*infoP).Colors.GVect) = g
(*(*infoP).Colors.BVect) = b

(*infoP).Colors.CurrentStretch = Ptr_New(long(findgen((*infoP).Colors.NColors)))

end

; pro NCView_InitColors

; rtiny = [0, 1, 0, 0, 0, 1, 1, 1]
; gtiny = [0, 0, 1, 0, 1, 0, 1, 1]
; btiny = [0, 0, 0, 1, 1, 1, 0, 1]
; tvlct, 255*rtiny, 255*gtiny, 255*btiny

; tvlct, [255],[255],[255], !d.table_size-1

; end

pro NCView_StretchCT, infoP, Brightness, Contrast,  GetCursor=GetCursor

ContrastScale=0.75

if (keyword_set(GetCursor)) then begin 
    (*infoP).Colors.Brightness = Brightness/float((*infoP).State.ImageWindowSize[0])
    (*infoP).Colors.Contrast = Contrast/float((*infoP).State.ImageWindowSize[1])
    x = (*infoP).Colors.Brightness*((*infoP).Colors.NColors-1)
    y = (*infoP).Colors.Contrast*((*infoP).Colors.NColors-1)*ContrastScale > 2
endif else begin 
    if (n_elements(Brightness) eq 0 or n_elements(Contrast) eq 0) then begin 
        x = (*infoP).Colors.Brightness*((*infoP).Colors.NColors-1)
        y = (*infoP).Colors.Contrast*((*infoP).Colors.NColors-1)*ContrastScale > 2
    endif else begin 
        x = Brightness*((*infoP).Colors.NColors-1)
        y = Contrast*((*infoP).Colors.NColors-1)*ContrastScale > 2 
    endelse 
endelse 

high = x+y 
low = x-y 
diff = (high-low) > 1

slope = float((*infoP).Colors.NColors-1)/diff 
intercept = -slope*low
p = long(findgen((*infoP).Colors.NColors)*slope+intercept)
Ptr_Free,(*infoP).Colors.CurrentStretch
(*infoP).Colors.CurrentStretch = Ptr_New(p)
tvlct, (*(*infoP).Colors.RVect)[p],(*(*infoP).Colors.GVect)[p],(*(*infoP).Colors.BVect)[p],8

end









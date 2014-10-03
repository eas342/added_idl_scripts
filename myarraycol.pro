function myarraycol,ncol,psversion=psversion
;; This function generates an array of colors that is ncol long
;; if there are many colors, it begins to reuse the colors
;; psversion - uses colors 

if n_elements(ncol) EQ 0 OR ncol LE 0 then begin
   print,"# of Colors must be 1 or greater"
   return,0
endif

if keyword_set(psversion) then begin
   colorChoices = mycol(['black','red','dgreen',$
                         'blue','dblue',$
                         'magenta','brown','purple','pink'])
endif else begin
   colorChoices = mycol(['white','green','lblue',$
                         'pink','yellow','orange',$
                         'turquoise'])
endelse

nchoices = n_elements(colorChoices)
colorArray = colorChoices[lindgen(ncol) mod nchoices]
return,colorArray

end

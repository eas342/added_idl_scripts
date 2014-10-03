function mycol,col
;; My handwritten function for doing colors in X windows
;; 

ncol = n_elements(col)
if ncol EQ 0 then print,"Error. No color entered to mycol!"
if ncol EQ 1 then output = 0l else output = lonarr(ncol)

for i=0,ncol-1l do begin
   if ncol GT 1 then input = col[i] else input = col
   case col[i] of 
      'red':     num = 255l
      'green':   num =      256l*255l
      'blue':    num =               +256l*256l*255l
      'lblue':   num =      256l*255l+256l*256l*255l
      'dblue':   num =               +256l*256l*102l
      'white':   num = 255l+256l*255l+256l*256l*255l
      'magenta': num = 255l          +256l*256l*255l
      'yellow':  num = 255l+256l*255l
      'orange':  num = 255l+256l*102l
      'gold':    num = 255l+256l*204l
      'brown':   num = 102l+256l* 51l
      'purple':  num = 102l+256l* 51l+256l*256l*204l
      'pink':    num = 255l+256l*102l+256l*256l*204l
      'dgreen':  num =     256l*125l
      'turquoise':num =      256l*153l+256l*256l*153l
      'black':   num =   0l
      'main': begin
         if !d.name EQ 'PS' then num = 0l else begin ;;white background
            num = 255l+256l*255l+256l*256l*255l ;; black background
         endelse
      end
      else: begin
         num = 256l*256l*255l+256l*255l+255l
         print,"Color not found in list!!"
      end
   endcase
   if ncol EQ 1 then output = num else begin
      output[i] = num
   endelse
endfor

return, output
end

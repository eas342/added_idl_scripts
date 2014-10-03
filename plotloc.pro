function plotloc,frac,y=y
;; Calculates a fractional place in a plot so it can be done with one
;; simple all
;; y - for the y axis (x is the default axis)

if keyword_set(y) then begin
   size = !y.crange[1] - !y.crange[0]
   start = !y.crange[0]
endif else begin
   size = !x.crange[1] - !x.crange[0]
   start = !x.crange[0]
endelse

return,frac * size + start

end

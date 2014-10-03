function threshold,xorig,low=low,high=high,mult=mult
;; This function takes an array and gives you the low% and high% levels of
;; the population. Useful for plotting data with huge outlies due to
;; things like cosmic rays
;; x - array to take thresholds from
;; low - an optional keyword to set the fraction (default 0.05)
;; high - an optional keyword to set the fraction (default 0.95)
;; mult - by default=0.2, the program gives an extra mult increase in
;;          range becuase you might want to see the top/bottom percentages

if n_elements(low) EQ 0 then low = 0.05D
if n_elements(high) EQ 0 then high = 0.95D
if n_elements(mult) EQ 0 then mult = 1.2D
x = xorig ;; copy the array so you don't modify it

;; ignore all NaNs
goodp = where(finite(x))
if n_elements(goodp) LT 3 then begin
   showvals = [!values.f_nan,!values.f_nan]
endif else begin
   x = x[goodp]
   sortx = sort(x)
   length = n_elements(x)
   xlowerL = x[sortx[floor(low *float(length))]]
   xupperL = x[sortx[floor(high * float(length))]]
   
   fullRange = (xupperL - xlowerL)
   
   xlowerShow = xlowerL - mult * fullRange
   xupperShow = xupperL + mult * fullRange
   showvals = [xlowerShow,xupperShow]
endelse

return,showvals

end

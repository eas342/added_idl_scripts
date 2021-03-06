function myexp,x,zerout=zerout
  ;; modified exponential function - when the argument is less than
  ;;  a given, then I just set the value to zero
  lowp = where(x LT -70D)
  hip = where(x GE -70D)
  y = x * 0D
  if lowp NE [-1] then y[lowp] = 0D 
  if hip NE [-1] then y[hip] = exp(x[hip])
  if n_elements(x) EQ 1 then return,y[0] else begin
     return,y
  endelse
end

function checkrange,X,low,high
;; Ensures a value within the specified range
;; if X is within the range, it will keep it, otherwise it will return
;; an endpoint it has gone over
;; for example, you want to sum a box of pixels that goes beyond the
;; array, it will truncate the box at the end points
Y = X
lowp = where(X LT low)
if lowp NE [-1] then Y[lowp] = low
highp = where(X GT high)
if highp NE [-1] then Y[highp] = high
return,Y

end

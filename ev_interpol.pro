function ev_interpol, VV, XX, XOUT
;; modified by Everett Schlawin, beginning on 9.17.12 to return NAN
;; over NAN points
  regular = n_params(0) eq 2
  
                                ; Make a copy so we don't overwrite the input arguments.
  v = vv
  x = xx
  m = N_elements(v)             ;# of input pnts
  
  if (regular) then nOut = LONG(x)
  
                                ; Filter out NaN values in both the V and X arguments.
  isNAN = FINITE(v, /NAN)
  isNanx = finite(x, /nan)
  if (~regular) then isNAN or= FINITE(x, /NAN)
  
  if (~ARRAY_EQUAL(isNAN, 0)) then begin
     good = WHERE(~isNAN, ngood,complement=bad)
     if (ngood gt 0 && ngood lt m) then begin
;      v = v[good]
        if (regular) then begin
                                ; We supposedly had a regular grid, but some of the values
                                ; were NaN (missing). So construct the irregular grid.
           regular = 0b
           x = LINDGEN(m)
           xout = FINDGEN(nOut) * ((m-1.0) / ((nOut-1.0) > 1.0)) ;Grid points
        endif
;      x = x[good]
     endif
  endif
  if isNanx NE [-1] then begin ;; get rid of all point where x is NAN, but we'll keep points where y is nan
     good = where(isNanx EQ 0)
     regular = 0b
     x = x[good]
     v = v[good]
  endif
  
                                ; get the number of input points again, in case some NaN's got filtered
  m = N_elements(v)
  type = SIZE(v, /TYPE)
  
  if regular && $               ;Simple regular case?
     ((keyword_set(ls2) || keyword_set(quad) || keyword_set(spline)) eq 0) $
  then begin
     xout = findgen(nOut)*((m-1.0)/((nOut-1.0) > 1.0)) ;Grid points in V
     xoutInt = long(xout)                              ;Cvt to integer
     case (type) of
        1: diff = v[1:*] - FIX(v)
        12: diff = v[1:*] - LONG(v)
        13: diff = v[1:*] - LONG64(v)
        15: diff = LONG64(v[1:*]) - LONG64(v)
        else: diff = v[1:*] - v
     endcase
     return, V[xoutInt] + (xout-xoutInt)*diff[xoutInt] ;interpolate
  endif
  
  if regular then begin                                   ;Regular intervals??
     xout = findgen(nOut) * ((m-1.0) / ((nOut-1.0) > 1.0)) ;Grid points
     s = long(xout)                                        ;Subscripts
  endif else begin                                         ;Irregular
     if n_elements(x) ne m then $
        message, 'V and X arrays must have same # of elements'
     s = VALUE_LOCATE(x, xout) > 0L < (m-2) ;Subscript intervals.
  endelse
  
                                ; Clip interval, which forces extrapolation.
                                ; XOUT[i] is between x[s[i]] and x[s[i]+1].
  
;  CASE (1) OF
;     
;     KEYWORD_SET(ls2): BEGIN    ;Least square fit quadratic, 4 points
;        s = s > 1L < (m-3)      ;Make in range.
;        p = replicate(v[0]*1.0, n_elements(s)) ;Result
;        for i=0L, n_elements(s)-1 do begin
;           s0 = s[i]-1
;           p[i] = ls2fit(regular ? s0+findgen(4) : x[s0:s0+3], v[s0:s0+3], xout[i])
;        endfor
;     END
;     
;     KEYWORD_SET(quad): BEGIN   ;Quadratic.
;        s = s > 1L < (m-2)      ;In range
;        x1 = regular ? float(s) : x[s]
;        x0 = regular ? x1-1.0 : x[s-1]
;        x2 = regular ? x1+1.0 : x[s+1]
;        p = v[s-1] * (xout-x1) * (xout-x2) / ((x0-x1) * (x0-x2)) + $
;            v[s] *   (xout-x0) * (xout-x2) / ((x1-x0) * (x1-x2)) + $
;            v[s+1] * (xout-x0) * (xout-x1) / ((x2-x0) * (x2-x1))
;     END
;     
;     KEYWORD_SET(spline): BEGIN
;        s = s > 1L < (m-3)             ;Make in range.
;        p = replicate(v[0], n_elements(s)) ;Result
;        sold = -1
;        for i=0L, n_elements(s)-1 do begin
;           s0 = s[i]-1
;           if sold ne s0 then begin
;              x0 = regular ? s0+findgen(4): x[s0: s0+3]
;              v0 = v[s0: s0+3]
;              q = spl_init(x0, v0)
;              sold = s0
;           endif
;           p[i] = spl_interp(x0, v0, q, xout[i])
;        endfor
;     END
;     
;     ELSE: begin                ;Linear, not regular
        case (type) of
           1: diff = v[s+1] - FIX(v[s])
           12: diff = v[s+1] - LONG(v[s])
           13: diff = v[s+1] - LONG64(v[s])
           15: diff = LONG64(v[s+1]) - LONG64(v[s])
           else: diff = v[s+1] - v[s]
        endcase
        
        p = (xout-x[s])*diff/(x[s+1] - x[s]) + v[s]
;    if n_elements(bad) GT 1 then begin
;       nanpt = VALUE_LOCATE(xx[bad], xout) > 0L < (m-2) ;get the
;       subscripts where points are bad
;       badInterPoints = where(s EQ 
;       pospoints = where(nanpt GE 0)
;       p[nanpt[pospoints]] = !values.f_nan                         ;; make these points nan
;       stop
;    endif
;     end
;     
;  ENDCASE
  
  RETURN, p
end


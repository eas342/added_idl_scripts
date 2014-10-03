pro histocompare,y
  ;; Compares a histogram of an array to a gaussian with
  ;; sigma=robust_sigma(y)
  sigTemp = robust_sigma(y)
  custbsize = sigTemp/10E
  datahistY = histogram(y,binsize=custbsize,locations=datahistX)
  plot,datahistX,datahistY,$
       xtitle=['Data'],ytitle='Counts',$
       xrange=(median(y) + [-10E,+10E]*sigTemp),psym=10
  xgaussian = findgen(100)/(100E - 1E) * (!x.crange[1] - !x.crange[0])+$
              !x.crange[0]
  dx = xgaussian[1] - xgaussian[0]
  totY = total(datahistY) * custbsize
  ygaussian = gaussian(xgaussian,[(totY )/sqrt(2E * !DPI * sigTemp^2),median(y),sigTemp])
  oplot,xgaussian,ygaussian,color=mycol('yellow'),linestyle=2
  legend,['Data Distribution','Gaussian Curve'],linestyle=[0,2],color=[!p.color,mycol('yellow')]
end

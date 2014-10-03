pro blockify,x,y,xb,yb ; turns x and y vector into blocky vectors xb and yb
  assert,n_elements(x),'=',n_elements(y),'Error in Blockify - x and y are not the same length'
  assert,n_elements(x),'>=',3,"Error, can't blockify less than 3 points"
  l=n_elements(x)
  xb=dblarr(l*2)
  yb=dblarr(l*2)
  for i=0,l-2 do begin
     xb[i*2]=x[i]-(x[i+1]-x[i])/2.0D
     xb[i*2+1]=x[i]+(x[i+1]-x[i])/2.0D
     yb[i*2]=y[i]
     yb[i*2+1]=y[i]
  endfor
  xb[l*2-2]=x[l-1]-(x[l-1]-x[l-2])/2.0D
  xb[l*2-1]=x[l-1]+(x[l-1]-x[l-2])/2.0D
  yb[l*2-1]=y[l-1]
  yb[l*2-2]=y[l-1]
end

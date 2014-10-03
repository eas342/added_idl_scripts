function specsmooth,wavl,f,res,refwav=refwav
;; Takes a spectrum (f) vs wavelength (wavl) and smooths to the
;; resolution (res) assuming even wavelength spacing
;; Uses a Gaussian Kernel with FWHM = 1/res
;; refwav - optional parameter to describe the resolution at a given wavelength

  if n_elements(refwav) EQ 0 then refwav = median(wavl)
  FWHM = refwav / res
  sigma = FWHM/2.3548E
  nwav = n_elements(wavl)
  tabinv,wavl,[refwav],refInd
  refInd = round(refInd[0]) ;; make it a scalar integer
  dwav = abs(wavl[refInd] - wavl[refInd - 1l])

  ;; Get the size of the needed kernel (3 X FWHM)
  nkern = round(FWHM * 1.5E /dwav) * 2l + 1l
  xkern = (findgen(nkern) - float(nkern/2l)) * dwav
  yraw = gaussian(xkern,[1E,0E,sigma])
  ykern = yraw / total(yraw) ;; normalize

  return,convol(f,ykern,/center)

end


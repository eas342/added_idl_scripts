pro ev_compile_red

;; Compiles the reduction scripts
cd,current=origDir

reductionDir = reduction_dir()
cd,reductionDir
list = file_search('.','*.pro')

;; For some reason, toggle_fits has to be compiled before some other
;; things
togFile = where(list EQ './toggle_fits.pro')
file_compile,list[togFile]

for i=0l,n_elements(list)-1l do begin
   file_compile,list[i]
endfor

;; return to current directory
cd,origDir

end

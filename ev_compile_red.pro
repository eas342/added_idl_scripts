pro ev_compile_red

;; Compiles the reduction scripts
cd,current=origDir

reductionDir = reduction_dir()
cd,reductionDir
list = file_search('.','*.pro')

for i=0l,n_elements(list)-1l do begin
   file_compile,list[i]
endfor

;; return to current directory
cd,origDir

end

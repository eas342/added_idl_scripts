function clobber_dir,f,extension=extension,dir=dir
;; Clobbers the directory info and just gives you the filename
;; for example, turns ../docs/directory/filename.txt into
;; filename.txt
;; dir - outputs the directory
split = strsplit(f,'/',/extract)
nsplit = n_elements(split)
s = split[nsplit - 1l]
if nsplit GT 1 then begin
   st1 = strpos(f,'/',/reverse_search)
   dir = strmid(f,0,st1)+'/'
endif else dir = ''
if keyword_set(extension) then begin
   ;; also clobber the extension
   s = clobber_exten(s)
endif
return,s
end

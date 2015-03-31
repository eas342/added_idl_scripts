function clobber_dir,f,extension=extension
;; Clobbers the directory info and just gives you the filename
;; for example, turns ../docs/directory/filename.txt into
;; filename.txt
split = strsplit(f,'/',/extract)
nsplit = n_elements(split)
s = split[nsplit - 1l]

if keyword_set(extension) then begin
   ;; also clobber the extension
   s = clobber_exten(s)
endif
return,s
end

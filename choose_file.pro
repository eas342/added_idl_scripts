function choose_file,searchDir=searchDir,filetype=filetype,$
                     all=all,filter=filter
;; Returns a user-chosen file from a directory. The default directory
;; is the current one IDL was run from
;; searDir is a custom search directory
;; filetype is the ending file extension ('fits' will do *.fits)
;; all -- return all files matching file type
;; filter - lets the user specify a filter within the directory

  ;; get the current directory
  cd,c=currentd
  ;; Search the given directory
  if n_elements(searchDir) EQ 0 then searchDir = '' else begin
     searchDir = searchDir+'/'
  endelse
  if n_elements(filetype) EQ 0 then filetype = ''

  ;; If it starts with /, then do the absolute path, not relative
  if keyword_set(filter) then begin
     if strmid(filter,0,1) EQ '/' then begin
        currentd = ''
     endif
     searchPath = currentd+'/'+searchDir+filter
  endif else begin 
     searchPath = currentd+'/'+searchDir+'*'+filetype
  endelse

  fileopt = file_search(searchPath)
  print,'Files found w/ Criteria:'
  for i=0l,n_elements(fileopt)-1l do begin
     trimst = strsplit(fileopt[i],'/',/extract)
     print,string(i,Format='(I5)'),' ',trimst(n_elements(trimst)-1l)
  endfor
  if keyword_set(all) then begin
     confirm=''
     read,'(y)es to continue?',confirm
     if confirm EQ 'y' or confirm EQ 'Y' then begin
        return,fileopt
     endif else return,''
  endif else begin
     read,'File Choice: ',filechoice
     return, fileopt[filechoice]
  endelse

end

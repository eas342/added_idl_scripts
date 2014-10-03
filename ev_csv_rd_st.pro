function ev_csv_rd_st,filen; read a csv file into a structure
nrows = file_lines(filen)
;; get the tag names
openr,1,filen
tagst = ''
readf,1,tagst
tags = strtrim(strsplit(tagst,',',/extract),1)
ntags = n_elements(tags)

;; get the data
filed = ''
file2d = strarr(nrows-1l,ntags)
for i=0l,nrows-2l do begin
   readf,1,filed
   file2d[i,*] = strtrim(strsplit(filed,',',/extract,/preserve_null),1)
endfor

;; make structure
st = create_struct(tags[0],file2d[*,0])
for j=1l,ntags-1l do begin
   st = create_struct(st,tags[j],file2d[*,j])
endfor

close,1
free_lun,1

return,st
end

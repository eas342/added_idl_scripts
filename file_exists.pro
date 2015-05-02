function file_exists,filen

filesch = file_search(filen)
if filesch EQ [''] then begin
   return,0
endif else return,1

end

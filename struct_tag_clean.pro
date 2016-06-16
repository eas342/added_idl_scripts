function struct_tag_clean,intag
    ;; Checks if the tag names are weird and replaces them 
    
    replaceTypes = [' ','(',')','/','\','.','-','=','#']
    nTypes = n_elements(replaceTypes)
    
    outtag = intag
    for j=0l,nTypes-1l do begin
      outtag = strjoin(strsplit(outtag,replaceTypes[j],/extract),'_')
    endfor
    return, outtag
end

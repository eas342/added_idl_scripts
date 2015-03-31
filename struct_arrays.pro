function struct_arrays,struct
;; Converts a structure with arrays to an array of structures

tags = tag_names(struct)
ntags = n_elements(tags)
for i=0l,ntags-1l do begin
   ev_add_tag,Arr,tags[i],struct.(i)[0]
endfor
nlength = n_elements(struct.(0))
Arr = replicate(Arr,nlength)
for i=0l,ntags-1l do begin
   Arr[*].(i) = struct.(i)[*]
endfor

return,Arr

end

pro ev_add_tag,struct,tag,val
;; Takes an array of structures and adds a tag to all of them
;outS. USing Coyote GUIDE:
; http://www.idlcoyote.com/code_tips/addfield.html
;; if val is a 1 element array, it is repeated
;; if val is an array with as many elements as struct, they get added
;; to each structure

npt = n_elements(struct)
if npt EQ 0 then begin
   struct = create_struct(tag,val)
endif else begin
   if tag_exist(struct,tag,index=index) then begin
      struct.(index) = val
   endif else begin
      if npt EQ 1 then begin
         newArr = create_struct(struct,tag,val)
      endif else begin
         tags = tag_names(struct)
         ntags = n_elements(tags)
         newStruct = create_struct(struct[0],tag,val[0])
         newArr = replicate(newStruct,npt)
         struct_assign,struct,newArr
         
         if n_elements(val) EQ npt then begin
            newArr[*].(ntags) = val
         endif else begin
            if n_elements(val) GT 1 then begin
               print,"Data array size different from number of structures in array"
            endif else newArr[*].(ntags) = val
         endelse
      endelse
      ;; Reassign the structure
      struct = newArr
   endelse

endelse

end

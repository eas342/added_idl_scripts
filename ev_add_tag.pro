pro ev_add_tag,struct,tag,val,noerase=noerase
;; Takes an array of structures and adds a tag to all of them
;outS. USing Coyote GUIDE:
; http://www.idlcoyote.com/code_tips/addfield.html
;; if val is a 1 element array, it is repeated
;; if val is an array with as many elements as struct, they get added
;; to each structure
;; noerase - don't erase the existing field if it already exists

npt = n_elements(struct)

cleantag = struct_tag_clean(tag)

if npt EQ 0 then begin
   struct = create_struct(cleantag,val)
endif else begin
   if tag_exist(struct,cleantag,index=index) then begin
      if keyword_set(noerase) then begin
         return
      endif
      if n_elements(struct) EQ 1 and $
         n_elements(struct.(index)) NE n_elements(val) then begin
         ev_undefine_tag,struct,cleantag
         if n_elements(struct) EQ 0 then begin
            struct = create_struct(cleantag,val)
         endif else struct = create_struct(struct,cleantag,val)
         ;; allow this option to increase the size of an array field
      endif else struct.(index) = val
   endif else begin
      if npt EQ 1 then begin
         newArr = create_struct(struct,cleantag,val)
      endif else begin
         tags = tag_names(struct)
         ntags = n_elements(tags)
         newStruct = create_struct(struct[0],cleantag,val[0])
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

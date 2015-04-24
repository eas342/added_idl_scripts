function quote_split,strin,delimiter
;; Splits a string by a delimiter
;; Also, it checks for pairs of quotes and ignores delimiters inside quotes

  maxiter = 3000l ;; max val to stop infinite loop
  start = 0l;; start of search
  i=0l ;; counter to stop infinite loop
  fulllength = strlen(strin);; full length of array
  prevPos = 0l ;; previous position
  while i LT maxiter and start LT fullLength do begin
     rest = strmid(strin,start,fullLength) ;; what you have left
     relPos = stregex(rest,'\'+delimiter+'|"')
     pos = relPos + start ;; location of either delimiter or quote
     case 1 of
        relpos EQ -1: begin
           ;; No delimiters or quotes left, include the remainder of the string
           ev_append,finalSplit,strmid(strin,prevPos,fullLength - prevPos)
           start = fulllength
        end
        strmid(strin,pos,1) EQ '"': begin
           ;; Quote - skip this section
           start = strpos(strin,'"',pos+1l) + 1l
           if start EQ -1 then message,'Unmatched quotations found'
           if start EQ fullLength then ev_append,finalSplit,strmid(strin,prevPos,fullLength - prevPos)
        end
        strmid(strin,pos,1) EQ delimiter: begin
           ;; Delimiter found, so split here
           ev_append,finalSplit,strmid(strin,prevPos,pos - prevPos)
           start = pos + 1l
           prevPos = start
           if start EQ fullLength then ev_append,finalSplit,strmid(strin,prevPos,fullLength - prevPos)
        end
     endcase
;     if n_elements(finalSplit) GT 0 then print,strmid(strin,0,start)
;     stop
     i = i+ 1l
  endwhile
  return,finalSplit
end

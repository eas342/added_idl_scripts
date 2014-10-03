pro assert,val1,compare,val2,atext
  flag=0
  missed=0
  case compare of
     "=": if(val1 NE val2) then flag=1
     ">": if(val1 LE val2) then flag=1
     "<": if(val1 GE val2) then flag=1
     "<=": if(val1 GT val2) then flag=1
     ">=": if(val1 LT val2) then flag=1
     "!=": if(val1 EQ val2) then flag=1
     else: begin
        flag =1
        print,"There was a syntax error in your use of an assert command"
        missed =1
     endelse 
  endcase
  if(flag EQ 1 and missed EQ 0) then begin
     print, "****************** Assert Thrown!! *********************"
     print,atext
     endif
        
end

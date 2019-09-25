pro NCView_Resize,infoP

;; Get the new size. 
Widget_Control, (*infoP).IDs.TopLevelID, Tlb_Get_Size=SizeEvent


NewXSize = (SizeEvent[0] - (*infoP).State.BasePad[0]) 
NewYSize = (SizeEvent[1] - (*infoP).State.BasePad[1])

Widget_Control, (*infoP).IDs.WidImageID, Scr_XSize=NewXSize, $
                Scr_YSize=NewYSize
Widget_Control, (*infoP).IDs.WidColorBarID, Scr_XSize=NewXSize, $
                Scr_YSize=(*infoP).Images.ColorBarHeight

(*infoP).State.ImageWindowSize = [NewXSize,NewYSize]

NCView_UpdateColorBar,infoP

;Widget_Control, (*infoP).IDs.TopLevelID, /clear_events
;Widget_Control, (*infoP).IDs.DrawImageID, /sensitive, /input_focus      

end

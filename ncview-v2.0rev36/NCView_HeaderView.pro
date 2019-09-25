pro NCView_HeaderView_Cleanup, TopLevelID


end

pro NCView_HeaderResize, infoP

Widget_Control, (*infoP).IDs.HeaderViewBaseID, Tlb_Get_Size=SizeEvent

; These are pixels sizes...
deltaXSize = (SizeEvent[0] - (*infoP).State.HeaderScrSize[0])
deltaYSize = (SizeEvent[1] - (*infoP).State.HeaderScrSize[1])

(*infoP).State.HeaderScrSize = SizeEvent

HeaderViewBaseGeometry = Widget_Info((*infoP).IDs.HeaderViewBaseID, /Geometry)

; Restrict it to be a max of 90% of screen real estate...
newHeaderXSize=(HeaderViewBaseGeometry.scr_xsize+deltaXSize) < 0.9*(*infoP).State.ScreenSize[0]
newHeaderYSize=(HeaderViewBaseGeometry.scr_ysize+deltaYSize) < 0.9*(*infoP).State.ScreenSize[1]

newTextWidth=newHeaderXSize+(*infoP).State.HeaderTextOffset[0]
newTextHeight=newHeaderYSize+(*infoP).State.HeaderTextOffset[1]

Widget_Control, (*infoP).IDs.HeaderViewBaseID, XSize=newHeaderXSize, $
                YSize=newHeaderYSize

Widget_Control, (*infoP).IDs.HeaderViewTextID, Scr_XSize=newTextWidth, $
                Scr_YSize=newTextHeight


end

pro NCView_HeaderView_Event, event

Widget_Control, event.id, Get_UValue=UValue
EventType = Tag_Names(event,/structure)
Widget_Control, event.top, Get_UValue=infoP

case EventType of
    
    'WIDGET_BASE' : begin 
        NCView_HeaderResize,infoP
    end
    else : begin 
        case UValue of
            'DismissHeaderView' : begin 
                Widget_Control, event.top, /destroy
            end
        endcase
    end
endcase

end


pro NCView_HeaderView, infoP

_imgIdx=(*infoP).State.CurrentImageTypeIndex

thisHeader=(*infoP).DataObj.Data[_imgIdx]->Header()

TextWidthPixels = (*infoP).State.HeaderScrSize[0]+(*infoP).State.HeaderTextOffset[0]
TextHeightPixels = (*infoP).State.HeaderScrSize[1]+(*infoP).State.HeaderTextOffset[1]

TmpTitle = 'Header View'
(*infoP).IDs.HeaderViewBaseID = Widget_Base(Group_Leader=(*infoP).IDs.TopLevelID, $
                                            Title=TmpTitle,/Base_Align_Right, /Column, $
                                            UValue='HeaderViewBase', /tlb_size_events, $
                                            XSize=(*infoP).State.HeaderScrSize[0], $
                                            YSize=(*infoP).State.HeaderScrSize[1], $
                                            /Align_Left $
                                           )

(*infoP).IDs.HeaderViewTextID = Widget_Text((*infoP).IDs.HeaderViewBaseID, /scroll, $
                                            value=thisHeader, $
                                            Scr_XSize=TextWidthPixels, $
                                            Scr_YSize=TextHeightPixels $
                                           )

ButtonBase = Widget_Base((*infoP).IDs.HeaderViewBaseID, /Row)
DismissHeaderView = Widget_Button(ButtonBase, Value='Done', $
                                  UValue='DismissHeaderView', $
                                  /Align_Left) 

Widget_Control, (*infoP).IDs.HeaderViewBaseID, /realize
Widget_Control, (*infoP).IDs.HeaderViewBaseID, Set_UValue=infoP
Widget_Control, (*infoP).IDs.HeaderViewBaseID, tlb_get_size=tmp_event
Xmanager, 'NCView_HeaderView', (*infoP).IDs.HeaderViewBaseID, /no_block, Cleanup='NCView_HeaderView_Cleanup'


end

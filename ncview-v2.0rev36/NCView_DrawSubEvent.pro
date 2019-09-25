pro NCView_DrawMotion, event, infoP 

_imgIdx=(*infoP).State.CurrentImageTypeIndex

; If we are in a motion event, don't update the State.Coord value.  That only gets
; updated on button presses to select the current pixel. 
;(*infoP).State.Coord = round ( (0.5 > ([event.x,event.y]/(*infoP).State.ZoomFactor + $
;                                       (*infoP).State.Offset) < $
;                                ((*infoP).State.ImageSize - 0.5)) - 0.5)
;_x = (*infoP).State.Coord[0]
;_y = (*infoP).State.Coord[1]

_thisCoord = round ( (0.5 > ([event.x,event.y]/(*infoP).State.ZoomFactor + $
                                       (*infoP).State.Offset) < $
                                ((*infoP).State.ImageSize - 0.5)) - 0.5)
_x = _thisCoord[0]
_y = _thisCoord[1]

_value = (*infoP).DataObj.Data[_imgIdx]->Pixel(_x,_y, $
                                               id=(*infoP).DataObj.Data[_imgIdx]->getCurFrame())

PosString = string(_x,_y,_value,format='("(",i5,",",i5,") ",g12.5)')
Widget_Control,(*infoP).IDs.LocationID, Set_Value=PosString

end

pro NCView_NewCenter, event, infoP
(*infoP).State.CurrentPixel = $
  round ( (0.5 > ([event.x,event.y]/(*infoP).State.ZoomFactor + $
                  (*infoP).State.Offset) $
           < ((*infoP).State.ImageSize - 0.5)) - 0.5)
(*infoP).State.CenterPixel = (*infoP).State.CurrentPixel 
NCView_UpdateDisplay, infoP  
end

pro NCView_DrawZoom, event, infoP

if (event.type eq 0) then begin ; A button press. 
    case event.press of        
        1 : NCView_Zoom, 'ZoomIn', infoP  ; Left mouse button
        2 : NCView_Zoom, 'none', infoP    ; Middle mouse button
        4 : NCView_Zoom, 'ZoomOut', infoP ; Right mouse button
    endcase
endif

; If just moving with zoom activated, just move.
if (event.type eq 2) then NCView_DrawMotion, event, infoP

end

pro NCView_DrawColor, event, infoP

case event.type of 
    0 : begin  ; A button press
        if (event.press eq 1) then begin  ; Left mouse button clicked. 
            (*infoP).State.ButtonPressed=1
            NCView_StretchCT, infoP, event.x, event.y, /getcursor
            NCView_UpdateColorBar, infoP
        endif else NCView_Zoom, 'none', infoP ; not held down for motion.
    end
    1 : begin  ; A button released
        (*infoP).State.ButtonPressed=0
        NCView_UpdateDisplay, infoP
        NCView_DrawMotion, event, infoP
    end
    2 : begin  ; A motion event
        ; What happens depends on whether a button is pressed or not. 
        if ((*infoP).State.ButtonPressed) then begin            
            NCView_StretchCT, infoP, event.x, event.y, /getcursor 
            NCView_UpdateDisplay, infoP
        endif else begin 
            NCView_DrawMotion, event, infoP
        endelse 
    end

endcase 

end

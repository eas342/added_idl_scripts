pro NCView_PixHistory_Cleanup, TopLevelID

end


;; Top level handler for draw events when MouseMode == Pixel History
pro NCView_DrawPixHistory, event, infoP

;; Realize the history window
case event.type of
    0 : begin  ; A button press
        if (event.press eq 1 or event.press eq 2 or event.press eq 4) then begin 
            ;; Register and display if it's not already displayed. 
            if (not (XRegistered('NCView_PixHistory', /noshow))) then $
              NCView_PixHistory, event, infoP
        endif 
        ;; Plot the pixel
        NCView_PixHistory_Configure, infoP
    end
    1 : begin  ; A button release
        ; who cares
    end
    2 : begin  ; A motion event 
        ;; just do motion
        NCView_DrawMotion, event, infoP
    end
endcase 

end

;; test

pro NCView_PixHistory, event, infoP

if (not (XRegistered('NCView_PixHistory', /noshow))) then begin 

    TmpTitle = 'Pixel Time History'
    (*infoP).IDs.PixHistoryBaseID  = Widget_Base(Group_Leader=(*infoP).IDs.TopLevelID, $
                                                 Title=TmpTitle, Row=1, /tlb_size_events)
    
    (*infoP).IDs.WidPixHistoryID = Widget_Draw((*infoP).IDs.PixHistoryBaseID, UValue='PixPlot', $
                                               Scr_XSize=(*infoP).Images.DefaultPlotSize[0], $
                                               Scr_YSize=(*infoP).Images.DefaultPlotSize[1], $
                                               Button_Events=1)
    

    StateBaseID = Widget_Base((*infoP).IDs.PixHistoryBaseID, Column=1, /Base_Align_Right, $
                               UValue='StateBase')
    ActionBaseID = Widget_Base((*infoP).IDs.PixHistoryBaseID, Column=1, /Base_Align_RIght, $
                               UValue='ActionBase')
    
    
    (*infoP).Plot.LocationID = Widget_Label(StateBaseID,Value=(*infoP).Plot.PixelString, $
                                            UValue='PixelID',Frame=1)

    (*infoP).Plot.PixelXID = CW_Field(StateBaseID, UValue='xpix',Title='X',Value=(*infoP).State.Coord[0], $
                                      /return_events, XSize=12)
    (*infoP).Plot.PixelYID = CW_Field(StateBaseID, UValue='ypix',Title='Y',Value=(*infoP).State.Coord[1], $
                                      /return_events, XSize=12)
    (*infoP).Plot.MinXTextID = CW_Field(StateBaseID, UValue='xmin',/floating, Title='X Min', $
                          Value=(*infoP).Plot.MinX, /return_events, XSize=12)
    (*infoP).Plot.MaxXTextID = CW_Field(StateBaseID, UValue='xmax', /floating, Title='X Max', $
                          Value=(*infoP).Plot.MaxX, /Return_Events, XSize=12)
    (*infoP).Plot.MinYTextID = CW_Field(StateBaseID, UValue='ymin',/floating, Title='Y Min', $
                          Value=(*infoP).Plot.MinY, /return_events, XSize=12)
    (*infoP).Plot.MaxYTextID = CW_Field(StateBaseID, UValue='ymax', /floating, Title='Y Max', $
                          Value=(*infoP).Plot.MaxY, /Return_Events, XSize=12)

    (*infoP).Plot.SlopeTextID = CW_Field(StateBaseID, UValue='slope',/floating, Title='Slope', $
                                         Value=0, XSize=12)
    (*infoP).Plot.SlopeETextID = CW_Field(StateBaseID, UValue='slopee',/floating, Title='+/-', $
                                         Value=0, XSize=12)
    if (*infoP).State.ImageLoaded[2] AND NOT (*infoP).State.ImageLoaded[3] then _titleTxt='Est. Y-Int' else _titleTxt='Y-Int'
    (*infoP).Plot.InterceptTextID = CW_Field(StateBaseID, UValue='intercept', /floating, Title=_titleTxt, $
                                         Value=0, XSize=12)
    (*infoP).Plot.InterceptETextID = CW_Field(StateBaseID, UValue='intercepte' ,/floating, Title='+/-', $
                                         Value=0, XSize=12)
    (*infoP).Plot.RestoreRangeID = Widget_Button(StateBaseID, Value='Restore', $
                                                 UValue='RestoreRange')

    PlotSwitchBaseID = Widget_Base(ActionBaseID, Row=1, /Base_Align_Right, /Exclusive)
    PlotRampID = Widget_Button(PlotSwitchBaseID, Value='Ramp', UValue='ramp')
    PlotDifferenceID = Widget_Button(PlotSwitchBaseID, Value='Difference', UValue='difference')

    PlotRampSwitchBaseID = Widget_Base(ActionBaseID, Row=1, /Base_Align_Right, /Exclusive)
    PlotRawRampID = Widget_Button(PlotRampSwitchBaseID, Value='Raw', UValue='raw')
    PlotRedRampID = Widget_Button(PlotRampSwitchBaseID, Value='Red', UValue='red')

    ; When we realize the plot window, force it to be in ramp plotting mode
    Widget_Control, PlotRampID, Set_Button=1
    (*infoP).State.RampPlotted=1
    ; ...and default to red ramp if we have it, otherwise, raw.
    if (*infoP).State.ImageLoaded[1] then begin 
        Widget_Control, PlotRedRampID, Set_Button=1
        (*infoP).State.RedRampPlotted=1
        (*infoP).State.RawRampPlotted=0
    endif else begin ; one or the other ImageLoaded[0,1] are set if we are here..
        Widget_Control, PlotRawRampID, Set_Button=1
        (*infoP).State.RedRampPlotted=0
        (*infoP).State.RawRampPlotted=1
    endelse
     
    (*infoP).Plot.RampID = PlotRampID ; need this for cases we don't have the fit. 
    (*infoP).Plot.DifferenceID = PlotDifferenceID
    (*infoP).Plot.RedRampID = PlotRedRampID
    (*infoP).Plot.RawRampID = PlotRawRampID 

    Widget_Control, (*infoP).Plot.RampID, Sensitive=1
    if (*infoP).State.ImageLoaded[0] then $
      Widget_Control, (*infoP).Plot.RawRampID, Sensitive=1 $
    else $
      Widget_Control, (*infoP).Plot.RawRampID, Sensitive=0

    if (*infoP).State.ImageLoaded[1] then $
      Widget_Control, (*infoP).Plot.RedRampID, Sensitive=1 $
    else $
      Widget_Control, (*infoP).Plot.RedRampID, Sensitive=0

    if (*infoP).State.ImageLoaded[2] then $
      Widget_Control, (*infoP).Plot.DifferenceID, Sensitive=1 $
    else $
      Widget_Control, (*infoP).Plot.DifferenceID, Sensitive=0

   
    (*infoP).Plot.TextOutID = Widget_Button(ActionBaseID, Value='Write Text File', $
                                            UValue='wtext')
    (*infoP).Plot.EPSOutID = Widget_Button(ActionBaseID, Value='Write EPS File', $
                                           UValue='weps')
    
    DismissPixHistory = Widget_Button(ActionBaseID, Value='Done', $
                                      UValue='DismissPixHistory')
   
    Widget_Control, (*infoP).IDs.PixHistoryBaseID, /Realize

    Widget_Control,(*infoP).IDs.WidPixHistoryID,Get_Value=thisID

    (*infoP).IDs.DrawPixHistoryID = thisID

    Widget_Control, (*infoP).IDs.PixHistoryBaseID, Set_Uvalue=infoP

    Window, /Free, XSize=(*infoP).Images.DefaultPlotSize[0],YSize=(*infoP).Images.DefaultPlotSize[1],/pixmap

    (*infoP).IDs.PixHistPixmapID=!D.Window
    
    Xmanager, 'NCView_PixHistory', (*infoP).IDs.PixHistoryBaseID, /no_block, Cleanup='NCView_PixHistory_Cleanup'
                                                
endif 

end

;; Default event hangler for PixHistory
pro NCView_PixHistory_Event, event 

Widget_Control, event.id, Get_UValue=UValue
EventType = Tag_Names(event,/structure)
Widget_Control, event.top, Get_UValue=infoP

; This seems a bit clunky  - probably a design flaw...
_imgIdx = (*infoP).State.CurrentImageTypeIndex

case EventType of 
    
    'WIDGET_BASE' : begin 
        ;print,'Resizing the history plot window...'
        ;(*infoP) = event.x
        ;(*infoP) = event.y

        ;WDelete, (*infoP).IDs.pixmapID
    end

    'WIDGET_DRAW' : begin ; Event happened in our plot window
        buttonClicks=['down','up','motion']
        thisClick=buttonClicks[event.type]
        
        case thisClick of
            'down' : begin  ; start the zoom box
                NCView_LoadPlotCT, infoP
                Widget_Control, (*infoP).IDs.WidPixHistoryID, Draw_Motion_Events=1
                (*infoP).State.ButtonPressed=1
                (*infoP).Plot.PixHistBoxStartX=event.x
                (*infoP).Plot.PixHistBoxStartY=event.y
            end
            'up' : begin ; do the zoom
                ; turn off motion events
                (*infoP).State.ButtonPressed=0
                Widget_Control, (*infoP).IDs.WidPixHistoryID, Draw_Motion_Events=0
                ; turn on zoom flag.
                (*infoP).Plot.PixHistZoomed=1
                ; Erase box
                WSet, (*infoP).IDs.DrawPixHistoryID
                Device, Copy=[0,0,(*infoP).Images.DefaultPlotSize[0],(*infoP).Images.DefaultPlotSize[1], 0, 0, $
                              (*infoP).IDs.PixHistPixmapID]
                ; Set up for new plot
                NCView_LoadImageCT, infoP
                ; construct new vector from box start and box release
                newx = [(*infoP).Plot.PixHistBoxStartX,event.x]
                newy = [(*infoP).Plot.PixHistBoxStartY,event.y]
                ; ensure they are properly ordered
                if (newx[0] gt newx[1]) then newx=[newx[1],newx[0]]
                if (newy[0] gt newy[1]) then newy=[newy[1],newy[0]]
                ; convert to data coordinates.
                coords = Convert_Coord(newx, newy, /device, /to_data)
                ; make sure the release was within data bounds. 
                x1 = !X.CRange[0] > coords[0,0] < !X.CRange[1]
                x2 = !X.CRange[0] > coords[0,1] < !X.CRange[1]
                y1 = !Y.CRange[0] > coords[1,0] < !Y.CRange[1]
                y2 = !Y.CRange[0] > coords[1,1] < !Y.CRange[1]
                ; Update display with new bounds.
                NCView_PixHistory_Update,infoP,thisxr=[x1,x2],thisyr=[y1,y2]
            end
            'motion' : begin    ; draw the box
                                
                if (*infoP).State.ButtonPressed then begin ; only draw if we've had a down event
                                ; Erase old box
                    WSet, (*infoP).IDs.DrawPixHistoryID
                    Device, Copy=[0,0,(*infoP).Images.DefaultPlotSize[0],(*infoP).Images.DefaultPlotSize[1], 0, 0, $
                                  (*infoP).IDs.PixHistPixmapID]
                    (*infoP).Plot.PixHistBoxCurX=event.x
                    (*infoP).Plot.PixHistBoxCurY=event.y
                    thisX=[(*infoP).Plot.PixHistBoxStartX, event.x]
                    thisY=[(*infoP).Plot.PixHistBoxStartY, event.y]
                    Coords=Convert_Coord(thisX, thisY, /Device, /To_Data)
                    x1 = !X.CRange[0] > coords[0,0] < !X.CRange[1]
                    x2 = !X.CRange[0] > coords[0,1] < !X.CRange[1]
                    y1 = !Y.CRange[0] > coords[1,0] < !Y.CRange[1]
                    y2 = !Y.CRange[0] > coords[1,1] < !Y.CRange[1]
                    BoxX = [x1,x2,x2,x1,x1]
                    BoxY = [y1,y1,y2,y2,y1]
                    plots,BoxX,BoxY,color=3,psym=0
                endif   ; End draw only if button down
            end  ; End draw the box      
        endcase  ; Is this a down, up, motion event? 
    end

    else : begin 
        
        ;; Event handlers for x,ymin/max events
        case UValue of 
            'ramp' : begin
                (*infoP).State.RampPlotted=1
                NCView_PixHistory_Configure, infoP
            end
            'difference' : begin
                ; It only makes sense to plot the difference if we have a fit...
                if (*infoP).State.ImageLoaded[2] then begin 
                    (*infoP).State.RampPlotted=0
                    NCView_PixHistory_Configure, infoP
                endif else begin 
                    ; switch buttons back. 
                    (*infoP).State.RampPlotted=1
                    Widget_Control, (*infoP).IDs.PlotRampID, Set_Button=1
                endelse 
            end
            'raw' : begin 
                if (*infoP).State.ImageLoaded[0] then begin 
                    (*infoP).State.RedRampPlotted=0
                    (*infoP).State.RawRampPlotted=1
                    NCView_PixHistory_Configure, infoP
                endif
            end
            'red' : begin 
                if (*infoP).State.ImageLoaded[1] then begin 
                    (*infoP).State.RedRampPlotted=1
                    (*infoP).State.RawRampPlotted=0
                    NCView_PixHistory_Configure, infoP
                endif
            end
            'DismissPixHistory': begin 
                Widget_Control, event.top, /destroy
            end
            'xmin' : begin 
                (*infoP).Plot.MinX = event.value
                Widget_Control, (*infoP).Plot.MinXTextID, Set_Value=(*infoP).Plot.MinX
                NCView_PixHistory_Update,infoP
            end
            'xmax' : begin 
                (*infoP).Plot.MaxX = event.value
                Widget_Control, (*infoP).Plot.MaxXTextID, Set_Value=(*infoP).Plot.MaxX
                NCView_PixHistory_Update,infoP
            end
            'ymin' : begin 
                (*infoP).Plot.MinY = event.value
                Widget_Control, (*infoP).Plot.MinYTextID, Set_Value=(*infoP).Plot.MinY
                NCView_PixHistory_Update,infoP
            end
            'ymax' : begin 
                (*infoP).Plot.MaxY = event.value
                Widget_Control, (*infoP).Plot.MaxYTextID, Set_Value=(*infoP).Plot.MaxY
                NCView_PixHistory_Update,infoP
            end
            'xpix' : begin 
                ;;SaveX = (*infoP).State.Coord[0]
                case 1 of  ; sanitize the input. 
                    event.value ge (*infoP).DataObj.Data[_imgIdx]->NX(): $
                      (*infoP).State.Coord[0] = (*infoP).DataObj.Data[_imgIdx]->NX()-1
                    event.value lt 0: (*infoP).State.Coord[0] = 0
                    else: (*infoP).State.Coord[0] = event.value
                endcase
                (*infoP).Plot.PixelString = string( (*infoP).State.Coord[0],(*infoP).Plot.Coord[1], $
                                                    format='("(",i5,",",i5,") ")')
                NCView_PixHistory_Configure, infoP
                NCView_PixHistory_Update, infoP
                ;; Where is this pixel in the panner? 
                (*infoP).State.CenterPixel[0]=(*infoP).State.Coord[0]
                NewPosition=round( (*infoP).State.CenterPixel*(*infoP).State.PannerScale + (*infoP).State.PannerOffset )
                NCView_Pan,NewPosition[0],NewPosition[1], infoP
                NCView_UpdateDisplay, infoP
                ;;(*infoP).State.Coord[0] = SaveX
                (*infoP).Plot.PixelString = string( (*infoP).State.Coord[0],(*infoP).State.Coord[1], $
                                                    format='("(",i5,",",i5,") ")')
            end
            'ypix' : begin 
                ;;SaveY = (*infoP).State.Coord[1]
                case 1 of       ; sanitize the input. 
                    event.value ge (*infoP).DataObj.Data[_imgIdx]->NY(): $
                      (*infoP).State.Coord[1] = (*infoP).DataObj.Data[_imgIdx]->NY()-1
                    event.value lt 0: (*infoP).State.Coord[1] = 0
                    else: (*infoP).State.Coord[1] = event.value
                endcase
                (*infoP).Plot.PixelString = string( (*infoP).Plot.Coord[0],(*infoP).State.Coord[1], $
                                                    format='("(",i5,",",i5,") ")')
                NCView_PixHistory_Configure, infoP
                NCView_PixHistory_Update, infoP
                ;; Where is this pixel in the panner? 
                (*infoP).State.CenterPixel[1]=(*infoP).State.Coord[1]
                NewPosition=round( (*infoP).State.CenterPixel*(*infoP).State.PannerScale + (*infoP).State.PannerOffset )
                ;; Move panner box to correct position
                NCView_Pan,NewPosition[0],NewPosition[1], infoP
                ;; Update display to center on defined pixel.
                NCView_UpdateDisplay, infoP
                ;;(*infoP).State.Coord[1] = SaveY
                (*infoP).Plot.PixelString = string( (*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1], $
                                                    format='("(",i5,",",i5,") ")')
            end
            'wtext' : begin
                OutputFile = (*infoP).DataObj.BaseName+'_x'+strtrim((*infoP).Plot.Coord[0],2) $
                             +'_y'+strtrim((*infoP).Plot.Coord[1],2)+'.dat'
                openw,unit1,OutputFile,/get_lun
                time = (*((*infoP).Plot.x))
                npt = n_elements(time)
                if ((*infoP).State.ImageLoaded[2] AND $
                    (*infoP).State.ImageLoaded[1] AND $
                    (*infoP).State.ImageLoaded[0]) then begin ;; raw, processed, slope
                    printf,unit1,'# Pixel history for Pixel '+ $
                           strtrim((*infoP).Plot.Coord[0],2)+','+ $
                           strtrim((*infoP).Plot.Coord[1],2),+ $
                           ' of file ',(*infoP).DataObj.BaseName
                    printf,unit1,'# We had access to raw, processed, and fit data for this file, so'
                    printf,unit1,'# the file contains 4 columns (see headings).' 
                    printf,unit1,'# The next line contains the x,y coordinates and slope/error intercept/error'
                    printf,unit1,(*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1], $
                           (*infoP).Plot.Slope[0],(*infoP).Plot.Slope[1], $
                           (*infoP).Plot.Intercept[0],(*infoP).Plot.Intercept[1]
                    printf,unit1,''
                    printf,unit1,'Time [sec]','Raw [ADU/s]','Processed [ADU/s]','Fit to Proc [ADU/s]', $
                           format='(a10,2x,a11,2x,a17,2x,a19)'
                    printf,unit1,'-------------------------------------------------------------------'
                   ; Get time, raw, red independent of plot values since we may be plotting a ratio
                    _time = (*infoP).DataObj.Data[0]->getTime()
                    _raw = (*infoP).DataObj.Data[0]->Pixel((*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1])
                    _red = (*infoP).DataObj.Data[1]->Pixel((*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1])
                    for i=0,npt-1 do printf,unit1,_time[i],_raw[i],_red[i],(*((*infoP).Plot.f))[i], $
                      format='(f10.2,2x,f11.1,2x,f13.1,2x,f19.1)'
                endif
                if (NOT (*infoP).State.ImageLoaded[2] AND $
                    (*infoP).State.ImageLoaded[1] AND $
                    (*infoP).State.ImageLoaded[0]) then begin ;; raw, processed, no fit/slope
                    printf,unit1,'# Pixel history for Pixel '+ $
                           strtrim((*infoP).Plot.Coord[0],2)+','+ $
                           strtrim((*infoP).Plot.Coord[1],2),+ $
                           ' of file ',(*infoP).DataObj.BaseName
                    printf,unit1,'# We had access to raw and processed data for this file, so'
                    printf,unit1,'# the file contains 3 columns (see headings).' 
                    printf,unit1,'# The next line contains the x,y coordinates'
                    printf,unit1,(*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1]                           
                    printf,unit1,''
                    printf,unit1,'Time [sec]','Raw [ADU/s]','Processed [ADU/s]', $
                           format='(a10,2x,a11,2x,a17)'
                    printf,unit1,'---------------------------------------------'
                    _time = (*infoP).DataObj.Data[0]->getTime()
                    _raw = (*infoP).DataObj.Data[0]->Pixel((*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1])
                    _red = (*infoP).DataObj.Data[1]->Pixel((*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1])
                    for i=0,npt-1 do begin 
                        printf,unit1,_time[i],_raw[i],_red[i]
                    endfor
                endif
                if (NOT (*infoP).State.ImageLoaded[2] AND $
                    NOT (*infoP).State.ImageLoaded[1] AND $
                    (*infoP).State.ImageLoaded[0]) then begin ;; raw, no processed, no fit/slope
                    printf,unit1,'# Pixel history for Pixel '+ $
                           strtrim((*infoP).Plot.Coord[0],2)+','+ $
                           strtrim((*infoP).Plot.Coord[1],2),+ $
                           ' of file ',(*infoP).DataObj.BaseName
                    printf,unit1,'# We had access to only raw data for this file, so'
                    printf,unit1,'# the file contains 2 columns (see headings).' 
                    printf,unit1,'# The next line contains the x,y coordinates'
                    printf,unit1,(*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1]                           
                    printf,unit1,''
                    printf,unit1,'Time [sec]','Raw [ADU/s]', $
                           format='(a10,2x,a11)'
                    printf,unit1,'-------------------------'
                    _time = (*infoP).DataObj.Data[0]->getTime()
                    _raw=(*infoP).DataObj.Data[0]->Pixel((*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1])
                    for i=0,npt-1 do begin                        
                        printf,unit1,_time[i],_raw[i]
                    endfor
                endif
                if ((*infoP).State.ImageLoaded[2] AND $
                    NOT (*infoP).State.ImageLoaded[1]AND $
                    (*infoP).State.ImageLoaded[0]) then begin ;; fit, raw, no processed
                    printf,unit1,'# Pixel history for Pixel '+ $
                           strtrim((*infoP).Plot.Coord[0],2)+','+ $
                           strtrim((*infoP).Plot.Coord[1],2),+ $
                           ' of file ',(*infoP).DataObj.BaseName
                    printf,unit1,'# We had access to raw and fit data for this file, so'
                    printf,unit1,'# the file contains 3 columns (see headings).' 
                    printf,unit1,'# The next line contains the x,y coordinates and slope/error intercept/error'
                    printf,unit1,(*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1], $
                           (*infoP).Plot.Slope[0],(*infoP).Plot.Slope[1], $
                           (*infoP).Plot.Intercept[0],(*infoP).Plot.Intercept[1]
                    printf,unit1,''
                    printf,unit1,'Time [sec]','Raw [ADU/s]','Fit to Proc [ADU/s]', $
                           format='(a10,2x,a11,2x,a19)'
                    printf,unit1,'-----------------------------------------------'
                    _time = (*infoP).DataObj.Data[0]->getTime()
                    _raw=(*infoP).DataObj.Data[0]->Pixel((*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1])
                    for i=0,npt-1 do begin                        
                        printf,unit1,_time[i],_raw[i],(*(*infoP).Plot.f)[i]
                    endfor
                endif
                if ((*infoP).State.ImageLoaded[2] AND $
                    (*infoP).State.ImageLoaded[1] AND $
                    NOT (*infoP).State.ImageLoaded[0]) then begin ;; fit, processed, no raw
                    printf,unit1,'# Pixel history for Pixel '+ $
                           strtrim((*infoP).Plot.Coord[0],2)+','+ $
                           strtrim((*infoP).Plot.Coord[1],2),+ $
                           ' of file ',(*infoP).DataObj.BaseName
                    printf,unit1,'# We had access to raw and fit data for this file, so'
                    printf,unit1,'# the file contains 3 columns (see headings).' 
                    printf,unit1,'# The next line contains the x,y coordinates and slope/error intercept/error'
                    printf,unit1,(*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1], $
                           (*infoP).Plot.Slope[0],(*infoP).Plot.Slope[1], $
                           (*infoP).Plot.Intercept[0],(*infoP).Plot.Intercept[1]
                    printf,unit1,''
                    printf,unit1,'Time [sec]','Processed [ADU/s]','Fit to Proc [ADU/s]', $
                           format='(a10,2x,a17,2x,a19)'
                    printf,unit1,'-----------------------------------------------------'
                    _time = (*infoP).DataObj.Data[1]->getTime()
                    _red = (*infoP).DataObj.Data[1]->Pixel((*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1])
                    for i=0,npt-1 do begin                        
                        printf,unit1,_time[i],_red[i],(*(*infoP).Plot.f)[i]
                    endfor
                endif
                if (NOT (*infoP).State.ImageLoaded[2]  AND $
                    (*infoP).State.ImageLoaded[1] AND $
                    NOT (*infoP).State.ImageLoaded[0]) then begin ;; processed, no fit, no raw
                    printf,unit1,'# Pixel history for Pixel '+ $
                           strtrim((*infoP).Plot.Coord[0],2)+','+ $
                           strtrim((*infoP).Plot.Coord[1],2),+ $
                           ' of file ',(*infoP).DataObj.BaseName
                    printf,unit1,'# We had access to only processed data for this file, so'
                    printf,unit1,'# the file contains 2 columns (see headings).' 
                    printf,unit1,'# The next line contains the x,y coordinates.'
                    printf,unit1,(*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1], $
                    printf,unit1,''
                    printf,unit1,'Time [sec]','Processed [ADU/s]', $
                           format='(a10,2x,a17)'
                    printf,unit1,'-------------------------------'
                    _time = (*infoP).DataObj.Data[1]->getTime()
                    _red = (*infoP).DataObj.Data[1]->Pixel((*infoP).Plot.Coord[0],(*infoP).Plot.Coord[1])
                    for i=0,npt-1 do begin                        
                        printf,unit1,_time[i],_red[i]
                    endfor
                endif
                free_lun,unit1
            end
            'RestoreRange' : begin 
                ; Restore min/max to original values,...
                (*infoP).Plot.MinX = (*infoP).Plot.MinXSv
                (*infoP).Plot.MaxX = (*infoP).Plot.MaxXSv
                (*infoP).Plot.MinY = (*infoP).Plot.MinYSv
                (*infoP).Plot.MaxY = (*infoP).Plot.MaxYSv 
                ; ... update display gui, and ...
                Widget_Control, (*infoP).Plot.MinXTextID, Set_Value=(*infoP).Plot.MinX 
                Widget_Control, (*infoP).Plot.MaxXTextID, Set_Value=(*infoP).Plot.MaxX 
                Widget_Control, (*infoP).Plot.MinYTextID, Set_Value=(*infoP).Plot.MinY 
                Widget_Control, (*infoP).Plot.MaxYTextID, Set_Value=(*infoP).Plot.MaxY 
                ; ... update the plot
                NCView_PixHistory_Update,infoP
            end
            'weps' : begin 
                NCView_PixHistory_Update, infoP, /eps
            end
            else : begin
            end
        endcase 
        
    end
    
endcase
    
end

pro NCView_PixHistory_Configure, infoP

if Ptr_Valid((*infoP).Plot.y) then Ptr_Free,(*infoP).Plot.y
if Ptr_Valid((*infoP).Plot.x) then Ptr_Free,(*infoP).Plot.x

; Get the Ramp
(*infoP).Plot.Coord = [(*infoP).State.Coord[0],(*infoP).State.Coord[1]]
; The ramp can either by a raw ramp or a processed ramp.  Default to 
; red ramp if it's available.
_x = (*infoP).Plot.Coord[0]
_y = (*infoP).Plot.Coord[1]

if Ptr_Valid((*infoP).Plot.x) then Ptr_Free,(*infoP).Plot.x
if Ptr_Valid((*infoP).Plot.y) then Ptr_Free,(*infoP).Plot.y
if (*infoP).State.RedRampPlotted then _idx=1 else _idx=0
(*infoP).Plot.x = Ptr_New((*infoP).DataObj.Data[_idx]->getTime())
(*infoP).Plot.y = Ptr_New(reform((*infoP).DataObj.Data[_idx]->Pixel(_x,_y))) 

; Get Slope info if we have it. 
if Ptr_Valid((*infoP).Plot.f) then Ptr_Free,(*infoP).Plot.f
if ((*infoP).State.ImageLoaded[2]) then begin ; We have a slope image
    (*infoP).Plot.Slope[0] = (*infoP).DataObj.Data[2]->Pixel(_x,_y,id=0)
    (*infoP).Plot.Slope[1] = (*infoP).DataObj.Data[2]->Pixel(_x,_y,id=1)
    (*infoP).Plot.FirstFrame = (*infoP).DataObj.Data[2]->DropFrame()
    (*infoP).Plot.f = Ptr_New(reform((*infoP).DataObj.Data[2]->Fit(_x,_y,*(*infoP).Plot.x)))
    if (NOT (*infoP).State.ImageLoaded[3]) then begin ; Slope, no diagnostic - guess intercept
        ; Take average of intercept derived from first 3 ramp points
        if (NOT (*infoP).DataObj.Data[2]->IsWFS()) then begin 
            _estInt = fltarr(3)
            for _i=1,3 do _estInt[_i-1]= (*(*infoP).Plot.y)[_i] - (*(*infoP).Plot.x)[_i]*(*infoP).Plot.Slope[0]
            _stats=moment(_estInt,/nan)
            (*infoP).Plot.Intercept[0]=_stats[0]
            (*infoP).Plot.Intercept[1]=sqrt(_stats[1])
            *(*infoP).Plot.f += (*infoP).Plot.Intercept[0]
           
        endif else begin 
            ; On WFS, force "fit" to go through the first point:
            (*infoP).Plot.Intercept[0] = (*(*infoP).Plot.y)[0]-(*(*infoP).Plot.f)[0] 
            (*infoP).Plot.Intercept[1] = 0
            *(*infoP).Plot.f += (*infoP).Plot.Intercept[0]
        endelse 
    endif else begin 
        (*infoP).Plot.LastFrame = (*infoP).DataObj.Data[3]->getNamedPlane(_x,_y,'SATURATION')
        ;print, (*infoP).Plot.Intercept[0]
        if (not (*infoP).DataObj.Data[2]->IsWFS()) then begin 
            (*infoP).Plot.Intercept[0] = (*infoP).DataObj.Data[3]->getNamedPlane(_x,_y,'INTERCEPT')
            (*infoP).Plot.Intercept[1] = (*infoP).DataObj.Data[3]->getNamedPlane(_x,_y,'EINTERCEPT')
            *(*infoP).Plot.f += (*infoP).Plot.Intercept[0]
        endif else begin 
            ; On WFS, force "fit" to go through the first point:
            ; If the time axis is the same....
            ;(*infoP).Plot.Intercept[0] = 0.5*(3.0*(*(*infoP).Plot.y)[0]-(*(*infoP).Plot.y)[2])
            ; this forces regardless....
            (*infoP).Plot.Intercept[0] = (*(*infoP).Plot.y)[0]-(*(*infoP).Plot.f)[0] 
            (*infoP).Plot.Intercept[1] = 0
            *(*infoP).Plot.f += (*infoP).Plot.Intercept[0]
        endelse 
    endelse
endif 

; if ((*infoP).State.ImageLoaded[3]) then begin ; We have a diagnostic image
;     (*infoP).Plot.LastFrame = (*infoP).DataObj.Data[3]->getNamedPlane(_x,_y,'SATURATION')
;     ;print, (*infoP).Plot.Intercept[0]
;     if (not (*infoP).DataObj.Data[2]->IsWFS()) then begin 
;         (*infoP).Plot.Intercept[0] = (*infoP).DataObj.Data[3]->getNamedPlane(_x,_y,'INTERCEPT')
;         (*infoP).Plot.Intercept[1] = (*infoP).DataObj.Data[3]->getNamedPlane(_x,_y,'EINTERCEPT')
;         *(*infoP).Plot.f += (*infoP).Plot.Intercept[0]
;     endif else begin 
;         ; On WFS, force "fit" to go through the first point:
;         (*infoP).Plot.Intercept[0] = 0.5*(3.0*(*(*infoP).Plot.y)[0]-(*(*infoP).Plot.y)[2])
;         (*infoP).Plot.Intercept[1] = 0
;     endelse
; endif

; We should handle error cases where we have no ramp to plot... But we
; don't. That's the royal we, BTW.
; Should we plot a ratio instead of the ramp? Check that the user has
; selected ramp button and that we have at least the slope image
; available. 
if NOT (*infoP).State.RampPlotted AND (*infoP).State.ImageLoaded[2] then begin
    ; Plot ratio as f(signal)
    ;print,(*(*infoP).Plot.y)
    ;print,(*(*infoP).Plot.f)
    (*(*infoP).Plot.x) = (*(*infoP).Plot.y)  ; make x axis = signal
    (*(*infoP).Plot.y) -= (*(*infoP).Plot.f) ; make y axis = signal-fit
endif

;; Fucking min...
tmp = (*(*infoP).Plot.y)
(*infoP).Plot.MinY = min(tmp,max=tmpy)
(*infoP).Plot.MaxY = tmpy
if (*infoP).State.ImageLoaded[2] AND (*infoP).State.RampPlotted then begin  ;; Make max and min bounds enough to bracket fit; 
    ;; especially imporant if intermediate file not present for
    ;; some reason. 
    tmp = (*(*infoP).Plot.f)
    tmpymin = min(tmp,max=tmpymax)
    (*infoP).Plot.MinY = ((*infoP).Plot.MinY gt tmpymin) ? tmpymin : (*infoP).Plot.MinY
    (*infoP).Plot.MaxY = ((*infoP).Plot.MaxY lt tmpymax) ? tmpymax : (*infoP).Plot.MaxY
endif
tmp = (*(*infoP).Plot.x)
(*infoP).Plot.MinX = min(tmp,max=tmpx)
(*infoP).Plot.MaxX = tmpx 
Widget_Control, (*infoP).Plot.LocationID, Set_Value=(*infoP).Plot.PixelString
Widget_Control, (*infoP).Plot.PixelXID,   Set_Value=(*infoP).Plot.Coord[0]
Widget_Control, (*infoP).Plot.PixelYID,   Set_Value=(*infoP).Plot.Coord[1]
Widget_Control, (*infoP).Plot.MinXTextID, Set_Value=(*infoP).Plot.MinX
Widget_Control, (*infoP).Plot.MaxXTextID, Set_Value=(*infoP).Plot.MaxX
Widget_Control, (*infoP).Plot.MinYTextID, Set_Value=(*infoP).Plot.MinY
Widget_Control, (*infoP).Plot.MaxYTextID, Set_Value=(*infoP).Plot.MaxY
Widget_Control, (*infoP).Plot.SlopeTextID, Set_Value=(*infoP).Plot.Slope[0]
Widget_Control, (*infoP).Plot.SlopeETextID, Set_Value=(*infoP).Plot.Slope[1]
Widget_Control, (*infoP).Plot.InterceptTextID, Set_Value=(*infoP).Plot.Intercept[0]
Widget_Control, (*infoP).Plot.InterceptETextID, Set_Value=(*infoP).Plot.Intercept[1]

(*infoP).Plot.MinXSv = (*infoP).Plot.MinX
(*infoP).Plot.MaxXSv = (*infoP).Plot.MaxX
(*infoP).Plot.MinYSv = (*infoP).Plot.MinY
(*infoP).Plot.MaxYSv = (*infoP).Plot.MaxY

;; Plot the pixel.
NCView_PixHistory_Update,infoP
;endif 
    
end

; really should move plot calls to separate independent function and 
; update only here to avoid the 'eps' switches...
pro NCView_PixHistory_Update,infoP,thisxr=thisxr,thisyr=thisyr,eps=eps

if n_elements(eps) eq 0 then eps=0 else eps=1
; Need to move this to "global"...
A = FINDGEN(17) * (!PI*2/16.) 
USERSYM, COS(A), SIN(A)

if not keyword_set(thisyr) then begin 
    YDiff = abs((*infoP).Plot.MaxY-(*infoP).Plot.MinY)
    ylower = (*infoP).Plot.MinY - 0.05*YDiff
    yupper = (*infoP).Plot.MaxY + 0.05*YDiff
endif else begin 
    ylower = thisyr[0]
    yupper = thisyr[1]
endelse 
if not keyword_set(thisxr) then begin 
    XDiff = abs((*infoP).Plot.MaxX-(*infoP).Plot.MinX)
    xlower = (*infoP).Plot.MinX - 0.05*XDiff
    xupper = (*infoP).Plot.MaxX + 0.05*XDiff
endif else begin 
    xlower = thisxr[0]
    xupper = thisxr[1]
endelse  
NCView_LoadPlotCT, infoP

_xtitle='Exposure Time (sec)'
if (*infoP).State.RampPlotted then begin 
    _xtitle= 'Exposure Time (sec)'
    _ytitle= 'Counts (ADU)' 
endif else begin 
    _xtitle= 'Counts (ADU)'
    _ytitle='Data-Fit'
endelse

; Draw to pixmap or to eps file
if (eps) then begin  ; the eps bit
    OutputFile = (*infoP).DataObj.BaseName+'_x'+strtrim((*infoP).Plot.Coord[0],2) $
                 +'_y'+strtrim((*infoP).Plot.Coord[1],2)+'.eps'
    set_plot,'ps'
    !P.FONT=0
    device,/encapsulated,/color,/portrait,/helvetica
    device,filename=OutputFile
    symsize=.5
endif else begin     ; the pixmap bit
    WSet, (*infoP).IDs.PixHistPixmapID
    symsize=.8
endelse 

; plot the data, either to the pixmap or to the eps device.
plot,[0],[0],yrange=[ylower,yupper],ystyle=1,xrange=[xlower,xupper],xstyle=1, $
     ytitle = _ytitle,xtitle =_xtitle,/nodata,color=1
oplot,(*(*infoP).Plot.x),(*(*infoP).Plot.y),psym=2,color=1,symsize=symsize

if ((*infoP).State.ImageLoaded[2]) then begin
    if (*infoP).State.RampPlotted then $  ; Only overplot fit if we are plotting the ramp.
      oplot,(*(*infoP).Plot.x),(*(*infoP).Plot.f),color=2
    if (*infoP).State.ImageLoaded[3] then begin ;$     ; Dia info useful in either case if we have it. 
      ;print,(*infoP).Plot.FirstFrame,(*infoP).Plot.LastFrame
      oplot,(*(*infoP).Plot.x)[(*infoP).Plot.FirstFrame:(*infoP).Plot.LastFrame], $
            (*(*infoP).Plot.y)[(*infoP).Plot.FirstFrame:(*infoP).Plot.LastFrame], $
            color=4,psym=8,symsize=symsize
  endif
endif

; only draw to the display if we are not epsing.
if (eps) then begin ; reset for normal displaying.
    device,/close
    !P.FONT=-1
    set_plot,'x'
endif else begin    ; Draw to window
    WSet, (*infoP).IDs.DrawPixHistoryID

    plot,[0],[0],yrange=[ylower,yupper],ystyle=1,xrange=[xlower,xupper],xstyle=1, $
         ytitle = _ytitle,xtitle = _xtitle,/nodata,color=1,background=255l+256l*255l+256l*256l*255l
;;oplot,(*(*infoP).Plot.x),(*(*infoP).Plot.y),color=1
    oplot,(*(*infoP).Plot.x),(*(*infoP).Plot.y),psym=2,color=1
    
    if ((*infoP).State.ImageLoaded[2]) then begin 
        if (*infoP).State.RampPlotted then $ ; Only overplot fit if we are plotting the ramp.
          oplot,(*(*infoP).Plot.x),(*(*infoP).Plot.f),color=2
        if (*infoP).State.ImageLoaded[3] then $ ; Dia info useful in either case if we have it. 
          oplot,(*(*infoP).Plot.x)[(*infoP).Plot.FirstFrame:(*infoP).Plot.LastFrame], $
                (*(*infoP).Plot.y)[(*infoP).Plot.FirstFrame:(*infoP).Plot.LastFrame], $
                color=4,psym=8
    endif

    ; update the current min/max values
    (*infoP).Plot.MinX = xlower
    (*infoP).Plot.MaxX = xupper
    (*infoP).Plot.MinY = ylower
    (*infoP).Plot.MaxY = yupper
    ; update text boxes
    Widget_Control, (*infoP).Plot.MinXTextID, Set_Value=(*infoP).Plot.MinX 
    Widget_Control, (*infoP).Plot.MaxXTextID, Set_Value=(*infoP).Plot.MaxX 
    Widget_Control, (*infoP).Plot.MinYTextID, Set_Value=(*infoP).Plot.MinY 
    Widget_Control, (*infoP).Plot.MaxYTextID, Set_Value=(*infoP).Plot.MaxY 
    
endelse

NCView_LoadImageCT, infoP

end

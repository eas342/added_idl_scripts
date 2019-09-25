@NCView_ReadImage
@NCView_ImageManip
@NCView_Resize
@NCView_DrawSubEvent
@NCView_ColorTable
@NCView_PixelHistory
@NCView_HeaderView

;-----------------------------------------------------------------------------
; Exit GUI module.
;-----------------------------------------------------------------------------
pro NCView_Quit, event
Widget_Control,event.top,/Destroy
end
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Clean up module
;-----------------------------------------------------------------------------
pro NCView_Cleanup,TopLevelID

print,'Cleaning up...'
Widget_Control,TopLevelID,Get_UValue=infoP

for i=0,3 do if Obj_Valid((*infoP).DataObj.Data[i]) then Obj_Destroy,(*infoP).DataObj.Data[i]
Ptr_Free, (*infoP).Images.ScaledImage
Ptr_Free, (*infoP).Images.DisplayImage
Ptr_Free, (*infoP).Images.PannerImage
Ptr_Free, (*infoP).Plot.x
Ptr_Free, (*infoP).Plot.y
if Ptr_Valid((*infoP).Plot.f) then Ptr_Free,(*infoP).Plot.f
Ptr_Free, (*infoP).Colors.GVect
Ptr_Free, (*infoP).Colors.RVect
Ptr_Free, (*infoP).Colors.BVect
Ptr_Free, (*infoP).Colors.CurrentStretch
Ptr_Free, (*infoP).Colors.PlotGVect
Ptr_Free, (*infoP).Colors.PlotRVect
Ptr_Free, (*infoP).Colors.PlotBVect
Ptr_Free, infoP

print,"Checking the heap - if you've done nothing to cause a crash, this should"
print," be the message you get when you exit cleanly:"
print,""
print,"Heap Variables:"
print,"    # Pointer: 0"
print,"    # Object : 0"
print,""
print,"If you get something different: "
print,"Contact Karl - misselt@as.arizona.edu"
print,""
help,/heap 

end
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------

pro NCView_Event, event 

;; Handle events on the base. 
Widget_Control, event.id, Get_UValue=UValue
Widget_Control, event.top, Get_UValue=infoP

;; Can't seem to get resize event name recognized, so...
EventType = tag_names(event,/structure) 

case EventType of
    
    'WIDGET_BASE' : begin 
        NCView_Resize,infoP
       if ((*infoP).State.ImageDisplayed) then NCView_UpdateDisplay,infoP
    end

    else : begin


        if (UValue eq 'MouseMode') then $
          (*infoP).State.MouseMode = (*infoP).State.MouseModeList[event.index]

        if (UValue eq 'ImageMode' AND (*infoP).State.ImageDisplayed) then begin 

            _doit=1
            if ( (event.index eq 2) AND (NOT (*infoP).State.ImageLoaded[2]) ) then begin 
                event.index=(*infoP).State.CurrentImageTypeIndex
                _doit=0
            endif 
            if ( (event.index eq 3) AND (NOT (*infoP).State.ImageLoaded[3]) ) then begin 
                event.index=(*infoP).State.CurrentImageTypeIndex
                _doit=0
            endif 
            if (event.index eq 1 AND (NOT (*infoP).State.ImageLoaded[1]) ) then begin 
                event.index=(*infoP).State.CurrentImageTypeIndex
                _doit=0
            endif 
            if (event.index eq 0 AND (NOT (*infoP).State.ImageLoaded[0]) ) then begin 
                event.index=(*infoP).State.CurrentImageTypeIndex
                _doit=0
            endif 

            Widget_Control,(*infoP).IDs.ImageModeID,Set_DropList_Select=event.index
            (*infoP).State.ImageMode = (*infoP).State.ImageModeList[event.index]
            (*infoP).State.CurrentImageTypeIndex = event.index  
            if (_doit eq 1) then begin  
                (*infoP).DataObj.Data[event.index]->setCurFrame,0
                NCView_ScaleImage,infoP
                NCView_MakePan,infoP
                NCView_UpdateDisplay,infoP
            endif

           

        endif
 

        if ((*infoP).State.ImageDisplayed AND UValue ne 'MouseMode' AND UValue ne 'ImageMode') then begin
            case UValue of
                'Invert'        : begin 
                    ;; Let the color table know we are flipping. 
                    (*infoP).Colors.Inverted = abs((*infoP).Colors.Inverted - 1)
                    (*((*infoP).Colors.RVect)) = reverse(*((*infoP).Colors.RVect))
                    (*((*infoP).Colors.GVect)) = reverse(*((*infoP).Colors.GVect))
                    (*((*infoP).Colors.BVect)) = reverse(*((*infoP).Colors.BVect))
                    WSet,(*infoP).IDs.DrawImageID
                    NCView_StretchCT, infoP
                    NCView_UpdateDisplay,infoP
                end
                'AutoScale'     : print,'auto scaling image'
                'FullScale'     : print,'returning to full scale'
                'ZoomIn'        : NCView_Zoom, UValue, infoP
                'ZoomOut'       : NCView_Zoom, UValue, infoP
                'FullView'      : begin 
                    SizeRatio = float((*infoP).State.ImageSize)/float((*infoP).State.ImageWindowSize)
                    MaxRatio = max(SizeRatio) 
                    (*infoP).State.ZoomLevel = floor((alog(MaxRatio)/alog(2.0))*(-1))
                    (*infoP).State.ZoomFactor = 2.0^((*infoP).State.ZoomLevel)
                    (*infoP).State.CenterPixel = round((*infoP).State.ImageSize/2.)
                    NCView_UpdateDisplay,infoP
                end
                'Center'        : begin 
                    NCView_Zoom,'none',infoP
                    ;(*infoP).State.CenterPixel = round((*infoP).State.ImageSize/2.)
                    ;NCView_UpdateDisplay, infoP
                end
                'PanImage'      : begin
                    case event.type of 
                        0 : begin ;; Down event
                            Widget_Control, (*infoP).IDs.WidImagePannerID, Draw_Motion_Events=1
                            NCView_Pan,event.x,event.y,infoP
                        end
                        1 : begin ;; Up event
                            
                            Widget_Control, (*infoP).IDs.WidImagePannerID, Draw_Motion_Events=0
                            Widget_Control, (*infoP).IDs.WidImagePannerID, /Clear_Events
                            NCView_Pan,event.x,event.y,infoP
                            NCView_UpdateDisplay, infoP
                        end
                        2 : begin ;; Motion event
                            NCView_Pan,event.x,event.y,infoP
                            Widget_Control, (*infoP).IDs.WidImagePannerID, /Clear_Events
                        end
                        else : print,'whooops'
                    endcase
                end
                else : print,'unknow uvalue... oh crap!'
                
            endcase
        endif 
    end
endcase

end
; 
;-----------------------------------------------------------------------------
pro NCView_MenuEvent, event 

Widget_Control, event.id, Get_UValue=Event_Name

;; Get Master info structure
Widget_Control, event.top, Get_UValue=infoP

case Event_Name of 
    
    'Quit' : NCView_Quit,event

    'Read' : begin
        (*infoP).State.Buffer=0
        NCView_ReadImage,infoP 
        if ((*infoP).State.ImageRead) then begin 
            NCView_ScaleImage,infoP
            NCView_MakePan,infoP
            NCView_UpdateDisplay,infoP
        endif 
    end

    'Read Buffered' : begin 
        (*infoP).State.Buffer=1
         NCView_ReadImage,infoP 
        if ((*infoP).State.ImageRead) then begin 
            NCView_ScaleImage,infoP
            NCView_MakePan,infoP
            NCView_UpdateDisplay,infoP
        endif 
    end

    'Process Data' : begin 
	_txt=['Processing from the viewer is currently disabled.  This is a tentatively',   $
              'planned enhancement.  Meanwhile, see NCDHAS_Execute for an IDL GUI wrapper', $
	      'that may help with NCDHAS command line construction.']
       _result = DIALOG_MESSAGE(_txt,/Center, Title='Processins', /Information) 
        ; If we haven't already loaded an image, do so. 
        ;if NOT (*infoP).State.ImageRead then begin 
        ;    NCView_ReadImage,infoP 
        ;    if ((*infoP).State.ImageRead) then begin 
        ;        NCView_ScaleImage,infoP
        ;        NCView_MakePan,infoP
        ;        NCView_UpdateDisplay,infoP
        ;    endif  
        ;endif
        ;; Now realize a processing widget - blocking.
        ;print,'Now we''ll realize a widget to set processing flags.'
    end

    'Log' : begin 
        (*infoP).State.ImageScaling='log' 
        if ((*infoP).State.ImageRead) then begin
            NCView_ScaleImage, infoP
            NCView_MakePan, infoP
            NCView_UpdateDisplay, infoP
        endif
    end
    'Linear' : begin 
        (*infoP).State.ImageScaling='linear'
        if ((*infoP).State.ImageRead) then begin
            NCView_ScaleImage, infoP
            NCView_MakePan, infoP
            NCView_UpdateDisplay, infoP
        endif
    end
    'Histogram Equalization': begin 
        (*infoP).State.ImageScaling='histeq'
        if ((*infoP).State.ImageRead) then begin
            NCView_ScaleImage, infoP
            NCView_MakePan, infoP
            NCView_UpdateDisplay, infoP
        endif
    end
    'ASinh' : begin 
        (*infoP).State.ImageScaling='asinh'
        if ((*infoP).State.ImageRead) then begin
            NCView_ScaleImage, infoP
            NCView_MakePan, infoP
            NCView_UpdateDisplay, infoP
        endif
    end
    'ASinh Beta': begin 
        NCView_SetASinhBeta, infoP
        if ((*infoP).State.ImageRead) then begin
            NCView_ScaleImage, infoP
            NCView_MakePan, infoP
            NCView_UpdateDisplay, infoP
        endif
    end
    'View Header': begin 
        ; Only attemp to view the header if we have an image displayed...
        if ((*infoP).State.ImageRead) then NCView_HeaderView, infoP
    end

    else: print, 'Unkown event in filemenu.'

endcase 

end
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Main  
;-----------------------------------------------------------------------------
pro NCView_DrawEvent, event 

Widget_Control, event.id, Get_UValue=Event_Name

;; Get Master info structure
Widget_Control, event.top, Get_UValue=infoP

if ((*infoP).State.ImageDisplayed) then begin 

    (*infoP).State.DisplayCoord = round ( (0.5 > ([event.x,event.y]/(*infoP).State.ZoomFactor + $
                                           (*infoP).State.Offset) < $
                                    ((*infoP).State.ImageSize - 0.5)) - 0.5)
    (*infoP).Plot.PixelString = string( (*infoP).State.DisplayCoord[0],(*infoP).State.DisplayCoord[1], $
                                        format='("(",i5,",",i5,") ")')

    case (*infoP).State.MouseMode of 
        'Standard'      : begin
            case event.press of
                4    : NCView_NewCenter, event, infoP
                2    : begin 
                    if (*infoP).State.ImageLoaded[0] OR $  ; Only do this if we have ramp.
                      (*infoP).State.ImageLoaded[1] then begin
                        (*infoP).State.Coord=(*infoP).State.DisplayCoord
                        NCView_DrawPixHistory, event, infoP
                    endif
                end
                else :  NCView_DrawColor, event, infoP ; motion event
            endcase            
        end
        'Zoom'          : begin 
            NCView_DrawZoom, event, infoP
        end
        'Pixel History' : begin 
            if event.type eq 0 then begin  ; on any press, draw a history
                ; ... if we have a ramp. 
                if (*infoP).State.ImageLoaded[0] OR (*infoP).State.ImageLoaded[1] then begin
                    (*infoP).State.Coord=(*infoP).State.DisplayCoord
                    NCView_DrawPixHistory, event, infoP
                endif   
            endif else NCView_DrawMotion, event, infoP
        end
    endcase 
    
endif

end
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Main 
;-----------------------------------------------------------------------------
pro NCView_ReadEvent, event 

Widget_Control, event.id, Get_UValue=Event_Name

;; Get Master info structure
Widget_Control, event.top, Get_UValue=infoP

if ((*infoP).State.ImageDisplayed) then begin 

    _imgIdx=(*infoP).State.CurrentImageTypeIndex

    case Event_Name of 
        
        'ReadBrowseBck' : begin 
            thisRead = (*infoP).DataObj.Data[_imgIdx]->getCurFrame()
            (*infoP).DataObj.Data[_imgIdx]->setCurFrame,thisRead-1
        end
        'ReadBrowseFwd' : begin
            thisRead = (*infoP).DataObj.Data[_imgIdx]->getCurFrame()
            (*infoP).DataObj.Data[_imgIdx]->setCurFrame,thisRead+1
        end
        'OnRead' : begin 
            thisRead = event.value
            (*infoP).DataObj.Data[_imgIdx]->setCurFrame,thisRead
            
        end
        'FrmSlider' : begin
            (*infoP).DataObj.Data[_imgIdx]->setCurFrame,event.value-1
        end
            
        else: print, 'Unkown event in readevent.'
    endcase 

    NCView_ScaleImage,infoP
    NCView_UpdateDisplay,infoP

endif 

end
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; NCView Widget Definition module
; 
; ****** NOTE: CODE BORROWS HEAVILY FROM ATV!!! ****************
;-----------------------------------------------------------------------------
pro ncview,path=path,buffer=buffer

if (keyword_set(path)) then begin 
    if (FILE_SEARCH(path,/TEST_DIRECTORY) eq '') then begin 
        print,"Specified path ",path," doesn't exist. Setting to current directory."
        path='./'
    endif 
endif else path='./'

;; Version 
Version = '2.0rev36'

;; How much screen area can we play with? 
ScreenSize = Get_Screen_Size(Resolution=Resolution) ;; Some difficulty with multihead here...

;; Resolution is in cm/pixel 
Resolution /= 2.54 ;; Now in in/pixel

;; We will have the option of 3 different base sizes.
;; They will be factors of 50%, 75%, and 90% of available 
;; real estate and will default to 90%
guiScale = [0.50,0.75,0.90]
if not n_elements(scale) then scale=2
GuiSize = ScreenSize*guiScale[scale]

;; Font definitions
fonttype=['-adobe-courier-bold-o-normal--12*', $
          '-adobe-courier-bold-o-normal--14*', $
          '-adobe-courier-bold-o-normal--20*'  $
         ]
fontsize=[12,14,20]/72.0/Resolution[1]
currentfont=0

;; Font sizes in pixels


;; Top level widget.
TopLevelID = Widget_Base(Title='NCView ('+Version+')', $
                         Row=1,/Base_Align_Right,App_MBar=MenuBar,UValue='Base', $
                         /Tlb_Size_Events)
;------------------------------------------------------------------------------->
;; Define our Menubar widget.
TmpStruct = {cw_pdmenu_s, flags:0, name:''}
MenuBarDefine = [ $
                {cw_pdmenu_s, 1, 'File'}, $ ; file menu
                {cw_pdmenu_s, 0, 'Read'}, $ 
                {cw_pdmenu_s, 0, 'Read Buffered'}, $
                {cw_pdmenu_s, 0, 'View Header'}, $
                {cw_pdmenu_s, 4, 'Process Data'}, $
                {cw_pdmenu_s, 6, 'Quit'}, $
                {cw_pdmenu_s, 1, 'ColorMap'}, $ ; color menu
                {cw_pdmenu_s, 0, 'Grayscale'}, $
                {cw_pdmenu_s, 0, 'Blue-White'}, $
                {cw_pdmenu_s, 0, 'Red-Orange'}, $
                {cw_pdmenu_s, 0, 'Green-White'}, $
                {cw_pdmenu_s, 0, 'Rainbow'}, $
                {cw_pdmenu_s, 0, 'BGRY'}, $
                {cw_pdmenu_s, 2, 'Stern Special'}, $
                {cw_pdmenu_s, 1, 'Scaling'}, $ ; scaling menu
                {cw_pdmenu_s, 0, 'Log'}, $
                {cw_pdmenu_s, 0, 'Linear'}, $
                {cw_pdmenu_s, 0, 'Histogram Equalization'}, $
                {cw_pdmenu_s, 0, 'ASinh'}, $
                {cw_pdmenu_s, 6, 'ASinh Beta'} $
                ;{cw_pdmenu_s, 0, 'Rotate/Zoom'}, $
                ;{cw_pdmenu_s, 0, 'Rotate'}, $
                ;{cw_pdmenu_s, 0, '90 deg'}, $
                ;{cw_pdmenu_s, 0, '180 deg'}, $
                ;{cw_pdmenu_s, 0, '270 deg'}, $
                ;{cw_pdmenu_s, 0, '--------------'}, $
                ;{cw_pdmenu_s, 0, 'Invert X'}, $
                ;{cw_pdmenu_s, 0, 'Invert Y'}, $
                ;{cw_pdmenu_s, 0, 'Invert XY'}, $
                ;{cw_pdmenu_s, 0, '--------------'}, $
                ;{cw_pdmenu_s, 1, 'ImageInfo'}, $ ;info menu
                ;{cw_pdmenu_s, 0, 'ImageHeader'}, $
                ;{cw_pdmenu_s, 2, 'Statistics'} $
                ]

MenuBar = CW_PDmenu(MenuBar, MenuBarDefine, /mbar, /return_name, UValue='MenuBar', font=fontmedium)
Widget_Control,MenuBar,Event_Pro='NCView_MenuEvent'
;<-------------------------------------------------------------------------------

DataObj = { $
          Data:     ObjArr(4), $
          BaseName: ""         $
;           Raw: Obj_New(), $ ; Object to hold RAW (.fits) data
;           Red: Obj_New(), $ ; Object to hold Intermediate (.red.fits) data
;           Slp: Obj_New(), $ ; Object to hold Slope (.slp.fits) data
;           Dia: Obj_New()  $ ; Object to hold Diagnostic (.dia.fits) data 
          }

Images = { $
         DefaultImageSize: [512L, 512L],  $
         DefaultPannerSize: [121L, 121L], $
         DefaultPlotSize: [0L, 0L],       $ 
         HeaderSize: [0L, 0L],            $
         ColorBarHeight: 6,               $
         ScaledImage: Ptr_New(),          $  ;; This is the rescaled image
         DisplayImage: Ptr_New(),         $  ;; This is the bit of the image that is displayed
         PannerImage: Ptr_New()           $  ;; This is the panner image. 
         }

State = { $
        MouseModeList: ['Standard','Zoom','Pixel History'],  $
        MouseMode: '',                      $
        ImageRead: 0B,                      $
        ImageLoaded: [0B,0B,0B,0B],         $
        ImageModeList: ['Raw','Intermediate','Fit Slope','Diagnostic'], $
        ImageMode: '',                      $
        FilePath: '',                       $
        BasePad: [0L, 0L],                  $
        HeaderPad: [0L, 0L],                $
        ImageDisplayed: 0B,                 $
        ImageWindowSize: [512L, 512L],      $   
        HeaderCharLine: [90L,45L],          $
        HeaderScrSize: [400L,400L],         $
        HeaderTextOffset: [0,-35],          $
        ImageWindowZoom: 1,                 $
        ImageSize: [0L, 0L],                $
        CurrentImageID: 0,                  $
        CurrentPannerID: 0,                 $
        CurrentOverID: 0,                   $
        CurrentPixel: [0,0],                $
        CurrentValue: 0.0,                  $
        CurrentRead: 0,                     $
        CurrentImageTypeIndex: 0,           $
        ZoomLevel: 0,                       $
        ZoomFactor: 1.0,                    $
        Coord: [0,0],                       $
        DisplayCoord: [0,0],                $
        Offset: [0,0],                      $
        ScreenSize: [0.0,0.0],              $
        CenterPixel: [0,0],                 $
        PannerScale: 0.0,                   $
        PannerOffset: [0,0],                $
        ButtonPressed: 0B,                  $
        RampPlotted: 0B,                    $
        RedRampPlotted: 0B,                 $
        RawRampPlotted: 0B,                 $
        ImageScaling: '',                   $
        Buffer: 0,                          $
        ASinhBeta: 0.1                      $

        }

IDs = { $
      TopLevelID: 0L,        $
      OnReadID: 0L,          $
      TotalReadsID: 0L,      $
      FileNameID: 0L,        $
      SCAID: 0L,             $
      DrawColorBarID: 0L,    $
      WidColorBarID: 0L,     $
      DrawImageID: 0L,       $
      WidImageID: 0L,        $
      DrawImagePannerID: 0L, $
      WidImagePannerID: 0L,  $
      PannerPixMapID: 0L,    $
      DrawImageOverID: 0L,   $
      WidImageOverID: 0L,    $
      LocationID: 0L,        $
      HeaderViewBaseID: 0L,  $
      HeaderViewTextID: 0L,  $
      PixHistoryBaseID: 0L,  $
      DrawPixHistoryID: 0L,  $
      WidPixHistoryID: 0L,   $
      PixHistPixmapID: 0L,   $
      FrameSliderID: 0L,     $
      ImageModeID: 0L        $
      }

Colors = { $
         Inverted: 0,               $
         NColors: 0B,               $
         RVect: Ptr_New(),          $
         GVect: Ptr_New(),          $
         BVect: Ptr_New(),          $
         ImageCTID: 0,              $
         CurrentStretch: Ptr_New(), $
         PlotRVect: Ptr_New(),      $
         PlotGVect: Ptr_New(),      $
         PlotBVect: Ptr_New(),      $
         Brightness: 0.5,           $
         Contrast: 0.5              $
         }
 
Plot = { $
       PixelXID: 0L,         $
       PixelYID: 0L,         $
       LocationID: 0L,       $
       MinXTextID: 0L,       $
       MaxXTextID: 0L,       $
       MinYTextID: 0L,       $
       MaxYTextID: 0L,       $       
       SlopeTextID: 0L,      $
       SlopeETextID: 0L,     $
       InterceptTextID: 0L,  $
       InterceptETextID: 0L, $
       RestoreRangeID: 0L,   $ 
       RampID: 0L,           $
       DifferenceID: 0L,     $
       RedRampID: 0L,        $
       RawRampID: 0L,        $
       MinX: 0.0,            $
       MaxX: 0.0,            $
       MinY: 0.0,            $
       MaxY: 0.0,            $
       MinXSv: 0.0,          $
       MaxXSv: 0.0,          $
       MinYSv: 0.0,          $
       MaxYSv: 0.0,          $
       Slope: [0.0,0.0],     $
       Intercept: [0.0,0.0], $
       Coord: [0,0],         $
       TextOutID: 0L,        $
       EPSOutID: 0L,         $
       x: Ptr_New(),         $
       y: Ptr_New(),         $
       f: Ptr_New(),         $
       FirstFrame: 0,        $
       LastFrame: 0,         $
       PixelString: '',      $
       PixHistZoomed: 0B,    $
       PixHistBoxStartX: 0,  $
       PixHistBoxStartY: 0,  $
       PixHistBoxCurX: 0,    $
       PixHistBoxCurY: 0     $
       }

Font = { $
       FontType: fonttype,       $
       CurrentFont: currentfont, $
       FontSize: fontsize        $
       }
       

IDs.TopLevelID = TopLevelID
State.FilePath = path 
if n_elements(buffer) eq 0 then State.Buffer=0 else State.Buffer=1
; LeftBaseID = Widget_Base(TopLevelID, Column=1, /Base_Align_Right, /Base_Align_Top) 

; TrackBaseID1 = Widget_Base(LeftBaseID, Row=1)

; InfoBaseID1 = Widget_Base(TrackBaseID1, Column=1, /Base_Align_Right)

; ButtonBarBaseID1 = Widget_Base(LeftBaseID, Column=1, /Base_Align_Center)

; ;PlotBaseID = Widget_Base(TrackBaseID, Column=1)


; ImageBaseID1 = Widget_Base(LeftBaseID, Column=1, /Base_Align_Left, $
;                           UValue='ImageBase')

; TmpString = string(0, 0, format='("(",i5,",",i5,")")')
                     
; ButtonBaseID1 = Widget_Base(ButtonBarBaseID1, Row=1) 
; LocationID1 = Widget_Label(ButtonBaseID1,Value=TmpString,UValue='Location', Frame=1)
; AutoScaleID1 = Widget_Button(ButtonBaseID1, Value='Auto Scale', UValue='AutoScale')
; FullScaleID1 = Widget_Button(ButtonBaseID1, Value='Full Scale', UValue='FullScale')
; DummyID1 = Widget_Label(ButtonBaseID1, Value='')
; ZoomInID1 = Widget_Button(ButtonBaseID1, Value='Zoom -', UValue='ZoomIn')
; ZoomOutID1 = Widget_Button(ButtonBaseID1, Value='Zoom +', UValue='ZoomOut')

; ;PlotBaseID = Widget_Base(
; ImageWindowSize1=[512,384]

; ImageID1 = Widget_Draw(ImageBaseID1, UValue='Image', /Motion_Events, /Button_Events, $
;                        Keyboard_Events=2, scr_xsize=ImageWindowSize1[0], $
;                        scr_ysize=ImageWindowSize1[1],frame=5)

RightBaseID = Widget_Base(TopLevelID, Column=1, /Base_Align_Right)

;------------------------------------------------------------------------------->
;; Define our bases for all the rest of the windows
TrackBaseID = Widget_Base(RightBaseID, Row=1)

InfoBaseID = Widget_Base(TrackBaseID, Column=1, /Base_Align_Right)
 
ReadBaseID = Widget_Base(InfoBaseID, Row=1, /Base_Align_Right)

ButtonBarBaseID = Widget_Base(RightBaseID, Column=2)


ImageBaseID = Widget_Base(RightBaseID, Column=1, /Base_Align_Left, $
                          UValue='ImageBase')
ColorBarBaseID = Widget_Base(RightBaseID, UValue='ColorBarBase', $
                             Column=1, /Base_Align_Left, $
                             Frame=2)
OnReadID = CW_FIELD(ReadBaseID, UValue='OnRead', $
                     Title='On Read ',Value=0, /Return_Events, $
                     XSize=6, font=Font.FontType[CurrentFont])
TotalReadsID = CW_FIELD(ReadBaseID, UValue='TotalReads',Value=0, $
                        XSize=6, font=Font.FontType[CurrentFont],Title='of')

ReadBrowseBckID = Widget_Button(ReadBaseID, UValue="ReadBrowseBck", Value="<")
ReadBrowseFwdID = Widget_Button(ReadBaseID, UValue="ReadBrowseFwd", Value=">")

; Get the geometry of readbase 
ReadBaseGeom = Widget_Info(ReadBaseID, /Geometry) 

FrameSliderID = Widget_Slider(InfoBaseID, Minimum=0, Maximum=1, UValue='FrmSlider', $
                             xsize=ReadBaseGeom.xsize, Event_Pro='NCView_ReadEvent')
; MaxTextID = CW_FIELD(InfoBaseID, UValue='MaxText',/floating, $
;                      Title='Max=',Value=0, /Return_Events, $
;                      XSize=12, font=fontsmall)

TmpString = string(State.CurrentPixel[0], State.CurrentPixel[1], State.CurrentValue, $
                   format='("(",i5,",",i5,") ",g12.5)')

LocationID = Widget_Label(InfoBaseID,Value=TmpString,UValue='Location', Frame=1)
TmpString = 'No image loaded'
FileNameID = Widget_Label(InfoBaseID,Value=TmpString,UValue='Filename', Frame=1, $
                          /Sunken_Frame, /Dynamic_Resize)
SCAID = Widget_Label(InfoBaseID, Value='', UValue='SCA', Frame=1, $
                     /Sunken_Frame,/Dynamic_Resize)

PanImageID = Widget_Draw(TrackBaseID, xsize=Images.DefaultPannerSize[0], $
                         ysize=Images.DefaultPannerSize[1], frame=2, $
                         UValue='PanImage', /Button_Events, /Motion_Events)
OverImageID = Widget_Draw(TrackBaseID, xsize=Images.DefaultPannerSize[0], $
                          ysize=Images.DefaultPannerSize[1], frame=2, $
                          UValue='OverImage')


MouseModeBase = Widget_Base(ButtonBarBaseID, Row=2, /Base_Align_Center)
;State.MouseBehaviorList = ['Color','Zoom','Pixel History']
MouseModeListID = Widget_Droplist(MouseModeBase, Frame=1, $
                                      title='Mouse Ctl:', UValue='MouseMode', $
                                      Value=State.MouseModeList)
State.MouseMode = State.MouseModeList[0]

ImageModeBase = Widget_Base(ButtonBarBaseID, Row=2, /Base_Align_Center)
;State.MouseBehaviorList = ['Color','Zoom','Pixel History']
ImageModeID = Widget_Droplist(ImageModeBase, Frame=1, $
                              title='Image Disp:', UValue='ImageMode', $
                              Value=State.ImageModeList)

State.ImageMode = State.ImageModeList[0]

ButtonBaseID = Widget_Base(ButtonBarBaseID, Row=2) 
InvertID = Widget_Button(ButtonBaseID, Value='Invert', UValue='Invert')
AutoScaleID = Widget_Button(ButtonBaseID, Value='Auto Scale', UValue='AutoScale')
FullScaleID = Widget_Button(ButtonBaseID, Value='Full Scale', UValue='FullScale')
DummyID = Widget_Label(ButtonBaseID, Value='')
ZoomInID = Widget_Button(ButtonBaseID, Value='Zoom In', UValue='ZoomIn')
ZoomOutID = Widget_Button(ButtonBaseID, Value='Zoom Out', UValue='ZoomOut')
FullViewID = Widget_Button(ButtonBaseID, Value='Full View', UValue='FullView')
CenterID = Widget_Button(ButtonBaseID, Value='Center', UValue='Center')

;PlotID = Widget_Draw(PlotBaseID, UValue='Plot', scr_xsize=320, scr_ysize=240)

ImageID = Widget_Draw(ImageBaseID, UValue='Image', /Motion_Events, /Button_Events, $
                      Keyboard_Events=2, scr_xsize=Images.DefaultImageSize[0], $
                      scr_ysize=Images.DefaultImageSize[1])

ColorBarID = Widget_Draw(ColorBarBaseID, UValue='ColorBar', $
                         scr_xsize=Images.DefaultImageSize[0], $
                         scr_ysize=Images.ColorBarHeight)



;<-------------------------------------------------------------------------------

Crap=0

Widget_Control,IDs.TopLevelID,/Realize
Widget_Control,PanImageID,Draw_Motion_Events=0

;; Set IDs 
IDs.WidImageID = ImageID
Widget_Control,ImageID,Get_Value=thisID
IDs.DrawImageID = thisID
IDs.WidImagePannerID = PanImageID
Widget_Control,PanImageID,Get_Value=thisID 
IDs.DrawImagePannerID = thisID
IDs.WidImageOverID = OverImageID
Widget_Control,OverImageID,Get_Value=thisID
IDs.DrawImageOverID = thisID
IDs.WidColorBarID = ColorBarID
Widget_Control,ColorBarID,Get_Value=thisID
IDs.DrawColorBarID = thisID

IDs.OnReadID = OnReadID
IDs.TotalReadsID = TotalReadsID
IDs.LocationID = LocationID
IDs.FileNameID = FileNameID
IDs.SCAID = SCAID
IDs.ImageModeID = ImageModeID

IDs.FrameSliderID = FrameSliderID

Colors.NColors = !D.table_size - 9
Colors.RVect = Ptr_New(bytarr(Colors.NColors))
Colors.GVect = Ptr_New(bytarr(Colors.NColors))
Colors.BVect = Ptr_New(bytarr(Colors.NColors))
Colors.ImageCTID = 0 ;; Start with a greyscale image

Colors.PlotRVect = Ptr_New(Colors.NColors*[1,0,0,0,1,1,1,0])
Colors.PlotGVect = Ptr_New(Colors.NColors*[1,0,0,1,0,1,0,1])
Colors.PlotBVect = Ptr_New(Colors.NColors*[1,0,1,0,0,0,1,1])

; Default scaling to linear
State.ImageScaling='linear'

State.ScreenSize = Get_Screen_Size() 
plotScale = 0.33
plotXsizemin = 600
plotXsize = (PlotScale*State.ScreenSize[0]) > plotXsizemin
plotYSize = 0.75*plotXsize
Images.DefaultPlotSize = [plotXsize,plotYsize]
State.HeaderScrSize = [plotXsize,plotXsize]

Widget_Control, IDs.TopLevelID, tlb_get_size=tmp_event
State.BasePad = tmp_event - State.ImageWindowSize

Widget_Control, ReadBaseID, Event_Pro='NCView_ReadEvent'
Widget_Control, IDs.WidImageID, Event_Pro='NCView_DrawEvent'

Window,/free,xsize=Images.DefaultPannerSize[0],ysize=Images.DefaultPannerSize[1], $
       /pixmap 
IDs.PannerPixMapID=!D.Window

;; Top level structrue. 
info = {                 $
       State: State,     $
       DataObj: DataObj, $
       Images: Images,   $
       Colors: Colors,   $
       IDs: IDs,         $
       Plot: Plot,       $
       Font: Font        $
       }

infoP = Ptr_New(info,/No_Copy)

NCView_GetCT, (*infoP).Colors.ImageCTID, infoP

Widget_Control,IDs.TopLevelID,Set_UValue=infoP

;; Register with the XManager.
XManager,'ncview',IDs.TopLevelID,Cleanup="NCView_Cleanup",/No_Block

end
;-------------------------------------------------------------------------------



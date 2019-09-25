pro NCView_MakePan,infoP

SizeRatio = (*infoP).State.ImageSize[1]/(*infoP).State.ImageSize[0]

if (SizeRatio ge 1) then $
  (*infoP).State.PannerScale=float((*infoP).Images.DefaultPannerSize[0])/float((*infoP).State.ImageSize[1]) $
else $
  (*infoP).State.PannerScale=float((*infoP).Images.DefaultPannerSize[0])/float((*infoP).State.ImageSize[0])

tmp_image = (*(*infoP).Images.ScaledImage)[0:(*infoP).State.ImageSize[0]-1,0:(*infoP).State.ImageSize[1]-1]
tmp_image = congrid(tmp_image, round((*infoP).State.PannerScale*(*infoP).State.ImageSize[0])>1, $
                    round((*infoP).State.PannerScale*(*infoP).State.ImageSize[1])>1, $
                    /Center,/Interp)

Ptr_Free,(*infoP).Images.PannerImage
(*infoP).Images.PannerImage = Ptr_New(tmp_image)

(*infoP).State.PannerOffset[0] = round(((*infoP).Images.DefaultPannerSize[0] - (size(tmp_image))[1])/2)
(*infoP).State.PannerOffset[1] = round(((*infoP).Images.DefaultPannerSize[1] - (size(tmp_image))[2])/2)

end

pro NCView_Display,infoP

Wset, (*infoP).IDs.DrawImageID
tv, (*(*infoP).Images.DisplayImage)

end


pro NCView_UpdateDisplay,infoP

NCView_Offset,infoP
NCView_SetDisplayImage,infoP
NCView_Display,infoP

_imgIdx=(*infoP).State.CurrentImageTypeIndex

;; Update the readinfo 
Widget_Control,(*infoP).IDs.OnReadID, Set_Value=(*infoP).DataObj.Data[_imgIdx]->getCurFrame()+1
Widget_Control,(*infoP).IDs.TotalReadsID, Set_Value=(*infoP).DataObj.Data[_imgIdx]->NPlane()
Widget_Control,(*infoP).IDs.FrameSliderID, Set_Slider_Min=1, $
               Set_Slider_Max=(*infoP).DataObj.Data[_imgIdx]->NPlane(), $
               Set_Value=1
Widget_Control,(*infoP).IDs.FrameSliderID, Set_Value=(*infoP).DataObj.Data[_imgIdx]->getCurFrame()+1
NCView_UpdateColorBar,infoP

(*infoP).State.ImageDisplayed=1

;; Update the panner pixmap...
WSet,(*infoP).IDs.PannerPixMapID
tv, *((*infoP).Images.PannerImage), (*infoP).State.PannerOffset[0], (*infoP).State.PannerOffset[1]
;; and the panner window. 
WSet,(*infoP).IDs.DrawImagePannerID
tv, *((*infoP).Images.PannerImage), (*infoP).State.PannerOffset[0], (*infoP).State.PannerOffset[1]
NCView_DrawBox,infoP,/NoRefresh

end

pro NCView_Offset,infoP

(*infoP).State.Offset = round( (*infoP).State.CenterPixel - $
                               (0.5*(*infoP).State.ImageWindowSize/(*infoP).State.ZoomFactor) )


end

;; Update the color bar.
pro NCView_UpdateColorBar,infoP
;print,(*infoP).Colors.NColors
WSet, (*infoP).IDs.DrawColorBarID
xsize = (Widget_Info((*infoP).IDs.WidColorBarID, /geometry)).xsize
b = congrid( findgen((*infoP).Colors.NColors), xsize) + 8
c = replicate(1, (*infoP).Images.ColorBarHeight)
a = b # c

tv, a

end

;;
pro NCView_ScaleImage,infoP

_imgIdx=(*infoP).State.CurrentImageTypeIndex

Ptr_Free,(*infoP).Images.ScaledImage

tmp_image = (*infoP).DataObj.Data[(*infoP).State.CurrentImageTypeIndex]->Plane(id=(*infoP).DataObj.Data[_imgIdx]->getCurFrame())

stats = moment(tmp_image,/nan)

mean=stats[0]
sig=sqrt(stats[1])
thismin=mean-3.*sig
thismax=mean+3.*sig

case (*infoP).State.ImageScaling of
    'linear': begin 
        tmp_image = bytscl(tmp_image, min=thismin, max=thismax, /nan)
    end
    'log' : begin 
        offset = thismin-(thismax-thismin)*0.01
        tmp_image = bytscl(alog10(tmp_image-offset), min=alog10(thismin-offset), $
                            max=alog10(thismax-offset), /nan)
    end
    'histeq' : begin 
        tmp_image = bytscl(hist_equal(tmp_image, minv=thismin, maxv=thismax), /nan)
    end
    'asinh' : begin 
        tmp_image = bytscl(asinh((tmp_image - thismin)/(*infoP).State.ASinhBeta), $
                           min=0, max=asinh((thismax-thismin)/(*infoP).State.ASinhBeta), /nan)
    end
endcase

(*infoP).Images.ScaledImage = Ptr_New(tmp_image)

tmp_image = 0

end

pro NCView_SetDisplayImage,infoP

_imgIdx=(*infoP).State.CurrentImageTypeIndex

Ptr_Free,(*infoP).Images.DisplayImage

xsize = (*infoP).State.ImageWindowSize[0]
ysize = (*infoP).State.ImageWindowSize[1]

tmp_image = bytarr(xsize,ysize)
(*infoP).Images.DisplayImage = Ptr_New(tmp_image)

ViewMin = round((*infoP).State.CenterPixel - $
                  (0.5 * (*infoP).State.ImageWindowSize/(*infoP).State.ZoomFactor))
ViewMax = round(ViewMin + (*infoP).State.ImageWindowSize/(*infoP).State.ZoomFactor)
ViewMin = (0 > ViewMin < ((*infoP).DataObj.Data[_imgIdx]->SpatialDimension() - 1))
ViewMax = (0 > ViewMax < ((*infoP).DataObj.Data[_imgIdx]->SpatialDimension() - 1))

NewSize = round((ViewMax - ViewMin + 1)*(*infoP).State.ZoomFactor) > 1
StartPos = abs( round((*infoP).State.Offset*(*infoP).State.ZoomFactor) < 0)

tmp_image = congrid( (*(*infoP).Images.ScaledImage)[ViewMin[0]:ViewMax[0],ViewMin[1]:ViewMax[1]], $
                      NewSize[0],NewSize[1])
xmax = NewSize[0] < ((*infoP).State.ImageWindowSize[0] - StartPos[0])
ymax = NewSize[1] < ((*infoP).State.ImageWindowSize[1] - StartPos[1])

(*(*infoP).Images.DisplayImage)[StartPos[0], StartPos[1]] = tmp_image[0:xmax-1,0:ymax-1]

tmp_image=0 

end

pro NCView_Zoom, Direction, infoP

case Direction of 

    'ZoomIn'  : (*infoP).State.ZoomLevel += 1
    'ZoomOut' : (*infoP).State.ZoomLevel -= 1
    'none'    : (*infoP).State.CenterPixel = round((*infoP).State.ImageSize/2.)
        
    else: print,'Unkown zoom option'

endcase

(*infoP).State.ZoomFactor = 2.0^((*infoP).State.ZoomLevel)

NCView_UpdateDisplay, infoP


end


pro NCView_DrawBox, infoP, NoRefresh=NoRefresh

WSet,(*infoP).IDs.DrawImagePannerID
device, copy=[0,0,(*infoP).Images.DefaultPannerSize[0],(*infoP).Images.DefaultPannerSize[1], 0, 0, (*infoP).IDs.PannerPixMapID]
ViewMin = round((*infoP).State.CenterPixel - $
                (0.5*(*infoP).State.ImageWindowSize/(*infoP).State.ZoomFactor))
ViewMax = round(ViewMin + (*infoP).State.ImageWindowSize/(*infoP).State.ZoomFactor)-1

BoxX = float((([ViewMin[0], $
                ViewMax[0], $
                ViewMax[0], $
                ViewMin[0], $
                ViewMin[0]]) * (*infoP).State.PannerScale) + (*infoP).State.PannerOffset[0])
BoxY = float((([ViewMin[1], $
                ViewMin[1], $
                ViewMax[1], $
                ViewMax[1], $
                ViewMin[1]]) * (*infoP).State.PannerScale) + (*infoP).State.PannerOffset[1])

w = where(BoxX LT 0, count)
if (count GT 0) then BoxX[w] = 0
w = where(BoxY LT 0, count)
if (count GT 0) then BoxY[w] = 0
w = where(BoxX GT (*infoP).Images.DefaultPannerSize[0]-1, count)
if (count GT 0) then BoxX[w] = (*infoP).Images.DefaultPannerSize[0]-1
w = where(BoxY GT (*infoP).Images.DefaultPannerSize[1]-1, count)
if (count GT 0) then BoxY[w] = (*infoP).Images.DefaultPannerSize[1]-1

if not n_elements(NoRefresh) then begin
    NCView_LoadImageCT, infoP
    device,copy=[0,0,(*infoP).Images.DefaultPannerSize[0],(*infoP).Images.DefaultPannerSize[1], $
                 0,0,(*infoP).IDs.PannerPixMapID]
endif 

NCView_LoadPlotCT,infoP
plots,BoxX,BoxY,/device,color=3,psym=0
NCView_LoadImageCT,infoP

end

pro NCView_LoadPlotCT, infoP
tvlct,(*(*infoP).Colors.PlotRVect),(*(*infoP).Colors.PlotGVect),(*(*infoP).Colors.PlotBVect)
end

pro NCView_LoadImageCT, infoP
tvlct,(*(*infoP).Colors.RVect)[(*(*infoP).Colors.CurrentStretch)], $
      (*(*infoP).Colors.GVect)[(*(*infoP).Colors.CurrentStretch)], $
      (*(*infoP).Colors.BVect)[(*(*infoP).Colors.CurrentStretch)],8
end

pro NCView_Pan, x, y, infoP

thisEvent = [x, y]

NewPosition = (*infoP).State.PannerOffset > thisEvent < $

             (((*infoP).State.PannerOffset) + (((*infoP).State.ImageSize)*((*infoP).State.PannerScale)))

(*infoP).State.CenterPixel = round( (NewPosition-(*infoP).State.PannerOffset)/(*infoP).State.PannerScale)

NCView_DrawBox, infoP, /NoRefresh
NCView_Offset, infoP

end

pro NCView_SetASinhBeta, infoP

b=string((*infoP).State.ASinhBeta)

formline = strcompress('0,float,' + b + $
                       ',label_left=Asinh beta parameter: ,width=10')

formdesc = [formline, $
           '0, button, Set beta, quit', $
           '0, button, Cancel, quit']

textform = cw_form(formdesc, ids=ids, /column, $
                   title = 'ASinh Stretch settings')

if (textform.tag2 EQ 1) then return

(*infoP).State.ASinhBeta = float(textform.tag0)

end

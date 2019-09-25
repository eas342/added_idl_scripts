function NCDHAS_Help, event

; compound button widget return different event structures relative to
; button widget... sigh. 
Widget_Control, event.id, Get_UValue=UValue
if UValue eq '0' then UValue=event.value ; CW_BGROUP gets a UValue of 0... not very elegant or robust...

case UValue of
    'hwrite_inter' : _txt=['If set, intermediate processing image will be written as BASE+.red.fits.', $
                           'The intermediate image will be a single ramp of the same length as the', $
                           'input ramp, but will all selected processing steps (eg. reference', $
                           'correction, dark subtraction, linearity correction, etc) applied.', $
                           'Select this if you want to look at the processed data ramp.']
    'hwrite_slope' : _txt=['If set, slope image will written out as BASE+.slp.fits', $
                           'Slope image consists of:', $
                           '  FRAME 1 = slope', $
                           '  FRAME 2 = slope error', $
                           'Select this if you want to look at the slope image.']
    'hwrite_diag'  : _txt=['If set, diagnostic data will written out as BASE+.dia.fits', $
                           'Current diagnostic info includes: ', $
                           '  FRAME 1 = Mask value', $
                           '  FRAME 2 = Frame ID of saturation (0 index)', $
                           '  FRAME 3 = Fit intercept', $
                           '  FRAME 4 = Fit intercept error', $
                           '  FRAME 5 = Fit chisq', $
                           'Select this if you want any of the above info']
    'hover_write'  : _txt=['If set, any existing processed files will be overwritten.', $
                           'i.e., and previous .red.fits, .slp.fits, or .dia.fits files', $
                           'will be destroyed. If not set, but previous files exist, the', $
                           'DHAS will halt with an error.', $
                           'Set this if you don''t need to keep any old processed data.']
    'hverbose'     : _txt=['Processing information is sent to screen', $
                           'This tends to make less sense for processing via the GUI...']
    'hlog'         : _txt=['Processing information is stored in a log file.', $
                           'Log file will be generated as ncdhas_BASE_DATE.log.', $
                           'Set this if you want a record of your processing.']
    'hmaxram'      : _txt=['Set value of maximum RAM to be used to process data.', $
                           'Units are in 512MB.  Note that RAM usage will be > 2x.', $
                           'Fractional values are allowed.', $
                           'Example: ', $
                           '   Max Ram of 4 means that 4 x 512MB ~ 2GB of RAM will be used', $
                           'Image will be broken into subsections to maintain RAM usage as', $
                           'specified level modulo calibration images.']
    'hdhasexec'    : _txt=['Name of DHAS executable.  Note that if the executable is not in', $
                           'your path, specify the full path, eg', $
                           '/usr/local/bin/ncdhas', $
                           'Use this if you''ve compiled the DHAS with a different name or', $
                           'placed the exectuable in a location not in your path.']
    else: return, 1

endcase

; Generate a modal widget with the help text
_result = DIALOG_MESSAGE(_txt,/Center, Title='NCDHAS Help', /Information)

return, 1

end

; need an event handler
; separate info structure?  don't really need to pass any 
; info back and forth...

; Needs resizing and optimal sizing to see all tabs at startup...
;

pro NCDHAS_Execute_Cleanup, TopLevelID

end 

pro NCDHAS_Process_Data, event ;, infoP

print,'construct the command line'
print,'execute the dhas'
print,'block untile complete...'
; Update the viewer infoP structure. 
; spawn execute command. 
;   Have a text window with procesing info? 
;   Will have to block until processing is done to make sure 
;     the viewer doesn't try to instantiate objects on not yet
;     created data. 
; Quit, return to view - calling code in viewer will update it's 
;   state to reflect newly generated data. 

; Destroy the widget, returns control to the veiwer. 
Widget_Control, event.top, /Destroy

end

pro NCDHAS_Execute_Event, event

Widget_Control, event.id, Get_UValue=UValue
EventType = tag_names(event,/structure) 
case EventType of 
    
    'WIDGET_BASE' : begin  ; Resize event
        Widget_Control, event.top, Scr_XSize=event.x, Scr_YSize=event.y
    end

    'WIDGET_TAB' : begin   ; Swithcing between Tabs - don't need to do anything
    end

    else : begin           ; Handle all other events (ie. constuct CL)
        case UValue of
            'cancel'  : Widget_Control, event.top, /Destroy
            'reset'   : print,'Reseting to defaults, book keeping'
            'execute' : NCDHAS_Process_Data, event ;,infoP will have to pass the info struct from viewer
        endcase
        
       
    end

endcase

end

pro NCDHAS_Execute ;, infoP <- info struct from viewer so we can update the viewer on available data. 

; Top level base + tab widget
TopLevelID = Widget_Base(Title='NCDHAS Execution', Column=1, /Tlb_Size_Events) 
TabID      = Widget_Tab(TopLevelID, Multiline=2, Location=0)
; location = 0 top
;          = 1 bottom
;          = 2 left
;          = 3 right 

; Maybe write a parser to parse the default configuration file if it
; exists and set the defaults from there.  Minimizes places where we
; need to track default config changes. 

; The session configuration
DefaultRam=2
SessionConfigID = Widget_Base(TabID, Title='Session Configuration', Column=1)
; Hold the buttons...
SessionButtonsID = Widget_Base(SessionConfigID, Row=1)
; ...and the field
SessionFieldsID = Widget_Base(SessionConfigID, Column=1)

; Make the buttons and fields.
; For buttons, use two side by side CW button groups, one for setting
; values, the other for generating a 'Help' dialog. 
_sessionPar_UValues  = ['pwrite_inter','pwrite_slope','pwrite_diag','pover_write','pverbose','plog']
_sessionPar_Labels   = ['Write Inter.','Write Slope' ,'Write Diag.','Over Write', 'Verbose', 'Log' ]
_sessionPar_Defaults = [1             , 1            , 1           , 0           , 1       ,  1    ]
_sessionHelp_UValues = ['hwrite_inter','hwrite_slope','hwrite_diag','hover_write','hverbose','hlog']
_sessionHelp_Labels  = replicate('?',n_elements(_sessionPar_UValues))
SessionParID  = CW_BGROUP(SessionButtonsID, _sessionPar_Labels, Button_UValue=_sessionPar_UValues, $
                          Column=1, /NonExclusive, Set_Value=_sessionPar_Defaults)
SessionHelpID = CW_BGROUP(SessionButtonsID, _sessionHelp_Labels, Button_UValue=_sessionHelp_UValues, $
                          Column=1, Event_Func='ncdhas_help')

; No tool tips for fields.... 
MaxRAMBase   = Widget_Base(SessionFieldsID, Row=1)
MaxRAMID     = CW_Field(MaxRAMBase, Title='Max RAM', UValue='maxram', Value=1, /Return_Events, XSize=5)
MaxRAMHelpID = Widget_Button(MaxRAMBase, Value='?', UValue='hmaxram', Event_Func='ncdhas_help') 
DHASExecBase   = Widget_Base(SessionFieldsID, Row=1)
DHASExecID     = CW_Field(DHASExecBase, Title='DHAS Executable', UValue='dhasexec', Value="ncdhas", /Return_Events, XSize=10) 
DHASExecHelpID = Widget_Button(DHASExecBase, Value='?', UValue='hdhasexec', Event_Func='ncdhas_help')

; Set defaults                        
Widget_Control, MaxRamID,     Set_Value =DefaultRam

; The reference pixel configuration
ReferenceConfigID = Widget_Base(TabID, Title='Reference Pixels', Column=1)

; The calibartion configuration
CalibrationConfigID = Widget_Base(TabID, Title='Calibration', Column=1)

; The ramp fit configuration
RampFitConfigID = Widget_Base(TabID, Title='Ramp Fit', Column=1)

; A base to hold 'reset', 'execute', 'done' buttons.
ControlID = Widget_Base(TopLevelID, Row=1) 
ResetButtonID = Widget_Button(ControlID, Value='Reset', UValue='reset', $
                             ToolTip='Reset all values to default')
ExecuteButtonID = Widget_Button(ControlID, Value='Run DHAS', UValue='execute', $
                               ToolTip='Run DHAS with the above configuration')
QuitButtonID = Widget_Button(ControlID, Value='Cancel', UValue='cancel', $
                            ToolTip='Exit without executing the DHAS')

Widget_Control, TopLevelID, /Realize
XManager,'ncdhas_execute',TopLevelID,Cleanup="NCDHAS_Execute_Cleanup",/No_Block

end



function ApplyGUIParameters(handles, Normalized,HeaderIndex,SampleRate,PlotRange,TrigDelay,PlotOddEvenAll,...
    PlotLastSignal,BPFilter,BPFreq,BP_Order,NotchFilter,NotchFreq,TrigCount,AmpLim,RefreshRate)
% filter
if NotchFilter
    set(handles.checkbox_Notch,'Value',1);
else
    set(handles.checkbox_Notch,'Value',0);
end
set(handles.edit_NotchLowCut,'string',num2str(NotchFreq(1)));
set(handles.edit_NotchHighCut,'string',num2str(NotchFreq(2)));
if BPFilter
    set(handles.checkbox_BP,'Value',1);
else
    set(handles.checkbox_BP,'Value',0);
end
SetPopupmenue(handles.popupmenu_LowCut,BPFreq(1));
SetPopupmenue(handles.popupmenu_HighCut,BPFreq(2));
set(handles.edit_FIRBPOrder,'string',num2str(BP_Order));
set(handles.edit_RefreshRate,'string',num2str(RefreshRate));
% Others
if PlotLastSignal
    set(handles.checkbox_PlotLastSignal,'Value',1);
else
    set(handles.checkbox_PlotLastSignal,'Value',0);
end
if PlotOddEvenAll(1)
    set(handles.checkbox_OddTrig,'Value',1);
else
    set(handles.checkbox_OddTrig,'Value',0);
end
if PlotOddEvenAll(2)
    set(handles.checkbox_EvenTrig,'Value',1);
else
    set(handles.checkbox_EvenTrig,'Value',0);
end
if PlotOddEvenAll(3)
    set(handles.checkbox_AllTrig,'Value',1);
else
    set(handles.checkbox_AllTrig,'Value',0);
end
if Normalized
    set(handles.checkbox_Normalized,'Value',1);
else
    set(handles.checkbox_Normalized,'Value',0);
end
set(handles.edit_TrigDelayOdd,'string',num2str(TrigDelay(1)));
set(handles.edit_TrigDelayEven,'string',num2str(TrigDelay(2)));
set(handles.edit_PlotStartTime,'string',num2str(PlotRange(1)));
set(handles.edit_PlotEndTime,'string',num2str(PlotRange(2)));
set(handles.edit_SampleRate,'string',num2str(SampleRate));
set(handles.popupmenu_Ch1,'Value',HeaderIndex(1));
if length(HeaderIndex)==2
    set(handles.popupmenu_Ch2,'Value',HeaderIndex(2)+1);
    set(handles.popupmenu_Ch3,'Value',1);
elseif length(HeaderIndex)==3
    set(handles.popupmenu_Ch2,'Value',HeaderIndex(2)+1);
    set(handles.popupmenu_Ch3,'Value',HeaderIndex(3)+1);
else
    set(handles.popupmenu_Ch2,'Value',1);
    set(handles.popupmenu_Ch3,'Value',1);
end
SetPopupmenue(handles.popupmenu_TriggerCount,TrigCount);
SetPopupmenue(handles.popupmenu_Sens,round(AmpLim(2)/1.5));

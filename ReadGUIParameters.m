function [Normalized,HeaderIndex,SampleRate,PlotRange,TrigDelay,PlotOddEvenAll,...
          PlotLastSignal,BPFilter,BPFreq,BP_Order,NotchFilter,NotchFreq,TrigCount,AmpLim,RefreshRate] ...
        = ReadGUIParameters(handles)
    
    % Filters
    NotchFilter = get(handles.checkbox_Notch,'Value');
    NotchFreq = [str2num(get(handles.edit_NotchLowCut,'string')), ...
                 str2num(get(handles.edit_NotchHighCut,'string'))];      
    BPFilter = get(handles.checkbox_BP,'Value');
    BPFreq(1) = str2num(ReadPopupmenue(handles.popupmenu_LowCut));
    BPFreq(2) = str2num(ReadPopupmenue(handles.popupmenu_HighCut));
    BP_Order = str2num(get(handles.edit_FIRBPOrder,'string'));
    RefreshRate = str2num(get(handles.edit_RefreshRate,'string'));
    
    % Others
    PlotLastSignal = get(handles.checkbox_PlotLastSignal,'Value');
    PlotOddEvenAll = [get(handles.checkbox_OddTrig,'Value'), ...
                      get(handles.checkbox_EvenTrig,'Value'),...
                      get(handles.checkbox_AllTrig,'Value')];               
    Normalized = get(handles.checkbox_Normalized,'Value');   
    TrigDelay = [str2num(get(handles.edit_TrigDelayOdd,'string')), ...
                 str2num(get(handles.edit_TrigDelayEven,'string'))];
    PlotRange = [str2num(get(handles.edit_PlotStartTime,'string')), ...
                 str2num(get(handles.edit_PlotEndTime,'string'))];  
    SampleRate = str2num(get(handles.edit_SampleRate,'string'));
    
    H1 = get(handles.popupmenu_Ch1,'Value');
    H2 = get(handles.popupmenu_Ch2,'Value');
    H3 = get(handles.popupmenu_Ch3,'Value');
    if H2 == 1        H2 = [];    end
    if H3 == 1        H3 = [];    end
    HeaderIndex = [H1 H2-1 H3-1];  
    TrigCount = str2num(ReadPopupmenue(handles.popupmenu_TriggerCount)); 
    
    val = str2num(ReadPopupmenue(handles.popupmenu_Sens));
    AmpLim = 1.5*[-val val]; 
end



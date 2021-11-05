function reset_popupmenu_ChannelName(Header, handles)
if ~isempty(Header)
    num = length(Header);
    for i = 1:length(Header)
        if isempty(Header{i})
           num = i-1; 
           break;
        end
    end
    if get(handles.popupmenu_Ch1,'Value')>num
        set(handles.popupmenu_Ch1,'Value',1);
    end
    if get(handles.popupmenu_Ch2,'Value')>num+1
        set(handles.popupmenu_Ch2,'Value',1);
    end
    if get(handles.popupmenu_Ch3,'Value')>num+1
        set(handles.popupmenu_Ch3,'Value',1);
    end     
    set(handles.popupmenu_Ch1,'String',Header(1:num));
    set(handles.popupmenu_Ch2,'String',['NA' Header(1:num)]);
    set(handles.popupmenu_Ch3,'String',['NA' Header(1:num)]);   
end
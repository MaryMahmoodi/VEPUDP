function val = ReadPopupmenue(hObject)
    Vals = get(hObject,'String');
    Ind = get(hObject,'Value');
    if iscell(Vals) val=Vals{Ind}; else val=Vals(Ind,:); end
end
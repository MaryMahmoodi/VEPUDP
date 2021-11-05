function SetPopupmenue(hObject,val);
    Vals = get(hObject,'String');
    if iscell(Vals)
        for Ind=1:length(Vals)
            if str2num(Vals{Ind})==val
                set(hObject,'Value',Ind);
                break;
            end
        end
    else
        for Ind=1:size(Vals,1)
            if str2num(Vals(Ind,:))==val
                set(hObject,'Value',Ind);
                break;
            end
        end 
    end
end
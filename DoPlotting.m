function DoPlotting(t, Current_Signal, Averaged_Signal, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, ind, GUIhandles)
if ~isempty(GUIhandles) % Updating AmpLim & HeaderIndex
    Vals = get(GUIhandles.popupmenu_Sens,'String');
    Ind = get(GUIhandles.popupmenu_Sens,'Value');
    if iscell(Vals) val=Vals{Ind}; else val=Vals(Ind,:); end
    AmpLim = 1.5*[-str2num(val) str2num(val)];
    H1 = get(GUIhandles.popupmenu_Ch1,'Value');
    H2 = get(GUIhandles.popupmenu_Ch2,'Value');
    H3 = get(GUIhandles.popupmenu_Ch3,'Value');
    if H2 == 1        H2 = [];    end
    if H3 == 1        H3 = [];    end
    HeaderIndex = [H1 H2-1 H3-1];
end
switch ind % ind is used to check if it is Odd, Even or All case for plotting
    case {1}
        subtitle = 'Odd';
    case {2}
        subtitle = 'Even';
        if ~PlotOddEvenAll(1) ind=1; end
    case {3}
        subtitle = 'All (Odd & Even)';
        if ~PlotOddEvenAll(1) ind=ind-1; end
        if ~PlotOddEvenAll(2) ind=ind-1; end
end
PlotNum = sum(PlotOddEvenAll);
cnt=0;
for ch = HeaderIndex
    cnt = cnt+1;
    subplot(length(HeaderIndex),PlotNum,ind); ind = ind+PlotNum;
    if ~isempty(Averaged_Signal) && size(Averaged_Signal,1)>1
        if PlotLastSignal && size(Current_Signal,1)>1
            cla;
            plot(t,Averaged_Signal(:,ch),'blue',t,Current_Signal(:,ch),'green'); 
        else
            cla;
            plot(t,Averaged_Signal(:,ch),'blue'); 
        end
        xlim([t(1) t(end)]);
    else
        cla; plot(0); 
        if ~isempty(GUIhandles)
            PlotRange = [str2num(get(GUIhandles.edit_PlotStartTime,'string')), ...
                str2num(get(GUIhandles.edit_PlotEndTime,'string'))];
        end
        xlim(PlotRange);
    end
    if ~isempty(Header) title([Header{ch} ': ' subtitle]); end
    if ~isempty(AmpLim) ylim([AmpLim(1) AmpLim(2)]); end   
    if Normalized ylabel('Amplitude (uV)'); else ylabel('Amplitude'); end
    if (cnt == length(HeaderIndex)) xlabel('Time (s)'); end
    hold on; drawnow;
end
end
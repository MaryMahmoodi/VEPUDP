%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Negar Andishgan Co. Ltd. www.NegAnd.com
% EEG 3840/EEG 5000Q Online Triggered Data Reader
% Modified in March 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function VEP_UDP2(Normalized,HeaderIndex,SampleRate,PlotRange,TrigDelay,PlotOddEvenAll,PlotLastSignal,BPFilter,BPFreq,BP_Order,NotchFilter,NotchFreq,TrigCount,AmpLim,GUIhandles,RefreshRate)
global Started LoopBroken t Averaged_Signal_Odd Averaged_Signal_Even Averaged_Signal_All Header ErrorCode
clear ALL;
if nargin==0
%%%% Input variables (can be modified) %%%%
    Normalized = true; % False/True, depending on software online-setting
    HeaderIndex = [1,2]; % Indices of the headers/channels to be plotted
    SampleRate = 500; % Hz/Per second (depending on the device)
    
    PlotRange = [-0.4, 0.4]; % In seconds; Signal is plotted in this time-range
    TrigDelay = [0 0.1]; % [TrigDelay(1) TrigDelay(2)]: In seconds; the time when trigger is received
    PlotOddEvenAll = [1 1 1]; % 1/0: Plotting/Not plotting the signal related  to [odd, even, all] triggers, respectively
    PlotLastSignal = 1; % 1/0: Plotting/Not plotting the last signal
    TrigCount = 60; % number of trigger before stopping
    AmpLim = []; % Amplitude limits
        
    % Filter
    BPFilter = true; % true/false: using/not using IIR bandpass filter
    NotchFilter = false; % true/false: using/not using FIR notch filter
    BP_Order = 1001; % order of IIR bandpass filter, must be odd
    BPFreq = [0.5 35]; % bandpass filter [LowCut HighCut]
    NotchFreq = [48 52]; % notch filter [LowCut HighCut]     
    Started = true; % Flag, not to be changed
    GUIhandles = []; % It is used with GUI, better not to be changed
    RefreshRate = 4; % Rate for refreshing the plot
end

%%%% Filter initialization %%%%
[NotchNUM,NotchDEN] = iirnotch(mean(NotchFreq)*2/SampleRate,(NotchFreq(2)-NotchFreq(1))*2/SampleRate); %2nd order IIR notch
BPNUM = fir1(2*floor(BP_Order/2)+1,BPFreq*2/SampleRate,'bandpass'); BPDEN = 1; %FIR Filter

%%%% Range & time initialization
OddTrigRange = round(SampleRate*(PlotRange - TrigDelay(1)));
EvenTrigRange = round(SampleRate*(PlotRange - TrigDelay(2)));
if BPFilter
    OddTrigRange = OddTrigRange + floor(BP_Order/2);
    EvenTrigRange = EvenTrigRange + floor(BP_Order/2);
end
EvenTrigRange(2) = EvenTrigRange(1) + (OddTrigRange(2)-OddTrigRange(1)); 
t = linspace(PlotRange(1),PlotRange(2),OddTrigRange(2)-OddTrigRange(1)+1); % time axis
PlotRefreshDelay = 1/min([abs(RefreshRate) 25]); % seconds; Every PlotRefreshDelay, checking GUI Input (such as sensitivity) to refresh plot

%%%% UDP Setting %%%%
ServerPort = 12220;
ClientPort = 12221;
if(~isempty(instrfindall))
    fclose(instrfindall);
end
u = udp('127.0.0.1','RemotePort',ServerPort, ...
    'Localport',ClientPort, 'ByteOrder','bigEndian');
set(u,'InputBufferSize',50*65535);
set(u,'InputDatagramPacketSize',65535);
set(u,'Timeout',10);
fopen(u);

%%%% Applying initial values
ErrorCode = 0;
OddCounter = 0;
EvenCounter = 0;
Current_Signal = 0;
Previous_Signal = 0;
Averaged_Signal_Odd = 0;
Averaged_Signal_Even = 0;
Averaged_Signal_All = 0;
ByteCount = 1;
Header = [];
IsOdd = true;
JustStarted = true;
LoopBroken = false;

%%%% Main %%%%
tic;
PreviousTime = toc;
while ByteCount && TrigCount>(OddCounter+EvenCounter) 
    % Reading new data
    [Packet,ByteCount] = fread(u,1);
    [LatestHeader,Data] = SplitNrSignUDPPacket(Packet,Normalized);     
    if ~isempty(GUIhandles) && toc-PreviousTime>PlotRefreshDelay        
        if ~get(GUIhandles.pushbutton_StartStop, 'Value')
            LoopBroken = true;
            Started = false;
            break;
        end
        if IsOdd % Waiting for odd trigger
            Even_Current_Signal = Current_Signal;
            Odd_Current_Signal = Previous_Signal;                       
        else
            Even_Current_Signal = Previous_Signal;
            Odd_Current_Signal = Current_Signal;
        end
        Ind = 1;
        if PlotOddEvenAll(1) % Plotting odd cases
            DoPlotting(t, Odd_Current_Signal, Averaged_Signal_Odd, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, Ind, GUIhandles);
        end    
        Ind = 2;
        if PlotOddEvenAll(2) % Plotting even cases
            DoPlotting(t, Even_Current_Signal, Averaged_Signal_Even, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, Ind, GUIhandles);
        end
        Ind = 3;
        if PlotOddEvenAll(3) % Plotting all cases
            DoPlotting(t, Current_Signal, Averaged_Signal_All, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, Ind, GUIhandles);
        end                                
        PreviousTime = toc;
    end    
    if isempty(Data)
        ErrorCode = 1; 
        LoopBroken = true;
        break;
    else
        % Initialization based on the first package
        if JustStarted
            Header = LatestHeader;
            SampleSize = size(Data,1);
            BufferLength = 2*SampleSize + max([OddTrigRange(2)-OddTrigRange(1),abs(OddTrigRange(1)),abs(OddTrigRange(2)),abs(EvenTrigRange(1)),abs(EvenTrigRange(2))]);
            HeaderNumber = size(Header,2);
            for i=1:size(Header,2)
                if isempty(Header{i})
                    HeaderNumber=i-1;
                    LoopBroken = true;
                    break;
                end
            end
            TrigChannels = find(strcmp(Header,'MARK')==1);
            if isempty(TrigChannels)
                ErrorCode = 2;
                LoopBroken = true;
                break;
            else
                TrigChannel = TrigChannels(1);
            end
            BufferData = zeros(BufferLength,HeaderNumber);
            BufferTrig = zeros(BufferLength,1);
            ZBP = zeros((max([length(BPNUM),length(BPDEN)])-1),HeaderNumber); % Bandpass filters initial values
            ZNotch = zeros((max([length(NotchNUM),length(NotchDEN)])-1),HeaderNumber); % Notch filters initial values
            if ~isempty(GUIhandles) 
                reset_popupmenu_ChannelName(Header, GUIhandles);
            end
            JustStarted = false;
        end
        % Storing Data while avoiding/applying filters
        TrigChannels = find(strcmp(LatestHeader,'MARK')==1);        
        if isempty(TrigChannels) % EEG software stopped sending triger or 'MARK'
            ErrorCode = 3;
            LoopBroken = true;
            break;     
        elseif TrigChannels(1)~=TrigChannel % Index of triger or 'MARK' is changed
            ErrorCode = 4;
            LoopBroken = true;
            break;            
        else
            BufferTrig = [BufferTrig(SampleSize+1:end) ; Data(:,TrigChannel)];
            if ~BPFilter && ~NotchFilter
                BufferData = [BufferData(SampleSize+1:end,:) ; Data(:,1:HeaderNumber)];
            else
                for ch = 1:HeaderNumber
                    y = Data(:,ch);
                    if BPFilter
                        [y,ZBP(:,ch)] = filter(BPNUM,BPDEN,y,ZBP(:,ch));
                    end
                    if NotchFilter
                        [y,ZNotch(:,ch)] = filter(NotchNUM,NotchDEN,y,ZNotch(:,ch));
                    end
                    BufferData(:,ch) = [BufferData(SampleSize+1:end,ch);y];
                end
            end
            % Finding trigger and plotting
            NewDataNeeded = false;
            TrigIndex = find(BufferTrig>0);
            while  ~isempty(TrigIndex) && ~NewDataNeeded && TrigCount>(OddCounter+EvenCounter)
                if IsOdd % Odd triggers
                    CurrentPlotRange = OddTrigRange + TrigIndex(1);
                    if CurrentPlotRange(2) <= BufferLength
                        Previous_Signal = Current_Signal;
                        Current_Signal = BufferData(CurrentPlotRange(1):CurrentPlotRange(2),:);
                        Averaged_Signal_Odd = (Averaged_Signal_Odd * OddCounter + Current_Signal)/(OddCounter+1);
                        Averaged_Signal_All = (Averaged_Signal_All * (OddCounter + EvenCounter) + Current_Signal)/(OddCounter + EvenCounter+1);
                        Ind = 1;
                        if PlotOddEvenAll(Ind) % Plotting odd cases
                            DoPlotting(t, Current_Signal, Averaged_Signal_Odd, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, Ind, GUIhandles);
                        end        
                        Ind = 3;
                        if PlotOddEvenAll(Ind) % Plotting all cases
                            DoPlotting(t, Current_Signal, Averaged_Signal_All, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, Ind, GUIhandles);
                        end
                        PreviousTime = toc;
                        OddCounter = OddCounter + 1;
                        if ~isempty(GUIhandles) % Show current count
                            set(GUIhandles.pushbutton_StartStop,'string',['STOP (' num2str(OddCounter+EvenCounter) ')']);
                        end                    
                        BufferTrig(TrigIndex(1))=0;
                        TrigIndex(1) = [];
                        IsOdd = false;
                    else
                        NewDataNeeded = true;
                    end
                else  % Even triggers
                    CurrentPlotRange = EvenTrigRange + TrigIndex(1);
                    if CurrentPlotRange(2) <= BufferLength
                        Previous_Signal = Current_Signal;
                        Current_Signal = BufferData(CurrentPlotRange(1):CurrentPlotRange(2),:);                  
                        Averaged_Signal_Even = (Averaged_Signal_Even * EvenCounter + Current_Signal)/(EvenCounter+1);
                        Averaged_Signal_All = (Averaged_Signal_All * (OddCounter + EvenCounter) + Current_Signal)/(OddCounter + EvenCounter+1);
                        Ind = 2;
                        if PlotOddEvenAll(Ind) % Plotting even cases
                            DoPlotting(t, Current_Signal, Averaged_Signal_Even, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, Ind, GUIhandles);
                        end    
                        Ind = 3;
                        if PlotOddEvenAll(Ind) % Plotting all cases
                            DoPlotting(t, Current_Signal, Averaged_Signal_All, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, Ind, GUIhandles);
                        end
                        PreviousTime = toc;
                        EvenCounter = EvenCounter + 1;
                        if ~isempty(GUIhandles) % Show current count
                            set(GUIhandles.pushbutton_StartStop,'string',['STOP (' num2str(OddCounter+EvenCounter) ')']);
                        end
                        BufferTrig(TrigIndex(1))=0;
                        TrigIndex(1) = [];
                        IsOdd = true;
                    else
                        NewDataNeeded = true;
                    end
                end
            end
        end
    end
end
switch ErrorCode
    case {1}
        disp('No data is available.');
    case {2}
        disp('VEP is stopped or "Sending Mark" is not enabled in the main EEG software');
    case {3}
        disp('VEP is stopped in the main EEG software');
    case {4}
        disp('Structure of the data sent by the main EEG software is changed.');        
end
fclose(u);
clear BufferData;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Package decoder %%%%
function [Header,Data] = SplitNrSignUDPPacket(Packet,Normalized)
PacketSize = size(Packet,1);
if (PacketSize < 3)
    Header = {};
    Data = [];
else
    SamplesCount = Packet(1) + 256 * Packet(2);
    Header = cell(1,65);
    Data = zeros(SamplesCount,65);
    Index = 3;
    i = 1;
    while (Index<=PacketSize)
        HeaderLength = Packet(Index);
        Header{i} = char(Packet(Index+1 : Index+HeaderLength))';
        if Normalized % in uV
            Index = Index + HeaderLength + 1;
            for j = 1:SamplesCount
                Data(j,i) = typecast(uint8(Packet(Index:Index+3)), 'single');
                Index = Index + 4;
            end
        else % Raw Data
            Data(:,i) = Packet(Index+HeaderLength+1 : 2 : ...
                Index+HeaderLength+1+2*(SamplesCount-1)) ...
                + 256 * Packet(Index+HeaderLength+2 : 2 : ...
                Index+HeaderLength+2+2*(SamplesCount-1));
            Index = Index+HeaderLength+2+2*(SamplesCount-1)+1;
        end
        i=i+1;
    end
    if ~Normalized
        Data = Data - 32768;
    end
end
end

%%%% Signal plotting function %%%%
% function DoPlotting(t, Current_Signal, Averaged_Signal, HeaderIndex, Header, PlotOddEvenAll, PlotLastSignal, Normalized, AmpLim, ind, GUIhandles)
% if ~isempty(GUIhandles) % Updating AmpLim & HeaderIndex
%     Vals = get(GUIhandles.popupmenu_Sens,'String');
%     Ind = get(GUIhandles.popupmenu_Sens,'Value');
%     if iscell(Vals) val=Vals{Ind}; else val=Vals(Ind,:); end
%     AmpLim = 1.5*[-str2num(val) str2num(val)];
%     H1 = get(GUIhandles.popupmenu_Ch1,'Value');
%     H2 = get(GUIhandles.popupmenu_Ch2,'Value');
%     H3 = get(GUIhandles.popupmenu_Ch3,'Value');
%     if H2 == 1        H2 = [];    end
%     if H3 == 1        H3 = [];    end
%     HeaderIndex = [H1 H2-1 H3-1];
% end
% switch ind % ind is used to check if it is Odd, Even or All case for plotting
%     case {1}
%         subtitle = 'Odd';
%     case {2}
%         subtitle = 'Even';
%         if ~PlotOddEvenAll(1) ind=1; end
%     case {3}
%         subtitle = 'All (Odd & Even)';
%         if ~PlotOddEvenAll(1) ind=ind-1; end
%         if ~PlotOddEvenAll(2) ind=ind-1; end
% end
% PlotNum = sum(PlotOddEvenAll);
% cnt=0;
% for ch = HeaderIndex
%     cnt = cnt+1;
%     subplot(length(HeaderIndex),PlotNum,ind); ind = ind+PlotNum;
%     if ~isempty(Averaged_Signal) && size(Averaged_Signal,1)>1
%         if PlotLastSignal
%             cla;
%             plot(t,Current_Signal(:,ch),'blue',t,Averaged_Signal(:,ch),'green'); drawnow;
%             hold on;
%         else
%             cla;
%             plot(t,Averaged_Signal(:,ch),'green'); drawnow;
%             hold on;
%         end
%         title([Header{ch} ': ' subtitle]); 
%         xlim([t(1) t(end)]);
%     else
%         plot(0);
%         if ~isempty(GUIhandles)
%             PlotRange = [str2num(get(GUIhandles.edit_PlotStartTime,'string')), ...
%                 str2num(get(GUIhandles.edit_PlotEndTime,'string'))];
%             xlim(PlotRange);
%         end
%     end
%     if Normalized ylabel('Amplitude (uV)'); else ylabel('Amplitude'); end
%     if ~isempty(AmpLim) ylim([AmpLim(1) AmpLim(2)]); end   
%     if (cnt == length(HeaderIndex)) xlabel('Time (s)'); end
% end
% end
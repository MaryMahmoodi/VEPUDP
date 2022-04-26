%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Negar Andishgan Co. Ltd. www.NegAnd.com
% EEG 3840/EEG 5000Q Online Data Reader
% Modified in Jan 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function EEG_UDP  
    %%%% Input variables (can be modified) %%%%
    Normalized = true; % false/true, depending on software online-setting
    HeaderIndex = [1:2]; % Indices of the headers/channels to be plotted
    SampleRate = 500; % Hz/Per second (depending on the device)
    PlotLength = 5; % In seconds; Minimum: Buffer_Size/Sample_Rate.
    PlotRefreshRate = 15; % Plot refreshing rate in Hz (<= 15 Hz).
    
    %%%% Parameters initialization %%%%
    HeaderNumber = length(HeaderIndex); % Number of channels to be plotted
    BufferLength = PlotLength*SampleRate; % data length to be plotted 
    BufferData = zeros(BufferLength,HeaderNumber); 
    
    %%%% Plotting initialization (1) %%%%
    t = [0:1/SampleRate:(BufferLength-1)/SampleRate]'; % Time (s)
    y = zeros(BufferLength,1); % Output signal
  
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
    set(u,'Timeout',60);
    fopen(u);
    ByteCount = 1;    
    JustStarted = true; 
    
    %%%% Main %%%%
    tic; toc_old=toc;
    while(ByteCount)
        % Reading new data
        [Packet,ByteCount] = fread(u,1);  
        [Header,Data] = SplitNrSignUDPPacket(Packet,Normalized);

        if isempty(Data)
            disp('No data is available.');
        else        
            if JustStarted 
                %%% Plotting initialization (2) %%%               
                for hd=1:HeaderNumber
                    temp = min(8,ceil(HeaderNumber/2));
                    subplot(temp,ceil(HeaderNumber/temp),hd);
                    plt(hd) = plot(t,y);
                    %ylim([-1000 1000]);
                    title(Header{HeaderIndex(hd)});
                    plt(hd).XDataSource = 't';
                    plt(hd).YDataSource = 'y';
                end   
                JustStarted = false;
            end 
            for hd = 1 : HeaderNumber  
                % Storing new data in buffer
                BufferData(:,hd)=[BufferData(size(Data,1)+1:end,hd); ...
                                  Data(:,HeaderIndex(hd))];            
                % Plotting new data   
                y=BufferData(:,hd);
                refreshdata(plt(hd),'caller');
            end
                
            if (toc-toc_old > 1/PlotRefreshRate)% Drawing the updated data
                drawnow;
                toc_old=toc;
            end            
        end
    end
    fclose(u);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

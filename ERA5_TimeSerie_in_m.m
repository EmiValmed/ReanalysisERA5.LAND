clear; close all; clc
%% Declarations
% Directories
dataPath='\OutPath Folder path in the Extract_ERA5 script'     ; addpath(dataPath);
OutPath= '\Outputs\ExcelFormat'                                ; addpath(OutPath);% Catchments

if ~exist(fullfile(OutPath), 'dir')
    mkdir(fullfile(OutPath)); addpath(OutPath);
end

data = 'ERA5'; % ERA5/ERA5LAND... % Specify the reanalysis
VarName = 'tp'; 

% Catchment (shapefile's name)
nameC = {'Bever_WGS84'};
nCth = numel(nameC);
             
% Output data Time steps
ts = 24;          % To modify
StartYear = 2005; % To modify
EndYear   = 2010; % To modify

% Time difference between UTC and the local time
TimeZone  = 'UTC';     
LocalZone = '-05:00';  % ----------------------------------------------------------------------------------------------------
                       % Note: You can specify the time zone value as a character vector of the form +HH:mm or -HH:mm, which 
                       % represents a time zone with a fixed offset from UTC that does not observe daylight saving time.
                       % You can also specify the time zone value as the name of a time zone region in the Internet Assigned 
                       % Numbers Authority (IANA) Time Zone Database. Run the function timezones in the command Windows to 
                       % display a list of all IANA time zones accepted by the datetime function.  
                       % ----------------------------------------------------------------------------------------------------
             
for iCatch = 1:nCth
    
    % Concatenate all the *.mat files   
    matFiles= dir(strcat(dataPath,sprintf('/%s_%s_%s*.mat',nameC{iCatch},data,VarName)));
    tmp=[];                                  % start w/ an empty array
    for i=1:length(matFiles)
        tmp=[tmp; load(matFiles(i).name)];   % read/concatenate into x
    end
    
    %Get variables
    tmp2 = struct2cell(tmp);
    Datetmp = datetime(vertcat(tmp2{1,:}),'ConvertFrom', 'datenum','TimeZone',TimeZone); % Date in the original timeZone.
    Datetmp.TimeZone = LocalZone;                                                        % Conversion to local time.
    Vartmp = vertcat(tmp2{2,:});                                                         % Variable time serie.
    
    
    % Considering full day 
    LocalDate = datevec(Datetmp);
    SD = find(LocalDate(:,4)==1 & LocalDate(:,1)==StartYear, 1 );      % SD: start date.
    ED = find(LocalDate(:,4)==0 & LocalDate(:,1)==EndYear, 1,'last');  % ED: End date.
    LocalDate =LocalDate(SD:ED,:);                                     % SD and ED are index to consider full days in the 
    Var1tmp = Vartmp(SD:ED);                                           % local time (from 1h to 00h)
        
 
    % Accumulating the values at the desired time step
    ntime = numel(Var1tmp);
    index = sumIndex(ntime, ts);
    Var  = round(cell2mat(cellfun(@(x) sum(Var1tmp(x)),index,'un',0)),2);
    
    % Date at the desired time step
    Date_up = LocalDate(ts:ts:end,:);
    Date = Date_up;
    
    %% Export Matlab format
    
    % Define output file name
    outfile = sprintf('%s/%s_%s_%s_%sh.mat',OutPath,nameC{iCatch},data,VarName,num2str(ts));
    
    % Export 
    save(outfile,'Var','Date','-v7.3');
    
    %% Export Excel format
    
    Excel = table(Date,Var);
       
    % Define output file name
    outfile = sprintf('%s/%s_%s_%s_%sh.xlsx',OutPath,nameC{iCatch},data,VarName,num2str(ts));
    
    % Export
    writetable(Excel,outfile)
end
clear

clear; close all; clc
%% Declarations
% Directories
dataPath='\OutPath Folder path in the Extract_ERA5LAND script' ; addpath(dataPath);
OutPath= '\Outputs\ExcelFormat'                                ; addpath(OutPath);% Catchments

if ~exist(fullfile(OutPath), 'dir')
    mkdir(fullfile(OutPath)); addpath(OutPath);
end

data = 'ERA5'; % ERA5/ERA5LAND... % Specify the reanalysis
VarName = 'tp'; 

% Catchment (shapefile's name)
nameC = {'Bever_WGS84'};
nBV = numel(nameC);
             
% Output data Time steps 
ts = 24;
EndYear = 2008;

% Time difference between UTC and the local time
TimeZone  = 'UTC';     
LocalZone = '+05:00';  % ----------------------------------------------------------------------------------------------------
                       % Note: You can specify the time zone value as a character vector of the form +HH:mm or -HH:mm, which 
                       % represents a time zone with a fixed offset from UTC that does not observe daylight saving time.
                       % You can also specify the time zone value as the name of a time zone region in the Internet Assigned 
                       % Numbers Authority (IANA) Time Zone Database. Run the function timezones in the command Windows to 
                       % display a list of all IANA time zones accepted by the datetime function.  
                       % ----------------------------------------------------------------------------------------------------
             
for iCatch = 1:nBV
% Define output file name

   
    matFiles= dir(strcat(dataPath,sprintf('/%s_%s_VarName*.mat',nameC{iCatch},data)));
    tmp=[];                                  % start w/ an empty array
    for i=1:length(matFiles)
        tmp=[tmp; load(matFiles(i).name)];   % read/concatenate into x
    end
    
    %Get variables
    tmp2 = struct2cell(tmp);
    Datetmp = datetime(vertcat(tmp2{1,:}),'ConvertFrom', 'datenum','TimeZone',TimeZone));
    Datetmp.TimeZone = LocalZone;
    ttmp = vertcat(tmp2{2,:});
    
                             
    % Convert dates to local time
    LocalDate = datevec(Datetmp);
    SD = min(find(LocalDate(:,4)==1));                          % SD: start date. 
    ED = max(find(LocalDate(:,4)==0 & LocalDate(:,1)==EndYear));% ED: End date.
    LocalDate =LocalDate(SD:ED,:);                              % SD and ED are index to consider a full day in the local time (from 1h to 00h)
    
    
    % Values on Local time
    t1tmp = ttmp(SD:ED);
    
    Date_up = LocalDate(ts:ts:end,:);
    Date5 = Date_up; 
    
    Date_up = LocalDate(:,1:3);
    Date_up = datevec(unique(datenum(Date_up)));             
    Date = Date_up;
   
    
    ntime = numel(Pt1tmp);
    index = sumIndex(ntime, ts);
    Var  = round(cell2mat(cellfun(@(x) sum(t1tmp(x)),index,'un',0)),2);

 
        % Export
     outfile = sprintf('%s/%s_%s_%s.mat',OutPath,nameC{iCatch}, data, ts, VarName);
     save(outfile,'Var','Date','-v7.3');
     
end



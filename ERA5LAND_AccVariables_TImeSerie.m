clear; close all; clc
%% Declarations
% Directories
dataPath='\OutPath Folder path in the Extract_ERA5LAND script' ; addpath(dataPath);
OutPath= '\Outputs\ExcelFormat'                                ; addpath(OutPath);% Catchments

if ~exist(fullfile(OutPath), 'dir')
    mkdir(fullfile(OutPath)); addpath(OutPath);
end

data = 'ERA5LAND'; % ERA5/ERA5LAND... % Specify the reanalysis
VarName = 'tp';
Operation = 'sum';

% Catchment (shapefile's name)
nameC = {'Bever_WGS84'};
nCth = numel(nameC);

% Output data Time steps
ts = 24;           % To modify
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
   
    matFiles= dir(strcat(dataPath,sprintf('/%s_%s_%s*.mat',nameC{iCatch},data,VarName)));
    tmp=[];            % start w/ an empty array
    for i=1:length(matFiles)
        tmp=[tmp; load(matFiles(i).name)];   % read/concatenate into x
    end
    
    % Get variables
    tmp2 = struct2cell(tmp);
    Datetmp = datevec(vertcat(tmp2{1,:}));
    Vartmp = vertcat(tmp2{2,:});
    
    % Index to start and finish the diff (getting the hourly values without accumulating) 
    diffSD = find(Datetmp(:,4)==1 & Datetmp(:,1)==StartYear, 1 );      % SD: start date.
    diffED = find(Datetmp(:,4)==0 & Datetmp(:,1)==EndYear, 1,'last');  % ED: End date.
    
    % Deaccumulate variables 
    Vartmp1 = Vartmp(diffSD:diffED);
    Vartmp2 = descVar(Vartmp1,24);
    
    % Local time
    Datetmp = datetime(datenum(Datetmp(diffSD:diffED,:)),'ConvertFrom', 'datenum','TimeZone',TimeZone);
    Datetmp.TimeZone = LocalZone;                                                        

    % Considering full day at the local time
    LocalDate = datevec(Datetmp);
    SD = find(LocalDate(:,4)==1 & LocalDate(:,1)==StartYear, 1 );      % SD: start date.
    ED = find(LocalDate(:,4)==0 & LocalDate(:,1)==EndYear, 1,'last');  % ED: End date.
    LocalDate =LocalDate(SD:ED,:);                                     % SD and ED are index to consider full days in the 
    Vartmp2 = Vartmp2(SD:ED);
    
    % Getting the values at the desired time step
    ntime = numel(Vartmp2);
    index = sumIndex(ntime, ts);   
    Var = VariableTS (Vartmp2,index,Operation);
      
    % Date at the desired time step
    if ts == 24
       Date_up = LocalDate(:,1:3);     
       Date = datevec(unique(datenum(Date_up)));
       Date = Date(1:end-1,:);
    else        
       Date_up = LocalDate(ts:ts:end,:);
       Date = Date_up;
    end
    
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

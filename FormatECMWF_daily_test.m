clear; close all; clc

%% Declarations

% % Directories Linux
% cd('/media/esvam/EMIDISK/THESE/ECMWF');
% dataPath='./01_ECMWFextracted/FRANCE'; addpath(dataPath);
% dataDate='./ECMWF_FRANCE/'; addpath(dataDate);
% resultPath= '/media/esvam/EMIDISK/THESE/HOOPLA-Countries/FRANCE/HOOPLA-master/Data/24h/Ens_met_fcast';
% CatchNamePath='/media/esvam/EMIDISK/THESE/HOOPLA-Countries/AUSTRALIA/HOOPLA-master/Data/24h/Misc';addpath(CatchNamePath)

% Directories Windows
Countrie = 'AUSTRALIA';
cd('G:\THESE');
dataPath=fullfile('ECMWF','01_ECMWFextracted',Countrie); addpath(dataPath);
resultPath= fullfile('HOOPLA-Countries', Countrie,'HOOPLA-master','Data','24h','Ens_met_fcast' );addpath(resultPath)
CatchNamePath= fullfile('HOOPLA-Countries', Countrie,'HOOPLA-master','Data','24h','Misc');addpath(CatchNamePath)
dataDate= fullfile('ECMWF',strcat('ECMWF_',Countrie)); addpath(dataDate);


% ECMWF
nbLeadTime=60; % = 60 max for ECMWF
nbMetMb=50; % = 50 max for ECMWF

% Reference time vector
fileID = fopen(sprintf('%s/Days.txt', dataDate), 'r');
Datestr = textscan(fileID,'%s');
dateRef = datenum([Datestr{:}]);

datatmp = [Datestr{:}];
dateStart = datatmp{1};
dateEnd = datatmp{end};
Date = datevec(dateRef);
%Date(:,4) = 9;
%
% nameC ={'A1080330','B2220010','H4252010','H7401010','I5221010'...
%,'J0121510','J3403020','J3404110','J3733010','J3821810','J4211910','J5712130','J7483010','J7500610'...
%,'J8202310','J9300610','K1321810','L0563010','L4411710','M0243010','M7112410','S2242510','U4644010'};
%

load(sprintf('%s/catchment_names.mat',CatchNamePath));
nBV = numel(nameC);



% Generate daily lead times
leadTimeECMWF = (6:6:(nbLeadTime+1)*6)./24;
leadTimeECMWF = floor(leadTimeECMWF);
leadTime00 = transpose(leadTimeECMWF(2:end)+1); % trick for accumarray + start at 6h for France

leadTime = 1:1:14; ComplDay = 2:1:15 ;% complete days

%% Change the timestep 6h -> 1 day

% Catchment loop
tic
for iCatch = 23:nBV
    
    % Display progress
    mntoc = round(toc/60,1);
    fprintf('%2.0f %% of files read - time elapsed %s minutes \n',iCatch/nBV*100, mntoc)
    
    i=iCatch
    % Load data
    load(sprintf('%s/C%s_%s_%s.mat',dataPath,nameC{i},...
        datestr(dateStart,'yyyymmdd'),datestr(dateEnd,'yyyymmdd')));
    
    iCatch = iCatch
    nameC{iCatch}
   
    
    % Member loop
    for iMetMb = nbMetMb:-1:1
        
        % Decumulate precipitation
        Pt=diff(squeeze(Pt_tmp(:,:,iMetMb)),1,2);
        % Aggregate
        Pt = arrayfun(@(iDate) accumarray(leadTime00 , squeeze(Pt(iDate,:)),[] , @sum),1:size(Pt,1),'UniformOutput',0);
        Pt = transpose(horzcat(Pt{:}));
        % Keep complete days
        Pt = Pt(:,ComplDay);
        % Correct
        Pt(Pt<=0) = 0;
        
        % Aggregate mean temperature. % First step=analyse or na
        T = squeeze(T_tmp(:,2:(nbLeadTime+1),iMetMb));
        T = arrayfun(@(iDate) accumarray(leadTime00 , squeeze(T(iDate,:)),[] , @mean),1:size(T,1),'UniformOutput',0);
        T = transpose(horzcat(T{:}));
        T = T(:,ComplDay);
        
        % Aggregate min temperature. % First step=analyse
        Tmin = squeeze(Tmin_tmp(:,2:(nbLeadTime+1),iMetMb));
        Tmin = arrayfun(@(iDate) accumarray(leadTime00 , squeeze(Tmin(iDate,:)),[] , @mean),1:size(Tmin,1),'UniformOutput',0);
        Tmin = transpose(horzcat(Tmin{:}));
        % Keep complete days
        Tmin = Tmin(:,ComplDay);
        
        % Aggregate max temperature. % First step=analyse
        Tmax = squeeze(Tmax_tmp(:,2:(nbLeadTime+1),iMetMb));
        Tmax = arrayfun(@(iDate) accumarray(leadTime00 , squeeze(Tmax(iDate,:)),[] , @mean),1:size(Tmax,1),'UniformOutput',0);
        Tmax = transpose(horzcat(Tmax{:}));
        % Keep complete days
        Tmax = Tmax(:,ComplDay);
        
        % Correction
        Tmax(T>Tmax)=T(T>Tmax);
        Tmin(Tmin>T)=T(Tmin>T);
        Met_fcast(iMetMb).Date = Date;
        Met_fcast(iMetMb).Pt = Pt;
        Met_fcast(iMetMb).T = T;
        Met_fcast(iMetMb).Tmax = Tmax;
        Met_fcast(iMetMb).Tmin = Tmin;
        Met_fcast(iMetMb).leadTime = leadTime;
        % Store in HOOPLA file
        
        
    end
    % Save outputs
    
    iCatch = iCatch
    nameC{iCatch}
    namefile =sprintf('%s/Met_fcast_%s.mat',resultPath,nameC{iCatch});
    save(namefile,'Met_fcast','Date','leadTime','-v7.3');
    
end






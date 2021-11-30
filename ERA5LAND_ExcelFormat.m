clear; close all; clc
%% Declarations
% Directories
dataPath='\OutPath Folder path in the Extract_ERA5LAND script' ; addpath(dataPath);
OutPath= '\Outputs\ExcelFormat'                                ; addpath(OutPath);% Catchments

if ~exist(fullfile(OutPath), 'dir')
    mkdir(fullfile(OutPath)); addpath(OutPath);
end

% Catchment (shapefile's name)
nameC = {'Bever_WGS84'};
nBV = numel(nameC);

% Time difference between UTC and Quebec
FH = 5; 

for iCatch = 1:nBV
   
    matFiles= dir(strcat(dataPath,sprintf('/%s*.mat',nameC{iCatch})));
    tmp=[];            % start w/ an empty array
    for i=1:length(matFiles)
        tmp=[tmp; load(matFiles(i).name)];   % read/concatenate into x
    end
    
    %Get variables
    tmp2 = struct2cell(tmp);
    Pttmp = vertcat(tmp2{3,:});
    Date = datevec(vertcat(tmp2{1,:}));
    Ettmp = (vertcat(tmp2{2,:}));
    Tmtmp = (vertcat(tmp2{4,:}));
    
    
    % Index to start and finish the diff
    SD = min(find(Date(:,4)==1));
    ED = max(find(Date(:,4)==0));
    
    % Deaccumulate variables 
    Pt1 =  Pttmp(SD:ED);
    Et1 = Ettmp(SD:ED);
    
    Pt1tmp = descVar(Pt1,24);
    Et1tmp = descVar(Et1,24);
    
    % Convert dates to Quebec time
    DateQbc = datevec(datenum(Date(SD:ED,:))-(FH/24));
    SDQ = min(find(DateQbc(:,4)==1));
    
    
    % Daily values on Quebec time
    Pt1tmp = Pt1tmp(:); Pt1tmp = Pt1tmp(SDQ:end);
    Et1tmp = Et1tmp(:); Et1tmp = Et1tmp(SDQ:end);
    Tm1tmp = Tmtmp(SDQ:end);
    
    
    Date_up = DateQbc(SDQ:end,1:3);
    Date_up = datevec(unique(datenum(Date_up)));
    Time = datetime(Date_up(1:end,:));
    
    ntime = numel(Pt1tmp);
    index = sumIndex(ntime, 24);
    Tmax = round(cell2mat(cellfun(@(x) max(Tm1tmp(x)),index,'un',0)),2);
    Tmin = round(cell2mat(cellfun(@(x) min(Tm1tmp(x)),index,'un',0)),2);
    Pt  = round(cell2mat(cellfun(@(x) sum(Pt1tmp(x)),index,'un',0)),2);
    Tm  = round(cell2mat(cellfun(@(x) mean(Tm1tmp(x)),index,'un',0)),2);
    Et  = round(cell2mat(cellfun(@(x) sum(Et1tmp(x)),index,'un',0)),2);
    
    Excel = table(Time,Pt,Et,Tm,Tmax,Tmin);
   
    
    % Define output file name
    outfile = sprintf('%s/%s_ERA5LAND.xlsx',OutPath,nameC{iCatch});
    
    % Export in Excel format
    writetable(Excel,outfile)
    
   
end

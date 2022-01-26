clear; close all; clc
%% Declarations 
% Directories
dataPath= '\.nc files path'           ; addpath(dataPath);
shpPath=  '\Sahpefiles path'          ; addpath(shpPath);
OutPath=  '\results folder path'      ; addpath(OutPath);

% Catchments
if ~exist(fullfile(OutPath), 'dir')
    mkdir(fullfile(OutPath)); addpath(OutPath);
end

% Datebase
data = 'ERA5'; % ERA5/ERA5LAND... % Specify the reanalysis


% Catchment (shapefile's name)
nameC = {'Bever_WGS84'};
nBV = numel(nameC);

%% -------------------------------------------------- DO NOT TOUCH FROM HERE ---------------------------------------------
             
% Recognizing  .nc files in the directory
cd(dataPath)
ncFiles = dir('*.nc');
for ifile = 1: size(ncFiles,1)
    tmp = split(convertCharsToStrings(ncFiles(ifile).name), ["_",".nc"]);
    StartDate(ifile,1) = tmp(1);
    EndDate(ifile,1) = tmp(2);
end


%% Step 1: Create catchments mask% Import NetCDF coordinates
fileToRead=fullfile(dataPath, sprintf('%s_%s.nc', StartDate{1},EndDate{1}));
ncid = netcdf.open(fileToRead,'NC_NOWRITE');

lat0 = netcdf.getVar(ncid,netcdf.inqVarID(ncid,'latitude'),'single');
lon0 = netcdf.getVar(ncid,netcdf.inqVarID(ncid,'longitude'),'single');% Conversion of Lat and Lon
lon0b = repmat(lon0, [1, size(lat0,1)])';
lat0b = repmat(lat0, [1, size(lon0,1)]);
netcdf.close(ncid);


% Building catchment masks
for iCatch = 1:nBV
    % Import ctch shape
    [S]=shaperead(fullfile(shpPath,sprintf('%s.shp',nameC{iCatch})));
    % Get points inside the catchment
    inGrid_tmp = inpolygon(lon0b,lat0b,S.X,S.Y);
    % Transpose mask for NetCDF compatibility (y,x,T)
    inGrid_tmp = transpose(inGrid_tmp);
    % Convert into nan/value mask for data extraction
    inGrid_tmp = double(inGrid_tmp);
    inGrid_tmp(inGrid_tmp==0) = NaN;
    % Store for NetCDF extraction
    inGrid.(sprintf('C%s',nameC{iCatch})) = inGrid_tmp;
end

% Housekeeping
clear ncid S lat0 lon0 inGrid_tmplon0b = lon0b'; lat0b = lat0b';

%% Retrieve NetCDF datafor iYears = 1:numel(StartYear)

for iDates = 1: numel(StartDate)
    
        % Display process
    if rem( iDates,round(numel(StartDate)/50,0) ) == 0
        mntoc = round(toc/60,1);
        fprintf('%2.0f %% of files read - time elapsed %s minutes \n',iDate/numel(StartDate)*100, mntoc)
    end
    
    % Open NetCDF file
    fileToRead=fullfile(dataPath, sprintf('%s_%s.nc', StartDate{iDates},EndDate{iDates}));
    ncid = netcdf.open(fileToRead,'NC_NOWRITE');
    
    % Retrieve ERA5 variables and attributes (scale_factor and add_offset).
    
    % Total Precipitation
    Psf   = netcdf.getAtt(ncid,netcdf.inqVarID(ncid,'tp'),'scale_factor');
    Pao   = netcdf.getAtt(ncid,netcdf.inqVarID(ncid,'tp'),'add_offset');
    dataP = netcdf.getVar(ncid,netcdf.inqVarID(ncid,'tp'),'double');
    dataP = (dataP .* Psf + Pao).*1000;
          
    % Time
    Date = netcdf.getVar(ncid,netcdf.inqVarID(ncid,'time'),'double');
    Date = datenum(Date./24) + datenum('1900-01-01 00:00:00');
    ntime = numel(Date);
    
    % Close NetCDF file
    netcdf.close(ncid);
    
    % Trick for computing cathcment mean at catchment scale
    Ptmp00   = arrayfun(@(iLT) squeeze(dataP(:,:,iLT)),1:ntime,'UniformOutput',0);
        
             
    %% Compute mean at the catchment scale - Catchment loop
    for iCatch = 1:nBV
        inan = isnan(inGrid.(sprintf('C%s',nameC{iCatch})));
        
        Ptmp    = transpose(arrayfun(@(iLT) mean(Ptmp00{iLT}(~inan)),1:ntime));
                
        % Define output file name
        outfile = sprintf('%s/%s_%s_Pt_%s_%s.mat',OutPath,nameC{iCatch},data,StartDate{iDates},EndDate{iDates});
        % Export
        save(outfile,'Ptmp', 'Date', '-v6');
        
    end
    
end
clear
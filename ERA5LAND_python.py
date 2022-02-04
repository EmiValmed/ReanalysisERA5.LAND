#%%

##------------------------------------------------------------------
## HEADER
##------------------------------------------------------------------

#!/usr/bin/env python2
# -*- coding: utf-8 -*-

# $Revision: 0.0 $  $Date: 2017/04/03 00:00:00 $Author: Guillaume HAZEMANN
#           Original function
# $Revision: 0.1 $  $Date: 2017/09/12 00:00:00 $Author: Carine PONCELET
#           Import all user parameters from bash
#           Allow user to change dataset parameters
#           Check the names instead of the number of downloaded files
#           Automatically update request to account for already downloaded files
#           Add process progress control
#           Add communication python-bash
#           Comment script
# $Revision: 0.2 $ $Date: 2021/04/05 00:00:00 $Author: Emixi Valdez
#            Modified code to extract ERA5-Land variables instead ECMWF forecasts.

#%%
##------------------------------------------------------------------
## DECLARATIONS
##------------------------------------------------------------------

## Define python libraries
import datetime as dt 
import os

## Import user parameters
DirPy=os.environ["DirPy"]
DirOut=os.environ["DirOut"]
StaYear=os.environ["StaYear"]
StaMonth=os.environ["StaMonth"]
StaDay=os.environ["StaDay"]
EndYear=os.environ["EndYear"]
EndMonth=os.environ["EndMonth"]
EndDay=os.environ["EndDay"]
GridRes=os.environ["GridRes"]
MeteoVar=os.environ["MeteoVar"]
Area=os.environ["Area"]

## Get connection informations
import cdsapi
server = cdsapi.Client()

## Set ECMWF MARS retrieval parameters
FileExt = ".nc"
Time =  [ '00:00','01:00','02:00',
          '03:00','04:00','05:00',
          '06:00','07:00','08:00',
          '09:00','10:00','11:00',
          '12:00','13:00','14:00',
          '15:00','16:00','17:00',
          '18:00','19:00','20:00',
          '21:00','22:00','23:00']
            

if( FileExt == ".nc" ):
    Format = "netcdf"

## Define objects
ProcessedFiles = []
ToDoFiles = []
Ind = []

#%%
##------------------------------------------------------------------
## Built the list of files to download
##------------------------------------------------------------------

## Convert user dates
StaDate = dt.date(year=int(StaYear), month=int(StaMonth), day=int(StaDay))
EndDate = dt.date(year=int(EndYear), month=int(EndMonth), day=int(EndDay))

## Infer initial list of files to download
NbDays = (EndDate-StaDate).days + 1
TargetFiles = [str(StaDate) + '_' + str(EndDate)]

## Check for already downloaded files
for iFile in TargetFiles:
    target = DirOut + iFile
    if(os.path.exists(target)):
        ProcessedFiles.append(str(iFile))

## Infer updated list of files to download
for iFile in TargetFiles:
    if(iFile not in ProcessedFiles):
        ToDoFiles.append(str(iFile))
        Ind.append(TargetFiles.index(iFile))


# Housekeeping
del iFile,Ind,NbDays,target

#%%
##------------------------------------------------------------------
## RETRIEVE ERA5-LAND DATA
##------------------------------------------------------------------

for iDate in range(len(TargetFiles)):
    
    ## Set the day to download
    iyear = list(range(int(StaYear),int(EndYear)+1)) 
    imonth = list(range(int(StaMonth),int(EndMonth)+1))
    iDay = list(range(int(StaDay),int(EndDay)+1))
    target = DirOut + TargetFiles[0]
    
    ## Send query to ecmwf server
    server.retrieve("reanalysis-era5-land",{
    "product_type": "reanalysis",
    "format": Format,
    "param": MeteoVar, 
    "area": Area,
    "grid": GridRes,
    "year": iyear,
    "month": imonth,
    "day": iDay,
    "time": Time
    },target+'.nc')
    
    ## Update files to download list
    if(os.path.exists(target)):
        ProcessedFiles.append(TargetFiles[iDate])
    
    ## Test if there are more files to download
    tmp = [ 1 if x in ProcessedFiles else 0 for x in ToDoFiles ]
    if(sum(tmp) == len(ToDoFiles)): 
        test=1
    else:
        test=0
    
    ## Export test result and progress for bash
    f1 = open(DirPy+'PyOut.txt', 'w')
    f1.write('test='+str(test)+'\n')
    f1.write('progress='+str(len(ProcessedFiles)/len(ToDoFiles)))
    f1.close()
    # Housekeeping
    del test,tmp,iDay,target
    

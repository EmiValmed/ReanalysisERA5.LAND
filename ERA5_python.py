# %%

## ------------------------------------------------------------------
## HEADER
## ------------------------------------------------------------------

# !/usr/bin/env python3
# -*- coding: utf-8 -*-

# $Revision: 0.0 $  $Date: 2017/04/03 00:00:00 $Author: Guillaume HAZEMANN
#            Original function
# $Revision: 0.1 $  $Date: 2017/09/12 00:00:00 $Author: Carine PONCELET
#            Import all user parameters from bash
#            Allow user to change dataset parameters
#            Check the names instead of the number of downloaded files
#            Automatically update request to account for already downloaded files
#            Add process progress control
#            Add communication python-bash
#            Comment script
# $Revision: 0.2 $ $Date: 2021/04/05 00:00:00 $Author: Emixi Valdez
#            Modified code to extract ERA5-Land variables instead ECMWF forecasts.

# %%
##------------------------------------------------------------------
## DECLARATIONS
##------------------------------------------------------------------

## Define python libraries
import datetime as dt
import os
import time

## Import user parameters
DirPy = os.environ["DirPy"]
DirOut = os.environ["DirOut"]
StaYear = os.environ["StaYear"]
StaMonth = os.environ["StaMonth"]
StaDay = os.environ["StaDay"]
EndYear = os.environ["EndYear"]
EndMonth = os.environ["EndMonth"]
EndDay = os.environ["EndDay"]
GridRes = os.environ["GridRes"]
MeteoVar = os.environ["MeteoVar"]
NameVar = os.environ["NameVar"]
Area = os.environ["Area"]
Format = os.environ["Format"]
ProductType = os.environ["ProductType"]

## Get connection informations
import cdsapi

server = cdsapi.Client()

## Set ECMWF MARS retrieval parameters
FileExt = ".nc"
Time = ['00:00', '01:00', '02:00',
        '03:00', '04:00', '05:00',
        '06:00', '07:00', '08:00',
        '09:00', '10:00', '11:00',
        '12:00', '13:00', '14:00',
        '15:00', '16:00', '17:00',
        '18:00', '19:00', '20:00',
        '21:00', '22:00', '23:00']

if (FileExt == ".nc"):
    Format = "netcdf"

# %%
##------------------------------------------------------------------
## Built the list of files to download
##------------------------------------------------------------------
Years = list(range(int(StaYear), int(EndYear)+1))


## Convert user dates
StaDate = [dt.date(year=int(Years[i]), month=int(StaMonth), day=int(StaDay))for i in range(0, len(Years))]
EndDate = [dt.date(year=int(Years[i]), month=int(EndMonth), day=int(EndDay))for i in range(0, len(Years))]

## Infer initial list of files to download
TargetFiles = []
Files = [str(NameVar) + '_' + str(StaDate[i]) + '_' + str(EndDate[i]) for i in range(0, len(StaDate))]
for i in range(0, len(Files)):
    if os.path.exists(DirOut + Files[i] + FileExt) == False :
        TargetFiles.append(Files[i])
    else :
        pass

# %%
##------------------------------------------------------------------
## RETRIEVE ERA5 DATA
##------------------------------------------------------------------

for iDate in range(len(TargetFiles)):
    start = time.time()
    print("--------------------------------------------------------")
    print("Fichier restant à télécharger : ", len(TargetFiles)-iDate)
    print("Fichier en cours de téléchargement : ", TargetFiles[iDate])

    ## Set the day to download
    iyear = TargetFiles[iDate].split('_')[-1].split("-")[0]
    imonth = list(range(int(StaMonth), int(EndMonth) + 1))
    iDay = list(range(int(StaDay), int(EndDay) + 1))
    target = DirOut + TargetFiles[iDate]

    ## Send query to ecmwf server
    server.retrieve("reanalysis-era5-single-levels", {
        "format": Format,
        "product_type" : ProductType,
        "variable": MeteoVar,
        "area": Area,
        "grid": GridRes,
        "year": iyear,
        "month": imonth,
        "day": iDay,
        "time" : Time
    }, target + FileExt)

    ## Test if there are more files to download
    tmp = len(TargetFiles)-iDate
    if tmp == 0:
        test = 1
    else:
        test = 0
        
    end = time.time()
    print("Temps de téléchargement :", (end - start)/60, " minutes")

    ## Export test result and progress for bash
    f1 = open(DirPy + 'PyOut.txt', 'w')
    f1.write('test=' + str(test) + '\n')
    f1.write('progress=' + str(iDate) + "/" + str(len(TargetFiles)) + '\n')
    f1.write('time download=' + str((end-start)/60) + " minutes")
    f1.close()
    # Housekeeping
    del test, tmp, iDay, target
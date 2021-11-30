##---------------------------------------------------------------
## HEADER
##---------------------------------------------------------------

#!/bin/bash


# $Revision: 0.0 $  $Date: 2021/06/11 18:20:42 $Author: EMIXI VALDEZ 
#            Original function
# $Revision: 0.1 $  $Date: 2021/06/11 00:00:00 $Author: DIMITRIS HERRERA  


##---------------------------------------------------------------
## USER PARAMETERS SETTINGS
##---------------------------------------------------------------

## Define ECMWF request
export min_lon="-5.1"  # Min long 
export min_lat="41.3"  # Min lat 
export max_lon="9.6"   # Max long
export max_lat="51.1"  # Max lat
export n_lon="148"     # no. long
export n_lat="99"      # no. lat

## Define directories
Country="FRANCE"

DirSh=/home/esvam/                          # Bash script directory
export DirPy=/home/esvam/                   # Python script directory
export DirOut=/media/esvam/LaCie/TEST/      # Directory where ECMWF at catchment scale are to be stored
DirShapes=/media/esvam/LaCie/Shapes/        # Directory of catchments shapefile
DirnetCDF=/media/esvam/LaCie/ncFiles/       # Directory where ECMWF data are stored
Dirtmp=/media/esvam/LaCie/tmp/


## Declarations
PyName="ECMWF_Ext.py"
FilePy=$DirPy/$PyName

##----------------------------------------------------------------------------------
## NCO: Compute mean at the catchment scale - Catchment loop  -- No need to modify
##----------------------------------------------------------------------------------


lsCatch=$(ls $DirShapes) # Get the list of catchments
Dates=$(ls $DirnetCDF)   # Get the list of netCDF files
echo $Dates


for Catch in $lsCatch ; do

    if [ ! -d "$Dirtmp$Catch" ]
    then
       mkdir -p "$Dirtmp$Catch"
    fi

    export DirtmpCatchSh=$DirShapes$Catch/
    export DirtmpCatchShOut=$Dirtmp$Catch/$Catch.nc
    export $Catch
    ## Launch data retrieval and get download ExitCode
    python3 -u $FilePy 

    for iDate in $Dates; do
        echo $iDate
        ECMWF=$DirnetCDF$iDate
        echo $ECMWF
        ncks -C -v mask -A $DirtmpCatchShOut $ECMWF
        ncwa -O -h -w mask -a latitude,longitude $ECMWF $Dirtmp$Catch/${Catch}_$iDate   
     done 
     ncrcat  $Dirtmp$Catch/${Catch}_*.nc $DirOut/${Catch}.nc 
done   

    


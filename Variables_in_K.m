function [dataVar] = Variables_in_K(VarName,ncid)

sf   = netcdf.getAtt(ncid,netcdf.inqVarID(ncid,VarName),'scale_factor');
ao   = netcdf.getAtt(ncid,netcdf.inqVarID(ncid,VarName),'add_offset');
dataVar = netcdf.getVar(ncid,netcdf.inqVarID(ncid,VarName),'double');
dataVar = (dataVar .* sf + ao ) - 273.15;

end

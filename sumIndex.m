function [index] = sumIndex(ntime, ts)

index = 1:ntime;
elem  = [repmat(ts,1,floor(ntime/ts))];
endv  = ntime-sum(elem);
if(~endv)
    endv = [];
end
index = mat2cell(index,1,[elem,endv])';

end
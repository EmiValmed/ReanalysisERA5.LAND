function [DescVar] = descVar(Var, time)
DescVar = NaN(time,numel(Var)/time);
Var = reshape(Var,24,[]);
Ptdiff = diff(Var);
DescVar(1,:) = Var(1,:);
DescVar(2:end,:) = Ptdiff;

end
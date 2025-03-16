%{
       THIS FILE ALLOWS THE USER TO CARRY OUT MULTIPLE SETS OF
                SIMULATIONS FOR AN ARRAY OF FORCES

Like NDC80.m, this program can be used to start the entire simulation
process. Unlike NDC80.m, it does not allow the user to create any graphical
representations of the simulations besides the detachment times
distribution during the run. 
Instead, it is useful for carrying out large sets of simulations with fixed
parameters and varying values of external forces with minimal interference
from the user. All of the additional graphical illustrations can be created
by directly running the corresponding functions after the simulation
process is finished.
%}

clearvars % deleting all of the variables that might have been left from the previous simulations



%===================== PREPARING FOR THE SIMULATIONS ======================

res='! General Results.txt'; % creating a text file that will later on contain the general results of the simulations
writelines("General Results",res,"WriteMode","overwrite"); % the header of the file
writecell({'Force, pN','Median detachment time, ns','25% percentile','75% percentile',...
    'Number of undetached molecules'},res,"WriteMode","append","Delimiter",'\t','QuoteStrings','none');
% All of the data is stored in a table format with each row corresponding
% to a different force value and each column corresponding to a different
% parameter.

file='Technical0'; 
% For each force value, a parameter file named Technical0.mat will be
% created. It will contain all of the model parameters along with the
% general results (such as the median detachment time).

Force=[-25 -16 -8 16 25]; % an array of force values that will be used in the simulations, [pN]
% The rest of the parameter values will be identical for all of the
% simulations and will be set in the Parameters.m file.
% An array of [-25 -16 -8 16 25] pN is typically used. When it is possible,
% the value of +8 pN is also included.



%========== CARRYING OUT THE SIMULATIONS AND SAVING THE RESULTS ===========

for F=Force % This cycle will sequentially carry out a set of simulations for each of the force values.

path=SingleNDC80(F); % calling the SingleNDC80.m function which will carry out the said set of simulations
% The path variable returned by the function will either contain the name
% of the directory for this force value or a zero denoting that the
% simulation has been ceased by the user.

if path==0 % If path equals 0, it means that the user has chosen to stop the entire simulation process.
    return % Therefore, the current program is terminated as well.
end

load([path,file],"MedianTime","Perc","NonDetached") 
% the general data for this set of simulations is loaded from the parameter
% file stored in the corresponding directory

writecell({F,MedianTime,Perc(1),Perc(2),NonDetached},res,"WriteMode","append","Delimiter",'\t','QuoteStrings','none');
% the data is printed into the "! General Results.txt" file

end

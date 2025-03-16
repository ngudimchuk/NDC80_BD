%{
     THIS FUNCTION SAVES ALL OF THE PARAMETER VALUES TO A TEXT FILE

This function gets called either by NDC80.m or SingleNDC80.m after the
completion of simulations. It saves all of the parameter values set in
Parameters.m, as well as some of the general results (all three of the
quartiles and the number of simulations in which the molecule did not
detach).
The text file is not needed for the functioning of the program but is far
more convenient for manual revue than the .mat files
%}

function WriteParam(path,file) % this function gets called either by NDC80.m or by SingleNDC80.m 
% path is the path to the directory in which all data for the set of 
% simulations are stored

load([path,file]) % loading all of the parameter values from the parameter file

param=[path,'Parameters.txt']; % creating a text file that will contain all of the values
writelines("Parameter Values",param,WriteMode="overwrite"); % the file header

%---------------------- saving the parameter values -----------------------
% the lines below save the parameter values one by one along a descriptive
% text, so that it is easy for the user to identify what exactly these
% values stand for
writecell({'Time step =',TimeStep,'ns'},param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Max time =',MaxTime,'ns'},param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Number of Simulations =',Iterations},param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Temperature =',Temperature,'K'},param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Viscosity =',Viscosity,'mPa*s'},param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Force =',Force,'pN'},param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Length of the helix until the bending point =',Length_helix,'nm'},param,"WriteMode","append","Delimiter",' ',...
    'QuoteStrings','none');
writecell({'Number of independent points in the helix until the bending point =',Number_helix},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
if Number_postBend>0 % checking if a bending point was present in the simualations
    % if so, writing the values of the parameters relevant to the second
    % part of the stalk, beyond the bending point
    writecell({'Length of the helix after the bending point =',Length_postBend,'nm'},param,"WriteMode","append",...
        "Delimiter",' ','QuoteStrings','none');
    writecell({'Number of independent points in the helix after the bending point =',Number_postBend},...
        param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
    writecell({'Flexural stiffness of the bending point =',FlexStiff_Bend,'pN*nm'},...
        param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
    writecell({'Angle of the undeformed bending point =',Angle0_Bend,'Rad'},...
        param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
end
writecell({'Strain stiffness of 1 nm of the helix =',StrainStiff_pernm,'pN'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Flexural stiffness of the helix =',FlexStiff_helix,'pN*nm'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Flexural stiffness of the joint =',FlexStiff_joint,'pN*nm'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Angle of the undeformed joint =',Angle0_joint,'Rad'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Length of the domain =',Length_domain,'nm'},param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Longitudinal strain stiffness of the domain =',StrainStiff_length,'pN/nm'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Diameter of the domain =',Diameter_domain,'nm'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Transverse strain stiffness of the domain =',StrainStiff_diameter,'pN/nm'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Flexural stiffness of the domain =',FlexStiff_domain,'pN*nm'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Depth of the energy well closest to the minus end =',Depth_well_minus,'kT'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Depth of the central energy well =',Depth_well_center,'kT'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Depth of the energy well closest to the plus end =',Depth_well_plus,'kT'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Width of the energy wells =',Width_well,'nm'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Repulsion coefficient for the MT =',Repuls_MT,'pN/nm'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Detachment distance =',Radius_det,'nm',newline},param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');

%----------------------- saving the general results -----------------------
if Iterations>1 % checking if there has been more than one iteration
    % if there has, the parameters of the detachment times distribution
    % shall be saved
writecell({'Median detachment time is',MedianTime,'ns'},param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'25% and 75% percentiles are',Perc(1),'and',Perc(2),'ns'},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
writecell({'Number of times the molecule did not detach =',NonDetached},...
    param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
else % if not, the detachment time for the sole simulation is saved
writecell({'The detachment time is',MedianTime,'ns'},param,"WriteMode","append","Delimiter",' ','QuoteStrings','none');
end
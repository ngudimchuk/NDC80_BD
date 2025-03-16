%{
                THIS FUNCTION IS CALLED BY RunNDC80.m AND
    CARRIES OUT A SET OF SIMULATIONS FOR THE GIVEN SET OF PARAMETERS

This function cannot be run independently and only functions as an
extension of RunNDC80.m. It is a part of a pathway alternative to NDC80.m.
While NDC80.m is focused on extensively studying the results obtained for
one set of parameters, the RunNDC80.m pathway allows the user to carry out
simulations for different force values in a single run. All of the
functionality that SingleNDC80.m lacks in comparison to NDC80.m can be
obtained by independently running the functions NDC80.m calls for.
%}

function path = SingleNDC80(Force) % This function gets called by RunNDC80.m.
% path is the path to the directory in which all the data for the set of
% simulations is stored.

% In case the function is terminated by user (more on that later) the path
% is set to 0 to induce the termination of the entire run:
path=0; 



%================= CREATING A FOLDER FOR THE FUTURE DATA ==================
% By default, the folder's name is "Results <Force value> pN".
% If such a directory already exists, the program will give the user three
% options:
% 1) to overwrite the previous data;
% 2) to change the name of the folder to "Results <Force value> pN <lowest
%    unused integer;
% 3) to stop the entire run of the program, including the upcoming
%    simulations with different forces.

if ~isfolder(sprintf('Results %d pN',Force)) % checking if a folder with such a name exists
    mkdir (sprintf('Results %d pN',Force)) % if it does not, creating the folder
    path=(sprintf('Results %d pN\\',Force)); % and setting the path to it
else % such a folder does exist
    for i=1:1000
        % searching for the lowest unused integer in the name of the file
        if ~isfolder(sprintf('Results %d pN %d',Force,i+1))
            opts.Interpreter='tex';
            opts.Default=sprintf('USE A NEW NAME (Results %d pN %d)',Force,i+1);
            Answer=questdlg('\fontsize{10}Directory already exists','Warning','OVERWRITE',...
                sprintf('USE A NEW NAME (Results %d pN %d)',Force,i+1),'STOP THE SIMULATION',opts);
            % creating a question dialogue with the three options described above

            switch Answer
                case 'OVERWRITE' % the user has chosen to overwrite the folder
                    path=(sprintf('Results %d pN\\',Force)); % setting the path to the already existing folder
                    break
                case sprintf('USE A NEW NAME (Results %d pN %d)',Force,i+1) % the user has chosen to use a different name
                    mkdir (sprintf('Results %d pN %d',Force,i+1)) % creating a folder with the found lowest integer
                    path=sprintf('Results %d pN %d\\',Force,i+1); % setting the path to the folder
                    break
                case 'STOP THE SIMULATION' % the user has chosen to terminate the entire run
                    return % the path has already been set to 0 so the only thing left to do is to terminate SingleNDC80.m
            end
        end
    end
end

file='Technical0'; % creating a file which will later on store all of the parameters along with some generalized results
save([path,file],"Force") % saving the force parameter to the Technical0.mat file that has just been created
Parameters(path); % calling a function Parameters.m which will set and save the rest of the parameter values



%======================== RUNNING THE SIMULATIONS =========================

Execute(path,file); % calling the core function Execute.m which performs the simulations themselves
% This function automatically saves the results to files named
% "Technical<simulation number>" in the created folder.



%====================== PROCESSING THE OBTAINED DATA ======================
% Execute.m only returns raw data such as bead positions or individual
% detachment times. To analize them and determine the detachment time
% distribution, further computations need to be performed. 

load([path,file],"Iterations") % loading the number of iterations from Technical0.mat

if Iterations>1 % If there was more than one simulation, the detachment time distribution needs to be studied.

    Survival(path,file);
    % This function determines the first, second and third percentiles of
    % the detachment time distribution; as well as the number of
    % simulations when the molecule did not detach in the given time limit.
    % The detachment time distribution is also visualized.

    WriteParam(path, file) % This function saves all the parameters along with some general results to a text file.

else % In case there was only one simulation, no additional calculations are needed.
    load([path,file],"NSteps","TimeStep","MaxTime") % loading some of the parameters concerning time
    TechN=[path,'Technical1']; 
    % Since there has only been one simualtion, only one additional file
    % has been created and it is numbered 1.
    load(TechN,"Ndet") % loading data from the said file

    if Ndet==NSteps 
        % If the parameter Ndet has been saved equal to the maximum number
        % of steps, it means the molecule did not detach in the given time
        % limit.
        MedianTime=sprintf('>%d',MaxTime); % median detachment time, [ns]
        % Since there has only been one simulation and the molecule did not
        % detach, the median detachment time is expected to be above the
        % time limit.
        NonDetached=1; % number of simulations when the molecule did not detach
        % There has only been one simulation and in it, the molecule did
        % not detach.

    else % the molecule did detach during the simulation
        MedianTime=Ndet*TimeStep; 
        % There has only been one simulation, so the median detachment time
        % equals its detachment time.
        NonDetached=0; % the molecule detached
    end

    save([path,file],"MedianTime","NonDetached",'-append') % saving the results to Technical0.mat
    WriteParam(path, file) % saving the parameters and the results to a text file

end

end
%{
     THIS PROGRAM ALLOWS THE USER TO CARRY OUT A SET OF SIMULATONS
           WITH FIXED PARAMETER VALUES AND ANALYZE THE RESULTS

This file can be used to start the entire simulation process, similar to
RunNDC80.m. However, in this case the simulations will be carried out for
one force value only. After the simualations are finished, the user is
offered to create a variety of visual representations of the results.
Another feature of this program is that the user can choose to ignore the
parameter values currently set in the Parameters.m file and load an already
existing parameter file instead.
Therefore, this program is useful for easily carrying out a set of
simulations and analyzing them without having to alter the Parameters.m
file or run other programs. 
%}

clearvars % deleting all of the variables that might have been left from the previous simulations

Force=-16; % the force value that is going to be used in the upcoming simualations, [pN]
% The values of +-8, +-16 and +-25 pN are typically used.
% The rest of the parameters are set in Parameters.m or can be loaded from
% a parameter file as described below.



%================= CREATING A FOLDER FOR THE FUTURE DATA ==================
% By default, the folder's name is "Results <Force value> pN".
% If such a directory already exists, the program will give the user three
% options:
% 1) to overwrite the previous data;
% 2) to change the name of the folder to "Results <Force value> pN <lowest
%    unused integer>";
% 3) to stop the entire run of the program.

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
                    return % terminating the run
            end
        end
    end
end



%================ SETTING THE REST OF THE PARAMETER VALUES ================
% Unlike with RunNDC80.m, here the user is not constrained to the parameter
% values set in Parameters.m. Instead, any previously created
% parameter file can be used.

opts.Interpreter='tex';
opts.Default='YES';

Answer=questdlg('\fontsize{10}Would you like to use the parameters set in the program?','Parameter Values','YES',...
    sprintf(' NO (load a parameter file) '),opts); 
% asking the user if they would prefer to use the values set in
% Parameters.m or to load a parameter file (these files are named
% Technical0.mat when they are created)

switch Answer
case 'YES' % the user has chosen to use the Parameters.m values
    file='Technical0'; % creating a file that will store the parameters along with some generalized results in the future
    % This file can be used to recreate the conditions of the simulations
    % in the future.
    save([path,file],"Force") % saving the force value into the file
    Parameters(path); % running the Parameters.m function which will set the rest of parameters

case ' NO (load a parameter file) ' 
    % the user has chosen to get the parameter values from an already existing .mat file
    [file,p] = uigetfile; % asking the user to choose the file the parameters should be taken from
    % Notice that the file does not have to be named Technical0.mat for the
    % program to work.
    copyfile([p,file],path); % copying the file to the previously created directory
    save([path,file],"Force",'-append') % saving the force value into the file
end



%======================== RUNNING THE SIMULATIONS =========================

Execute(path,file);  % calling the core function Execute.m which performs all of the simulations
% This function automatically saves the results to files named
% "Technical<simulation number>" in the created folder.



%====================== PROCESSING THE OBTAINED DATA ======================
% Execute.m only returns raw data such as bead positions or individual
% detachment times. To analize them, further computations need to be
% performed. 
% The most important task is to determine the detachment time
% distribution, therefore the corresponding functions are always called
% for. The detachment time distribution also gets visualized via charts.
% The program also offers the user to visualize some of the other data. 
% There are 3 visuals that can be created for any simulation: 
% 1) intramolecular angles vs time;
% 2) attachment state of the molecule vs time;
% 3) a video of the molecule's movements during the simulation.

load([path,file],"Iterations") % loading the number of iterations from the parameter file

if Iterations>1 % If there was more than 1 simulation, the detachment time distribution needs to be investigated.

    Survival(path,file);
    % This function determines the first, second and third percentiles as
    % well as the number of simulations when the molecule did not detach
    % in the given time limit.
    % The detachment time distribution is also visualized.

    WriteParam(path, file) % This function saves all the parameters along with some general results to a text file.

    % If there have been more than 30 simulations the program does not
    % offer the user to visualize any other aspects of the simulations.
    if Iterations>30 
        return 
        % There are multiple ways the visualizations might be canceled,
        % all of those paths end in a return command. If no return command
        % is encountered, the program will proceed to the visualization
        % part.
    end

    % As has already been said, the program also allows the user to
    % visualize certain aspects of individual simulations. This question
    % asks the user if they would like to proceed to that part of the
    % program.
    Answer=questdlg('\fontsize{10}Would you like to continue analysis?','Continue?','YES','NO',opts);
    % If the user chooses yes, there is no need to do anything since the
    % visualizations will be carried out as long as no return commands are
    % encountered.
    switch Answer
        case 'NO' % the user has chosen not to visualize any data beyond the time distribution
        return; % the program is terminated
    end

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
        % there has only benn one simulation and in it, the molecule did
        % not detach.

        Answer=questdlg(sprintf('\\fontsize{10}The molecule did not detach.\nWould you like to continue analysis?'),...
            'Continue?','YES','NO',opts);
        % Notifying the user that the molecule did not detach and asking
        % them if any visualization is needed. The answer will be relevant
        % later.

    else % the molecule did detach during the simulation
        MedianTime=Ndet*TimeStep;
        % There has only been one simulation, so the median detachment time
        % equals its detachment time.
        NonDetached=0; % the molecule detached

        Answer=questdlg(sprintf(...
            '\\fontsize{10}The molecule detached after %.1f ns.\nWould you like to continue analysis?'...
            ,Ndet*TimeStep),'Continue?','YES','NO',opts);
        % Notifying the user of the detachment time and asking them if any 
        % visualization is needed. The answer will be relevant later.
    end

    save([path,file],"MedianTime","NonDetached",'-append') % saving the results to the parameter file
    WriteParam(path, file) % This function saves all the parameters along with some general results to a text file.

    switch Answer
        case 'NO' % the user chose not to perform any other visualization earlier
            return; % the program is terminated
    end

end



%================== CREATING ADDITIONAL PLOTS AND MOVIES ==================

% Asking the user if any intramolecular angles versus time plots should be
% created:
Answer=questdlg('\fontsize{10}Would you like to create angle plot(s)?','Angle Plots','YES','NO',opts);
switch Answer
case 'YES' % the user has chosen to create the plots
    AngleGraphs(path,file); % calling the corresponding function
end

% Asking the user if any molecular attachment state versus time plots
% should be created: 
Answer=questdlg('\fontsize{10}Would you like to create attachment plot(s)?','Attachment Plots','YES','NO',opts);
switch Answer
case 'YES' % the user has chosen to create the plots
    AttachmentGraphs(path,file); % calling the corresponding function
end

% asking the user if videos of any simulations should be created
Answer=questdlg('\fontsize{10}Would you like to create movie(s)?','Videos','YES','NO',opts);
switch Answer
case 'YES' % the user has chosen to create videos
    Movies(path,file) % calling the corresponding function
end
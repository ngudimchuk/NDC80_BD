%{
        THIS FUNCTION ANALYZES THE DETACHMENT TIMES DISTRIBUTION

This function is called by both SingleNDC80.m and NDC80.m. It can also be
run independently. It determines the main parameters of the distribution
and creates two graphs visualizing it (individual detachment times with the
three percentiles and a survival plot).
All of the parameters get saved to the parameter file (usually named
Technical0.mat). They also get added to the parameter text file if the
function is run by NDC80.m or SingleNDC80.m.
%}

function Survival(path,file) % This function gets called either by NDC80.m or by SingleNDC80.m.
% path is the path to the directory in which all the data for the set of
%   simulations is stored; 
% file is a Matlab data file containing all of the model parameter values. 
%   It is typically named Technical0.mat.

% The following if clause allows the function to be run independently:
if exist('file','var')~=1 % checking if there has been any input
    [file,path] = uigetfile; 
    % If the function is run independently, it has no input variables, so
    % path and file have to be defined manually.
end



%================ CALCULATING THE DISTRIBUTION PARAMETERS =================

load([path,file],"Iterations","NSteps","TimeStep","MaxTime") % loading the necessary parameters from the parameter file

NonDetached=0; % the number of times the molecule did not detach; its value will be changed later
Times=zeros(2,Iterations); % creating an array of detachment times for all simulations

Survival=zeros(2,NSteps); % This matrix will later contain the values of the survival function at each time step.
% The first row contains the time steps, the second row the fractions.
for k=1:NSteps 
    Survival(1,k)=k*TimeStep; % filling the first row of the Survival matrix
end

% loading the detachment times from the individusl data files for each simulation
for n=1:Iterations 
    TechN=[path,sprintf('Technical%d',n)]; % The data files are named "Technical<simulation number>.mat".
    load(TechN,"Ndet") % loading the detachment time

    Times(:,n)=[n;Ndet*TimeStep]; % saving the detachment time value to a corresponding cell

    if Ndet==NSteps
        NonDetached=NonDetached+1; 
        % If during the reviewed simualtion the molecule did not detach,
        % the total number of times the molecule did not detach increases
        % by one.
    end

    % adding this simulation's data to the future survival plot
    for k=1:NSteps
        if k<=Ndet % checking if the molecule is still attached at each timestep
            Survival(2,k)=Survival(2,k)+1; 
            % If so, the total number of molecules attached at this time point increases by one.
        end
    end
end
Survival(2,:)=Survival(2,:)/Iterations; 
% dividing the number of simulations in which the molecule did not detach
% up until this time point by the total number of simulations

% If the number of simulations in which the molecule did not detach is
% equal to or greater than half of the total number of simulations, the
% median detachment time cannot be calculated.
if NonDetached*2<Iterations 
    MedianTime=median(Times(2,:)); % calculating the median detachment time
else
    MedianTime=sprintf('>%d',MaxTime); % The median detachment time must be greater than the maximum simulation time.
end

Perc=[prctile(Times(2,:),25) prctile(Times(2,:),75)]; % calculating the first and the third quartiles
for i=1:2
    if Perc(i)==prctile(Times(2,:),100) 
        % If a quartile is equal to the percentile for 100%, it means that
        % the molecule detached in less than 1/4 (or 3/4 for the third
        % quartile) of cases.
        Perc(i)=0/0; % If so, the quartile was not calculated properly and is instead set to NaN.
    end
end

% If all of the molecules have detached, it would be beneficial to crop the
% matrix to only contain the informative data:
if Survival(2,end)==0 % checking if the matrix contains zeros
    Number=min(ceil(ceil(find(any(~Survival),1)/1000*TimeStep)*1000/TimeStep),NSteps);
    % determining the optimal length of the matrix. The number is set to be
    % a multiple of a thousand.
else
    Number=NSteps; % if the Survival matrix does not contain zeros, its length should stay the same
end

Survival=Survival(:,1:Number); % cropping the matrix

save([path,file],"Times","MedianTime","NonDetached","Perc",'-append') 
% saving the calculated distribution parameters to the parameter file



%============= CREATING THE DETACHMENT TIME DISTRIBUTION PLOT =============

f01=figure; set(gcf,'WindowState','maximized'); % creating the first figure, visualizing the detachment times distribution
hold on
grid on

% if the molecule does not detach during the simulation its detachment time
% is set to the maximum time. But this is not an actual time of detachment
% and should not be added to the plot
T=Times; % creating a matrix that will only contain the times for the molecules that have actually detached
for i=length(T):-1:1 % the matrix length will be changing
  if(T(2,i)==NSteps*TimeStep) % checking if the detachment time equals the max time
    T(:,i)=[]; % if it does, removing the corresponding row
  end
end

scatter(T(1,:),T(2,:),150,"black","filled"); % plotting the detachment times
if ~isnan(Perc(1)) % checking if the first quartile was calculated properly
    plot([1 Iterations],[Perc(1) Perc(1)],'r.--','LineWidth',3,'Marker','none');
    % plotting a line reflecting the first quartile
end
if NonDetached*2<Iterations % checking if the median time could be calculated
    plot([1 Iterations],[MedianTime MedianTime],'r.-','LineWidth',3,'Marker','none'); 
    % plotting a line reflecting the median detachment time
end
if ~isnan(Perc(2)) % checking if the third quartile was calculated properly
    plot([1 Iterations],[Perc(2) Perc(2)],'r.--','LineWidth',3,'Marker','none');
    % plotting a line reflecting the third quartile
end

% changing the style of the plot
g=gca;
g.FontSize=16;
xticks(T(1,:))
xlabel('Experiment','FontSize',16)
ylabel('Time,ns','FontSize',16)
legend('Experiments','First Quartile','Median','Third Quartile','FontSize',16,'Location','best')
title('Times','FontSize',16);

saveas(f01,[path,'Times.png']); % saving the plot to the same directory where the rest of the data is stored



%===================== PLOTTING THE SURVIVAL FUNCTION =====================

f02=figure; set(gcf,'WindowState','maximized'); % creating the second figure, depicting the survival function
hold on
grid on

plot(Survival(1,:),Survival(2,:),'r-','LineWidth',1,'Marker','none'); % plotting the survival function
axis([0 Survival(1,Number) 0 1]) % changing the axis size to perfectly encompass the plot

if NonDetached*2<Iterations % checking if the median time could be calculated
    ax=axis;
    % calculating the preferable position for a text annotation
    if MedianTime<=(ax(1)+ax(2))/2 % checking if the median time is lower than the middle point of the X axis
        text(ax(2)-(ax(2)-ax(1))/50,0.5,sprintf('Median detachment time: %.1f ns',MedianTime),"FontSize",16,...
            "HorizontalAlignment","right")
        % If so, it is better to position the text annotation on the right
        % side of the plot. The text indicates the detachment time.
    else % if the median time is greater than the middle point of the X axis,
        text(ax(1)+(ax(2)-ax(1))/50,0.5,sprintf('Median detachment time: %.1f ns',MedianTime),"FontSize",16,...
            "HorizontalAlignment","left") % the annotation should be positioned on the left
    end
end

% changing the style of the plot
g=gca;
g.FontSize=16;
xlabel('Time,ns','FontSize',16)
ylabel('Fraction of attached molecules','FontSize',16)
title('Survival Plot','FontSize',16);

saveas(f02,[path,'Survival.png']); % saving the plot



%==== NOTIFYING THE USER IS IN SOME CASES THE MOLECULE DID NOT DETACH =====

if NonDetached~=0 % checking if there was a simulation when the molecule did not detach
    % if so, creating a dialogue window notifying the user that a certain
    % number of molecules did not detach
    NonDet=helpdlg(sprintf('%d molecule(s) did not detach',NonDetached),'Notification');
    FontSz=findall(NonDet,'Type','Text');
    FontSz.FontSize=10;
end

end
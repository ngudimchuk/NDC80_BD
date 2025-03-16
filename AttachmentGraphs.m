%{
              THIS FUNCTION ALLOWS THE USER TO CREATE 
                  MOLECULE ATTACHMENT STATE PLOTS

This function can be either called by NDC80.m or run independently. The
function calculates the fraction of spheres that are considered attached at
each time frame and creates a plot depicting its dependence on time.
The function allows the user to choose the simulations for which the plots
should be created and then renders them one by one.
%}

function AttachmentGraphs(path,file) % This function can be called by NDC80.m.
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

load([path,file],"Iterations","Times") % loading the needed variables from the parameter file

%====================== CREATING THE DIALOGUE WINDOW ======================
% In this window, a list of all simulations run via the given parameter
% file is presented with the determined detachment times. Checking boxes
% next to simulations allows the user to choose the simulations for which
% videos will be created.

CBXv=zeros(Iterations,1); % creating an array that will contain the checkbox values
if Iterations>1
% If there has only been one simulation running the function already
% implies that a video plot be created for it.

set(0,"Units","pixels")
Screen=get(0,"ScreenSize"); % getting the size of the screen
Position=[floor((Screen(3)-545)/2) floor((Screen(4)-60-Iterations*25)/2) 545 60+Iterations*25];
% defining the dialogue window position

fig=uifigure('Name','Attachment Graphs','Position',Position); % creating the window
lbl=uilabel(fig,"Text",'Please, choose the simulations you would like to create attachment graphs for','FontSize',...
    14,'Position',[30 30+Iterations*25 1000 20]); % creating the header

% Creating the checkboxes:
for n=1:Iterations
    cbx(n)=uicheckbox(fig,"Position",[45 30+(Iterations-n)*25 1000 15],"Text",sprintf('Simulation %d, %.1f ns',...
        n,Times(2,n)),'FontSize',14);
end

% Creating a button for the user to press when all the desired boxes have
% been ticked:
btn=uibutton(fig,'state','Position',[415 30 100 30],'Text','Continue');
while(btn.Value ~=1)
    pause(1); % waiting for the user to hit the button
end

for n=1:Iterations
    CBXv(n)=cbx(n).Value; % returning the checkbox values to the created array
end
delete(fig) % closing the dialogue window
end



%==================== PLOTTING THE ATTACHMENT GRAPHS ======================

for n=1:Iterations % the program goes through every simulation number checking if a plot needs to be created

% If multiple simulations took place, only the ones for which the box has
% been checked will have a plot created. If there has only been one 
% simulation and the Attachment function has been called, that
% automatically means an angle plot needs to be created for that
% simulation.
if (CBXv(n)==1) || (Iterations==1)

% Loading the file that contains data specific to the chosen simulation:
TechN=[path,sprintf('Technical%d',n)];
load(TechN,"Attachments","Ndet"); % loading the attachmnet states for each of the sites at each timestep

Fractions=sum(Attachments(2:4,:),1)/3; % calculating the fraction of attached spheres for each timestep

f3=figure; set(gcf,'WindowState','maximized'); % creating a figure for the plot
hold on
grid on
% plotting the fraction of attached spheres versus time
plot(Attachments(1,1:Ndet+1),Fractions(1:Ndet+1),'k-','LineWidth',1,'Marker','none');

% changing the style of the plot
g=gca;
g.FontSize=16;
xlabel('Time, ns','FontSize',16)
ylabel('State','FontSize',16)
title('Fraction of Contacts','FontSize',16);

saveas(f3,[path,sprintf('Attachments %d.png',n)]); % saving the plot

end

end

end
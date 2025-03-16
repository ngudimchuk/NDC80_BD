%{
     THIS FUNCTION ALLOWS THE USER TO CREATE VIDEOS OF SIMULATIONS

This function can be either called by NDC80.m or run independently. It
allows the user to choose the simulations for which videos should be
created and then renders them one by one.
%}

function Movies(path,file) % This function can be called by NDC80.m.
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

load([path,file],"Iterations","TimeStep","Diameter_domain","Force","Times","Number_helix","Number_postBend","Length_segment")
% loading the needed variables from the parameter file
Number=Number_helix+Number_postBend; % calculating the number of beads in the stalk



%======================= CREATING A DIALOGUE WINDOW =======================
% In this window, a list of all performed simulations is presented with the
% determined detachment times. Checking boxes next to the simulations
% allows the user to choose the simulations for which videos shall be
% created.

CBXv=zeros(Iterations,1); % creating an array that will contain the checkbox values
if Iterations>1 
% If there has only been one simulation, running the function already
% implies that a video should be created for it.

set(0,"Units","pixels")
Screen=get(0,"ScreenSize"); % getting the size of the screen
Position=[floor((Screen(3)-470)/2) floor((Screen(4)-60-Iterations*25)/2) 470 60+Iterations*25]; 
% defining the dialogue window position

fig=uifigure('Name','Videos','Position',Position); % creating the window
lbl=uilabel(fig,"Text",'Please, choose the simulations you would like to create movies for','FontSize',...
    14,'Position',[30 30+Iterations*25 1000 20]); % creating the header

% Creating the checkboxes:
for n=1:Iterations
    cbx(n)=uicheckbox(fig,"Position",[45 30+(Iterations-n)*25 1000 15],"Text",sprintf('Simulation %d, %.1f ns',...
        n,Times(2,n)),'FontSize',14); 
end

% Creating a button for the user to press when all the desired boxes have
% been ticked:
btn=uibutton(fig,'state','Position',[340 30 100 30],'Text','Continue'); 
while(btn.Value ~=1)
    pause(1); % waiting for the user to hit the button
end

for n=1:Iterations
    CBXv(n)=cbx(n).Value; % returning the checkbox values to the created array
end
delete(fig) % closing the dialogue window
end



%========================== RENDERING THE VIDEOS ==========================
% The program functions by succesively redrawing the molecule at the
% determined timesteps (description below) and saving the drawings to a
% video file.

for n=1:Iterations % the program goes through every simulation number checking if a video needs to be created

% If multiple simulations took place, only the ones for which the box has
% been checked will have a video created. If there has only been one
% simulation and the video function has been called, that automatically
% implies that a video needs to be created.
if (CBXv(n)==1) || (Iterations==1)


%---------------- Preparing the system for video recording ----------------

TechN=[path,sprintf('Technical%d',n)]; % loading the file that contains data specific to the chosen simulation
load(TechN,"Experiment"); % loading the coordinates of each bead at each timestep

NSteps=size(Experiment,3); % determening the ultimate number of timesteps by the size of the Experiment matrix

f4=figure; set(gcf,'WindowState','maximized'); % creating a figure to draw the molecule in
grid on
hold on

% Warning the user to not close or minimize the created figure:
Warn=helpdlg('Please wait for the process to finish','Warning'); 
FontSz=findall(Warn,'Type','Text');
FontSz.FontSize=10;
Warn.Position=Warn.Position+[-4 0 8 0];

NFrames=min(1200,NSteps); 
% The final video is supposed to have 1200 frames. However, if the number
% of timesteps is below that, the length of the video is limited by this
% number instead.

k=NSteps/NFrames; % calculating the number of in-simulation timesteps between the frames


%----------------------- Determening the axes scale -----------------------

% The program functions by succesively redrawing the molecule for each of
% the chosen timesteps. However, if the axes scale is not fixed it might
% change during the redrawing process, creating an uneven scale throughout
% the video. To avoid that, an axes scale is determined and fixed in
% advance.

% The following cycle draws the molecule at each frame at once to ensure
% the scale is large enough to fit the molecule at each frame:
for i=1:NFrames
    Frame=floor(i*k); % calculating the number of the timestep for which the image should be created

    plot([Experiment(1,1:2,Frame) Experiment(1,Number+4,Frame) Experiment(1,3:Number+3,Frame)],...
        [Experiment(2,1:2,Frame) Experiment(2,Number+4,Frame) Experiment(2,3:Number+3,Frame)],...
        'k.-','LineWidth',3,'MarkerSize',30); 
    % creating the backbome of the molecule depicted as lines and circles
    % at the centers of the beads 
    
    rectangle('Position',[Experiment(1,1,Frame)-Diameter_domain/2 Experiment(2,1,Frame)-...
        Diameter_domain/2 Diameter_domain Diameter_domain]);
    rectangle('Position',[Experiment(1,2,Frame)-Diameter_domain/2 Experiment(2,2,Frame)-...
        Diameter_domain/2 Diameter_domain Diameter_domain]);
    rectangle('Position',[Experiment(1,Number+3,Frame)-Length_segment/2 Experiment(2,Number+3,Frame)-...
        Length_segment/2 Length_segment Length_segment]);
    % depicting the three outermost beads of the molecule to ensure they
    % also fit the frame
end

axis equal % setting the same scale for X and Y axes to avoid molecule distortion
ax=axis; % saving the dimensions of axes

p=[0.13 0.11 0.775 0.81]; % creating an array with the positions of the axes within the figure
g=gca;
g.Position=p; % setting the axes to the manual positions


%-------------------- Defining the molecule appearance --------------------

% To ensure the molecule looks appealing for any set of parameters, a
% special multiplier is employed for line thicknesses:
Multiplier=(14/(ax(2)-ax(1)))^0.8; % the multiplier is calculated through the X-axis length

% If the stalk is short, it is beneficial for the beads to be
% translucent. If the stalk is long, however, the beads become very small
% on video and should be drawn opaque for better visibility.
if Number_postBend==0 % the choice is made by checking if the stalk has a bending point
    opacity=0.5; % if it does not, the opacity is set to 50 %
else
    opacity=1; % if it does, the opacity is set to 100%
end


%--------------------------- Creating the video ---------------------------

v=VideoWriter([path,sprintf('Dynamics %d',n)]); % creating a video file
v.FrameRate=20; % setting the frame rate
open(v);

for i=1:NFrames 
    Frame=floor(i*k); % calculating the number of the timestep for which the image should be created
    
    hold off % this way, everything that has been previouslt drawn, will be deleted

    plot([ax(1) ax(2)],[0 0],'k--','LineWidth',3*Multiplier,'Marker','none');
    % plotting a line depicting the microtubule surface
    hold on
    patch([ax(1) ax(2) ax(2) ax(1)],[ax(3) ax(3) 0 0],[0 0 1 1],'EdgeColor','none'); 
    % filling the microtubule body with a gradient
    colormap gray % setting the gradient to gray
    plot([ax(1) ax(2)],[0 0],'k--','LineWidth',3*Multiplier,'Marker','none');
    % redrawing the microtubule surface above the patch. The surface had to
    % be drawn before because the patch function is not compatible with the
    % hold command
    
    % creating three points depicting the sites on the microtubule surface
    scatter([-Diameter_domain/2 0 Diameter_domain/2],[0 0 0],500*Multiplier^2,"black","filled");
    scatter([-Diameter_domain/2 0 Diameter_domain/2],[0 0 0],250*Multiplier^2,"white","filled");

    % Drawing the bead ternary that interacts with the microtubule. The
    % sizes of all beads are true to the scale. 
    rectangle('Position',[Experiment(1,1,Frame)-Diameter_domain/2 Experiment(2,1,Frame)-...
        Diameter_domain/2 Diameter_domain Diameter_domain],'Curvature',[1 1],'FaceColor',[1 0.627 0.024 opacity],...
        'LineStyle','none');
    rectangle('Position',[Experiment(1,2,Frame)-Diameter_domain/2 Experiment(2,2,Frame)-...
        Diameter_domain/2 Diameter_domain Diameter_domain],'Curvature',[1 1],'FaceColor',[1 0.627 0.024 opacity],...
        'LineStyle','none');
    rectangle('Position',[Experiment(1,Number+4,Frame)-Diameter_domain/2 Experiment(2,Number+4,Frame)-...
        Diameter_domain/2 Diameter_domain Diameter_domain],'Curvature',[1 1],'FaceColor',[1 0.627 0.024 opacity],...
        'LineStyle','none');

    % Drawing the rest of the beads:
    for j=3:Number+3
        rectangle('Position',[Experiment(1,j,Frame)-Length_segment/2 Experiment(2,j,Frame)-...
            Length_segment/2 Length_segment Length_segment],'Curvature',[1 1],'FaceColor',[0.6 0.6 0.6 opacity],...
            'LineStyle','none');
    end

    % Plotting the molecule backbone. Its geometric parameters are
    % determined by the multiplier.
    plot([Experiment(1,1:2,Frame) Experiment(1,Number+4,Frame) Experiment(1,3:Number+3,Frame)],...
        [Experiment(2,1:2,Frame) Experiment(2,Number+4,Frame) Experiment(2,3:Number+3,Frame)],...
        'k.-','LineWidth',5*Multiplier,'MarkerSize',50*Multiplier);

    text(ax(1)+(ax(2)-ax(1))/30,ax(4)-(ax(4)-ax(3))/17,sprintf('%.1f ns',Frame*TimeStep),"FontSize",16)
    % adding a timestamp to the video
    
    axis(ax) % setting the axes sizes to the pretedetrmined values
    % changing the style of the frame
    g=gca;
    g.FontSize=16;
    xlabel('X, nm','FontSize',16)
    ylabel('Y, nm','FontSize',16)
    title('Molecule Shape','FontSize',16);
    
    % adding an arrow representing the external force
    if Force~=0 && (Experiment(1,Number+3,Frame)-ax(1))>0 && (Experiment(1,Number+3,Frame)-ax(1))<(ax(2)-ax(1))
        % checking if the external force was applied and if the arrow would
        % fit within the axes

        x=[(Experiment(1,Number+3,Frame)-ax(1))/(ax(2)-ax(1))*p(3)+p(1)+0.01*Multiplier^0.5*sign(Force) (Experiment(1,...
            Number+3,Frame)-ax(1))/(ax(2)-ax(1))*p(3)+p(1)+0.09*Multiplier^0.5*sign(Force)];
        y=[(Experiment(2,Number+3,Frame)-ax(3))/(ax(4)-ax(3))*p(4)+p(2) (Experiment(2,Number+3,Frame)-...
            ax(3))/(ax(4)-ax(3))*p(4)+p(2)];
        % setting the arrow coordinates

        annotation('arrow',x,y,'Color','black','LineWidth',10*Multiplier^0.6,'HeadWidth',30*Multiplier^0.6,'HeadLength',...
            30*Multiplier^0.6,'HeadStyle',"vback1"); % drawing the arrow
    end
    
    FrameCapture=getframe; % capturing the drawing as a new video frame
    writeVideo(v,FrameCapture);
        delete(findall(gcf,'type','annotation')); % deleting the arrow and the timestamp
end

close(v); % finishing the video
close(f4); % deleting the figure

delete(Warn); % the video has been saved, closing the warning window

Saved=helpdlg('Video file saved','Notification'); % notifying the user the video has been saved
FontSz=findall(Saved,'Type','Text');
FontSz.FontSize=10;

end

end
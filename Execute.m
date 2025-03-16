%{
        THIS FUNCTION ENCOMPASSES THE ENTIRE SIMULATION PROCESS

First, a symbolic function for the total energy of the sistem is created;
A gradient of this function is calculated for every bead of the molecule
    and then turned into a matlab function;
Then, the simulations themselves take place. At the beginning of each
    simulation, three matrices are created that will then be filled with 
    data describing the molecule at each time point of the simulation;
If the molecule detaches, the simulation ceases, all of its data gets saved
    and a new simulation begins;
%}

function Execute(path,file) % This function gets called either by NDC80.m or by SingleNDC80.m
% path is the path to the directory in which all the data for the set of
%   simulations is stored; 
% file is a Matlab data file containing all of the model parameter values. 
%   It is typically named Technical0.mat.

load([path,file]); % loading the parameter file.
% Since (almost) all of the variables stored in this file are going to be
% used, no further specification is needed. 



%==== CREATING A SYMBOLIC FUNCTION FOR THE TOTAL ENERGY OF THE SYSTEM =====
% Some of the custom symbolic functions are created by the same matlab
% function that defines the parameter values and get saved to the parameter 
% file. However, the symbolic functions defined below are too long to be
% saved to a Matlab data file. Therefore, they have to be defined within
% the function that calls them. 

syms x1 y1 x2 y2 x3 y3 % creating symbolic variables that will later be used to define the energy function
% The variables with indexes 1 and 2 represent the outer beads of the
%   ternary interacting with the microtubule
% The central bead of the ternary does not need a special variable because
%   its position is determined as the middle point between the two edge
%   points.
% The index 3 is used for the hinge bead between the ternary and the 
%   stalk of the molecule.

syms x4 [1 Number_helix+Number_postBend]
syms y4 [1 Number_helix+Number_postBend]
% The x4 and y4 vectors represent the entire stalk of the molecule
% They have to be created as vectors instead of separate variables because 
% the number of beads in the stalk is not fixed


%--- Creating an energy function for the helical stalk of the molecule ----
% The stalk function has to be created in an iterative manner because the
% number of beads in it can differ.

% The function starts off as a single strain potential for the first bead
% of the stalk since it is applicable to a stalk of any length.
UHelix=@(x3,y3,x4,y4) UStrain(StrainStiff_segment,Length_segment,x4(1)-x3,y4(1)-y3);

for i=2:Number_helix % adding the strain energy components for the rest of the stalk
    UHelix=@(x3,y3,x4,y4) UHelix(x3,y3,x4,y4)+...
        UStrain(StrainStiff_segment,Length_segment,x4(i)-x4(i-1),y4(i)-y4(i-1));
end

if Number_helix>1 
% If there are at least two beads in the stalk, there is another bending
% energy function that conctains the hinge bead (the bead numbered 3):
    UHelix=@(x3,y3,x4,y4) UHelix(x3,y3,x4,y4)+...
        UHelixBend(x4(1)-x3,y4(1)-y3,x4(2)-x4(1),y4(2)-y4(1));
end

for i=3:Number_helix % adding the rest of the bending energy components
    UHelix=@(x3,y3,x4,y4) UHelix(x3,y3,x4,y4)+...
        UHelixBend(x4(i-1)-x4(i-2),y4(i-1)-y4(i-2),x4(i)-x4(i-1),y4(i)-y4(i-1));
end

% The if clause below adds the energy components of the part of the stalk
% beyond the bending point. The process is very similar to what has been
% described above.
if Number_postBend>0
    UHelix=@(x3,y3,x4,y4) UHelix(x3,y3,x4,y4)+UBend(FlexStiff_Bend,x4(Number_helix)-x4(Number_helix-1),y4(Number_helix)-...
        y4(Number_helix-1),x4(Number_helix+1)-x4(Number_helix),y4(Number_helix+1)-y4(Number_helix),Angle0_Bend);
    for i=1:Number_postBend % adding the strain energy components
        UHelix=@(x3,y3,x4,y4) UHelix(x3,y3,x4,y4)+...
            UStrain(StrainStiff_SpB,Length_SpB,x4(Number_helix+i)-x4(Number_helix+i-1),y4(Number_helix+i)-...
            y4(Number_helix+i-1));
    end
    for i=2:Number_postBend % adding the bending energy components
        UHelix=@(x3,y3,x4,y4) UHelix(x3,y3,x4,y4)+...
           UHelixBend(x4(Number_helix+i-1)-x4(Number_helix+i-2),y4(Number_helix+i-1)-...
           y4(Number_helix+i-2),x4(Number_helix+i)-x4(Number_helix+i-1),y4(Number_helix+i)-y4(Number_helix+i-1));
    end
end


% -------------------- Summarizing all of the energies --------------------

U=@(x1,y1,x2,y2,x3,y3,x4,y4) UBond(x1+Diameter_domain/2,y1,Depth_well_minus*4.114)+...
    UBond(x2-Diameter_domain/2,y2,Depth_well_plus*4.114)+...
    UBond(x1/2+x2/2,y1/2+y2/2,Depth_well_center*4.114)+...
    UStrain(StrainStiff_diameter,Diameter_domain,x2-x1,y2-y1)+...
    UDomainBend(x2-x1,y2-y1,x3-x1/2-x2/2,y3-y1/2-y2/2)+...
    UStrain(StrainStiff_length,Length_domain,x3-x1/2-x2/2,y3-y1/2-y2/2)+...
    UJoint(x3-x1/2-x2/2,y3-y1/2-y2/2,x4(1)-x3,y4(1)-y3)+...
    UHelix(x3,y3,x4,y4)-Force*x4(Number_helix+Number_postBend)+...
    UMT(y1)+UMT(y2)+UMT(y1/2+y2/2)+UMT(y3)+UMT(y4(Number_helix+Number_postBend));
% The UBond functions have a 4.114 multiplier to translate kT into pN*nm.



%============== CALCULATING GRADIENTS OF THE ENERGY FUNCTION ==============
% The gradients are turned into matlab functions to increase the speed of
% calculations during the simulations.

% These gradients represent the beads interacting with the microtubuke and
% the bead at the hinge:
G1f=matlabFunction(gradient(U(x1,y1,x2,y2,x3,y3,x4,y4),[x1,y1]),'Vars',{x1,y1,x2,y2,x3,y3,x4,y4});
G2f=matlabFunction(gradient(U(x1,y1,x2,y2,x3,y3,x4,y4),[x2,y2]),'Vars',{x1,y1,x2,y2,x3,y3,x4,y4});
G3f=matlabFunction(gradient(U(x1,y1,x2,y2,x3,y3,x4,y4),[x3,y3]),'Vars',{x1,y1,x2,y2,x3,y3,x4,y4});

% Once again, the entire stalk has to be represented as a single vector
% because the number of beads in it can differ:
G4f=cell(1,Number_helix+Number_postBend);
for i=1:Number_helix+Number_postBend
    G4f{i}=matlabFunction(gradient(U(x1,y1,x2,y2,x3,y3,x4,y4),[x4(i),y4(i)]),'Vars',{x1,y1,x2,y2,x3,y3,x4,y4});
end

% Turning the angle fuctions defined during the parameter creation process
% into matlab functions:
AlphaAngle=matlabFunction(AlphaAngle);
Theta=matlabFunction(Theta);



% ============================ THE SIMULATIONS ============================

w=waitbar(0,'Simulation Initiated','Name',sprintf('Force = %d pN',Force)); % creating a waitbar


% ---------------- Start of the entire simulation process -----------------

n=1;
while n<=Iterations % starting the simulation cycle
% A while cycle is employed to accomodate for potential errors in
% calculations (see below).

waitbar((n-0.5)/Iterations,w,sprintf('Run %d out of %d',n,Iterations)); % updating the waitbar

Ndet=NSteps;   
% If the molecule does not detach, its detachment time will be left equal
% to the  simulation time. Other functions will recognize it as the
% molecule not detaching.


%--------------------- Creating a coordinates matrix ----------------------
% Creating a matrix that will later contain the coordinates of all of the
% beads at all time points. Its name is Experiment.
% First, a matrix of the desired size is created filled with zeros;
% Then, the  initial coordinates of each bead are set in such a way that 
%     the potential energy of the molecule is minimal;
% Finally, a stochastic component is added to the coordinates of all of the
% beads

Experiment=zeros(2,Number_helix+Number_postBend+4,NSteps+1);

% Experiment(:,1:2,:) contains the coordiantes of the two outer beads
% interacting with the microtubule:
Experiment(1,1:2,1)=[-Diameter_domain/2 Diameter_domain/2];

% Experiment(:,3,:) contains the coordiantes of the bead connecting the
% head and the stalk of the molecule:
Experiment(:,3,1)=[0;Length_domain];
Experiment(:,1:3,1)=Experiment(:,1:3,1)+[Coefficients(2,1:3);Coefficients(2,1:3)].*randn(2,3);

% Experiment(:,4:3+Number_helix+Number_postBend,:) contains the coordiantes of
% all of the beads of the stalk:
for i=1:Number_helix
    Experiment(:,3+i,1)=[Experiment(1,2+i,1)+Length_segment*sin(Angle0_joint);Experiment(2,2+i,1)+...
        Length_segment*cos(Angle0_joint)]+[Coefficients(2,4);Coefficients(2,4)].*randn(2,1);
end
for i=1:Number_postBend
    Experiment(:,3+Number_helix+i,1)=[Experiment(1,2+Number_helix+i,1)+Length_SpB*sin(Angle0_joint+...
        Angle0_Bend);Experiment(2,2+Number_helix+i,1)+Length_SpB*cos(Angle0_joint+Angle0_Bend)]+...
        [Coefficients(2,4);Coefficients(2,4)].*randn(2,1);
end

% Experiment(:,4+Number_helix+Number_postBend) contains the coordiantes of
% the middle bead interacting with the microtubule (this is the only bead
% whose coordiantes are fully determined by the coordiantes of the adjacent
% beads):
Experiment(:,Number_helix+Number_postBend+4,1)=Experiment(:,1,1)/2+Experiment(:,2,1)/2;


%-------------------- Creating the other data matrices --------------------

% AngleTable is a matrix that will later contain the values of the most 
% important intramolecular angles at all time points.
% The angles are calculated with the functions AlphaAngle and Theta 
% described previously.
AngleTable=zeros(4,NSteps+1);

% AngleTable(2,:) describes the angle between the molecule and the surface
% of the microtubule: 
AngleTable(2,1)=Theta(1,0,Experiment(1,2,1)-Experiment(1,1,1),Experiment(2,2,1)-Experiment(2,1,1));
% (when the potential energy of the system is lowest it equals 0)

% AngleTable(3,:) describes the angle between the normal to the ternary 
% interacting with the microtubule and the section connecting them to the
% stalk: 
AngleTable(3,1)=AlphaAngle(Experiment(1,2,1)-Experiment(1,1,1),Experiment(2,2,1)-Experiment(2,1,1),...
    Experiment(1,3,1)-Experiment(1,Number_helix+Number_postBend+4,1),Experiment(2,3,1)-...
    Experiment(2,Number_helix+Number_postBend+4,1));
% (when the potential energy of the system is lowest it equals 0)

% AngleTable(4,:) describes the angle between the section connecting the
% ternary to the stalk and the line connecting the first and the last beads
% of the of the stalk:
AngleTable(4,1)=Theta(Experiment(1,3,1)-Experiment(1,Number_helix+Number_postBend+4,1),Experiment(2,3,1)-...
    Experiment(2,Number_helix+Number_postBend+4,1),Experiment(1,Number_helix+3,1)-...
    Experiment(1,3,1),Experiment(2,Number_helix+3,1)-Experiment(2,3,1));
% (when the potential energy of the system is lowest it equals pi/4)

% Attachments is a matrix that will later contain the binary attachment
% states of the bead ternary at all time steps.
Attachments=zeros(4,NSteps+1);
Attachments(2:4,1)=[1;1;1];
% 1, the bead is considred attached; 0, the bead is considered detached.

% G is the matrix that will contain the values of all of the gradients at
% the current time step:
G=zeros(2,Number_helix+Number_postBend+3);


%------------------------- Start of a simulation --------------------------
i=1;
while i<=NSteps
    
    % calculating the gradient values:
    G(:,1)=G1f(Experiment(1,1,i),Experiment(2,1,i),Experiment(1,2,i),Experiment(2,2,i),...
        Experiment(1,3,i),Experiment(2,3,i),Experiment(1,4:Number_helix+Number_postBend+...
        3,i),Experiment(2,4:Number_helix+Number_postBend+3,i));
    G(:,2)=G2f(Experiment(1,1,i),Experiment(2,1,i),Experiment(1,2,i),Experiment(2,2,i),...
        Experiment(1,3,i),Experiment(2,3,i),Experiment(1,4:Number_helix+Number_postBend+...
        3,i),Experiment(2,4:Number_helix+Number_postBend+3,i));
    G(:,3)=G3f(Experiment(1,1,i),Experiment(2,1,i),Experiment(1,2,i),Experiment(2,2,i),...
        Experiment(1,3,i),Experiment(2,3,i),Experiment(1,4:Number_helix+Number_postBend+...
        3,i),Experiment(2,4:Number_helix+Number_postBend+3,i));
    for k=1:Number_helix+Number_postBend
        G(:,k+3)=G4f{k}(Experiment(1,1,i),Experiment(2,1,i),Experiment(1,2,i),Experiment(2,2,i),...
            Experiment(1,3,i),Experiment(2,3,i),Experiment(1,4:Number_helix+Number_postBend+...
            3,i),Experiment(2,4:Number_helix+Number_postBend+3,i));
    end

    % Updating the bead positions according to Brownian dynamics (the
    % Brownian function is defined below):
    for j=1:3
        Experiment(:,j,i+1)=Experiment(:,j,i)+Brownian(Coefficients(1,j),G(:,j),Coefficients(2,j));
    end
    for j=4:Number_helix+Number_postBend+3
        Experiment(:,j,i+1)=Experiment(:,j,i)+Brownian(Coefficients(1,4),G(:,j),Coefficients(2,4));
    end
    Experiment(:,Number_helix+Number_postBend+4,i+1)=Experiment(:,1,i+1)/2+Experiment(:,2,i+1)/2;

    % Because of the complexity of the functions and the vast number of 
    % steps on rare occasions an error will occur and a coordinate of one 
    % of the beads will become a NaN. This error cannot be fixed and would
    % eventually affect the entire simulation. 
    % Because of that, a failsafe measure has been employed. If any 
    % coordinate becomes a NaN at any timestep, the entire simulation will 
    % be shut down and started over. Such occurences are very rare and
    % weakly affect the simulation flow. 
    if anynan(Experiment(:,:,i+1))==1
        i=i+1; % the variable i must be increased by one to conform to the values of a cycle that runs without mistakes
        break
    end

    % Calculating the angles and storing them in the AngleTable:
    AngleTable(1,i+1)=i*TimeStep;
    AngleTable(2,i+1)=Theta(1,0,Experiment(1,2,i+1)-Experiment(1,1,i+1),Experiment(2,2,i+1)-Experiment(2,1,i+1));
    AngleTable(3,i+1)=AlphaAngle(Experiment(1,2,i+1)-Experiment(1,1,i+1),Experiment(2,2,i+1)-Experiment(2,1,i+1),...
        Experiment(1,3,i+1)-Experiment(1,Number_helix+Number_postBend+4,i+1),Experiment(2,3,i+1)-...
        Experiment(2,Number_helix+Number_postBend+4,i+1));
    AngleTable(4,i+1)=Theta(Experiment(1,3,i+1)-Experiment(1,Number_helix+Number_postBend+4,i+1),Experiment(2,3,i+1)-...
        Experiment(2,Number_helix+Number_postBend+4,i+1),Experiment(1,Number_helix+3,i+1)-...
        Experiment(1,3,i+1),Experiment(2,Number_helix+3,i+1)-Experiment(2,3,i+1));

    % Checking attachments and storing them in the Attachments matrix (the
    % Attached function is defined below):
    Attachments(1,i+1)=i*TimeStep;
    Attachments(2,i+1)=Attached([-Diameter_domain/2;0],Experiment(:,1,i+1),Radius_det);
    Attachments(3,i+1)=Attached([0;0],Experiment(:,Number_helix+Number_postBend+4,i+1),Radius_det);
    Attachments(4,i+1)=Attached([Diameter_domain/2;0],Experiment(:,2,i+1),Radius_det);

    % Sometimes, during early simulations, all of the beads of the ternary
    % would move significantly far from their attachment sites (the
    % distance between each bead and its site would become 2 or even 3
    % times the radius of the well) but the molecule would not truly
    % detach. Insted of drifting away from the microtubule it would move
    % back to its original position. In experiment, such an episode 
    % would not be registered as a detachment. Therefore, the detachment
    % times cannot be solely determined by the distance between the beads 
    % and their sites.
    % Instead, a two-step process of detachment registration has been
    % employed. If the entire bead ternary moves far from their sites (the
    % threshold distance is set as a parameter), this occurence gets saved
    % as a potential detachment event. If afterwards the molecule drifts
    % back to the microtubule, this potential detachment event is
    % discarded. If, however, the molecule keeps moving away from its
    % initial position until there is a vast distance between it and the
    % sites, the potential detachment event is considered the actual
    % detachment.
    % This way, we can ensure the molecule has actually detached but not
    % include the potentially long drifting time into the detachment time. 

    if Attachments(2,i+1)==0 && Attachments(3,i+1)==0 && Attachments(4,i+1)==0 
    % checking if the ternary is far from their sites
        if Ndet==NSteps % checking if the potential detachment event has already been recorded
            Ndet=i; % saving the current timestep as the potential detachment time
        end
        if norm(Experiment(:,Number_helix+Number_postBend+4,i+1))>10*min([Width_well Radius_det])
        % checking if the molecule has drifted far from its initial position
            break % stopping the simulation
        end
    else
        Ndet=NSteps; % if the molecule moves back to the microtubule, the detachment event has to be erased
    end

    i=i+1;
end

%------------------------- End of the simulation --------------------------


% checking if there was a NaN in the last performed timestep of the
% simulation. If so, discarding the data and starting the simulation over.
if anynan(Experiment(:,:,i))==1
    clear Experiment AngleTable Attachments Ndet
    continue

else
    % If no errors occured during the simulation, the data is saved to a
    % Matlab data file with the number of simulation in the name:
    TechN=[path,sprintf('Technical%d',n)];

    % Cropping all of the matrices so that only the meaningful data is
    % stored:
    Experiment=Experiment(:,:,1:i);
    AngleTable=AngleTable(:,1:i);
    Attachments=Attachments(:,1:i);

    % Saving the matrices and the detachment time to the file:
    save(TechN,"Experiment","AngleTable","Attachments","Ndet");

    clear Experiment AngleTable Attachments Ndet % clearing the matrices for future simulations

    n=n+1;

end

end

close(w); % closing the waitbar after all of the simulations have been performed 

% ----------------- End of the entire simulation process ------------------

end



%==================== DEFINING THE AUXILIARY FUNCTIONS ====================

% A function reflecting the equation of motion in Brownian dynamics 
function X = Brownian(kF,F,kR)
    X=-kF*F+kR*randn(2,1); % [nm/s]
end

% A function for checking if the bead is attached to its site
function A = Attached(X0,X1,R)
    if(norm(X1-X0)<=R)
        A=1;
    else
        A=0;
    end
end
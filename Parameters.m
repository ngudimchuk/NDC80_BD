%{
       THE PARAMETERS OF THE MODEL ARE DEFINED BY THIS FUNCTION

All of the model parameter values except for the external force value are
set by this function. Therefore, to change any of these values the code
below should be changed.
The defined parameters are saved to a Matlab data file typically named
Technical0.mat. This file is later used by other programs to retrieve the
needed values. Premade parameter files can also be called for by
NDC80.m to easily reproduce simulation conditions without changing
Parameters.m.

Besides defining parameters, this file is also used to create an array of
symbolic functions describing the molecule. These functions are also stored
in Technical0.mat for later use by Execute.m.
%}

function Parameters(path) % This function gets called either by NDC80.m or by SingleNDC80.m.
% path is the path to the directory in which all the data for the set of
% simulations is stored; 



%=============== DEFINING THE PARAMETERS OF THE SIMULATION ================

TimeStep=0.02; % Time step used in the simulations, [ns]. Is typically set to 0.02 ns.
MaxTime=70000; % Maximum in-model run time for one simulation, [ns]. 
% The value of 70000 ns is sufficient for most parameter sets.
Iterations=30; % Number of independent simulations. Is typically set to 30.

Temperature=310; % Temperature of the system, [K]. Is typically set to 310 K
Viscosity=4.793; % Dynamic viscosity of the medium, [mPa*s]. Is typically set to 4.793 mPa*s

% The following set of parameters describes the entire stalk of the
% molecule (if there is no bending point in the stalk) or the section of 
% the stalk between the CH-domain and the bending point.
Length_helix=5.9; % Length of the stalk, [nm]
% In molecular dynamics, the length of 5.9 nm was used;
% The length of the NDC80 bonsai stalk is approximately 13 nm;
% The distance from the CH-domain to the bending point of the stalk is
% about 15.5 nm in wild type NDC80.
Number_helix=3; % Number of beads in the stalk
% This parameter should be set in such a way that there is approximately 1
% bead each 2 nm.
% This means that for molecular dynamics, the parameter should equal 3;
% For NDC80 bonsai, if should be set to 7;
% For the full length NDC80, this parameter should equal 8 and a second
% part of the stalk should be created (see below).

% This set of parameters is used to describe the second part of the stalk,
% after the bending point. None of these parameters affect the simulations
% as long as Number_postBend is set to zero. 
Length_postBend=46.5; % Length of the second segment of the stalk, [nm]. In wild type NDC80, it is approximately 46.5 nm.
Number_postBend=0; % Number of beads in the second segment. 
% There should also be approximately 1 bead each 2 nm. For wild type NDC80, 
% Number_postBend should be set to 23.
% ! If Number_postBend is set to 0, no part of the stalk past the bending
% point will be created. Therefore, the "bending point" will actually be
% the last point of the molecule.
FlexStiff_Bend=300; % Flexural stiffness of the bending point, [pN*nm]. Is typically set to 300 pN*nm.
Angle0_Bend=pi/6; % Angle of deflection of the stalk after the bending point, [Rad]. Is typically set to pi/6.

FlexStiff_helix=2300; % Flexural stiffness of the structured parts of the stalk (a coiled coil helix), [pN*nm]
% Is typically set to 2300 pN*nm.
StrainStiff_pernm=1156; % Strain stiffness of 1 nm of the stalk, [pN]. Is typically set to 1156 pN.

FlexStiff_joint=600; % Flexural stiffness of the hinge between the CH-domain and the stalk of the molecule, [pN*nm]
% Is typically set to 600 pN*nm.
Angle0_joint=pi/4; % Deflection angle between the CH-domain and the stalk, [Rad]. Is typically set to pi/4.

Length_domain=1.8; % Distance between the hinge and the bead ternary interacting with the microtubule, [nm]
% Is typically set to 1.8 nm.
StrainStiff_length=580; % Strain stiffness for the said distance, [pN/nm]. Is typically set to 580 pN/nm.
Diameter_domain=2.3; % Distance between the outer beads of the ternary, [nm]. Is typically set to 2.3 nm.
StrainStiff_diameter=500; % Strain stiffness between the outer beads of the ternary, [pN/nm]
% Is typically set to 500 pN/nm.
FlexStiff_domain=2300; 
% Flexural stiffness of the point at which the ternary interacting with the
% microtubule is attached to the rest of the molecule, [pN*nm].
% Is typically set to 2300 pN*nm. 

% Depths of the bead-microtubule bond energy wells. Are given in kT.
Depth_well_minus=5; % For the bead closest to the minus-end of the microtubule. Is typically set to 5 kT.
Depth_well_center=12; % For the central bead. Is typically set to 12 kT.
Depth_well_plus=5; % For the bead closest to the plus-end of the microtubule. Is typically set to 5 kT.

Width_well=0.8; % Width of each of the energy wells, [nm]
% Is typically set to 0.8 nm (an approximate Debye length in cytosol).
Radius_det=2*Width_well; % Distance at which a bead is considered detached from its site, [nm]
% Is typically set equal to a doubled radius of the well.
% Note that the entire molecule is not automatically considered detached
% when all of the beads have surpassed this threshold. See Execute.m for an
% explanation.

Repuls_MT=500; 
% A coefficient used to describe the repulsion any bead experiences after
% entering the surface of the microtubule, [pN/nm].
% Is typically set to 500 pN/nm.



%=================== CALCULATING ADDITIONAL PARAMETERS ====================

NSteps=round(MaxTime/TimeStep); % calculating the maximum number of steps

Length_segment=Length_helix/Number_helix; % calculating the diameter of each bead of the stalk
StrainStiff_segment=StrainStiff_pernm/Length_segment; % calculating the strain stiffness between the beads of the stalk

if Number_postBend>0 % calculating similar parameters for the segment of the stalk past the bending point
    Length_SpB=Length_postBend/Number_postBend; % diameter of the beads
    StrainStiff_SpB=StrainStiff_pernm/Length_SpB; % strain stiffness between the beads
end

% Coefficients is a matrix containing all the values of the coefficients
% appearing in the equation of motion for all of the beads in the molecule.
% The FCoeff and RCoeff functions are defined below.
Coefficients=zeros(2,4); % creating a matrix of the desired size
Coefficients(:,1)=[FCoeff(Viscosity,Diameter_domain/2,TimeStep);RCoeff(Temperature,Viscosity,Diameter_domain/2,TimeStep)];
Coefficients(:,2)=Coefficients(:,1); 
% Coefficients(:,1:2) describe the two outer beads of the ternary interacting with the microtubule.
Coefficients(:,3)=[FCoeff(Viscosity,Length_segment/2,TimeStep);RCoeff(Temperature,Viscosity,Length_segment/2,TimeStep)];
% Coefficients(:,3) describe the bead connecting the ternary to the stalk.
Coefficients(:,4)=[FCoeff(Viscosity,Length_segment/2,TimeStep);RCoeff(Temperature,Viscosity,Length_segment/2,TimeStep)];
% Coefficients(:,4) describe all the beads of the stalk.



%=============== CREATING SYMBOLIC FUNCTIONS FOR FUTURE USE ===============

syms CosTheta(x12,y12,x23,y23) % This function calculates the cosine of an angle between two vectors.
CosTheta(x12,y12,x23,y23)=(x12*x23+y12*y23)/(x12^2+y12^2)^{1/2}/(x23^2+y23^2)^{1/2};
syms SignTheta(x12,y12,x23,y23) % This function calculates the sign of an angle between two vectors.
SignTheta(x12,y12,x23,y23)=sign(y12*x23-y23*x12);
syms Theta(x12,y12,x23,y23) % This function calculates the angle between two vectors.
Theta(x12,y12,x23,y23)=SignTheta(x12,y12,x23,y23)*acos(CosTheta(x12,y12,x23,y23));

syms UBend(stiff,x12,y12,x23,y23,theta0)
% This function calculates the bending energy of a three point system. The
% dependence is quadratic.
UBend(stiff,x12,y12,x23,y23,theta0)=stiff*(Theta(x12,y12,x23,y23)-theta0)^2/2;
syms UJoint(x12,y12,x23,y23)
% This function calculates the bending energy of the point connecting the
% head and the stalk of the molecule.
UJoint(x12,y12,x23,y23)=UBend(FlexStiff_joint,x12,y12,x23,y23,Angle0_joint);
syms UHelixBend(x12,y12,x23,y23)
% This function calculates the bending energy of any point of the stalk.
UHelixBend(x12,y12,x23,y23)=UBend(FlexStiff_helix,x12,y12,x23,y23,0);

syms UBond(x12,y12,U)
% This function calculates the energy of a bead in a Gaussian energy well.
UBond(x12,y12,U)=-U*exp(-(x12^2+y12^2)/2/Width_well^2);

syms UMT(y)
% This function calculates the energy of a bead that has gone below the
% surface of the microtubule. It represents the rigidity of the
% microtubule's surface. The dependence is quadratic:
UMT(y)=(1-sign(y))*y^2*Repuls_MT;

syms CosAlpha(x12,y12,x23,y23)
% This function calculates the cosine of an angle between a vector and a
% normal to another vector.
CosAlpha(x12,y12,x23,y23)=(x12*y23-y12*x23)/(x12^2+y12^2)^{1/2}/(x23^2+y23^2)^{1/2};
syms SignAlpha(x12,y12,x23,y23)
% This function calculates the sign of an angle between a vector and a
% normal to another vector.
SignAlpha(x12,y12,x23,y23)=sign(x12*x23+y23*y12);
syms AlphaAngle(x12,y12,x23,y23)
% This function calculates the angle between a vector and a normal to 
% another vector.
AlphaAngle(x12,y12,x23,y23)=SignAlpha(x12,y12,x23,y23)*acos(CosAlpha(x12,y12,x23,y23));
syms UDomainBend(x12,y12,x03,y03)
% This function calculates the bending energy of the point connecting the
% bead ternary interacting with the MT and the segment connecting it to the
% stalk.
UDomainBend(x12,y12,x03,y03)=FlexStiff_domain*(AlphaAngle(x12,y12,x03,y03))^2/2;

syms UStrain(Kstrain,L0,x12,y12)
% This function calculates the strain energy of a two point system. The
% dependence is quadratic.
UStrain(Kstrain,L0,x12,y12)=Kstrain*((x12^2+y12^2)^{1/2}-L0)^2/2;



%======== CREATING A FILE CONTAINING ALL OF THE MODEL'S PARAMETERS ========

% All of the parameters are stored in a Matlab data file (it is usually
% called Technical0.mat). This file is later used by the other matlab
% programs to extract the values of needed parameters.

% If there is a need to reproduce the conditions of any simulation, it can
% be easily done by referring to the corresponding parameter file while
% running NDC80.m.

Tech0=[path,'Technical0'];
save(Tech0,'-regexp', '^(?!path$).',"-append") % saving all of the parameters except for the directory to the parameter file.

end



%==================== DEFINING THE AUXILIARY FUNCTIONS ====================

% A function used to calculate the coefficients for the deterministic
% member of the Brownian equation of motion:
function kF = FCoeff(u,L,dt)
    kF=dt/6/pi/u/L; % nm/pN
end

% A function used to calculate the coefficients for the stochastic
% member of the Brownian equation of motion:
function kR = RCoeff(T,u,L,dt)
    kR=1.21*sqrt(dt*T/u/L/1000); % nm
end

% =========================================================================
% Script: Conformal Bending Geometry and 3D Mesh Transformation
% Description: Attempts to evaluate the impedance detuning of the fractal 
%              CPW antenna when conformally deformed around a cylindrical 
%              radius (R = 30 mm), simulating a human arm. 
%              NOTE: This script demonstrates the mathematical geometry 
%              transformation but exposes the fundamental limitations of 
%              the 2.5D MoM solver for volumetric (Z-varying) calculations.
%
% Dependencies:
%   - Environment: MATLAB 25.2.0.3123386 (R2025b) Update 3 or later
%   - Toolboxes: Antenna Toolbox
% =========================================================================

% --- 1. Radiating Element: 48-Point Fractal Geometry Definition ---
% Initialize the coordinate matrix for the continuous serpentine trace
origin = [-9 -60 0];
points = zeros(48,3);

% Define relative spatial transformations for the fractal trace
points(1, :) = origin;
points(2, :) = points(1, :) + [0 36 0];
points(3, :) = points(2, :) + [6 0 0];
points(4, :) = points(3, :) + [0 24 0];
points(5, :) = points(4, :) + [-6 0 0];
points(6, :) = points(5, :) + [0 6 0];
points(7, :) = points(6, :) + [-4 0 0];
points(8, :) = points(7, :) + [0 -6 0];
points(9, :) = points(8, :) + [-18 0 0];
points(10, :) = points(9, :) + [0 32 0];
points(11, :) = points(10, :) + [18 0 0];
points(12, :) = points(11, :) + [0 -7 0];
points(13, :) = points(12, :) + [5 0 0];
points(14, :) = points(13, :) + [0 7 0];
points(15, :) = points(14, :) + [4 0 0];
points(16, :) = points(15, :) + [0 -11 0];
points(17, :) = points(16, :) + [-14 0 0];
points(18, :) = points(17, :) + [0 6 0];
points(19, :) = points(18, :) + [-8 0 0];
points(20, :) = points(19, :) + [0 -23 0];
points(21, :) = points(20, :) + [9 0 0];
points(22, :) = points(21, :) + [0 6 0];
points(23, :) = points(22, :) + [12 0 0];
points(24, :) = points(23, :) + [0 -6 0];
points(25, :) = points(24, :) + [8 0 0];
points(26, :) = points(25, :) + [0 6 0];
points(27, :) = points(26, :) + [12 0 0];
points(28, :) = points(27, :) + [0 -6 0];
points(29, :) = points(28, :) + [9 0 0];
points(30, :) = points(29, :) + [0 23 0];
points(31, :) = points(30, :) + [-8 0 0];
points(32, :) = points(31, :) + [0 -6 0];
points(33, :) = points(32, :) + [-14 0 0];
points(34, :) = points(33, :) + [0 11 0];
points(35, :) = points(34, :) + [4 0 0];
points(36, :) = points(35, :) + [0 -7 0];
points(37, :) = points(36, :) + [5 0 0];
points(38, :) = points(37, :) + [0 7 0];
points(39, :) = points(38, :) + [18 0 0];
points(40, :) = points(39, :) + [0 -32 0];
points(41, :) = points(40, :) + [-18 0 0];
points(42, :) = points(41, :) + [0 6 0];
points(43, :) = points(42, :) + [-4 0 0];
points(44, :) = points(43, :) + [0 -6 0];
points(45, :) = points(44, :) + [-6 0 0];
points(46, :) = points(45, :) + [0 -24 0];
points(47, :) = points(46, :) + [6 0 0];
points(48, :) = points(47, :) + [0 -36 0];

% Resonance Compensation: Stretch Y-axis by 4% to target 2.5 GHz
points(:, 2) = (points(:, 2) - (-60)) * 1.04 + (-60);

% Normalize coordinate scaling to standard SI units (meters)
points = (points / 4) * 1e-3;

% --- 2. Planar Geometry Unification ---
% Construct individual components for a single-layer transformation
topLayer = antenna.Polygon('Vertices', points);
groundLeft  = antenna.Rectangle('Length', 11e-3, 'Width', 8e-3, 'Center', [-9.75e-3, -11e-3]);
groundRight = antenna.Rectangle('Length', 11e-3, 'Width', 8e-3, 'Center', [9.25e-3, -11e-3]);
groundBridge = antenna.Rectangle('Length', 10e-3, 'Width', 0.5e-3, 'Center', [-0.25e-3, -14.75e-3]);

% Boolean Addition: Merge trace and ground planes into a single unified 
% pure-metal planar shape to allow for holistic conformal meshing.
geom = topLayer + groundLeft + groundRight + groundBridge;

% --- 3. Pre-Deformation Mesh Discretization ---
% Due to object-oriented encapsulation, direct triangulation is bypassed 
% by generating the mesh graphically and extracting the raw patch data.
fig = figure('Visible', 'off'); 
mesh(geom, 'MaxEdgeLength', 1.0e-3);

% Extract the planar coordinate vertices (p) and triangle connectivity (t)
patchObj = findobj(fig, 'Type', 'Patch');
p = patchObj(1).Vertices'; 
t = patchObj(1).Faces';
close(fig);

% --- 4. Cylindrical Coordinate Transformation ---
% Target conformal bending radius (30 mm = approximate human arm)
R = 30e-3;
p_bent = zeros(size(p));

% Map 2D Cartesian coordinates to a 3D cylindrical shell
p_bent(1,:) = R * sin(p(1,:) / R);       % X wraps azimuthally around the cylinder
p_bent(2,:) = p(2,:);                    % Y remains completely longitudinal (vertical)
p_bent(3,:) = R * cos(p(1,:) / R) - R;   % Z arcs perpendicularly into 3D space

% --- 5. 3D Conformal Mesh Reconstruction ---
% Reassemble the discrete elements into a custom 3D mesh object
bentAnt = customAntennaMesh(p_bent, t);

% Translate the discrete planar feed coordinates into the new 3D domain
feedX_flat = -0.25e-3;
feedX_bent = R * sin(feedX_flat / R);
feedZ_bent = R * cos(feedX_flat / R) - R;

% Define the localized gap port across the conformally bent micro-bridge
pt1_bent = [feedX_bent, -14.5e-3, feedZ_bent];
pt2_bent = [feedX_bent, -14.75e-3, feedZ_bent];
bentAnt = createFeed(bentAnt, pt1_bent, pt2_bent);

% Visualize the successfully deformed 3D geometry
figure;
show(bentAnt);
title('Conformally Bent Fractal CPW Geometry (R = 30 mm)');

% --- 6. Electromagnetic Evaluation & Solver Limitations ---
% Define smart sweep frequency range (2.0 GHz to 3.0 GHz)
freqRange = linspace(2.0e9, 3.0e9, 40);

% IMPORTANT NOTE: The following calls will trigger a solver fault. 
% The MATLAB Antenna Toolbox utilizes a 2.5D Method of Moments (MoM) solver. 
% This numerical method intrinsically requires basis functions to remain 
% strictly within the X-Y plane (Z-coordinate cannot vary). 
% Evaluating this 3D transformed mesh requires transitioning to a 
% full 3D Finite Element Method (FEM) solver, such as Ansys HFSS.

% S = sparameters(bentAnt, freqRange);
% figure;
% rfplot(S);
% title('Simulated S11 (Bent Antenna, Free Space)');

% figure;
% pattern(bentAnt, 2.5e9);
% title('3D Radiation Pattern at 2.5 GHz (Bent)');
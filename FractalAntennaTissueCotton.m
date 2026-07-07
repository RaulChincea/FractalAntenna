% =========================================================================
% Script: Flexible Fractal CPW Antenna Simulation (Textile Isolation Gap)
% Description: Evaluates the impedance recovery and radiation performance 
%              of the CPW antenna when decoupled from the tissue phantom 
%              using a low-permittivity textile (cotton) layer. 
%              Incorporates micro-bridge capacitive retuning and 
%              meander-line inductive scaling to restore 50-ohm resonance.
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

% Inductance Tuning: Compress the Y-axis by a factor of 0.8. 
% By physically shortening the longitudinal meander lines, the series 
% inductance (L) is reduced, shifting the resonant frequency upward 
% (from ~2.05 GHz toward the 2.45 GHz ISM band) to compensate for the 
% added parallel capacitance of the widened micro-bridge.
points(:, 2) = (points(:, 2) - (-60)) * 0.8 + (-60);

% Normalize coordinate scaling to standard SI units (meters)
points = points / 4;
points = points * 1e-3;

% --- 2. Dielectric, Conductive, and Phantom Material Specifications ---
% Define flexible substrate characteristics
d = dielectric("Name", "Polyimide");
d.EpsilonR = 3.4; 
d.Thickness = 0.024e-3;
d.LossTangent = 0.005;

% Define radiating conductor characteristics
silverInk = metal('Silver');
silverInk.Thickness = 1e-6; 

% Define 3-Layer Biological Tissue Phantom
% Loss tangent constrained to 0.03 for 2.5D MoM numerical stability.
skin = dielectric("Name", "Skin");
skin.EpsilonR = 38.0; 
skin.Thickness = 2e-3; 
skin.LossTangent = 0.03; 

fat = dielectric("Name", "Fat");
fat.EpsilonR = 5.28; 
fat.Thickness = 5e-3; 
fat.LossTangent = 0.03; 

muscle = dielectric("Name", "Muscle");
muscle.EpsilonR = 52.7; 
muscle.Thickness = 10e-3; 
muscle.LossTangent = 0.03; 

% Define Textile Isolation Layer (Cotton)
% Acts as a low-permittivity near-field buffer to decouple the antenna 
% from the highly capacitive and lossy biological tissue.
cotton = dielectric("Name", "Cotton");
cotton.EpsilonR = 1.6; 
cotton.Thickness = 3e-3; 
cotton.LossTangent = 0.02;

% --- 3. Geometric Assembly: Dual-Layer CPW Approximation ---
% Define overall substrate footprint (36x36 mm)
boardShape = antenna.Rectangle('Length', 36e-3, 'Width', 36e-3);

% Construct top radiating layer
topLayer = antenna.Polygon('Vertices', points);

% Construct bottom ground layer (2.0 mm gap)
groundLeft  = antenna.Rectangle('Length', 11e-3, 'Width', 8e-3, 'Center', [-9.75e-3, -11e-3]);
groundRight = antenna.Rectangle('Length', 11e-3, 'Width', 8e-3, 'Center', [9.25e-3, -11e-3]);

% Capacitive Retuning Micro-Bridge:
% Width expanded from 0.5 mm to 1.5 mm. This triples the capacitive 
% surface area at the feed point, injecting parallel capacitance (C) 
% back into the circuit to recover the 50-ohm match lost due to the 
% 3 mm textile gap displacement.
groundBridge = antenna.Rectangle('Length', 10e-3, 'Width', 1.5e-3, 'Center', [-0.25e-3, -14.75e-3]);
bottomLayer = groundLeft + groundRight + groundBridge;

% --- 4. PCB Stackup Initialization ---
ant = pcbStack;
ant.Name = 'Fractal_CPW_On_Tissue_With_Cotton';
ant.BoardShape = boardShape;

% Total board thickness sum includes the substrate, textile, and biological layers
ant.BoardThickness = d.Thickness + cotton.Thickness + skin.Thickness + fat.Thickness + muscle.Thickness; 

% Assemble the planar volumetric stack (Top to Bottom)
ant.Layers = {topLayer, d, bottomLayer, cotton, skin, fat, muscle}; 
ant.Conductor = silverInk;

% --- 5. Excitation Port and Mesh Configuration ---
% Assign a localized via port bridging the top feedline and bottom micro-bridge
ant.FeedLocations = [-0.25e-3, -14.75e-3, 1, 3];
ant.FeedDiameter = 0.25e-3;

% Visualize the constructed dual-layer geometry
figure;
show(ant);
title('Fractal CPW Geometry (Cotton Isolated)');

% Memory Management: Force maximum edge length to prevent O(N^3) RAM exhaustion
mesh(ant, 'MaxEdgeLength', 2.5e-3);

% --- 6. Electromagnetic (MoM) Simulation and Post-Processing ---
% Define wideband evaluation range to capture the retuned resonance point
freqRange = linspace(2.0e9, 3.5e9, 31);

% Compute Scattering Parameters
S = sparameters(ant, freqRange);

% Evaluate and plot Return Loss (S11)
figure;
rfplot(S);
title('Simulated Return Loss (S11) with 3mm Cotton Isolation');

% Evaluate impedance matching on the Smith Chart
figure;
smithplot(S);
title('Impedance Matching (Smith Chart)');

% Compute and visualize near-field surface current distribution
figure;
current(ant, 2.45e9);
title('Surface Current Distribution at 2.45 GHz');

% Plot complex impedance components (Resistance and Reactance)
figure;
impedance(ant, freqRange);
title('Antenna Impedance Profile');

% Plot the 3D Radiation Pattern at the target frequency
targetFreq = 2.45e9; 
figure;
pattern(ant, targetFreq);
title(['3D Radiation Pattern at ', num2str(targetFreq/1e9), ' GHz']);
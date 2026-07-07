% =========================================================================
% Script: Flexible Fractal CPW Antenna Simulation (Baseline Free Space)
% Description: Evaluates the impedance and radiation characteristics of a 
%              single-layer fractal/serpentine coplanar waveguide (CPW) 
%              antenna approximated as a dual-layer structure for MoM 
%              solver stability. Target center frequency: 2.5 GHz.
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

% Normalize coordinate scaling to standard SI units (meters)
points = points / 4;
points = points * 1e-3;

% --- 2. Dielectric and Conductive Material Specifications ---
% Define flexible substrate characteristics
d = dielectric("Name", "Polyimide");
d.EpsilonR = 3.4; 
d.Thickness = 0.024e-3;
d.LossTangent = 0.005;

% Define radiating conductor characteristics (simulating printed fabrication)
silverInk = metal('Silver');
silverInk.Thickness = 1e-6; 

% --- 3. Geometric Assembly: Dual-Layer CPW Approximation ---
% Define overall substrate footprint (36x36 mm)
boardShape = antenna.Rectangle('Length', 36e-3, 'Width', 36e-3);

% Construct top radiating layer
topLayer = antenna.Polygon('Vertices', points);

% Construct bottom ground layer
% Left and right coplanar ground planes offset to maintain a 2.0 mm gap
groundLeft  = antenna.Rectangle('Length', 11e-3, 'Width', 8e-3, 'Center', [-9.75e-3, -11e-3]);
groundRight = antenna.Rectangle('Length', 11e-3, 'Width', 8e-3, 'Center', [9.25e-3, -11e-3]);

% Define impedance-tuning micro-bridge. Width restricted to 0.5 mm to 
% minimize parallel parasitic capacitance and maintain 50-ohm match.
groundBridge = antenna.Rectangle('Length', 10e-3, 'Width', 0.5e-3, 'Center', [-0.25e-3, -14.75e-3]);

% Execute boolean addition for bottom layer
bottomLayer = groundLeft + groundRight + groundBridge;

% --- 4. PCB Stackup Initialization ---
ant = pcbStack;
ant.Name = 'Fractal_CPW_DualLayer';
ant.BoardShape = boardShape;
ant.BoardThickness = d.Thickness; 
ant.Layers = {topLayer, d, bottomLayer}; 
ant.Conductor = silverInk;

% --- 5. Excitation Port Configuration ---
% Assign a localized via port bridging the top feedline and bottom micro-bridge
ant.FeedLocations = [-0.25e-3, -14.75e-3, 1, 3];
% Restricted feed diameter to prevent edge-collision errors in the meshing algorithm
ant.FeedDiameter = 0.25e-3;

% Visualize the constructed dual-layer geometry
figure;
show(ant);
title('Fractal CPW Geometry (Dual-Layer Approximation)');

% --- 6. Electromagnetic (MoM) Simulation and Post-Processing ---
% Define wideband evaluation range (1.5 GHz to 3.5 GHz)
freqRange = linspace(1.5e9, 3.5e9, 41);

% Compute Scattering Parameters
S = sparameters(ant, freqRange);

% Evaluate and plot Return Loss (S11)
figure;
rfplot(S);
title('Simulated Return Loss (S11) in Free Space');

% Evaluate impedance matching on the Smith Chart
figure;
smithplot(S);
title('Impedance Matching (Smith Chart)');

% Compute and visualize near-field surface current distribution at target resonance
figure;
current(ant, 2.45e9);
title('Surface Current Distribution at 2.45 GHz');

% Plot complex impedance components (Resistance and Reactance)
figure;
impedance(ant, freqRange);
title('Antenna Impedance Profile');
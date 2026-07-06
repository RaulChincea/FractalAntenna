% --- 48-Point Fractal Geometry ---
origin = [-9 -60 0];
points = zeros(48,3);

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

% Scale to meters
points = points / 4;
points = points * 1e-3;

% --- 1. Materials ---
d = dielectric("Name", "Polyimide");
d.EpsilonR = 3.4; 
d.Thickness = 0.024e-3;
d.LossTangent = 0.005;

silverInk = metal('Silver');
silverInk.Thickness = 1e-6; 

% --- 2. Build the Dual-Layer Geometry ---
% EXPANDED BOARD: 32x32 mm 
boardShape = antenna.Rectangle('Length', 36e-3, 'Width', 36e-3);

% Top Layer: Your custom 48-point polygon
topLayer = antenna.Polygon('Vertices', points);

% 1. The Mathematically Perfect Ground Plates (2.0 mm gaps)
groundLeft  = antenna.Rectangle('Length', 11e-3, 'Width', 8e-3, 'Center', [-9.75e-3, -11e-3]);
groundRight = antenna.Rectangle('Length', 11e-3, 'Width', 8e-3, 'Center', [9.25e-3, -11e-3]);

% 2. The Micro-Bridge (Starving the parasitic capacitor!)
% Shrunk the width from 2.0 mm down to 0.5 mm, and moved it to the very bottom edge.
groundBridge = antenna.Rectangle('Length', 10e-3, 'Width', 0.5e-3, 'Center', [-0.25e-3, -14.75e-3]);

bottomLayer = groundLeft + groundRight + groundBridge;

% --- 3. Assemble PCB Stack ---
ant = pcbStack;
ant.Name = 'Fractal_CPW_DualLayer';
ant.BoardShape = boardShape;
ant.BoardThickness = d.Thickness; 
ant.Layers = {topLayer, d, bottomLayer}; 
ant.Conductor = silverInk;

% --- 4. The Flawless Via Port ---
% Placed at the exact mathematical center of your 48-point feedline!
ant.FeedLocations = [-0.25e-3, -14.75e-3, 1, 3];
ant.FeedDiameter = 0.5e-3;

% View Geometry
figure;
show(ant);
title('Fractal CPW Geometry (Dual-Layer)');

% --- Phase 2: Electromagnetic Simulation ---
freqRange = linspace(1.5e9, 3.5e9, 41);

% 1. Calculate S-Parameters
S = sparameters(ant, freqRange);

% 2. Plot S11 in standard negative dB format
figure;
rfplot(S);
title('Simulated S11 (Fractal Antenna)');

% 3. View the Smith Chart
figure;
smithplot(S);
title('Smith Chart');

% 4. Surface Current Distribution
figure;
current(ant, 2.45e9);
title('Surface Current Distribution at 2.45 GHz');

figure;
impedance(ant, freqRange)

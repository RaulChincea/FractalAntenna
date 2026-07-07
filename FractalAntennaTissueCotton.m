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

% 1. Stretch ONLY the Y-axis by 4% to lower the frequency to 2.5 GHz
% We anchor the stretch at the bottom edge (Y = -60) so the feedline doesn't move!
points(:, 2) = (points(:, 2) - (-60)) * 1.04 + (-60);

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

% --- Biological Tissue Phantom (at 2.45 GHz) ---
% 1. Skin Layer
skin = dielectric("Name", "Skin");
skin.EpsilonR = 38.0; 
skin.Thickness = 2e-3; 
skin.LossTangent = 0.03; % Capped at MATLAB's maximum

% 2. Fat Layer
fat = dielectric("Name", "Fat");
fat.EpsilonR = 5.28; 
fat.Thickness = 5e-3; 
fat.LossTangent = 0.03; % Capped at MATLAB's maximum

% 3. Muscle Layer
muscle = dielectric("Name", "Muscle");
muscle.EpsilonR = 52.7; 
muscle.Thickness = 10e-3; 
muscle.LossTangent = 0.03; % Capped at MATLAB's maximum

% --- Clothing Isolation Layer ---
cotton = dielectric("Name", "Cotton");
cotton.EpsilonR = 1.6; 
cotton.Thickness = 3e-3; % 1 mm thickness 
cotton.LossTangent = 0.02;

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
groundBridge = antenna.Rectangle('Length', 10e-3, 'Width', 1.5e-3, 'Center', [-0.25e-3, -14.75e-3]);

bottomLayer = groundLeft + groundRight + groundBridge;

% --- 3. Assemble PCB Stack ---
ant = pcbStack;
ant.Name = 'Fractal_CPW_On_Tissue_With_Cotton';
ant.BoardShape = boardShape;
% Add cotton to the total thickness calculation!
ant.BoardThickness = d.Thickness + cotton.Thickness + skin.Thickness + fat.Thickness + muscle.Thickness; 

% Stack: Top Metal -> Polyimide -> Bottom Metal -> Cotton -> Skin -> Fat -> Muscle
ant.Layers = {topLayer, d, bottomLayer, cotton, skin, fat, muscle}; 
ant.Conductor = silverInk;

% --- 4. The Flawless Via Port ---
% Placed at the exact mathematical center of your 48-point feedline!
ant.FeedLocations = [-0.25e-3, -14.75e-3, 1, 3];
ant.FeedDiameter = 0.25e-3;

% View Geometry
figure;
show(ant);
title('Fractal CPW Geometry (Dual-Layer)');

% Forces the MoM solver to use larger triangles, drastically reducing the N x N matrix size
mesh(ant, 'MaxEdgeLength', 2.5e-3);

% --- Phase 2: Electromagnetic Simulation ---
freqRange = linspace(2.0e9, 3.5e9, 31);

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

% Plot the 3D Radiation Pattern at the exact target frequency
targetFreq = 2.45e9; % Or update to 2.5e9 / 2.6e9 depending on your current center!
figure;
pattern(ant, targetFreq);
title(['3D Radiation Pattern at ', num2str(targetFreq/1e9), ' GHz']);

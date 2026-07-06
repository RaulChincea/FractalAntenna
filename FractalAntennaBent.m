% --- 1. Generate the 48-Point Fractal Geometry ---
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

% Stretch Y-axis by 4% to hit 2.5 GHz
points(:, 2) = (points(:, 2) - (-60)) * 1.04 + (-60);

% Scale down to mm, convert to meters
points = (points / 4) * 1e-3;

% --- 2. Construct the Single-Layer Flat Metal Geometry ---
topLayer = antenna.Polygon('Vertices', points);
groundLeft  = antenna.Rectangle('Length', 11e-3, 'Width', 8e-3, 'Center', [-9.75e-3, -11e-3]);
groundRight = antenna.Rectangle('Length', 11e-3, 'Width', 8e-3, 'Center', [9.25e-3, -11e-3]);
groundBridge = antenna.Rectangle('Length', 10e-3, 'Width', 0.5e-3, 'Center', [-0.25e-3, -14.75e-3]);

% Boolean Addition: Merge everything into one flat pure-metal shape
geom = topLayer + groundLeft + groundRight + groundBridge;

% --- 3. Extract the Mesh for Coordinate Warping ---
% Create an invisible figure so it doesn't flash on your screen
fig = figure('Visible', 'off'); 
mesh(geom, 'MaxEdgeLength', 1.0e-3);

% Forcefully search the entire figure hierarchy for the raw Patch graphics object
patchObj = findobj(fig, 'Type', 'Patch');

% Extract the coordinates and triangle IDs directly from the Patch, and transpose them
p = patchObj(1).Vertices'; 
t = patchObj(1).Faces';

% Clean up by closing the invisible figure
close(fig);

% --- 4. Mathematical Cylindrical Transformation (Radius = 30 mm) ---
R = 30e-3;
p_bent = zeros(size(p));

% p(1,:) = X, p(2,:) = Y, p(3,:) = Z
p_bent(1,:) = R * sin(p(1,:) / R);       % X wraps spherically around the cylinder
p_bent(2,:) = p(2,:);                    % Y remains completely vertical
p_bent(3,:) = R * cos(p(1,:) / R) - R;   % Z arcs backward into 3D space

% --- 5. Rebuild as a 3D Conformal Mesh Antenna ---
bentAnt = customAntennaMesh(p_bent, t);

% Calculate the transformed 3D feed coordinates
% Flat Feed Gap was across Y = -14.5 (trace) to Y = -14.75 (bridge) at X = -0.25
feedX_flat = -0.25e-3;
feedX_bent = R * sin(feedX_flat / R);
feedZ_bent = R * cos(feedX_flat / R) - R;

pt1_bent = [feedX_bent, -14.5e-3, feedZ_bent];
pt2_bent = [feedX_bent, -14.75e-3, feedZ_bent];

% Assign the gap port in 3D space
bentAnt = createFeed(bentAnt, pt1_bent, pt2_bent);

% View the beautiful curved geometry
figure;
show(bentAnt);
title('Conformally Bent Fractal CPW (R = 30 mm)');

% --- 6. Electromagnetic Simulation (40 Frequencies) ---
% Using the smart sweep to bypass flat tails
freqRange = linspace(2.0e9, 3.0e9, 40);

S = sparameters(bentAnt, freqRange);

figure;
rfplot(S);
title('Simulated S11 (Bent Antenna, Free Space)');

figure;
pattern(bentAnt, 2.5e9);
title('3D Radiation Pattern at 2.5 GHz (Bent)');
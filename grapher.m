clc, clearvars, clear all
inFile = "R20_sorted.csv";

newTable = readtable(inFile);

uniqueLoads = unique(newTable.NormalForce);
slipAngle = newTable.SlipAngle;
corneringForce = newTable.LateralForce;

order = 1;
cutoff = 0.05;
[b, a] = butter(order, cutoff, 'low');
corneringForceFilter = filtfilt(b, a, corneringForce);

figure('Color', [1 1 1]);
scatter(slipAngle, corneringForce, 1, 'b', 'filled');
hold on;
grid on;
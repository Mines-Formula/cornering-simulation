clc, clearvars, clear all
inFile = "R20_sorted.csv";

newTable = readtable(inFile);

slipAngle = newTable.SlipAngle;
corneringForce = newTable.LateralForce;
load = newTable.NormalForce;
weight = load / 9.81;

uniqueLoads = round(unique(weight)/100) * 100;

order = 4;
cutoff = 0.05;
[b, a] = butter(order, cutoff, 'low');

figure('Color', [1 1 1]);
scatter(slipAngle, corneringForce, 1, 'b', 'filled');
hold on
grid on;


%plot(slipAngle, corneringForceFilter, 'r-', 'LineWidth', 2);
%xlabel('Slip Angle [deg]');
%ylabel('Cornering Force [N]');
%title('Cornering Force vs Slip Angle (Filtered)');
%legend('Raw Data','Butterworth Filtered','Location','best');
%grid on

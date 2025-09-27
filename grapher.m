clc, clearvars, clear all
inFile = "R20_sorted.csv";

newTable = readtable(inFile);

Y = newTable.LateralForce;
X = newTable.SlipAngle;

figure;
plot(X, Y, 'b-', 'LineWidth', 0.1);
xlabel('Slip Angle (deg)'); 
ylabel('Cornering Force (kN)'); 
xlim(-10, 10);
ylim(-5, 5);
grid on;
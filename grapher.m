clc, clearvars, clear all
inFile = "R20_sorted.csv";

newTable = readtable(inFile);
slipAngle = newTable.SlipAngle;
corneringForce = newTable.LateralForce;
normalForce = newTable.NormalForce;

uniqueLoads = unique(newTable.NormalForce);


order = 2;
cutoff = 0.05;
[b, a] = butter(order, cutoff, 'low');

figure('Color', [1 1 1]);
hold on;
grid on;
colors = lines(length(uniqueLoads));

for i = 1:length(uniqueLoads)
    thisLoad = uniqueLoads(i);
    idx = (normalForce == thisLoad);
    sa = slipAngle(idx);
    cf = corneringForce(idx);
end
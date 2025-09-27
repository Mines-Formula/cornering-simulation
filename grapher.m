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
hold on;
colors = lines(length(uniqueLoads));

for i = 1:length(uniqueLoads)
    curLoad = uniqueLoads(i);
    idx = abs(weight - curLoad) < 10;

    sa = slipAngle(idx);
    cf = corneringForce(idx);

    coneringForceFilter = filtfilt(b, a, corneringForce);

    plot(sa, cf, 'LineWidth', 2, 'Color', colors(i,:));

end

xlabel('Slip Angle (deg)');
ylabel('Cornering Force (N)');
legend(cellstr(num2str(uniqueLoads', '%d kg')), 'Location', 'best');
grid on;
clc, clearvars, clear all
inFile = "R20_sorted.csv";

newTable = readtable(inFile);
slipAngle = newTable.SlipAngle;
corneringForce = newTable.LateralForce;
normalForce = newTable.NormalForce;

loadBins = round(normalForce / 50) * 50;
uniqueLoads = unique(loadBins);

order = 2;
cutoff = 0.05;
[b, a] = butter(order, cutoff, 'low');

colors = lines(length(uniqueLoads));

figure('Color', [1,1,1]);
hold on;
grid on;

for i = 1:length(uniqueLoads)
    thisLoad = uniqueLoads(i);
    idx = (loadBins == thisLoad);

    sa = slipAngle(idx);
    cf = corneringForce(idx);

    [saSorted, sortIdx] = sort(sa);
    cfSorted = cf(sortIdx);

    cfFilt = filtfilt(b, a, cfSorted);

    scatter(slipAngle(idx), corneringForce(idx), 1, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.4);
end

xlabel('Slip Angle (deg)');
ylabel('Cornering Force (N)');
title('Cornering Force vs Slip Angle');
legend(cellstr(num2str(uniqueLoads, '%d N')), 'Location', 'best');
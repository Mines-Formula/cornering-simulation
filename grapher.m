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

    if numel(sa) < 10
        continue;
    end

    cfFilt = filtfilt(b, a, cf);
    scatter(sa, cf, 5, colors(i,:), 'filled', 'MarkerFaceAlpha', 0.3);
    plot(sa, cfFilt, 'LineWidth', 2, 'Color', colors(i,:));
end

xlabel('Slip Angle [deg]');
ylabel('Cornering Force [N]');
title('Cornering Force vs Slip Angle by Load');
legendStrings = cellstr(num2str(uniqueLoads, '%d N'));
legend(legendStrings, 'Location', 'best')
clc, clearvars, clear all
inFile = "R20_sorted.csv";

withOriginalPlot = true;

newTable = readtable(inFile);
slipAngleRaw = newTable.SlipAngle;
corneringForceRaw = newTable.LateralForce;
normalForceRaw = newTable.NormalForce;

% bins by normal force to the nearest 50
loadBins = round(normalForceRaw / 50) * 50;
uniqueLoads = unique(loadBins);

% Butterworth
order = 2;
cutoff = 0.05;
[b, a] = butter(order, cutoff, 'low');

slipAngleBinWidth = 0.5;
minPointsperLoad = 30; 
minSlipAnglePoints = 5;

colors = lines(length(uniqueLoads));
figure('Color', [1,1,1]);
hold on;
grid on;

for i = 1:length(uniqueLoads)
    thisLoad = uniqueLoads(i);
    idx = (loadBins == thisLoad);
    curSlipAngle = slipAngleRaw(idx);
    curCorneringForce = corneringForceRaw(idx);

    if numel(curSlipAngle) < minPointsperLoad
        continue
    end

    valid = ~isnan(curSlipAngle) & ~isnan(curCorneringForce);
    curSlipAngle = curSlipAngle(valid);
    curCorneringForce = curCorneringForce(valid);

    medianCorneringForce = median(curCorneringForce, 'omitnan');
    madCorneringForce = median(abs(curCorneringForce - medianCorneringForce), 'omitnan');

    outlierMask = abs(curCorneringForce - medianCorneringForce) > 3 * max(madCorneringForce, 1e-6);
    curCorneringForce(outlierMask) = NaN;


    if abs(medianCorneringForce) > 50
        tooSmall = abs(curCorneringForce) < 0.02 * abs(medianCorneringForce);
        curCorneringForce(tooSmall) = NaN;
    end

    valid = ~isnan(curCorneringForce);
    curSlipAngle = curSlipAngle(valid);
    curCorneringForce = curCorneringForce(valid);

    if numel(curSlipAngle) < minPointsperLoad
        continue
    end

    edges = min(curSlipAngle):slipAngleBinWidth:max(curSlipAngle);
    centers = edges(1:end - 1) + slipAngleBinWidth / 2;
    medianCorneringForce = nan(size(centers));
    counts = zeros(size(centers));

    for j = 1:length(edges) - 1
        inBin = curSlipAngle >= edges(j) & curSlipAngle < edges(j + 1);
        counts(j) = sum(inBin);
        if counts(j) >= minPointsperLoad
            medianCorneringForce(j) = median(curCorneringForce(inBin), 'omitnan');
        end
    end

    validBins = ~isnan(medianCorneringForce);
    if sum(validBins) < max(3 * order + 1, 10) % Check if there is enough to filter
        continue
    end

    binnedSlipAngle = centers(validBins);
    binnedCorneringForce = medianCorneringForce(validBins);

    smoothCorneringForce = filtfilt(b, a, binnedCorneringForce);

    % Added step
    %%step = 20;
    %saPlot = saSorted(1:step:end);
    %cfPlot = cfSorted(1:step:end);
    %scatter(saSorted, cfSorted, 1, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.2);

    if withOriginalPlot
        scatter(curSlipAngle, curCorneringForce, 1, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.05);
    end
    plot(binnedSlipAngle, smoothCorneringForce, '-', 'LineWidth', 2, 'Color', colors(i,:));
end

xlabel('Slip Angle (deg)');
ylabel('Cornering Force (N)');
title('Cornering Force vs Slip Angle');
legend(cellstr(num2str(uniqueLoads, '%d N')), 'Location', 'best');
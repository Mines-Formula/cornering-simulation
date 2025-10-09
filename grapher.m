clc, clearvars, clear all
inFile = "R20_sorted.csv";

withOriginalPlot = true;

% Parameters
slipAngleBinWidth = 0.5;
minPointsPerLoad = 30;

% Butterworth Parameters
order = 2;
cutoff = 0.05;

% loess parameters
loessFrace = 0.2; % This is alpha

% import data
newTable = readtable(inFile);
slipAngleRaw = newTable.SlipAngle;
corneringForceRaw = newTable.LateralForce;
normalForceRaw = newTable.NormalForce;

% Bin the loads in groups of 50
loadBins = round(normalForceRaw / 50) * 50;
uniqueLoads = unique(loadBins);



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

    [binnedSlipAngle, sidx] = sort(binnedSlipAngle);
    binnedCorneringForce = binnedCorneringForce(sidx);

    Ngrid = max(200, length(binnedSlipAngle) * 3);
    slipAngleUniform = linspace(min(binnedSlipAngle), max(binnedSlipAngle), Ngrid);

    corneringForceInterpolation = interp1(binnedSlipAngle, binnedCorneringForce, slipAngleUniform, 'linear', 'extrap');

    order = 2;
    cutoff = 0.15;
    [b, a] = butter(order, cutoff, 'low');

    corneringForceSmoothUniform = filfilt(b, a, corneringForceInterpolation);



    % Don't touch below this for now
    if withOriginalPlot
        scatter(curSlipAngle, curCorneringForce, 1, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.05);
    end
    plot(slipAngleUniform, corneringForceSmoothUniform, '-', 'LineWidth', 2, 'Color', colors(i,:));
end

xlabel('Slip Angle (deg)');
ylabel('Cornering Force (N)');
title('Cornering Force vs Slip Angle');
legend(cellstr(num2str(uniqueLoads, '%d N')), 'Location', 'best');
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
loessFrac = 0.2; % This is alpha

% import data
newTable = readtable(inFile);
slipAngleRaw = newTable.SlipAngle;
corneringForceRaw = newTable.LateralForce;
normalForceRaw = newTable.NormalForce;

% Bin the loads in groups of 50
loadBins = round(normalForceRaw / 50) * 50;
uniqueLoads = unique(loadBins);

colors = lines(length(uniqueLoads));
figure('Color', [0 0 0]);
hold on;
grid on;

results = table('Size', [0,6], 'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'double'}, 'VariableNames', {'LoadN', 'B', 'C', 'D', 'E', 'R2'});

for i = 1:length(uniqueLoads)

    thisLoad = uniqueLoads(i);
    idx = (loadBins == thisLoad);
    curSlipAngle = slipAngleRaw(idx);
    curCorneringForce = corneringForceRaw(idx);

    if numel(curSlipAngle) < minPointsPerLoad
        continue
    end

    % clears the NaN values
    valid = ~isnan(curSlipAngle) & ~isnan(curCorneringForce);
    curSlipAngle = curSlipAngle(valid);
    curCorneringForce = curCorneringForce(valid);


    % median absolute value deviation to remove outliers
    medianCorneringForce = median(curCorneringForce);
    madCorneringForce = median(abs(curCorneringForce - medianCorneringForce));
    outlierMask = abs(curCorneringForce - medianCorneringForce) > 3 * max(madCorneringForce, 1e-6);
    curSlipAngle = curSlipAngle(outlierMask);
    curCorneringForce = curCorneringForce(outlierMask);

    % Slip Angle Bins
    edges = min(curSlipAngle):slipAngleBinWidth:max(curSlipAngle);
    centers = edges(1:end - 1) + slipAngleBinWidth / 2;
    medianCorneringForce = nan(size(centers));
    counts = zeros(size(centers));

    for j = 1:length(edges) - 1
        inBin = curSlipAngle >= edges(j) & curSlipAngle < edges(j + 1);
        counts(j) = sum(inBin);
        if counts(j) >= minPointsPerLoad
            medianCorneringForce(j) = median(curCorneringForce(inBin), 'omitnan');
        end
    end

    validBins = ~isnan(medianCorneringForce);
    if sum(validBins) < 10
        continue
    end

    binnedSlipAngle = centers(validBins);
    binnedCorneringForce = medianCorneringForce(validBins);
    [binnedSlipAngle, sidx] = sort(binnedSlipAngle);
    binnedCorneringForce = binnedCorneringForce(sidx);

    % LOESS
    window = round(numel(binnedCorneringForce) * loessFrac);
    loessForce = smoothdata(binnedCorneringForce, 'rloess', window);

    % Turn on or off the original scatter plot
    if withOriginalPlot

        scatter(curSlipAngle, curCorneringForce, 1, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.25);

    end

    % This is the new LOESS based plot
    brightColor = min(colors(i,:) * 1.5, 1.0);
    plot(binnedSlipAngle, loessForce, '--', 'Color', brightColor, 'LineWidth', 2, 'DisplayName', sprintf('%d N (LOESS)', thisLoad));
    
end

xlabel('Slip Angle (deg)', 'Color', [0.9 0.9 0.9]);
ylabel('Cornering Force (N)', 'Color', [0.9 0.9 0.9]);
title('Cornering Force vs Slip Angle - Original vs LOESS', 'Color', [0.95 0.95 0.95]);
legend('TextColor', 'w', 'Location', 'best', 'FontSize', 9);
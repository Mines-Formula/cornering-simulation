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

for i = 1:length(uniqueLoads)

    brightColor = min(colors(i,:) * 1.5, 1.0);
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
    curSlipAngle(outlierMask) = [];
    curCorneringForce(outlierMask) = [];

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

    % The butterworth part
    [b, a] = butter(order, cutoff, 'low');
    corneringForceSmooth = filtfilt(b, a, binnedCorneringForce);

    % LOESS
    window = round(numel(binnedCorneringForce) * loessFrac);
    loessForce = smoothdata(binnedCorneringForce, 'rloess', window);

    % Compute D_y
    [peakForce, peakIdx] = max(loessForce);
    [valleyForce, valleyIdx] = min(loessForce);

    Dy = (abs(peakForce) + abs(valleyForce)) / 2;

    % Compute pD_y
    pDy = Dy / (abs(thisLoad) * 9.8);

    fprintf('Load = %d N --> D_y = %.2f N,  pD_y = %.4f\n', abs(thisLoad), Dy, pDy);

    if ~exist('Dy_results', 'var')
        Dy_results = table(thisLoad, Dy, pDy);
    else
        Dy_results = [Dy_results; table(thisLoad, Dy, pDy)];
    end


    % pacejka function for best fit
    pacejkaFunction = @(params, alpha) params(3) .* sin(params(2) .* atan(params(1)*alpha - params(4)*(params(1)*alpha - atan(params(1)*alpha))));

    initialGuess = [10, 1.3, Dy, 0.97];

    opts = optimoptions('lsqcurvefit', 'Display', 'off');
    lb = [0, 0.5, 0.5 * Dy, 0];
    ub = [50, 2.0, 1.5 * Dy, 1];
    params = lsqcurvefit(pacejkaFunction, initialGuess, binnedSlipAngle * pi / 180, loessForce, [], [], opts); 

    B = params(1);
    C = params(2);
    D = params(3);
    E = params(4);

    fprintf('Load = %d N --> B=%.3f, C=%.3f, D=%.2f, E=%.3f\n', abs(thisLoad), B, C, D, E);

    alphaFine = linspace(min(binnedSlipAngle), max(binnedSlipAngle), 200);
    FyFit = pacejkaFunction(params, alphaFine * pi / 180);

    plot(alphaFine, FyFit, '-', 'Color', brightColor, 'LineWidth', 2.5, 'DisplayName', sprintf('%d N (Pacejka Fit)', thisLoad));

    if ~exist('fitResults', 'var')
        fitResults = table(abs(thisLoad), B, C, D, E);
    else
        fitResults = [fitResults; table(abs(thisLoad), B, C, D, E)];
    end

    % Turn on or off the original scatter plot
    if withOriginalPlot

        scatter(curSlipAngle, curCorneringForce, 1, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.05);

    end

    % This is the previous plot just for comparison
    %plot(binnedSlipAngle, corneringForceSmooth, '-', 'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', sprintf('%d kg (ORIGINAL)', abs(thisLoad)));

    % This is the new LOESS based plot
    plot(binnedSlipAngle, loessForce, '--', 'Color', brightColor, 'LineWidth', 2, 'DisplayName', sprintf('%d kg (LOESS)', abs(thisLoad)));

    % --- compute slope near origin (±2°) ---
    originWindow = 2; % degrees, adjustable
    nearZeroIdx = abs(binnedSlipAngle) <= originWindow;
    
    if sum(nearZeroIdx) >= 3
        % linear fit to LOESS curve near origin
        p_lin = polyfit(binnedSlipAngle(nearZeroIdx), loessForce(nearZeroIdx), 1);
        ky_origin = p_lin(1) / (pi / 180); % convert from N/deg to N/rad
    else
        ky_origin = NaN;
    end
    
    % normalized version
    Fz0 = 1962;
    pky_origin = ky_origin / Fz0;
    
    fprintf('Load = %.0f kg --> ky_origin=%.0f N/rad, pKy_origin=%.2f\n', abs(thisLoad), ky_origin, pky_origin);
    
    if ~exist('ky_origin_results', 'var')
        ky_origin_results = table(abs(thisLoad), ky_origin, pky_origin);
    else
        ky_origin_results = [ky_origin_results; table(abs(thisLoad), ky_origin, pky_origin)];
    end


    % Compute D_y
    [peakForce, peakIdx] = max(loessForce);
    [valleyForce, valleyIdx] = min(loessForce);
    Dy = (abs(peakForce) + abs(valleyForce)) / 2;

    % Convert load to N
    thisLoadN = abs(thisLoad) * 9.81;

    % Compute pD_y
    pDy = Dy / thisLoadN;

    fprintf('Load = %.0f kg --> D_y = %.2f N,  pD_y = %.4f\n', abs(thisLoad), Dy, pDy);

    if ~exist('Dy_results', 'var')
        Dy_results = table(thisLoad, Dy, pDy);
    else
        Dy_results = [Dy_results; table(thisLoad, Dy, pDy)];
    end

    % Textbook-style cornering stiffness (k_y)
    FyTarget = 5000;
    [~, idxClosest] = min(abs(loessForce - FyTarget));
    alphaAtFy = binnedSlipAngle(idxClosest);
    kyBook = FyTarget / (alphaAtFy * pi / 180); % N/rad

    % Textbook normalization
    Fz0 = 1962; % N (reference load)
    pkyBook = kyBook / Fz0;

    fprintf('Load = %.0f kg --> alpha@Fy=%.2f°, k_y=%.0f N/rad, pK_y=%.1f\n', abs(thisLoad), alphaAtFy, kyBook, pkyBook);

    if ~exist('ky_results', 'var')
        ky_results = table(abs(thisLoad), alphaAtFy, kyBook, pkyBook);
    else
        ky_results = [ky_results; table(abs(thisLoad), alphaAtFy, kyBook, pkyBook)];
    end

    
end

disp('Summary of origin style looks');
disp(ky_origin_results);

disp('Summary of textbook-style cornering stiffness:');
disp(ky_results);

disp('Summary of pacejka Fit Parameters');
disp(fitResults);

xlabel('Slip Angle (deg)', 'Color', [0.9 0.9 0.9]);
ylabel('Cornering Force (N)', 'Color', [0.9 0.9 0.9]);
title('Cornering Force vs Slip Angle - Original vs LOESS', 'Color', [0.95 0.95 0.95]);
legend('TextColor', 'w', 'Location', 'best', 'FontSize', 9);
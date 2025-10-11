clc, clearvars, clear all
inFile = "R20_sorted.csv";

withOriginalPlot = true;

% Parameters
slipAngleBinWidth = 0.5;
minPointsPerLoad = 30;

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

    % LOESS
    window = round(numel(binnedCorneringForce) * loessFrac);
    loessForce = smoothdata(binnedCorneringForce, 'rloess', window);

        % Compute D_y
    [peakForce, peakIdx] = max(loessForce);
    [valleyForce, valleyIdx] = min(loessForce);

    Dy = (abs(peakForce) + abs(valleyForce)) / 2;

    % pacejka function for best fit
    pacejkaFunction = @(params, alpha) params(3) .* sin(params(2) .* atan(params(1)*alpha - params(4)*(params(1)*alpha - atan(params(1)*alpha))));

    initialGuess = [10, 1.3, Dy, 0.97];

    opts = optimoptions('lsqcurvefit', 'Display', 'off');
    params = lsqcurvefit(pacejkaFunction, initialGuess, binnedSlipAngle * pi / 180, loessForce, [], [], opts); 

    B = params(1);
    C = params(2);
    D = params(3);
    E = params(4);

    ky = B * C * D;

    fprintf('Load = %d kg --> B = %.3f, C = %.3f, D = %.2f, E = %.3f, ky = %.3f\n', abs(thisLoad), B, C, D, E, ky);

    alphaFine = linspace(min(binnedSlipAngle), max(binnedSlipAngle), 200);
    FyFit = pacejkaFunction(params, alphaFine * pi / 180);

    plot(alphaFine, FyFit, '-', 'Color', brightColor, 'LineWidth', 2.5, 'DisplayName', sprintf('%d kg (Pacejka Fit)', thisLoad));

    if ~exist('fitResults', 'var')
        fitResults = table(abs(thisLoad), B, C, D, E, ky);
    else
        fitResults = [fitResults; table(abs(thisLoad), B, C, D, E, ky)];
    end

   

    % Turn on or off the original scatter plot
    if withOriginalPlot

        scatter(curSlipAngle, curCorneringForce, 1, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.05);

    end

    % This is the new LOESS based plot
    plot(binnedSlipAngle, loessForce, '--', 'Color', brightColor, 'LineWidth', 2, 'DisplayName', sprintf('%d kg (LOESS)', abs(thisLoad)));
    
end

disp('Summary of pacejka Fit Parameters');
disp(fitResults);

xlabel('Slip Angle (deg)', 'Color', [0.9 0.9 0.9]);
ylabel('Cornering Force (N)', 'Color', [0.9 0.9 0.9]);
title('Cornering Force vs Slip Angle - Original vs LOESS', 'Color', [0.95 0.95 0.95]);
legend('TextColor', 'w', 'Location', 'best', 'FontSize', 9);

fitResults.Fz = fitResults.Var1 * 9.8;
fitResults.gamma = zeros(height(fitResults), 1); % Took this out because
% we don't HAVE ANY!!!

fitResults.mu_y = fitResults.D ./ (fitResults.Fz);
fitResults.ky_norm = fitResults.ky ./ max(fitResults.Fz);

FZ0 = median(fitResults.Fz); % We can change this to exactly match the books value

fprintf('Nominal load FZ0 = %.1f N\n\n', FZ0);

% µy(Fz) = P_DY1 + P_DY2*(Fz/FZ0 - 1) + P_DY3*gamma^2.  Type it into Google
% and some good results come up
X_mu = [ones(height(fitResults),1), (fitResults.Fz./FZ0 - 1), (fitResults.gamma).^2];
b_mu = X_mu \ fitResults.mu_y;

P_DY1 = b_mu(1);
P_DY2 = b_mu(2);
P_DY3 = b_mu(3); % This one is useless without camber angle comparisons

fprintf('Friction (µy) coefficients:\n');
fprintf('  P_DY1 = %.6f\n  P_DY2 = %.6f\n  P_DY3 = %.6f\n\n', P_DY1, P_DY2, P_DY3);

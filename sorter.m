clc, clearvars, clear all

dataFolder = 'C:\Users\ajsau\Documents\formula\corneringSim\cornering-simulation';
inFile  = fullfile(dataFolder, "LCO.csv");

newTable = readtable(inFile);
genericSort(newTable, {'LateralForce', 'SlipAngle'}, "LCO_ordered_lateral_force_and_slip_angle.csv");

function [newTable] = genericSort(startTable, sortVars, outFile)
    newTable = sortrows(startTable, sortVars);
    writetable(newTable, outFile);
    disp("Finished sort.")
end
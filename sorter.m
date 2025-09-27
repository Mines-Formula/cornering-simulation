clc, clearvars, clear all

dataFolder = '/Users/Blanchards1/Documents/FormulaSim/documentation/data/runData';
inFile  = fullfile(dataFolder, "R20.csv");

newTable = readtable(inFile);
genericSort(newTable, {'TirePressure', 'RoadSpeed'}, "R20_sorted.csv");

function [newTable] = genericSort(startTable, sortVars, outFile)
    newTable = sortrows(startTable, sortVars);
    writetable(newTable, outFile);
    disp("Finished sort.")
end
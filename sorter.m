clc, clearvars, clear all

dataFolder = '/Users/Blanchards1/Documents/FormulaSim/documentation/data/runData';
inFile  = fullfile(dataFolder, "R20.csv");
outFile = fullfile(dataFolder, "R20_ordered_tire_pressure.csv");

newTable = readtable(inFile);

newTable.TirePressure_round = round(newTable.TirePressure);

newTable = sortrows(newTable, {'TirePressure_round', 'TirePressure'});

writetable(newTable, outFile);

disp("Finished")
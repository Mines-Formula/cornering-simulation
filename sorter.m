clc, clearvars, clear all

dataFolder = '/Users/Blanchards1/Documents/FormulaSim/documentation/data/runData';
inFile  = fullfile(dataFolder, "R20.csv");
%outFile = fullfile(dataFolder, "R20_ordered_tire_pressure.csv");

newTable = readtable(inFile);



function [newTable] = tirePressureSort(newTable) 
    newTable.TirePressure_round = round(newTable.TirePressure);
    newTable = sortrows(newTable, {'TirePressure_round', 'TirePressure'});
    disp("Finished with tire pressure sort.")
end

function [newTable] = speedSort(newTable)
    newTable.sortrows(newTable, 'RoadSpeed');
    disp("Finished with speed store.");

end

function [newTable] = inclinationAngleSort(newTable)
    newTable.sortrows(newTable, 'InclinationAngle');
    disp("Finished inclination angle sort.");

end

function [newTable] = verticalLoad(newTable)
    newTable.sortrows(newTable, 'NormalForce');
    disp("Finished inclination angle sort.");
    
end
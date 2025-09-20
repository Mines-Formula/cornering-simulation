clc, clearvars, clear all

dataFolder = '/Users/Blanchards1/Documents/FormulaSim/documentation/data/runData';
inFile  = fullfile(dataFolder, "R20.csv");
%outFile = fullfile(dataFolder, "R20_ordered_tire_pressure.csv");

newTable = readtable(inFile);
tirePressureSort(newTable);
speedSort(newTable);
inclinationAngleSort(newTable);
verticalLoadSort(newTable);

function [newTable] = tirePressureSort(newTable) 
    newTable.TirePressure_round = round(newTable.TirePressure);
    newTable = sortrows(newTable, {'TirePressure_round', 'TirePressure'});
    writetable(newTable, "R20_ordered_tire_pressure.csv");
    disp("Finished tire pressure sort.")
end

function [newTable] = speedSort(newTable)
    newTable = sortrows(newTable, 'RoadSpeed');
    writetable(newTable, "R20_ordered_speed.csv");
    disp("Finished speed sort.");

end

function [newTable] = inclinationAngleSort(newTable)
    newTable = sortrows(newTable, 'InclinationAngle');
    writetable(newTable, "R20_ordered_inclination_angle.csv");
    disp("Finished inclination angle sort.");

end

function [newTable] = verticalLoadSort(newTable)
    newTable = sortrows(newTable, 'NormalForce');
    writetable(newTable, "R20_ordered_vertical_load.csv");
    disp("Finished vertical load sort.");
    
end
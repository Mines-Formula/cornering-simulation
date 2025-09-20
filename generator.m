clc, clearvars, clear all

dataFolder = '/Users/Blanchards1/Documents/FormulaSim/documentation/data/runData';
fileList = dir(fullfile(dataFolder, "*.mat"));

finalTable = table();

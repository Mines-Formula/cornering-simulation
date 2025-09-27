clc, clearvars, clear all
inFile = "R20_sorted.csv";

newTable = readtable(inFile);

uniqueLoads = unique(newTable.NormalForce);
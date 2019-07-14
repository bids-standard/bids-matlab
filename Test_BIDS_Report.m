% RootFolder = 'D:\Dropbox\GitHub\BIDS-examples\';
RootFolder = 'D:\BIDS\';
% RootFolder = 'E:\McGurk\'; 
% RootFolder = 'E:\AV_Att\';
% RootFolder = 'E:\AVT\';

% DIR_ls = dir([RootFolder 'ds*']);
% DIR_ls = dir([RootFolder '7*']);
% DIR_ls = dir([RootFolder 'rawda*']);

DIR_ls = dir([RootFolder, 'ds003', filesep, 'rawda*']);

DIR_ls([DIR_ls.isdir]==0) = [];

clc

Subj = 1;
Ses = 0;
Run = 1 ;
ReadGZ = 1;

for iDIR = 1:numel(DIR_ls)
    bids.report([DIR_ls(iDIR).folder filesep DIR_ls(iDIR).name], Subj, Ses, Run, ReadGZ)
end
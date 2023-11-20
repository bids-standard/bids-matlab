% # Create filenames, filepaths, and JSON
%
% (C) Copyright 2021 BIDS-MATLAB developers

%%

add_bids_matlab_to_path();

% ## Initialising a new BIDS dataset

% This can be useful when you are going to output your analysis or your data acquisition into a new dataset.

%%

help bids.init;

% Derivatives datasets have some extra info in their `dataset_description.json`.
%
% If you are going to curate the dataset with
% [Datalad](http://handbook.datalad.org/en/latest/),
% you can also mention it and this will modify the README
% to add extra info about this (taken from the datalad handbook).

%%

pth = fullfile(pwd, 'dummy_ds');

folders.subjects = {'01', '02'};
folders.sessions = {'pre', 'post'};
folders.modalities = {'anat', 'eeg'};

%%

bids.init(pth, 'folders', folders, 'is_derivative', true, 'is_datalad_ds', true);

%%

!tree dummy_ds

% Template README was generated.

%%

!cat dummy_ds/README

%%

!cat dummy_ds/dataset_description.json

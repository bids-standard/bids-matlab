% +BIDS - The bids-matlab library
%
% Contents
%   layout              - Parse a directory structure formated according to the BIDS standard
%   query               - Queries a directory structure formatted according to the BIDS standard
%   validate            - BIDS Validator
%   report              - Create a short summary of the acquisition parameters of a BIDS dataset
%   copy_to_derivative  - Copy selected data from BIDS layout to given derivatives folder,
%   File                - Class to handle BIDS filenames.
%   Description         - Class to deal with dataset_description files.
%   init                - Initialize dataset with README, description, folder structure...
%   derivatives_json    - Creates dummy content for a given BIDS derivative file.
%   Schema              - Class to interact with the BIDS schema
%
%   util.jsondecode - Decode JSON-formatted file
%   util.jsonencode - Encode data to JSON-formatted file
%   util.mkdir      - Make new directory trees
%   util.tsvread    - Load text and numeric data from tab-separated-value or other file
%   util.tsvwrite   - Save text and numeric data to .tsv file
%
%
% __________________________________________________________________________
%
% BIDS-MATLAB is a library that aims at centralising MATLAB/Octave tools
% for interacting with datasets conforming to the BIDS format.
% See https://github.com/bids-standard/bids-matlab for more details.
%
% __________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%
% The brain imaging data structure, a format for organizing and
% describing outputs of neuroimaging experiments.
% K. J. Gorgolewski et al, Scientific Data, 2016.
% __________________________________________________________________________
%
%
% (C) Copyright 2016-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
%
% (C) Copyright 2018 BIDS-MATLAB developers

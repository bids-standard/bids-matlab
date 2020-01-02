function test_bids_query(pth)
% Test BIDS queries on ds007
% This dataset comes from https://github.com/bids-standard/bids-examples
% and is downloaded automatically by the continuous integration framework
% and is required for the tests to be run.
% Based on https://en.wikibooks.org/wiki/SPM/BIDS#BIDS_parser_and_queries
%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________

% Copyright (C) 2019, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2019--, BIDS-MATLAB developers


if ~nargin, pth = fullfile(pwd,'bids-examples','ds007'); end

layout = bids.readlayout(pth);

subjs = arrayfun(@(x) sprintf('%02d',x), 1:20, 'UniformOutput',false);
assert(isequal(bids.query(layout,'subjects'),subjs));

assert(isempty(bids.query(layout,'sessions')));

assert(isequal(bids.query(layout,'runs'),{'01','02'}));

tasks = {'stopsignalwithletternaming','stopsignalwithmanualresponse','stopsignalwithpseudowordnaming'};
assert(isequal(bids.query(layout,'tasks'),tasks));

types = {'T1w','bold','events','inplaneT2'};
assert(isequal(bids.query(layout,'types'),types));

mods = {'anat','func'};
assert(isequal(bids.query(layout,'modalities'),mods));

assert(isempty(bids.query(layout,'runs','type','T1w')));

runs = {'01','02'};
assert(isequal(bids.query(layout,'runs','type','bold'),runs));

bold = bids.query(layout,'data','sub','05','run','02','task','stopsignalwithmanualresponse','type','bold');
assert(iscellstr(bold));
assert(numel(bold) == 1);

md = bids.query(layout,'metadata','sub','05','run','02','task','stopsignalwithmanualresponse','type','bold');
assert(isstruct(md) & isfield(md,'RepetitionTime') & isfield(md,'TaskName'));
assert(md.RepetitionTime == 2);
assert(strcmp(md.TaskName,'stop signal with manual response'));

t1 = bids.query(layout,'data','type','T1w');
assert(iscellstr(t1));
assert(numel(t1) == numel(bids.query(layout,'subjects')));

% Check sessions
%   parse a folder with sessions
pth = fullfile(fileparts(pth),'synthetic');
layout = bids.readlayout(pth);
%   test
sessions = {'01','02'};
assert(isequal(bids.query(layout,'sessions'),sessions))
assert(isequal(bids.query(layout,'sessions','sub','02'),sessions))

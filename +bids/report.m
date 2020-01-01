function report(BIDS, Subj, Ses, Run, ReadNII)
% Create a short summary of the acquisition parameters of a BIDS dataset
% FORMAT bids.report(BIDS, Subj, Ses, Run, ReadNII)
%
% INPUTS:
% - BIDS: directory formatted according to BIDS [Default: pwd]
%
% - Subj: Specifies which subject(s) to take as template.
% - Ses:  Specifies which session(s) to take as template. Can be a vector.
%         Set to 0 to do all sessions.
% - Run:  Specifies which BOLD run(s) to take as template.
% - ReadNII: If set to 1 (default) the function will try to read the
%             NIfTI file to get more information. This relies on the
%             spm_vol.m function from SPM.
%
% Unless specified the function will only read the data from the first
% subject, session, and run (for each task of BOLD). This can be an issue
% if different subjects/sessions contain very different data.
%
% See also:
% bids

%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________

% Copyright (C) 2018, Remi Gau
% Copyright (C) 2018--, BIDS-MATLAB developers

% TODO
%--------------------------------------------------------------------------
% - deal with DWI bval/bvec values not read by bids.query
% - write output to a txt file?
% - deal with "EEG" / "MEG"
% - deal with "events": compute some summary statistics as suggested in
% COBIDAS report
% - report summary statistics on participants as suggested in COBIDAS report
% - check if all subjects have the same content?
% - adapt for several subjects or runs
% - take care of other recommended metafield in BIDS specs or COBIDAS?


%-Check inputs
%--------------------------------------------------------------------------
if ~nargin
    BIDS = pwd;
end
if nargin < 2 || isempty(Subj)
    Subj = 1;
end
if nargin < 3 || isempty(Ses)
    Ses = 1;
end
if nargin < 4 || isempty(Run)
    Run = 1;
end
if nargin < 5 || isempty(ReadNII)
    ReadNII = true;
end
ReadNII = ReadNII & exist('spm_vol','file') == 2;

%-Parse the BIDS dataset directory
%--------------------------------------------------------------------------
if ~isa(BIDS, 'bids.layout.BIDSLayout')
    fprintf('\n-------------------------\n')
    fprintf('  Reading BIDS: %s', BIDS)
    fprintf('\n-------------------------\n')
    BIDS = bids.layout(BIDS);
    fprintf('Done.\n\n')
end

BIDS.report(Subj, Ses, Run, ReadNII);

% (C) Copyright 2021 Remi Gau
% (C) Copyright 2014 Guillaume Flandin, Wellcome Centre for Human Neuroimaging

clear;

force = true;
verbose =  true;
use_schema =  true;
tolerant = false;

preproc_pipeline_name = 'spm12_preproc';
stats_pipeline_name = 'spm12_stats';

subject_label = '01';

%%
pth = bids.util.download_ds('source', 'spm', ...
                            'demo', 'moae', ...
                            'force', force, ...
                            'verbose', verbose);

derivatives_pth = fullfile(pth, 'derivatives');

%% COPY DATA TO DERIVATIVES FOLDER
BIDS = bids.layout(pth, ...
                   'use_schema', use_schema, ...
                   'tolerant', tolerant, ...
                   'verbose', verbose);

% copy the dataset into a folder for derivatives
bids.copy_to_derivative(BIDS, ...
                        'pipeline_name', preproc_pipeline_name, ...
                        'out_path', fullfile(pth, 'derivatives'), ...
                        'unzip', true, ...
                        'force', force, ...
                        'skip_dep', false, ...
                        'verbose', verbose);

% prepare folder for stats
stats_pth = fullfile(derivatives_pth, stats_pipeline_name);
folders = struct('subjects',  {{subject_label}}, ...
                 'modalities', {{'stats'}});
is_derivative = true;
bids.init(stats_pth, 'folders', folders, 'is_derivative', is_derivative);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% WRITE DATASET DESCRIPTION REPORT

% read the dataset
BIDS = bids.layout(fullfile(pth, 'derivatives', preproc_pipeline_name), ...
                   'use_schema', use_schema, ...
                   'tolerant', tolerant, ...
                   'verbose', verbose);

% write the report in the log folder
mkdir(BIDS.pth, 'log');
bids.report(BIDS, ...
            'output_path', fullfile(pth, 'derivatives', preproc_pipeline_name, 'log'), ...
            'read_nifti', true, ...
            'verbose', verbose);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The rest of the batch script was adapted from that of the SPM website:
%   http://www.fil.ion.ucl.ac.uk/spm/data/auditory/
% as described in the SPM manual:
%   http://www.fil.ion.ucl.ac.uk/spm/doc/manual.pdf#Chap:data:auditory
% __________________________________________________________________________
% Copyright (C) 2014 Wellcome Trust Centre for Neuroimaging

% Guillaume Flandin
% $Id: auditory_spm12_batch.m 8 2014-09-29 18:11:56Z guillaume $

%% Initialise SPM
% --------------------------------------------------------------------------
spm('Defaults', 'fMRI');
spm_jobman('initcfg');

clear matlabbatch;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SPATIAL PREPROCESSING

anat = bids.query(BIDS, 'data', ...
                  'sub', subject_label, ...
                  'suffix', 'T1w');
func = bids.query(BIDS, 'data', ...
                  'sub', subject_label, ...
                  'suffix', 'bold');

% Realign
% --------------------------------------------------------------------------
estwrite.data{1} = cellstr(func);
estwrite.roptions.which = [0 1];

matlabbatch{1}.spm.spatial.realign.estwrite = estwrite;

% Coregister
% --------------------------------------------------------------------------
estimate.ref = cellstr(spm_file(func, 'prefix', 'mean'));
estimate.source = cellstr(anat);

matlabbatch{2}.spm.spatial.coreg.estimate = estimate;

% Segment
% --------------------------------------------------------------------------
preproc.channel.vols  = cellstr(anat);
preproc.channel.write = [0 1];
preproc.warp.write    = [0 1];

matlabbatch{3}.spm.spatial.preproc = preproc;

% Normalise: Write
% --------------------------------------------------------------------------
write.subj.def = cellstr(spm_file(anat, 'prefix', 'y_', ...
                                  'ext', 'nii'));
write.subj.resample = cellstr(func);
write.woptions.vox  = [3 3 3];

matlabbatch{4}.spm.spatial.normalise.write = write;

write.subj.def = cellstr(spm_file(anat, 'prefix', 'y_', ...
                                  'ext', 'nii'));
write.subj.resample = cellstr(spm_file(anat, 'prefix', 'm', ...
                                       'ext', 'nii'));
write.woptions.vox  = [1 1 3];

matlabbatch{5}.spm.spatial.normalise.write = write;

% Smooth
% --------------------------------------------------------------------------
smooth.data = cellstr(spm_file(func, 'prefix', 'w'));
smooth.fwhm = [6 6 6];
matlabbatch{6}.spm.spatial.smooth = smooth;

spm_jobman('run', matlabbatch);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GLM SPECIFICATION, ESTIMATION, INFERENCE, RESULTS

% re-read the dataset without the schela to index the new files
use_schema = false;
BIDS = bids.layout(fullfile(pth, 'derivatives', preproc_pipeline_name), ...
                   'use_schema', use_schema);

func = bids.query(BIDS, 'data', ...
                  'sub', subject_label, ...
                  'suffix', 'bold', ...
                  'prefix', 'sw');

metadata = bids.query(BIDS, 'metadata', ...
                      'sub', subject_label, ...
                      'suffix', 'bold', ...
                      'prefix', 'sw');

events = bids.query(BIDS, 'data', ...
                    'sub', subject_label, ...
                    'suffix', 'events', ...
                    'extension', '.tsv');

events = spm_load(events{1});

subj_stats_pth = fullfile(BIDS.pth, ['sub-' subject_label], 'stats');
SPM_mat = fullfile(subj_stats_pth, 'SPM.mat');

clear matlabbatch;

% Model Specification
% --------------------------------------------------------------------------
fmri_spec.dir = cellstr(subj_stats_pth);
fmri_spec.timing.units = 'secs';
fmri_spec.timing.RT = metadata.RepetitionTime;
fmri_spec.sess.scans = cellstr(func);
fmri_spec.sess.cond.name = 'active';
fmri_spec.sess.cond.onset = events.onset;
fmri_spec.sess.cond.duration = events.duration;

matlabbatch{1}.spm.stats.fmri_spec = fmri_spec;

% Model Estimation
% --------------------------------------------------------------------------
matlabbatch{2}.spm.stats.fmri_est.spmmat = cellstr(SPM_mat);

% Contrasts
% --------------------------------------------------------------------------
con.spmmat = cellstr(SPM_mat);
con.consess{1}.tcon.name = 'Listening > Rest';
con.consess{1}.tcon.weights = [1 0];
con.consess{2}.tcon.name = 'Rest > Listening';
con.consess{2}.tcon.weights = [-1 0];

matlabbatch{3}.spm.stats.con = con;

% Inference Results
% --------------------------------------------------------------------------
results.spmmat = cellstr(SPM_mat);
results.conspec.contrasts = 1;
results.conspec.threshdesc = 'FWE';
results.conspec.thresh = 0.05;
results.conspec.extent = 0;
results.print = false;

matlabbatch{4}.spm.stats.results = results;

% Rendering
% --------------------------------------------------------------------------
surface = fullfile(spm('Dir'), 'canonical', 'cortex_20484.surf.gii');
display.rendfile = {surface};
display.conspec.spmmat = cellstr(SPM_mat);
display.conspec.contrasts = 1;
display.conspec.threshdesc = 'FWE';
display.conspec.thresh = 0.05;
display.conspec.extent = 0;

matlabbatch{5}.spm.util.render.display = display;

spm_jobman('run', matlabbatch);

% (C) Copyright 2021 Remi Gau
% (C) Copyright 2014 Guillaume Flandin, Wellcome Centre for Human Neuroimaging

% TODO compare results to original script

clear;

force = true;
verbose =  true;
use_schema =  true;
tolerant = false;

preproc_pipeline_name = 'spm12-preproc';
stats_pipeline_name = 'spm12-stats';

subject_label = '01';

%%
pth = bids.util.download_ds('source', 'spm', ...
                            'demo', 'facerep', ...
                            'force', force, ...
                            'verbose', verbose);

derivatives_pth = fullfile(pth, 'derivatives');

%% COPY TO DERIVATIVES
BIDS = bids.layout(pth, ...
                   use_schema, ...
                   tolerant, ...
                   verbose);
% copy the dataset into a folder for derivatives
bids.copy_to_derivative(BIDS, preproc_pipeline_name, ...
                        fullfile(pth, 'derivatives'), ...
                        'unzip', true, ...
                        'force', force, ...
                        'skip_dep', false, ...
                        'use_schema', use_schema, ...
                        'verbose', verbose);

% prepare folder for stats
stats_pth = fullfile(derivatives_pth, stats_pipeline_name);
folders = struct('subjects',  {{subject_label}}, ...
                 'modalities', {{'stats'}});
is_derivative = true;
bids.init(stats_pth, folders, is_derivative);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% WRITE REPORT

% read the dataset
BIDS = bids.layout(fullfile(derivatives_pth, preproc_pipeline_name), ...
                   use_schema, ...
                   tolerant, ...
                   verbose);

log_folder = fullfile(BIDS.pth, 'log');
mkdir(log_folder);
bids.report(BIDS, ...
            'output_path', log_folder, ...
            'read_nifti', true, ...
            'verbose', verbose);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The rest of the batch script was adapted from that of the SPM website:
%   http://www.fil.ion.ucl.ac.uk/spm/data/face_rep/
% as described in the SPM manual:
%   http://www.fil.ion.ucl.ac.uk/spm/doc/spm12_manual.pdf#Chap:data:faces
% __________________________________________________________________________
% Copyright (C) 2014-2015 Wellcome Trust Centre for Neuroimaging

% Guillaume Flandin
% $Id: face_rep_spm12_batch.m 17 2015-03-06 11:24:19Z guillaume $

% Initialise SPM
% --------------------------------------------------------------------------
spm('Defaults', 'fMRI');
spm_jobman('initcfg');

% Change working directory (useful for PostScript (.ps) files only)
% --------------------------------------------------------------------------
% clear matlabbatch
% matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_cd.dir = cellstr(data_path);
% spm_jobman('run',matlabbatch);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SPATIAL PREPROCESSING

clear matlabbatch;

% Select functional and structural scans
% --------------------------------------------------------------------------
a = bids.query(BIDS, 'data', ...
               'sub', subject_label, ...
               'suffix', 'T1w');
f = bids.query(BIDS, 'data', ...
               'sub', subject_label, ...
               'suffix', 'bold');
metadata = bids.query(BIDS, 'metadata', ...
                      'sub', subject_label, ...
                      'suffix', 'bold');

% Realign
% --------------------------------------------------------------------------
matlabbatch{1}.spm.spatial.realign.estwrite.data{1} = cellstr(f);

% Slice Timing Correction
% --------------------------------------------------------------------------
temporal.st.scans{1} = cellstr(spm_file(f, 'prefix', 'r'));
temporal.st.nslices = numel(metadata.SliceTiming);
temporal.st.tr = metadata.RepetitionTime;
temporal.st.ta = metadata.RepetitionTime - metadata.RepetitionTime / numel(metadata.SliceTiming);
temporal.st.so = metadata.SliceTiming / 1000;
temporal.st.refslice = median(metadata.SliceTiming);

matlabbatch{2}.spm.temporal = temporal;

% Coregister
% --------------------------------------------------------------------------
coreg.estimate.ref    = cellstr(spm_file(f, 'prefix', 'mean'));
coreg.estimate.source = cellstr(a);
matlabbatch{3}.spm.spatial.coreg = coreg;

% Segment
% --------------------------------------------------------------------------
preproc.channel.vols  = cellstr(a);
preproc.channel.write = [0 1];
preproc.warp.write    = [0 1];
matlabbatch{4}.spm.spatial.preproc = preproc;

% Normalise: Write
% --------------------------------------------------------------------------
normalise.write.subj.def      = cellstr(spm_file(a, 'prefix', 'y_', 'ext', 'nii'));
normalise.write.subj.resample = cellstr(char(spm_file(f{1}, 'prefix', 'ar'), ...
                                             spm_file(f{1}, 'prefix', 'mean')));
normalise.write.woptions.vox  = [3 3 3];

matlabbatch{5}.spm.spatial.normalise = normalise;

normalise.write.subj.def      = cellstr(spm_file(a, 'prefix', 'y_', 'ext', 'nii'));
normalise.write.subj.resample = cellstr(spm_file(a, 'prefix', 'm', 'ext', 'nii'));
normalise.write.woptions.vox  = [1 1 1.5];

matlabbatch{6}.spm.spatial.normalise = normalise;

% Smooth
% --------------------------------------------------------------------------
smooth.data = cellstr(spm_file(f, 'prefix', 'war'));
smooth.fwhm = [8 8 8];

matlabbatch{7}.spm.spatial.smooth = smooth;

code_folder = fullfile(derivatives_pth, preproc_pipeline_name, 'code');
spm_mkdir(code_folder);
save(fullfile(code_folder, 'face_batch_preprocessing.mat'), 'matlabbatch');

spm_jobman('run', matlabbatch);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CLASSICAL STATISTICAL ANALYSIS (CATEGORICAL)

% re-read the dataset without the schela to index the new files
use_schema = false;
BIDS = bids.layout(BIDS.pth, use_schema);

f = bids.query(BIDS, 'data', ...
               'sub', subject_label, ...
               'suffix', 'bold', 'prefix', 'swar');

realignment = bids.query(BIDS, 'data', ...
                         'sub', subject_label, ...
                         'suffix', 'bold', 'prefix', 'rp_');

events = bids.query(BIDS, 'data', ...
                    'sub', subject_label, ...
                    'suffix', 'events', ...
                    'extension', '.tsv');

events = bids.util.tsvread(events{1});

subj_stats_pth = fullfile(stats_pth, ['sub-' subject_label], 'stats-categorical');
SPM_mat = fullfile(subj_stats_pth, 'SPM.mat');

clear matlabbatch;

% Load onsets
% --------------------------------------------------------------------------
onsets    = events.onset;
condnames = events.trial_type;
condition_lists = unique(condnames);

% Model Specification
% --------------------------------------------------------------------------
fmri_spec.dir = cellstr(subj_stats_pth);
fmri_spec.timing.units = 'secs';
fmri_spec.timing.RT = metadata.RepetitionTime;
fmri_spec.timing.fmri_t = numel(metadata.SliceTiming);
fmri_spec.timing.fmri_t0 = median(1:numel(metadata.SliceTiming));
fmri_spec.sess.scans = cellstr(f);

for i = 1:numel(condition_lists)
  fmri_spec.sess.cond(i).name = condition_lists{i};
  idx = ismember(condnames, condition_lists{i});
  fmri_spec.sess.cond(i).onset = onsets(idx);
  fmri_spec.sess.cond(i).duration = 0;
end

fmri_spec.sess.multi_reg   = cellstr(realignment);
fmri_spec.fact(1).name     = 'Fame';
fmri_spec.fact(1).levels   = 2;
fmri_spec.fact(2).name     = 'Rep';
fmri_spec.fact(2).levels   = 2;
fmri_spec.bases.hrf.derivs = [1 1];

matlabbatch{1}.spm.stats.fmri_spec = fmri_spec;

% Model Estimation
% --------------------------------------------------------------------------
matlabbatch{2}.spm.stats.fmri_est.spmmat = cellstr(SPM_mat);

save(fullfile(code_folder, 'categorical_spec.mat'), 'matlabbatch');

% Inference
% --------------------------------------------------------------------------
results.spmmat = cellstr(SPM_mat);
results.conspec.contrasts = Inf;
results.conspec.threshdesc = 'FWE';

matlabbatch{3}.spm.stats.results = results;

results.spmmat = cellstr(SPM_mat);
results.conspec.contrasts  = 3;
results.conspec.threshdesc = 'none';
results.conspec.thresh     = 0.001;
results.conspec.extent     = 0;
results.conspec.mask.contrasts = 5;
results.conspec.mask.mtype     = 0;
results.conspec.mask.thresh    = 0.001;

matlabbatch{4}.spm.stats.results = results;

con.spmmat = cellstr(SPM_mat);
con.consess{1}.fcon.name = 'Movement-related effects';
con.consess{1}.fcon.weights = [zeros(6, 3 * 4) eye(6)];

matlabbatch{5}.spm.stats.con = con;

results.spmmat = cellstr(SPM_mat);
results.conspec.contrasts = 17;
results.conspec.threshdesc = 'FWE';

matlabbatch{6}.spm.stats.results = results;

% Run
% --------------------------------------------------------------------------
save('face_batch_categorical.mat', 'matlabbatch');
spm_jobman('run', matlabbatch);

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                BIDS DATASET NOT YET READY FOR THIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CLASSICAL STATISTICAL ANALYSIS (PARAMETRIC)

clear matlabbatch;

% Load onsets
% --------------------------------------------------------------------------
onsets = load(fullfile(data_path, 'sots.mat'));

% Output directory
% --------------------------------------------------------------------------
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.parent = cellstr(data_path);
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.name = 'parametric';

% Model Specification (copy and edit the categorical one)
% --------------------------------------------------------------------------
batch_categ = load(fullfile(data_path, 'categorical_spec.mat'));
matlabbatch{2} = batch_categ.matlabbatch{2};

matlabbatch{2}.spm.stats.fmri_spec.sess.cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
matlabbatch{2}.spm.stats.fmri_spec.sess.cond(2).pmod.name = 'Lag';
matlabbatch{2}.spm.stats.fmri_spec.sess.cond(2).pmod.param = onsets.itemlag{2};
matlabbatch{2}.spm.stats.fmri_spec.sess.cond(2).pmod.poly = 2;
matlabbatch{2}.spm.stats.fmri_spec.sess.cond(3).pmod = struct('name', {}, 'param', {}, 'poly', {});
matlabbatch{2}.spm.stats.fmri_spec.sess.cond(4).pmod.name = 'Lag';
matlabbatch{2}.spm.stats.fmri_spec.sess.cond(4).pmod.param = onsets.itemlag{4};
matlabbatch{2}.spm.stats.fmri_spec.sess.cond(4).pmod.poly = 2;
matlabbatch{2}.spm.stats.fmri_spec.dir = cellstr(fullfile(data_path, 'parametric'));
matlabbatch{2}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];

% Model Estimation
% --------------------------------------------------------------------------
matlabbatch{3}.spm.stats.fmri_est.spmmat = cellstr(fullfile(data_path, 'parametric', 'SPM.mat'));

% Inference
% --------------------------------------------------------------------------
matlabbatch{4}.spm.stats.con.spmmat = cellstr(fullfile(data_path, 'parametric', 'SPM.mat'));
matlabbatch{4}.spm.stats.con.consess{1}.fcon.name = 'Famous Lag';
matlabbatch{4}.spm.stats.con.consess{1}.fcon.weights = [zeros(2, 6) eye(2)];

matlabbatch{5}.spm.stats.results.spmmat = cellstr(fullfile(data_path, 'parametric', 'SPM.mat'));
matlabbatch{5}.spm.stats.results.conspec.contrasts = Inf;
matlabbatch{5}.spm.stats.results.conspec.threshdesc = 'FWE';

matlabbatch{6}.spm.stats.results.spmmat = cellstr(fullfile(data_path, 'parametric', 'SPM.mat'));
matlabbatch{6}.spm.stats.results.conspec.contrasts  = 9;
matlabbatch{6}.spm.stats.results.conspec.threshdesc = 'none';
matlabbatch{6}.spm.stats.results.conspec.thresh     = 0.001;
matlabbatch{6}.spm.stats.results.conspec.extent     = 0;
matlabbatch{6}.spm.stats.results.conspec.mask.contrasts = 5;
matlabbatch{6}.spm.stats.results.conspec.mask.thresh    = 0.05;
matlabbatch{6}.spm.stats.results.conspec.mask.mtype     = 0;

% Run
% --------------------------------------------------------------------------
save('face_batch_parametric.mat', 'matlabbatch');
% spm_jobman('interactive',matlabbatch);
spm_jobman('run', matlabbatch);

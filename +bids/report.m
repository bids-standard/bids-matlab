function report(BIDS, subj, sess, run, read_nii)
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

    % __________________________________________________________________________
    %
    % BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
    %   The brain imaging data structure, a format for organizing and
    %   describing outputs of neuroimaging experiments.
    %   K. J. Gorgolewski et al, Scientific Data, 2016.
    % __________________________________________________________________________

    % Copyright (C) 2018, Remi Gau
    % Copyright (C) 2018--, BIDS-MATLAB developers

    % TODO
    % --------------------------------------------------------------------------
    % - deal with DWI bval/bvec values not read by bids.query
    % - write output to a txt file?
    % - deal with "EEG" / "MEG"
    % - deal with "events": compute some summary statistics as suggested in
    % COBIDAS report
    % - report summary statistics on participants as suggested in COBIDAS report
    % - check if all subjects have the same content?
    % - adapt for several subjects or runs
    % - take care of other recommended metafield in BIDS specs or COBIDAS?

    % -Check inputs
    % --------------------------------------------------------------------------
    if ~nargin
        BIDS = pwd;
    end
    if nargin < 2 || isempty(subj)
        subj = 1;
    end
    if nargin < 3 || isempty(sess)
        sess = 1;
    end
    if nargin < 4 || isempty(run)
        run = 1;
    end
    if nargin < 5
        read_nii = true;
    end
    read_nii = read_nii & exist('spm_vol', 'file') == 2;

    % -Parse the BIDS dataset directory
    % --------------------------------------------------------------------------
    if ~isstruct(BIDS)
        fprintf('\n-------------------------\n');
        fprintf('  Reading BIDS: %s', BIDS);
        fprintf('\n-------------------------\n');
        BIDS = bids.layout(BIDS);
        fprintf('Done.\n\n');
    end

    % -Get sessions
    % --------------------------------------------------------------------------
    subjs_ls = bids.query(BIDS, 'subjects');
    sess_ls = bids.query(BIDS, 'sessions', 'sub', subjs_ls(subj));
    if isempty(sess_ls)
        sess_ls = {''};
    end
    if sess == 0
        sess = 1:numel(sess_ls);
    end

    % -Scanner details
    % --------------------------------------------------------------------------
    % str = 'MR data were acquired using a {tesla}-Tesla {manu} {model} MRI scanner.';

    % -Loop through all the required sessions
    % --------------------------------------------------------------------------
    for iSess = sess

        if numel(sess) ~= 1 && ~strcmp(sess_ls{iSess}, '')
            fprintf('\n-------------------------\n');
            fprintf('  Working on session: %s', sess_ls{iSess});
            fprintf('\n-------------------------\n');
        end

        types_ls = bids.query(BIDS, 'types', 'sub', subjs_ls(subj), 'ses', sess_ls(iSess));
        tasks_ls = bids.query(BIDS, 'tasks', 'sub', subjs_ls(subj), 'ses', sess_ls(iSess));
        % mods_ls = bids.query(BIDS,'modalities');

        for iType = 1:numel(types_ls)

            boilerplate_text = get_boilerplate(type);

            switch types_ls{iType}

                case {'T1w' 'inplaneT2' 'T1map' 'FLASH'}

                    % -Anatomical
                    % ----------------------------------------------------------
                    fprintf('Working on anat...\n');

                    % get the parameters
                    acq_param = get_acq_param(BIDS, subjs_ls{subj}, sess_ls{iSess}, ...
                                              types_ls{iType}, '', '', read_nii);

                    % print output
                    fprintf('\n ANAT REPORT \n');
                    fprintf(boilerplate_text, ...
                            acq_param.type, acq_param.variants, acq_param.seqs, ...
                            acq_param.n_slices, acq_param.tr, ...
                            acq_param.te, acq_param.fa, ...
                            acq_param.fov, acq_param.ms, acq_param.vs);
                    fprintf('\n');

                case 'bold'
                    % -Functional
                    % ----------------------------------------------------------
                    fprintf('Working on func...\n');

                    % loop through the tasks
                    for iTask = 1:numel(tasks_ls)

                        runs_ls = bids.query(BIDS, 'runs', 'sub', subjs_ls{subj}, 'ses', sess_ls{iSess}, ...
                                             'type', 'bold', 'task', tasks_ls{iTask});

                        if isempty(runs_ls)
                            % get the parameters for that task
                            acq_param = get_acq_param(BIDS, subjs_ls{subj}, sess_ls{iSess}, ...
                                                      'bold', tasks_ls{iTask}, '', read_nii);

                            % compute the number of BOLD run for that task
                            acq_param.run_str = '1';

                        else % if there is more than 1 run
                            % get the parameters for that task
                            acq_param = get_acq_param(BIDS, subjs_ls{subj}, sess_ls{iSess}, ...
                                                      'bold', tasks_ls{iTask}, runs_ls{run}, read_nii);
                            % compute the number of BOLD run for that task
                            acq_param.run_str = num2str(numel(runs_ls));
                        end

                        % set run duration
                        if ~strcmp(acq_param.tr, '[XXXX]') && ~strcmp(acq_param.n_vols, '[XXXX]')
                            acq_param.length = num2str(str2double(acq_param.tr) / 1000 * str2double(acq_param.n_vols) / 60);
                        end

                        % print output
                        fprintf('\n FUNC REPORT \n');
                        fprintf(boilerplate_text, ...
                                acq_param.run_str, acq_param.task, acq_param.variants, acq_param.seqs, ...
                                acq_param.n_slices, acq_param.so_str, acq_param.tr, ...
                                acq_param.te, acq_param.fa, ...
                                acq_param.fov, acq_param.ms, ...
                                acq_param.vs, acq_param.mb_str, acq_param.pr_str, ...
                                acq_param.length, ...
                                acq_param.n_vols);
                        fprintf('\n\n');
                    end

                case 'phasediff'
                    % -Fieldmap
                    % ----------------------------------------------------------
                    fprintf('Working on fmap...\n');

                    % loop through the tasks
                    for iTask = 1:numel(tasks_ls)

                        runs_ls = bids.query(BIDS, 'runs', 'sub', subjs_ls{subj}, 'ses', sess_ls{iSess}, ...
                                             'type', 'phasediff');

                        if isempty(runs_ls)
                            % get the parameters for that task
                            acq_param = get_acq_param(BIDS, subjs_ls{subj}, sess_ls{iSess}, ...
                                                      'phasediff', '', '', read_nii);
                        else
                            % get the parameters for that task
                            acq_param = get_acq_param(BIDS, subjs_ls{subj}, sess_ls{iSess}, ...
                                                      'phasediff', '', runs_ls{run}, read_nii);
                        end

                        % goes through task list to check which fieldmap is for which
                        % run
                        acq_param.for = [];
                        nb_run = [];
                        tmp = strfind(acq_param.for_str, tasks_ls{iTask});
                        if ~iscell(tmp)
                            tmp = {tmp};
                        end
                        nb_run(iTask) = sum(~cellfun('isempty', tmp)); %#ok<AGROW>
                        acq_param.for = sprintf('for %i runs of %s, ', nb_run, tasks_ls{iTask});

                        % print output
                        fprintf('\n FMAP REPORT \n');
                        fprintf(boilerplate_text, ...
                                acq_param.variants, acq_param.seqs, acq_param.phs_enc_dir, ...
                                acq_param.n_slices, acq_param.tr, ...
                                acq_param.te, acq_param.fa, acq_param.fov, acq_param.ms, ...
                                acq_param.vs, acq_param.for);
                        fprintf('\n\n');

                    end

                case 'dwi'
                    % -DWI
                    % ----------------------------------------------------------
                    fprintf('Working on dwi...\n');

                    % get the parameters
                    acq_param = get_acq_param(BIDS, subjs_ls{subj}, sess_ls{iSess}, ...
                                              'dwi', '', '', read_nii);

                    % dirty hack to try to look into the BIDS structure as bids.query does not
                    % support querying directly for bval and bvec
                    try
                        acq_param.n_vecs = num2str(size(BIDS.subjects(subj).dwi.bval, 2));
                        %             acq_param.bval_str = ???
                    catch
                        warning('Could not read the bval & bvec values.');
                    end

                    % print output
                    fprintf('\n DWI REPORT \n');
                    fprintf(boilerplate_text, ...
                            acq_param.variants, acq_param.seqs, acq_param.n_slices, acq_param.so_str, ...
                            acq_param.tr, acq_param.te, acq_param.fa, acq_param.fov, acq_param.ms, ...
                            acq_param.vs, acq_param.bval_str, acq_param.n_vecs, acq_param.mb_str);
                    fprintf('\n\n');

                case 'physio'
                    % -Physio
                    % ----------------------------------------------------------
                    warning('physio not supported yet');

                case {'headshape' 'meg' 'eeg' 'channels'}
                    % -M/EEG
                    % ----------------------------------------------------------
                    warning('MEEG not supported yet');

                case 'events'
                    % -Events
                    % ----------------------------------------------------------
                    warning('events not supported yet');
            end

        end

    end

end

function boilerplate_text = get_boilerplate(type)

    switch type

        case {'T1w' 'inplaneT2' 'T1map' 'FLASH'}
            boilerplate_text = [ ...
                                '%s %s %s structural MRI data were collected (%s slices; \n', ...
                                'repetition time, TR= %s ms; echo time, TE= %s ms; flip angle, FA=%s deg; \n', ...
                                'field of view, FOV= %s mm; matrix size= %s; voxel size= %s mm) \n\n'];

        case 'bold'
            boilerplate_text = [ ...
                                '%s run(s) of %s %s %s fMRI data were collected (%s slices acquired in \n', ...
                                'a %s fashion; repetition time, TR= %s ms; echo time, TE= %s ms;  \n', ...
                                'flip angle, FA= %s deg; field of view, FOV= %s mm; matrix size= %s; \n', ...
                                'voxel size= %s mm; multiband factor= %s; in-plane acceleration factor= %s).  \n', ...
                                'Each run was %s minutes in length, during which %s functional volumes  \n', ...
                                'were acquired. \n\n'];

        case   'phasediff'
            boilerplate_text = [ ...
                                'A %s %s field map (phase encoding: %s; %s slices; repetition time, \n', ...
                                'TR= %s ms; echo time 1 / 2, TE 1/2= %s ms; flip angle, FA= %s deg; \n', ...
                                'field of view, FOV= %s mm; matrix size= %s; \n', ...
                                'voxel size= %s mm) was acquired %s. \n\n'];

        case 'dwi'

            boilerplate_text = [ ...
                                'One run of %s %s diffusion-weighted (dMRI) data were collected \n', ...
                                '(%s  slices %s ; repetition time, TR= %s ms \n', ...
                                'echo time, TE= %s ms; flip angle, FA= %s deg; field of view, \n', ...
                                'FOV= %s mm; matrix size= %s ; voxel size= %s mm \n', ...
                                'b-values of %s acquired; %s diffusion directions; \n', ...
                                'multiband factor= %s ). \n\n'];

    end

end

function acq_param = get_acq_param(BIDS, subj, sess, type, task, run, read_gz)
    % Will get info from acquisition parameters from the BIDS structure or from
    % the NIfTI files

    % to return dummy values in case nothing was specified
    acq_param.type = type;
    acq_param.variants = '[XXXX]';
    acq_param.seqs = '[XXXX]';

    acq_param.tr = '[XXXX]';
    acq_param.te = '[XXXX]';
    acq_param.fa = '[XXXX]';

    acq_param.task  = task;

    acq_param.run_str  = '[XXXX]'; % number of runs (dealt with outside this function but initialized here)
    acq_param.so_str  = '[XXXX]'; % slice order string
    acq_param.mb_str  = '[XXXX]'; % multiband
    acq_param.pr_str  = '[XXXX]'; % parallel imaging
    acq_param.length  = '[XXXX]';

    acq_param.for_str = '[XXXX]'; % for fmap: for which run this fmap is for.
    acq_param.phs_enc_dir = '[XXXX]'; % phase encoding direction.

    acq_param.bval_str = '[XXXX]';
    acq_param.n_vecs = '[XXXX]';

    acq_param.fov = '[XXXX]';
    acq_param.n_slices = '[XXXX]';
    acq_param.ms = '[XXXX]'; % matrix size
    acq_param.vs = '[XXXX]'; % voxel size
    acq_param.n_vols  = '[XXXX]';

    % -Look into the metadata sub-structure for BOLD data
    % --------------------------------------------------------------------------
    if ismember(type, {'T1w' 'inplaneT2' 'T1map' 'FLASH' 'dwi'})

        filename = bids.query(BIDS, 'data', 'sub', subj, 'ses', sess, 'type', type);
        metadata = bids.query(BIDS, 'metadata', 'sub', subj, 'ses', sess, 'type', type);

    elseif strcmp(type, 'bold')

        filename = bids.query(BIDS, 'data', 'sub', subj, 'ses', sess, 'type', type, ...
                              'task', task, 'run', run);
        metadata = bids.query(BIDS, 'metadata', 'sub', subj, 'ses', sess, 'type', type, ...
                              'task', task, 'run', run);

    elseif strcmp(type, 'phasediff')

        filename = bids.query(BIDS, 'data', 'sub', subj, 'ses', sess, 'type', type, 'run', run);
        metadata = bids.query(BIDS, 'metadata', 'sub', subj, 'ses', sess, 'type', type, 'run', run);

    end

    fprintf(' - %s\n', filename{1});

    if isfield(metadata, 'EchoTime')
        acq_param.te = num2str(metadata.EchoTime * 1000);
    elseif isfield(metadata, 'EchoTime1') && isfield(metadata, 'EchoTime2')
        acq_param.te = [num2str(metadata.EchoTime1 * 1000) ' / '  num2str(metadata.EchoTime2 * 1000)];
    end

    if isfield(metadata, 'RepetitionTime')
        acq_param.tr = num2str(metadata.RepetitionTime * 1000);
    end

    if isfield(metadata, 'FlipAngle')
        acq_param.fa = num2str(metadata.FlipAngle);
    end

    if isfield(metadata, 'SliceTiming')
        acq_param.so_str = define_slice_timing(metadata.SliceTiming);
    end

    if isfield(metadata, 'PhaseEncodingDirection')
        acq_param.phs_enc_dir = metadata.PhaseEncodingDirection;
    end

    if isfield(metadata, 'IntendedFor')
        acq_param.for_str = metadata.IntendedFor;
    end

    % -Try to read the relevant NIfTI file to get more info from it
    % --------------------------------------------------------------------------
    if read_gz
        fprintf('  Opening file %s.\n', filename{1});
        try
            % read the header of the NIfTI file
            hdr = spm_vol(filename{1});
            acq_param.n_vols  = num2str(numel(hdr)); % nb volumes

            hdr = hdr(1);
            dim = abs(hdr.dim);
            acq_param.n_slices = sprintf('%i', dim(3)); % nb slices
            acq_param.ms = sprintf('%i X %i', dim(1), dim(2)); % matrix size

            vs = abs(diag(hdr.mat));
            acq_param.vs = sprintf('%.2f X %.2f X %.2f', vs(1), vs(2), vs(3)); % voxel size

            acq_param.fov = sprintf('%.2f X %.2f', vs(1) * dim(1), vs(2) * dim(2)); % field of view

        catch
            warning('Could not read the header from file %s.\n', filename{1});
        end
    end
end

function ST_def = define_slice_timing(slice_timing)
    % Try to figure out the order the slices were acquired from their timing
    if iscell(slice_timing)
        slice_timing = cell2mat(slice_timing);
    end
    [~, I] = sort(slice_timing);
    if all(I == (1:numel(I))')
        ST_def = 'ascending';
    elseif all(I == (numel(I):-1:1)')
        ST_def = 'descending';
    elseif I(1) < I(2)
        ST_def = 'interleaved ascending';
    elseif I(1) > I(2)
        ST_def = 'interleaved descending';
    else
        ST_def = '????';
    end

end

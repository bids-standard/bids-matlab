function report(BIDS, subj, sess, run, read_nii, output_path)
  % Create a short summary of the acquisition parameters of a BIDS dataset
  % FORMAT bids.report(BIDS, Subj, Ses, Run, ReadNII)
  %
  % INPUTS:
  % - BIDS: directory formatted according to BIDS [Default: pwd]
  %
  % - subj: Specifies which subject(s) to take as template.
  %
  % - sess:  Specifies which session(s) to take as template. Can be a vector.
  %         Set to 0 to do all sessions.
  %
  % - run:  Specifies which BOLD run(s) to take as template.
  %
  % - read_nii: If set to 1 (default) the function will try to read the
  %             NIfTI file to get more information. This relies on the
  %             spm_vol.m function from SPM.
  %
  % - output_file: filename where the output should be printed. If empty
  % (default) then the output is send to the prompt.
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
  % - add a dataset description (ethics, grant, institution, scanner
  % details...)
  % - make it work with "modality" and not "type"

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

  if nargin < 5 || isempty(read_nii)
    read_nii = true;
  end
  read_nii = read_nii & exist('spm_vol', 'file') == 2;

  if nargin < 6
    output_path = '';
  end

  file_id = open_output_file(BIDS, output_path);

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

    types_ls = bids.query(BIDS, 'types', ...
                          'sub', subjs_ls(subj), ...
                          'ses', sess_ls(iSess));
    tasks_ls = bids.query(BIDS, 'tasks', ...
                          'sub', subjs_ls(subj), ...
                          'ses', sess_ls(iSess));
    % mods_ls = bids.query(BIDS,'modalities');

    for iType = 1:numel(types_ls)

      boilerplate_text = get_boilerplate(types_ls{iType}, file_id);

      switch types_ls{iType}

        case {'T1w' 'inplaneT2' 'T1map' 'FLASH'}

          fprintf(file_id, '\n\n\nANATOMICAL REPORT\n\n');

          % get the parameters
          acq_param = get_acq_param(BIDS, ...
                                    subjs_ls{subj}, ...
                                    sess_ls{iSess}, ...
                                    types_ls{iType}, '', '', read_nii);

          fprintf(file_id, boilerplate_text, ...
                  acq_param.type, ...
                  acq_param.variants, ...
                  acq_param.seqs, ...
                  acq_param.n_slices, ...
                  acq_param.tr, ...
                  acq_param.te, ...
                  acq_param.fa, ...
                  acq_param.fov, ...
                  acq_param.ms, ...
                  acq_param.vs);

        case 'bold'

          fprintf(file_id, '\n\n\nFUNCTIONAL REPORT\n\n');

          % loop through the tasks
          for iTask = 1:numel(tasks_ls)

            runs_ls = bids.query(BIDS, 'runs', ...
                                 'sub', subjs_ls{subj}, ...
                                 'ses', sess_ls{iSess}, ...
                                 'type', 'bold', ...
                                 'task', tasks_ls{iTask});

            run_str = '1';
            this_run = '';

            if ~isempty(runs_ls)

              this_run = runs_ls{run};

              % compute the number of BOLD run for that task
              run_str = num2str(numel(runs_ls));

            end

            % get the parameters for that task
            acq_param = get_acq_param(BIDS, ...
                                      subjs_ls{subj}, ...
                                      sess_ls{iSess}, ...
                                      'bold', tasks_ls{iTask}, ...
                                      this_run, read_nii);

            acq_param.run_str = run_str;

            % set run duration
            if ~strcmp(acq_param.tr, '[XXtrXX]') && ...
                    ~strcmp(acq_param.n_vols, '[XXn_volsXX]')

              acq_param.length = ...
                  num2str(str2double(acq_param.tr) / 1000 * ...
                          str2double(acq_param.n_vols) / 60);

            end

            fprintf(file_id, boilerplate_text, ...
                    acq_param.run_str, ...
                    acq_param.task, ...
                    acq_param.variants, ...
                    acq_param.seqs, ...
                    acq_param.n_slices, ...
                    acq_param.so_str, ...
                    acq_param.tr, ...
                    acq_param.te, ...
                    acq_param.fa, ...
                    acq_param.fov, ...
                    acq_param.ms, ...
                    acq_param.vs, ...
                    acq_param.mb_str, ...
                    acq_param.pr_str, ...
                    acq_param.length, ...
                    acq_param.n_vols);

            fprintf(file_id, '\n');

          end

        case 'phasediff'

          fprintf(file_id, '\n\n\nFIELD MAP REPORT\n\n');

          for iTask = 1:numel(tasks_ls)

            runs_ls = bids.query(BIDS, 'runs', ...
                                 'sub', subjs_ls{subj}, ...
                                 'ses', sess_ls{iSess}, ...
                                 'type', 'phasediff');

            this_run = '';
            if ~isempty(runs_ls)

              this_run = runs_ls{run};

            end

            acq_param = get_acq_param(BIDS, ...
                                      subjs_ls{subj}, ...
                                      sess_ls{iSess}, ...
                                      'phasediff', '', this_run, read_nii);

            % goes through task list to check which fieldmap is for which run
            acq_param.for = [];
            nb_run = [];
            tmp = strfind(acq_param.for_str, tasks_ls{iTask});
            if ~iscell(tmp)
              tmp = {tmp};
            end
            nb_run(iTask) = sum(~cellfun('isempty', tmp)); %#ok<AGROW>
            acq_param.for = sprintf('for %i runs of %s, ', nb_run, tasks_ls{iTask});

            fprintf(file_id, boilerplate_text, ...
                    acq_param.variants, ...
                    acq_param.seqs, ...
                    acq_param.phs_enc_dir, ...
                    acq_param.n_slices, ...
                    acq_param.tr, ...
                    acq_param.te, ...
                    acq_param.fa, ...
                    acq_param.fov, ...
                    acq_param.ms, ...
                    acq_param.vs, ...
                    acq_param.for);

          end

        case 'dwi'

          fprintf(file_id, '\n\n\nDWI REPORT\n\n');

          % get the parameters
          acq_param = get_acq_param(BIDS, ...
                                    subjs_ls{subj}, ...
                                    sess_ls{iSess}, ...
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

          fprintf(file_id, boilerplate_text, ...
                  acq_param.variants, ...
                  acq_param.seqs, ...
                  acq_param.n_slices, ...
                  acq_param.so_str, ...
                  acq_param.tr, ...
                  acq_param.te, ...
                  acq_param.fa, ...
                  acq_param.fov, ...
                  acq_param.ms, ...
                  acq_param.vs, ...
                  acq_param.bval_str, ...
                  acq_param.n_vecs, ...
                  acq_param.mb_str);

        case 'physio'

          warning('physio not supported yet');

        case {'headshape' 'meg' 'eeg' 'channels'}

          warning('MEEG not supported yet');

        case 'events'

          warning('events not supported yet');

      end

      fprintf(file_id, '\n\n');

    end

  end

end

function file_id = open_output_file(BIDS, output_path)

  file_id = 1;

  if ~isempty(output_path)

    [~, folder] = fileparts(BIDS);

    filename = fullfile( ...
                        output_path, ...
                        ['dataset-' folder '_bids-matlab_report.md']);

    file_id = fopen(filename, 'w+');

    if file_id == -1

      warning('Unable to write file %s. Will print to screen.', filename);

      file_id = 1;

    else
      fprintf('Dataset description saved in:  %s', filename);

    end

  end

end

function template = get_boilerplate(type, file_id)

  template = '';

  switch type

    case {'T1w' 'inplaneT2' 'T1map' 'FLASH'}
      template = [ ...
                  '%s %s %s structural MRI data were collected (%s slices; \n', ...
                  'repetition time, TR= %s ms; echo time, TE= %s ms; flip angle, FA=%s deg; \n', ...
                  'field of view, FOV= %s mm; matrix size= %s; voxel size= %s mm) \n\n'];

    case 'bold'
      template = [ ...
                  '%s run(s) of %s %s %s fMRI data were collected (%s slices acquired in \n', ...
                  'a %s fashion; repetition time, TR= %s ms; echo time, TE= %s ms;  \n', ...
                  'flip angle, FA= %s deg; field of view, FOV= %s mm; matrix size= %s; \n', ...
                  'voxel size= %s mm; multiband factor= %s; \n', ...
                  'in-plane acceleration factor= %s). \n', ...
                  'Each run was %s minutes in length, during which %s functional volumes  \n', ...
                  'were acquired. \n\n'];

    case   'phasediff'
      template = [ ...
                  'A %s %s field map (phase encoding: %s; %s slices; repetition time, \n', ...
                  'TR= %s ms; echo time 1 / 2, TE 1/2= %s ms; flip angle, FA= %s deg; \n', ...
                  'field of view, FOV= %s mm; matrix size= %s; \n', ...
                  'voxel size= %s mm) was acquired %s. \n\n'];

    case 'dwi'

      template = [ ...
                  'One run of %s %s diffusion-weighted (dMRI) data were collected \n', ...
                  '(%s  slices %s ; repetition time, TR= %s ms \n', ...
                  'echo time, TE= %s ms; flip angle, FA= %s deg; field of view, \n', ...
                  'FOV= %s mm; matrix size= %s ; voxel size= %s mm \n', ...
                  'b-values of %s acquired; %s diffusion directions; \n', ...
                  'multiband factor= %s ). \n\n'];

  end

  % if we save to file we don't need new lines.
  if file_id > 1
    template = strrep(template, '\n', '');
  end

end

function acq_param = get_acq_param(varargin)
  % Will get info from acquisition parameters from the BIDS structure or from
  % the NIfTI files

  [BIDS, subj, sess, type, task, run, read_gz] = deal(varargin{:});

  acq_param = set_default_acq_param(type, task);

  [filename, metadata] = get_filemane_and_metadata(BIDS, subj, sess, type, task, run);

  fprintf('  Getting parameters - %s\n\n', filename{1});

  if isfield(metadata, 'EchoTime')
    acq_param.te = num2str(metadata.EchoTime * 1000);
  elseif isfield(metadata, 'EchoTime1') && isfield(metadata, 'EchoTime2')
    acq_param.te = [ ...
                    num2str(metadata.EchoTime1 * 1000) ' / ' ...
                    num2str(metadata.EchoTime2 * 1000)];
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
    fprintf(' Opening file - %s.\n\n', filename{1});
    try
      % read the header of the NIfTI file
      hdr = spm_vol(filename{1});

      % nb volumes
      acq_param.n_vols  = num2str(numel(hdr));

      hdr = hdr(1);
      dim = abs(hdr.dim);

      % nb slices
      acq_param.n_slices = sprintf('%i', dim(3));

      % matrix size
      acq_param.ms = sprintf('%i X %i', dim(1), dim(2));

      % voxel size
      vs = abs(diag(hdr.mat));
      acq_param.vs = sprintf('%.2f X %.2f X %.2f', vs(1), vs(2), vs(3));

      % field of view
      acq_param.fov = sprintf('%.2f X %.2f', vs(1) * dim(1), vs(2) * dim(2));

    catch
      warning('Could not read the header from file %s.\n', filename{1});
    end
  end
end

function acq_param = set_default_acq_param(type, task)

  % to return dummy values in case nothing was specified
  acq_param.type = type;
  acq_param.variants = '[XXvariantsXX]';
  acq_param.seqs = '[XXseqsXX]';

  acq_param.tr = '[XXtrXX]';
  acq_param.te = '[XXteXX]';
  acq_param.fa = '[XXfaXX]';

  acq_param.task  = task;

  % number of runs (dealt with outside this function but initialized here)
  acq_param.run_str  = '[XXrun_strXX]';
  acq_param.so_str  = '[XXso_strXX]'; % slice order string
  acq_param.mb_str  = '[XXmb_strXX]'; % multiband
  acq_param.pr_str  = '[XXpr_strXX]'; % parallel imaging
  acq_param.length  = '[XXlengthXX]';

  acq_param.for_str = '[XXfor_strXX]'; % for fmap: for which run this fmap is for.
  acq_param.phs_enc_dir = '[XXphs_enc_dirXX]'; % phase encoding direction.

  acq_param.bval_str = '[XXbval_strXX]';
  acq_param.n_vecs = '[XXn_vecsXX]';

  acq_param.fov = '[XXfovXX]';
  acq_param.n_slices = '[XXn_slicesXX]';
  acq_param.ms = '[XXmsXX]'; % matrix size
  acq_param.vs = '[XXvsXX]'; % voxel size
  acq_param.n_vols  = '[XXn_volsXX]';

end

function [filename, metadata] = get_filemane_and_metadata(varargin)

  [BIDS, subj, sess, type, task, run] = deal(varargin{:});

  switch type

    case {'T1w' 'inplaneT2' 'T1map' 'FLASH' 'dwi'}

      filename = bids.query(BIDS, 'data', ...
                            'sub', subj, ...
                            'ses', sess, ...
                            'type', type);
      metadata = bids.query(BIDS, 'metadata', ...
                            'sub', subj, ...
                            'ses', sess, ...
                            'type', type);

    case 'bold'

      filename = bids.query(BIDS, 'data', ...
                            'sub', subj, ...
                            'ses', sess, ...
                            'type', type, ...
                            'task', task, ...
                            'run', run);
      metadata = bids.query(BIDS, 'metadata', ...
                            'sub', subj, ...
                            'ses', sess, ...
                            'type', type, ...
                            'task', task, ...
                            'run', run);

    case   'phasediff'

      filename = bids.query(BIDS, 'data', ...
                            'sub', subj, ...
                            'ses', sess, ...
                            'type', type, ...
                            'run', run);
      metadata = bids.query(BIDS, 'metadata', ...
                            'sub', subj, ...
                            'ses', sess, ...
                            'type', type, ...
                            'run', run);

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

function report(BIDS, sub, ses, run, read_nii, output_path)
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

  if nargin < 2 || isempty(sub) || ~ischar(sub)
    sub = 1;
  end

  if nargin < 3 || isempty(ses) || ~ischar(ses)
    ses = 1;
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

  % -Get sessions and subjects
  % --------------------------------------------------------------------------
  if ischar(sub)
    sub_ls = sub;
    sub = 1;
  else
    sub_ls = bids.query(BIDS, 'subjects');
  end

  if ischar(ses)
    ses_ls = ses;
    ses = 1;
  else
    ses_ls = bids.query(BIDS, 'sessions', 'sub', sub_ls(sub));
  end

  if isempty(ses_ls)
    ses_ls = {''};
  end
  if ses == 0
    ses = 1:numel(ses_ls);
  end

  % -Scanner details
  % --------------------------------------------------------------------------
  % str = 'MR data were acquired using a {tesla}-Tesla {manu} {model} MRI scanner.';

  % -Loop through all the required sessions
  % --------------------------------------------------------------------------
  for iSess = ses

    if numel(ses) ~= 1 && ~strcmp(ses_ls{iSess}, '')
      fprintf('\n-------------------------\n');
      fprintf('  Working on session: %s', ses_ls{iSess});
      fprintf('\n-------------------------\n');
    end

    types_ls = bids.query(BIDS, 'types', ...
                          'sub', sub_ls(sub), ...
                          'ses', ses_ls(iSess));
    tasks_ls = bids.query(BIDS, 'tasks', ...
                          'sub', sub_ls(sub), ...
                          'ses', ses_ls(iSess));
    % mods_ls = bids.query(BIDS,'modalities');

    for iType = 1:numel(types_ls)

      boilerplate_text = get_boilerplate(types_ls{iType}, file_id);

      switch types_ls{iType}

        case {'T1w' 'inplaneT2' 'T1map' 'FLASH'}

          fprintf(file_id, '\nANATOMICAL REPORT\n\n');

          [this_task, this_run] = return_task_and_run_labels(types_ls{iType});

          % get the parameters
          acq_param = get_acq_param(BIDS, ...
                                    sub_ls{sub}, ...
                                    ses_ls{iSess}, ...
                                    types_ls{iType}, this_task, this_run, read_nii);

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

          fprintf(file_id, '\nFUNCTIONAL REPORT\n\n');

          % loop through the tasks
          for iTask = 1:numel(tasks_ls)

            [this_task, this_run, n_runs] = return_task_and_run_labels( ...
                                                                       types_ls{iType}, ...
                                                                       BIDS, ...
                                                                       sub_ls{sub}, ...
                                                                       ses_ls{iSess}, ...
                                                                       tasks_ls{iTask}, ...
                                                                       run);

            % get the parameters for that task
            acq_param = get_acq_param(BIDS, ...
                                      sub_ls{sub}, ...
                                      ses_ls{iSess}, ...
                                      'bold', this_task, ...
                                      this_run, read_nii);

            acq_param.n_runs = n_runs;

            % set run duration
            if ~strcmp(acq_param.tr, '[XXtrXX]') && ...
                    ~strcmp(acq_param.n_vols, '[XXn_volsXX]')

              acq_param.length = ...
                  num2str(str2double(acq_param.tr) / 1000 * ...
                          str2double(acq_param.n_vols) / 60);

            end

            fprintf(file_id, boilerplate_text, ...
                    acq_param.n_runs, ...
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

          fprintf(file_id, '\nFIELD MAP REPORT\n\n');

          for iTask = 1:numel(tasks_ls)

            [this_task, this_run] = return_task_and_run_labels(types_ls{iType}, ...
                                                               BIDS, ...
                                                               sub_ls{sub}, ...
                                                               ses_ls{iSess}, ...
                                                               tasks_ls{iTask}, ...
                                                               run);

            acq_param = get_acq_param(BIDS, ...
                                      sub_ls{sub}, ...
                                      ses_ls{iSess}, ...
                                      'phasediff', this_task, this_run, read_nii);

            % goes through task list to check which fieldmap is for which run
            acq_param.for = [];
            nb_run = [];
            tmp = strfind(acq_param.for_str, this_task);
            if ~iscell(tmp)
              tmp = {tmp};
            end
            nb_run(iTask) = sum(~cellfun('isempty', tmp)); %#ok<AGROW>
            acq_param.for = sprintf('for %i runs of %s, ', nb_run, this_task);

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

          [this_task, this_run] = return_task_and_run_labels(types_ls{iType});

          fprintf(file_id, '\nDWI REPORT\n\n');

          % get the parameters
          acq_param = get_acq_param(BIDS, ...
                                    sub_ls{sub}, ...
                                    ses_ls{iSess}, ...
                                    'dwi', this_task, this_run, read_nii);

          % dirty hack to try to look into the BIDS structure as bids.query does not
          % support querying directly for bval and bvec
          try
            acq_param.n_vecs = num2str(size(BIDS.subjects(sub).dwi.bval, 2));
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

      fprintf(file_id, '\n');

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

function [task, this_run, n_runs] = return_task_and_run_labels(type, BIDS, sub, ses, task, run)

  if nargin < 4
    task = '';
  end

  this_run = '';
  n_runs = '';

  switch type

    case 'bold'

      runs_ls = bids.query(BIDS, 'runs', ...
                           'sub', sub, ...
                           'ses', ses, ...
                           'type', type, ...
                           'task', task);

    case 'phasediff'

      runs_ls = bids.query(BIDS, 'runs', ...
                           'sub', sub, ...
                           'ses', ses, ...
                           'type', type);
  end

  if any(strcmp(type, {'bold', 'phasediff'}))

    if ~isempty(runs_ls)
      this_run = runs_ls{run};
      if strcmp(type, {'bold'})
        n_runs = num2str(numel(runs_ls));
      end
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

  fields_list = { ...
                 'te', 'EchoTime'; ...
                 'tr', 'RepetitionTime'; ...
                 'fa', 'FlipAngle'; ...
                 'so_str', 'SliceTiming'; ...
                 'phs_enc_dir', 'PhaseEncodingDirection'; ...
                 'for_str', 'IntendedFor'};

  acq_param = get_parameter(acq_param, metadata, fields_list);

  if isfield(metadata, 'EchoTime1') && isfield(metadata, 'EchoTime2')
    acq_param.te = [metadata.EchoTime1 metadata.EchoTime2];
  end

  acq_param = convert_field_to_millisecond(acq_param, {'tr', 'te'});

  if isfield(metadata, 'EchoTime1') && isfield(metadata, 'EchoTime2')
    acq_param.te = sprintf('%0.2f / %0.2f', acq_param.te);
  end

  acq_param = convert_field_to_str(acq_param);

  acq_param.so_str = define_slice_timing(acq_param.so_str);

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
  acq_param.n_runs  = '[XXn_runsXX]';
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

function acq_param = get_parameter(acq_param, metadata, fields_list)

  for iField = 1:size(fields_list, 1)

    if isfield(metadata, fields_list{iField})
      acq_param.(fields_list{iField, 1}) = metadata.(fields_list{iField, 2});
    end

  end

end

function acq_param = convert_field_to_str(acq_param)

  fields_list = fieldnames(acq_param);

  for iField = 1:numel(fields_list)
    if isnumeric(acq_param.(fields_list{iField}))
      acq_param.(fields_list{iField}) = num2str(acq_param.(fields_list{iField}));
    end
  end
end

function acq_param = convert_field_to_millisecond(acq_param, fields_list)

  for iField = 1:numel(fields_list)
    if isnumeric(acq_param.(fields_list{iField}))
      acq_param.(fields_list{iField}) = acq_param.(fields_list{iField}) * 1000;
    end
  end

end

function so_str = define_slice_timing(slice_timing)

  so_str = slice_timing;
  if strcmp(so_str, '[XXso_strXX]')
    return
  end

  % Try to figure out the order the slices were acquired from their timing
  if iscell(so_str)
    so_str = cell2mat(so_str);
  end

  [~, I] = sort(so_str);

  if all(I == (1:numel(I))')
    so_str = 'ascending';

  elseif all(I == (numel(I):-1:1)')
    so_str = 'descending';

  elseif I(1) < I(2)
    so_str = 'interleaved ascending';

  elseif I(1) > I(2)
    so_str = 'interleaved descending';

  else
    so_str = '????';

  end

end

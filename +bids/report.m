function report(varargin)
  %
  % Create a short summary of the acquisition parameters of a BIDS dataset
  %
  % USAGE::
  %
  %     bids.report(BIDS, sub, ses, output_path, 'read_nifti', true, 'verbose', true)
  %
  % INPUTS:
  % - BIDS: path to BIDS dataset or output of bids.layout [Default: pwd]
  %
  % - sub: Specifies which the subject label to take as template. [Default is the first subject]
  %
  % - ses: Specifies which the session label to take as template.
  %
  % - read_nii: If set to 1 (default) the function will try to read the
  %             NIfTI file to get more information. This relies on the
  %             spm_vol.m function from SPM.
  %
  % - output_path: folder where the report should be printed. If empty
  %                (default) then the output is sent to the prompt.
  %
  % Unless specified the function will only read the data from the first
  % subject, session, and run (for each task of BOLD). This can be an issue
  % if different subjects/sessions contain very different data.
  %
  % See also:
  % bids
  %
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  % TODO
  % --------------------------------------------------------------------------
  % - deal with DWI bval/bvec values not read by bids.query
  % - deal with "EEG" / "MEG"
  % - deal with "events": compute some summary statistics as suggested in COBIDAS report
  % - report summary statistics on participants as suggested in COBIDAS report
  % - check if all subjects have the same content?
  % - take care of other recommended metafield in BIDS specs or COBIDAS?
  % - add a dataset description (ethics, grant, institution, scanner details...)

  default_BIDS = pwd;
  default_sub = false;
  default_ses = false;
  default_output_path = '';
  default_read_nifti = true;
  default_verbose = false;

  p = inputParser;

  addOptional(p, 'BIDS', default_BIDS, @ischar);
  addOptional(p, 'sub', default_sub, @ischar);
  addOptional(p, 'ses', default_ses, @ischar);
  addOptional(p, 'output_path', default_output_path, @ischar);

  %   addOptional(p, 'filter', default_filter, @isstruct);

  addParameter(p, 'read_nifti', default_read_nifti);
  addParameter(p, 'verbose', default_verbose);

  parse(p, varargin{:});

  % -Parse the BIDS dataset directory
  % --------------------------------------------------------------------------
  BIDS = p.Results.BIDS;
  if ~isstruct(p.Results.BIDS)
    BIDS = bids.layout(p.Results.BIDS);
  end

  sub = select_subject(BIDS, p);

  [ses, nb_ses] = select_session(BIDS, p, sub);

  read_nii = p.Results.read_nifti & exist('spm_vol', 'file') == 2;

  file_id = open_output_file(BIDS, p.Results.output_path, p.Results.verbose);

  for iSess = 1:nb_ses

    clear filter;

    filter.sub = sub;

    if ~isempty(ses)
      filter.ses = ses{iSess};

      if nb_ses > 1
        text = sprintf('\n Working on session: %s\n', ses{iSess});
        print_to_output(text, 1, p.Results.verbose);
      end

    end

    suffixes = bids.query(BIDS, 'suffixes', filter);

    for iType = 1:numel(suffixes)

      filter.suffix = suffixes{iType};

      tasks = bids.query(BIDS, 'tasks', filter);

      boilerplate_text = get_boilerplate(suffixes{iType});

      switch suffixes{iType}

        case {'T1w' 'inplaneT2' 'T1map' 'FLASH'}

          fprintf(file_id, '\nANATOMICAL REPORT\n\n');

          [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);

          % get the parameters
          acq_param = get_acq_param(BIDS, filter, read_nii, p.Results.verbose);

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
          for iTask = 1:numel(tasks)

            filter.task = tasks{iTask};
            [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);

            % get the parameters for that task
            acq_param = get_acq_param(BIDS, filter, read_nii, p.Results.verbose);

            acq_param.n_runs = num2str(nb_runs);

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

          [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);

          acq_param = get_acq_param(BIDS, filter, read_nii, p.Results.verbose);

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

        case 'dwi'

          fprintf(file_id, '\nDWI REPORT\n\n');

          % get the parameters
          acq_param = get_acq_param(BIDS, filter, read_nii, p.Results.verbose);

          % dirty hack to try to look into the BIDS structure as bids.query does not
          % support querying directly for bval and bvec
          try
            acq_param.n_vecs = num2str(size(BIDS.subjects(sub).dwi.bval, 2));
            %             acq_param.bval_str = ???
          catch
            bids.internal.warning('Could not read the bval & bvec values.', p.Results.verbose);
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
          bids.internal.warning('physio not supported yet', p.Results.verbose);

        case {'headshape' 'meg' 'eeg' 'channels'}
          bids.internal.warning('MEEG not supported yet', p.Results.verbose);

        case 'events'
          bids.internal.warning('events not supported yet', p.Results.verbose);

      end

      print_to_output('\n', file_id, p.Results.verbose);

    end

  end

  print_credit(file_id, p.Results.verbose);

end

function print_credit(file_id, verbose)
  boilerplate_text = get_boilerplate('credit');
  text = [boilerplate_text '\n'];
  print_to_output(text, file_id, verbose);
end

function print_to_output(text, file_id, verbose)
  fprintf(file_id,  text);
  if verbose && file_id ~= 1
    fprintf(1, text);
  end
end

function sub = select_subject(BIDS, p)

  sub = p.Results.sub;
  if isempty(p.Results.sub)
    subjects = bids.query(BIDS, 'subjects');
    sub = subjects{1};
  end

end

function [ses, nb_ses] = select_session(BIDS, p, sub)

  ses = p.Results.ses;
  sessions = bids.query(BIDS, 'sessions', 'sub', sub);
  if isempty(ses) || ~ismember(ses, sessions)
    ses = sessions;
  end
  if ischar(ses)
    ses = {ses};
  end

  nb_ses = numel(ses);
  if nb_ses < 1
    nb_ses = 1;
  end

end

function file_id = open_output_file(BIDS, output_path, verbose)

  file_id = 1;

  if ~isempty(output_path)

    bids.util.mkdir(output_path);

    [~, folder] = fileparts(BIDS.dir);

    filename = fullfile( ...
                        output_path, ...
                        ['dataset-' folder '_bids-matlab_report.md']);

    file_id = fopen(filename, 'w+');

    if file_id == -1

      bids.internal.warning('Unable to write file %s. Will print to screen.', verbose);

      file_id = 1;

    else
      if verbose
        fprintf('Dataset description saved in:  %s\n\n', filename);
      end

    end

  end

end

function [filter, nb_runs] = update_filter_with_run_label(BIDS, filter)

  runs_ls = bids.query(BIDS, 'runs', filter);
  nb_runs = 0;

  if ~isempty(runs_ls)
    filter.run = runs_ls{1};
    nb_runs = numel(runs_ls);
  else
    if isfield(filter, 'run')
      filter = rmfield(filter, 'run');
    end
  end

end

function template = get_boilerplate(suffix)

  file = '';

  switch suffix

    case 'institution'
      file = 'institution.tmp';

    case {'T1w' 'inplaneT2' 'T1map' 'FLASH'}
      file = 'anat.tmp';

    case 'bold'
      file = 'func.tmp';

    case   'phasediff'
      file = 'fmap.tmp';

    case 'dwi'
      file = 'dwi.tmp';

    case 'credit'
      file = 'credit.tmp';

  end

  if ~isempty(file)
    fid = fopen(fullfile(fileparts(mfilename('fullpath')), '..', ...
                         'templates', 'boilerplates', file));
    C = textscan(fid, '%s');
    fclose(fid);
    template = strjoin(C{1}, ' ');
  else
    template = '';
  end

end

function acq_param = get_acq_param(BIDS, filter, read_gz, verbose)
  % Will get info from acquisition parameters from the BIDS structure or from
  % the NIfTI files

  acq_param = set_default_acq_param(filter);

  [filename, metadata] = get_filemane_and_metadata(BIDS, filter);

  if verbose
    fprintf('  Getting parameters - %s\n\n', filename{1});
  end

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

  acq_param = read_nifti(read_gz, filename{1}, acq_param, verbose);

end

function acq_param = read_nifti(read_gz, filename, acq_param, verbose)

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
      bids.internal.warning(sprintf('Could not read the header from file %s.\n', filename{1}), ...
                            verbose);
    end
  end

end

function acq_param = set_default_acq_param(filter)

  % to return dummy values in case nothing was specified
  acq_param.type = filter.suffix;
  acq_param.variants = '[XXvariantsXX]';
  acq_param.seqs = '[XXseqsXX]';

  acq_param.tr = '[XXtrXX]';
  acq_param.te = '[XXteXX]';
  acq_param.fa = '[XXfaXX]';

  acq_param.task  = '';
  if isfield(filter, 'task')
    acq_param.task  = filter.task;
  end

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

function [filename, metadata] = get_filemane_and_metadata(BIDS, filter)

  filename = bids.query(BIDS, 'data', filter);
  metadata = bids.query(BIDS, 'metadata', filter);

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

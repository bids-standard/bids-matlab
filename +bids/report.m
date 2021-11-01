function filename = report(varargin)
  %
  % Create a short summary of the acquisition parameters of a BIDS dataset.
  %
  % The output can be saved to a markdown file and/or printed to the screen.
  %
  % USAGE::
  %
  %     bids.report(BIDS,
  %                 'filter', filter, ...
  %                 'output_path', output_path, ...
  %                 'read_nifti', read_nifti, ...
  %                 'verbose', verbose);
  %
  % :param BIDS:  Path to BIDS dataset or output of bids.layout [Default = pwd]
  % :type  BIDS:  string or structure
  % :param filter: Specifies which the subject, session, ... to take as template.
  %                [Default = struct('sub', '', 'ses', '')]. See bids.query
  %                for more information.
  % :type  sub:   structure
  % :type  ses:   string
  % :param output_path:  Folder where the report should be printed. If empty
  %                      (default) then the output is sent to the prompt.
  % :type  output_path:  string
  % :param read_nifti:  If set to ``true`` (default) the function will try to read the
  %                     NIfTI file to get more information. This relies on the
  %                     ``spm_vol.m`` function from SPM.
  % :type  read_nifti:  boolean
  % :param read_nifti:  If set to ``false`` (default) the function does not
  %                     output anything to the prompt.
  % :type  read_nifti:  boolean
  % :param verbose:
  % :type  verbose:  boolean
  %
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  % TODO
  % --------------------------------------------------------------------------
  % - deal with DWI bval/bvec values not read by bids.query
  % - enhance with "EEG" / "MEG"
  % - add task description
  % - deal with "events": compute some summary statistics as suggested in COBIDAS report
  % - report summary statistics on participants as suggested in COBIDAS report
  % - check if all subjects have the same content?
  % - take care of other recommended metafield in BIDS specs or COBIDAS?
  % - add a dataset description (ethics, grant, scanner details...)

  default_BIDS = pwd;
  default_filter = struct('sub', '', 'ses', '');
  default_output_path = '';
  default_read_nifti = false;
  default_verbose = false;

  p = inputParser;

  charOrStruct = @(x) ischar(x) || isstruct(x);

  addOptional(p, 'BIDS', default_BIDS, charOrStruct);
  addParameter(p, 'output_path', default_output_path, @ischar);
  addParameter(p, 'filter', default_filter, @isstruct);
  addParameter(p, 'read_nifti', default_read_nifti);
  addParameter(p, 'verbose', default_verbose);

  parse(p, varargin{:});

  BIDS = bids.layout(p.Results.BIDS);

  filter = check_filter(BIDS, p);

  nb_sub = numel(filter.sub);

  read_nii = p.Results.read_nifti & exist('spm_vol', 'file') == 2;

  file_id = open_output_file(BIDS, p.Results.output_path, p.Results.verbose);

  for i_sub = 1:nb_sub

    this_filter = filter;
    this_filter.sub = filter.sub{i_sub};

    sessions = bids.query(BIDS, 'sessions', this_filter);
    
    if isempty(sessions)
        sessions = {''};
    end

    for i_sess = 1:numel(sessions)

      this_filter.ses = sessions{i_sess};

      if numel(sessions) > 1
        text = sprintf('\n Working on session: %s\n', this_filter.ses);
        print_to_output(text, file_id, p.Results.verbose);
      end

      modalities = bids.query(BIDS, 'modalities', this_filter);

      for i_modality = 1:numel(modalities)

        this_filter.modality = modalities(i_modality);

        print_to_output(['\n' upper(this_filter.modality{1}) ' REPORT\n\n'], ...
                        file_id, ...
                        p.Results.verbose);

        switch this_filter.modality{1}

          case  {'anat'}
            report_anat(BIDS, this_filter, read_nii, p.Results.verbose, file_id);

          case  {'func'}
            report_func(BIDS, this_filter, read_nii, p.Results.verbose, file_id);

          case  {'eeg', 'meg', 'ieeg'}
            report_meeg(BIDS, this_filter, p.Results.verbose, file_id);

          case {'perf'}
            report_perf(BIDS, this_filter, read_nii, p.Results.verbose, file_id);

          case  {'dwi'}
            report_dwi(BIDS, this_filter, read_nii, p.Results.verbose, file_id);

          case {'fmap'}
            report_fmap(BIDS, this_filter, read_nii, p.Results.verbose, file_id);

          case  {'pet', 'beh'}
            not_supported(this_filter.modality{1}, p.Results.verbose);

          otherwise
            not_supported(this_filter.modality{1}, p.Results.verbose);

        end

      end

    end

    print_to_output('\n', file_id, p.Results.verbose);

  end

  print_credit(file_id, p.Results.verbose);

end

% TODO refactor the different reports

function report_fmap(BIDS, filter, read_nii, verbose, file_id)

  suffixes = bids.query(BIDS, 'suffixes', filter);

  for iType = 1:numel(suffixes)

    filter.suffix = suffixes{iType};
    boilerplate = get_boilerplate(filter.modality{1}, verbose);

    [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);
    acq_param.n_runs = num2str(nb_runs);

    [~, metadata] = get_filemane_and_metadata(BIDS, filter);
    boilerplate = replace_placeholders(boilerplate, metadata);

    acq_param = get_acq_param(BIDS, filter, read_nii, p.Results.verbose);

    % acq_param.for = sprintf('for %i runs of %s, ', nb_runs, this_task);
    acq_param.for = 'TODO';

    text = sprintf(boilerplate, ...
                   acq_param.n_slices, ...
                   acq_param.te, ...
                   acq_param.fov, ...
                   acq_param.ms, ...
                   acq_param.vs, ...
                   acq_param.for);

    print_base_report(file_id, metadata, p.Results.verbose);
    print_to_output(text, file_id, p.Results.verbose);

  end
end

function report_dwi(BIDS, filter, read_nii, verbose, file_id)

  suffixes = bids.query(BIDS, 'suffixes', filter);

  for iType = 1:numel(suffixes)

    filter.suffix = suffixes{iType};
    boilerplate = get_boilerplate(filter.modality{1}, verbose);

    [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);
    acq_param.n_runs = num2str(nb_runs);

    [~, metadata] = get_filemane_and_metadata(BIDS, filter);
    boilerplate = replace_placeholders(boilerplate, metadata);

    acq_param = get_acq_param(BIDS, filter, read_nii, verbose);

    % dirty hack to try to look into the BIDS structure as bids.query does not
    % support querying directly for bval and bvec
    try
      acq_param.n_vecs = num2str(size(BIDS.subjects(sub).dwi.bval, 2));
      %             acq_param.bval_str = ???
    catch
      msg = 'Could not read the bval & bvec values.';
      bids.internal.error_handling(mfilename, ...
                                   'cannotReadBvalBvec', ...
                                   msg, ...
                                   true, ...
                                   verbose);
    end

    text = sprintf(boilerplate, ...
                   acq_param.n_slices, ...
                   acq_param.so_str, ...
                   acq_param.te, ...
                   acq_param.fov, ...
                   acq_param.ms, ...
                   acq_param.vs, ...
                   acq_param.bval_str, ...
                   acq_param.n_vecs, ...
                   acq_param.mb_str);

    print_base_report(file_id, metadata, verbose);
    print_to_output(text, file_id, verbose);

  end
end

function report_meeg(BIDS, filter, verbose, file_id)

  suffixes = bids.query(BIDS, 'suffixes', filter);

  for iType = 1:numel(suffixes)

    filter.suffix = suffixes{iType};

    boilerplate = get_boilerplate(filter.modality{1}, verbose);
    % beh and bold should not be there
    % this seems like a bug of bids.query
    if ismember(filter.suffix, {'bold', 'beh', 'events', 'physio', 'channels', 'headshape'})
      continue
    end

    tasks = bids.query(BIDS, 'tasks', filter);

    for iTask = 1:numel(tasks)

      filter.task = tasks{iTask};
      [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);
      acq_param.n_runs = num2str(nb_runs);

      [~, metadata] = get_filemane_and_metadata(BIDS, filter);
      boilerplate = replace_placeholders(boilerplate, metadata);

      acq_param = get_acq_param(BIDS, filter, false, verbose);
      acq_param.n_runs = num2str(nb_runs);

      text = sprintf(boilerplate, ...
                     acq_param.n_runs, ...
                     filter.modality{1});

      print_base_report(file_id, metadata, verbose);
      print_to_output(text, file_id, verbose);

    end

  end
end

function report_perf(BIDS, filter, read_nii, verbose, file_id)

  suffixes = bids.query(BIDS, 'suffixes', filter);

  for iType = 1:numel(suffixes)

    filter.suffix = suffixes{iType};
    boilerplate = get_boilerplate(filter.modality{1}, verbose);

    [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);

    [~, metadata] = get_filemane_and_metadata(BIDS, filter);
    boilerplate = replace_placeholders(boilerplate, metadata);

    acq_param = get_acq_param(BIDS, filter, read_nii, verbose);
    acq_param.n_runs = num2str(nb_runs);

    text = sprintf(boilerplate, ...
                   acq_param.n_slices, ...
                   acq_param.te, ...
                   acq_param.fov, ...
                   acq_param.ms, ...
                   acq_param.vs);

    print_base_report(file_id, metadata, verbose);
    print_to_output(text, file_id, verbose);

  end

end

function report_anat(BIDS, filter, read_nii, verbose, file_id)

  suffixes = bids.query(BIDS, 'suffixes', filter);

  for iType = 1:numel(suffixes)

    filter.suffix = suffixes{iType};
    boilerplate = get_boilerplate(filter.modality{1}, verbose);

    [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);

    [~, metadata] = get_filemane_and_metadata(BIDS, filter);
    boilerplate = replace_placeholders(boilerplate, metadata);

    acq_param = get_acq_param(BIDS, filter, read_nii, verbose);
    acq_param.n_runs = num2str(nb_runs);

    text = sprintf(boilerplate, ...
                   acq_param.n_slices, ...
                   acq_param.te, ...
                   acq_param.fov, ...
                   acq_param.ms, ...
                   acq_param.vs);

    print_base_report(file_id, metadata, verbose);
    print_to_output(text, file_id, verbose);

  end

end

function report_func(BIDS, filter, read_nii, verbose, file_id)

  suffixes = bids.query(BIDS, 'suffixes', filter);

  for iType = 1:numel(suffixes)

    filter.suffix = suffixes{iType};
    boilerplate = get_boilerplate(filter.modality{1}, verbose);

    % beh, 'channels', 'headshape' should not be there
    % this seems like a bug of bids.query
    if ismember(filter.suffix, {'beh', 'events', 'physio', 'channels', 'headshape'})
      continue
    end

    tasks = bids.query(BIDS, 'tasks', filter);

    % add mention of contrast
    for iTask = 1:numel(tasks)

      this_filter.task = tasks{iTask};
      [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);
      acq_param.n_runs = num2str(nb_runs);

      [~, metadata] = get_filemane_and_metadata(BIDS, filter);
      boilerplate = replace_placeholders(boilerplate, metadata);

      acq_param = get_acq_param(BIDS, this_filter, read_nii, verbose);

      % set run duration
      %             if ~strcmp(acq_param.tr, '[XXtrXX]') && ...
      %                     ~strcmp(acq_param.n_vols, '[XXn_volsXX]')
      %
      %               acq_param.length = ...
      %                   num2str(str2double(acq_param.tr) / 1000 * ...
      %                           str2double(acq_param.n_vols) / 60);
      %
      %             end

      text = sprintf(boilerplate, ...
                     acq_param.n_runs, ...
                     acq_param.n_slices, ...
                     acq_param.so_str, ...
                     acq_param.te, ...
                     acq_param.fov, ...
                     acq_param.ms, ...
                     acq_param.vs, ...
                     acq_param.mb_str, ...
                     acq_param.pr_str, ...
                     acq_param.length, ...
                     acq_param.n_vols);

      print_base_report(file_id, metadata, verbose);
      print_to_output(text, file_id, verbose);

    end

  end

end

function not_supported(thing_not_supported, verbose)
  msg = [thing_not_supported ' not supported yet'];
  bids.internal.error_handling(mfilename, ...
                               [thing_not_supported 'NotSupported'], ...
                               msg, ...
                               true, ...
                               verbose);
end

function filter = check_filter(BIDS, p)

  filter = p.Results.filter;

  if ~isfield(filter, 'sub')
    filter.sub = '';
  end
  if ~isfield(filter, 'ses')
    filter.ses = '';
  end

  if isempty(filter.sub)
    subjects = bids.query(BIDS, 'subjects');
    filter.sub = subjects(1);
  end
  if isempty(filter.ses)
    filter = set_sessions(filter, BIDS);
  end

  if ischar(filter.sub)
    filter.sub = {filter.sub};
  end
  if ischar(filter.ses)
    filter.ses = {filter.ses};
  end

end

function filter = set_sessions(filter, BIDS, sessions)
  if nargin < 3
    sessions = bids.query(BIDS, 'sessions');
  end
  if ischar(sessions)
    sessions = {sessions};
  end
  if isempty(sessions)
    sessions = {''};
  end
  filter.ses = sessions;
end

function [file_id, filename] = open_output_file(BIDS, output_path, verbose)

  file_id = 1;

  if ~isempty(output_path)

    bids.util.mkdir(output_path);

    [~, folder] = fileparts(BIDS.pth);

    filename = fullfile( ...
                        output_path, ...
                        ['dataset-' folder '_bids-matlab_report.md']);

    file_id = fopen(filename, 'w+');

    if file_id == -1

      msg = 'Unable to write file %s. Will print to screen.';
      bids.internal.error_handling(mfilename, 'cannotWriteToFile', msg, true, verbose);

      file_id = 1;

    else

      text = sprintf('Dataset description saved in:  %s\n\n', filename);
      print_to_output(text, 1, verbose);

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

function template = get_boilerplate(type, verbose)

  file = '';

  switch type

    case {'institution', 'device_info', 'func', 'anat', 'fmap', 'dwi', 'credit'}
      file = [type '.tmp'];

    case {'events', 'physio', 'channels', 'headshape'}
      % TODO
      template = '';
      not_supported(type, verbose);

    otherwise

      template = '';
      not_supported(type, verbose);

      return

  end

  if ~isempty(file)
    fid = fopen(fullfile(fileparts(mfilename('fullpath')), '..', ...
                         'templates', 'boilerplates', file));
    C = textscan(fid, '%s');
    fclose(fid);
    template = strjoin(C{1}, ' ');
  end

end

function acq_param = get_acq_param(BIDS, filter, read_gz, verbose)
  % Will get info from acquisition parameters from the BIDS structure or from
  % the NIfTI files

  acq_param = set_default_acq_param();

  [filename, metadata] = get_filemane_and_metadata(BIDS, filter);

  if verbose
    fprintf('\n  Getting parameters - %s\n\n', filename{1});
  end

  fields_list = { ...
                 'te', 'EchoTime'; ...
                 'so_str', 'SliceTiming'; ...
                 'for_str', 'IntendedFor'
                };

  acq_param = get_parameter(acq_param, metadata, fields_list);

  if isfield(metadata, 'EchoTime1') && isfield(metadata, 'EchoTime2')
    acq_param.te = [metadata.EchoTime1 metadata.EchoTime2];
  end

  % TODO
  % acq_param = convert_field_to_millisecond(acq_param, {'tr', 'te'});

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
    fprintf(' Opening file - %s.\n\n', filename);
    try
      % read the header of the NIfTI file
      hdr = spm_vol(filename);

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

      msg = sprintf('Could not read the header from file %s.\n', filename);
      bids.internal.error_handling(mfilename, 'cannotReadHeader', msg, true, verbose);

    end
  end

end

function acq_param = set_default_acq_param()

  acq_param.te = '[XXteXX]';

  % number of runs (dealt with outside this function but initialized here)
  acq_param.n_runs  = '[XXn_runsXX]';
  acq_param.so_str  = '[XXso_strXX]'; % slice order string
  acq_param.mb_str  = '[XXmb_strXX]'; % multiband
  acq_param.pr_str  = '[XXpr_strXX]'; % parallel imaging
  acq_param.length  = '[XXlengthXX]';

  acq_param.for_str = '[XXfor_strXX]'; % for fmap: for which run this fmap is for.

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
  % TODO

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

function print_to_output(text, file_id, verbose)

  text = [text '\n'];
  text = strrep(text, '{{', '');
  text = strrep(text, '}}', '');

  text = add_word_wrap(text);

  if file_id ~= 1
    fprintf(file_id,  text);
  end

  % Print to screen
  if verbose
    fprintf(1, text);
  end

end

function text = add_word_wrap(text)

  linelength = 80;

  space = strfind(text, ' ');

  linebreaks = find(diff(mod(space, linelength)) < 1) + 1;

  for i_linebreaks = 1:numel(linebreaks)

    % the line break shift the string sequence
    % so the breaks should be offsetted;
    offset = 2 * (i_linebreaks - 1);

    this_break = space(linebreaks(i_linebreaks)) + offset;

    text = [text(1:this_break), ...
            '\n', ...
            text(this_break + 1:end)];
  end
end

function boilerplate_text = replace_placeholders(boilerplate_text, metadata)

  placeholders = return_list_placeholders(boilerplate_text);

  for i = 1:numel(placeholders)

    this_placeholder = placeholders{i}{1};

    if isfield(metadata, this_placeholder) && ...
            ~isempty(metadata.(this_placeholder))

      text_to_insert = metadata.(this_placeholder);
      
      if isnumeric(text_to_insert)
          text_to_insert = num2str(text_to_insert);
      end
      
      boilerplate_text = strrep(boilerplate_text, ...
          this_placeholder,  ...
          text_to_insert);

    else
%       text_to_insert = ['XXX' placeholders{i}{1} 'XXX'];

    end



  end

end

function placeholders = return_list_placeholders(boilerplate_text)
  placeholders = regexp(boilerplate_text, '{{(\w*)}}', 'tokens');
end

function print_base_report(file_id, metadata, verbose)
  print_institution_info(file_id, metadata, verbose);
  print_device_info(file_id, metadata, verbose);
end

function print_institution_info(file_id, metadata, verbose)
  boilerplate_text = get_boilerplate('institution', verbose);
  boilerplate_text = replace_placeholders(boilerplate_text, metadata);
  print_to_output(boilerplate_text, file_id, verbose);
end

function print_device_info(file_id, metadata, verbose)
  boilerplate_text = get_boilerplate('device_info', verbose);
  boilerplate_text = replace_placeholders(boilerplate_text, metadata);
  print_to_output(boilerplate_text, file_id, verbose);
end

function print_credit(file_id, verbose)
  boilerplate_text = get_boilerplate('credit', verbose);
  print_to_output(boilerplate_text, file_id, verbose);
end

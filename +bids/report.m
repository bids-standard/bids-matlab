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
  % :type  filter:   structure
  % :param output_path:  Folder where the report should be printed. If empty
  %                      (default) then the output is sent to the prompt.
  % :type  output_path:  string
  % :param read_nifti:  If set to ``true`` (default) the function will try to read the
  %                     NIfTI file to get more information. This relies on the
  %                     ``spm_vol.m`` function from SPM.
  % :type  read_nifti:  boolean
  % :param verbose:  If set to ``false`` (default) the function does not
  %                     output anything to the prompt.
  % :type  verbose:  boolean
  %
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  % TODO
  % --------------------------------------------------------------------------
  % - deal with DWI bval/bvec values not read by bids.query
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

  [file_id, filename] = open_output_file(BIDS, p.Results.output_path, p.Results.verbose);

  if p.Results.verbose
    fprintf(1, '\n%s\n', repmat('-', 80, 1));
  end

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

        print_to_output([upper(this_filter.modality{1}) ' REPORT'], ...
                        file_id, ...
                        p.Results.verbose);

        switch this_filter.modality{1}

          case  {'anat', 'perf', 'dwi', 'fmap', 'pet'}
            report_nifti(BIDS, this_filter, read_nii, p.Results.verbose, file_id);

          case  {'func'}
            report_func(BIDS, this_filter, read_nii, p.Results.verbose, file_id);

          case  {'eeg', 'meg', 'ieeg'}
            report_meeg(BIDS, this_filter, p.Results.verbose, file_id);

          case  {'beh'}
            not_supported(this_filter.modality{1}, p.Results.verbose);

          otherwise
            not_supported(this_filter.modality{1}, p.Results.verbose);

        end

      end

    end

  end

  print_text('credit', file_id, p.Results.verbose);

end

function report_nifti(BIDS, filter, read_nii, verbose, file_id)

  suffixes = bids.query(BIDS, 'suffixes', filter);

  for iType = 1:numel(suffixes)

    filter.suffix = suffixes{iType};
    boilerplate = get_boilerplate(filter.modality{1}, verbose);

    if ismember(filter.suffix, {'blood', 'asllabeling'})
      not_supported(filter.suffix, verbose);
      continue
    end

    [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);

    [~, metadata] = get_filemane_and_metadata(BIDS, filter);
    boilerplate = bids.internal.replace_placeholders(boilerplate, metadata);

    acq_param = get_acq_param(BIDS, filter, read_nii, verbose);
    acq_param.nb_runs = num2str(nb_runs);

    switch filter.modality{1}

      case {'anat', 'perf', 'fmap', 'pet'}

        % for fmap acq_param.for = sprintf('for %i runs of %s, ', nb_runs, this_task);
        acq_param.for = 'TODO';

        text = bids.internal.replace_placeholders(boilerplate, acq_param);

      case 'dwi'

        % dirty hack to try to look into the BIDS structure as bids.query does not
        % support querying directly for bval and bvec
        try
          acq_param.nb_vecs = num2str(size(BIDS.subjects(sub).dwi.bval, 2));
          %             acq_param.bval_str = ???

        catch
          msg = 'Could not read the bval & bvec values.';
          bids.internal.error_handling(mfilename, ...
                                       'cannotReadBvalBvec', ...
                                       msg, ...
                                       true, ...
                                       verbose);
        end

        text = bids.internal.replace_placeholders(boilerplate, acq_param);

    end

    print_text('institution', file_id, verbose, metadata);

    if strcmp(filter.modality{1}, 'pet')
      % TODO task for pet
      print_text('pet_info', file_id, verbose, metadata);
    else
      print_text('mri_info', file_id, verbose, metadata);
    end

    print_to_output(text, file_id, verbose);

  end

end

function report_func(BIDS, filter, read_nii, verbose, file_id)

  suffixes = bids.query(BIDS, 'suffixes', filter);

  for iType = 1:numel(suffixes)

    filter.suffix = suffixes{iType};
    boilerplate = get_boilerplate(filter.modality{1}, verbose);

    if ismember(filter.suffix, {'physio'})
      not_supported(filter.suffix, verbose);
      continue
    end

    % events are taken care of as part by print_events_info below
    if ismember(filter.suffix, {'events'})
      continue
    end

    tasks = bids.query(BIDS, 'tasks', filter);

    % add mention of contrast
    for iTask = 1:numel(tasks)

      this_filter.task = tasks{iTask};
      [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);

      [~, metadata] = get_filemane_and_metadata(BIDS, filter);
      boilerplate = bids.internal.replace_placeholders(boilerplate, metadata);

      acq_param = get_acq_param(BIDS, this_filter, read_nii, verbose);
      acq_param.nb_runs = num2str(nb_runs);

      acq_param = set_run_duration(acq_param, metadata);

      text = bids.internal.replace_placeholders(boilerplate, acq_param);

      print_text('institution', file_id, verbose, metadata);

      print_text('mri_info', file_id, verbose, metadata);

      print_to_output(text, file_id, verbose);

      print_text('task', file_id, verbose, acq_param);

      print_events_info(file_id, BIDS, filter, verbose);

    end

  end

end

function report_meeg(BIDS, filter, verbose, file_id)

  suffixes = bids.query(BIDS, 'suffixes', filter);

  for iType = 1:numel(suffixes)

    filter.suffix = suffixes{iType};

    boilerplate = get_boilerplate(filter.modality{1}, verbose);

    if ismember(filter.suffix, {'physio', 'channels', 'headshape'})
      not_supported(filter.suffix, verbose);
      continue
    end

    % events are taken care of as part by print_events_info below
    if ismember(filter.suffix, {'events'})
      continue
    end

    tasks = bids.query(BIDS, 'tasks', filter);

    for iTask = 1:numel(tasks)

      filter.task = tasks{iTask};
      [filter, nb_runs] = update_filter_with_run_label(BIDS, filter);

      [~, metadata] = get_filemane_and_metadata(BIDS, filter);
      boilerplate = bids.internal.replace_placeholders(boilerplate, metadata);

      acq_param = get_acq_param(BIDS, filter, false, verbose);
      acq_param.nb_runs = num2str(nb_runs);

      text = bids.internal.replace_placeholders(boilerplate, acq_param);

      print_base_report(file_id, metadata, verbose);

      print_to_output(text, file_id, verbose);

      print_text('task', file_id, verbose, acq_param);

      print_events_info(file_id, BIDS, filter, verbose);

    end

  end
end

function param = set_run_duration(param, metadata)
  if isfield(param, 'nb_vols') && ~isempty(param.nb_vols)
    param.length = metadata.RepetitionTime * str2double(param.nb_vols);
    param.length = num2str(param.length / 60);
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
  filename = '';

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
  nb_runs = 1;

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

  % TODO {'physio', 'channels', 'headshape'}

  file = [type '.tmp'];

  if ismember(type, {'meg', 'eeg', 'ieeg'})
    file = 'meeg.tmp';
  end

  fid = fopen(fullfile(fileparts(mfilename('fullpath')), '..', ...
                       'templates', 'boilerplates', file));
  if fid == -1
    template = '';
    not_supported(type, verbose);
    return
  end

  C = textscan(fid, '%s');
  fclose(fid);
  template = strjoin(C{1}, ' ');

end

function param = get_acq_param(BIDS, filter, read_gz, verbose)
  % Will get info from acquisition parameters from the BIDS structure or from
  % the NIfTI files

  %   acq_param = set_default_acq_param();
  param = struct();

  [filename, metadata] = get_filemane_and_metadata(BIDS, filter);

  if verbose
    fprintf('\n Getting parameters - %s\n\n', bids.internal.file_utils(filename{1}, 'filename'));
  end

  fields_list = { ...
                 'echo_time', 'EchoTime'; ...
                 'so_str', 'SliceTiming'; ...
                 'for_str', 'IntendedFor'
                };

  param = get_parameter(param, metadata, fields_list);

  bidsFile = bids.File(filename{1});
  param.suffix = bidsFile.suffix;

  if isfield(metadata, 'EchoTime1') && isfield(metadata, 'EchoTime2')
    param.echo_time = [metadata.EchoTime1 metadata.EchoTime2];
  end

  % TODO
  % acq_param = convert_field_to_millisecond(acq_param, {'te'});

  if isfield(metadata, 'EchoTime1') && isfield(metadata, 'EchoTime2')
    param.echo_time = sprintf('%0.2f / %0.2f', param.echo_time);
  end

  param = convert_field_to_str(param);

  param = define_slice_timing(param);

  param = read_nifti(read_gz, filename{1}, param, verbose);

end

function acq_param = read_nifti(read_gz, filename, acq_param, verbose)

  % -Try to read the relevant NIfTI file to get more info from it
  % --------------------------------------------------------------------------
  if read_gz
    try
      if verbose
        fprintf('\n Opening file - %s.\n', filename);
      end
      % read the header of the NIfTI file
      hdr = spm_vol(filename);

      % nb volumes
      acq_param.nb_vols  = num2str(numel(hdr));

      hdr = hdr(1);
      dim = abs(hdr.dim);

      % nb slices
      acq_param.nb_slices = sprintf('%i', dim(3));

      % matrix size
      acq_param.mat_size = sprintf('%i X %i', dim(1), dim(2));

      % voxel size
      vs = abs(diag(hdr.mat));
      acq_param.vox_size = sprintf('%.2f X %.2f X %.2f', vs(1), vs(2), vs(3));

      % field of view
      acq_param.fov = sprintf('%.2f X %.2f', vs(1) * dim(1), vs(2) * dim(2));

    catch

      msg = sprintf('Could not read the header from file %s.\n', filename);
      bids.internal.error_handling(mfilename, 'cannotReadHeader', msg, true, verbose);

    end
  end

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

function acq_param = define_slice_timing(acq_param)

  if ~isfield(acq_param, 'so_str') || isempty(acq_param.so_str)
    return
  end

  so_str = acq_param.so_str;

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

  acq_param.so_str = so_str;

end

function print_to_output(text, file_id, verbose)

  text = [text '\n\n'];

  text = add_word_wrap(text);

  if file_id ~= 1
    if bids.internal.is_octave()
      bids.internal.error_handling(mfilename(), ...
                                   'notImplemented', ...
                                   'saving to file not implement for Ocatve', ...
                                   true, verbose);
    else
      fprintf(file_id,  text);
    end
  end

  % Print to screen
  if verbose
    fprintf(1, text);
  end

end

function text = add_word_wrap(text)

  % TODO make optional?

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

function print_base_report(file_id, metadata, verbose)
  print_text('institution', file_id, verbose, metadata);
  print_text('device_info', file_id, verbose, metadata);
end

function print_events_info(file_id, BIDS, filter, verbose)

  filter.suffix = 'events';
  [~, metadata] = get_filemane_and_metadata(BIDS, filter);
  if isfield(metadata, 'StimulusPresentation')
    print_text('events', file_id, verbose, metadata);
  end
  if isfield(metadata, 'trial_type')
    % TODO
    not_supported('trial_type description', verbose);
  end

end

function print_text(template_name, file_id, verbose, metadata)
  if nargin < 4
    metadata = struct([]);
  end
  boilerplate_text = get_boilerplate(template_name, verbose);
  if ~isempty(metadata)
    boilerplate_text = bids.internal.replace_placeholders(boilerplate_text, metadata);
  end
  print_to_output(boilerplate_text, file_id, verbose);
end

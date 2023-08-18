function [diagnostic_table, sub_ses, headers] = diagnostic(varargin)
  %
  % Create a diagnostic figure for a dataset.
  %
  % - list the number of files for each subject split by:
  %   - modality
  %   - task (optional)
  % - list the number of trials for each event type
  %
  % USAGE::
  %
  %   diagnostic_table = diagnostic(BIDS, ...
  %                                 'use_schema', true, ...
  %                                 'output_path', '', ...
  %                                 'filter', struct(), ...
  %                                 'split_by', {''})
  %
  % :param BIDS:       BIDS directory name or BIDS structure (from ``bids.layout``)
  % :type  BIDS:       structure or char
  %
  % :param split_by:   splits results by a given BIDS entity (now only ``task`` is supported)
  % :type  split_by:   cell
  %
  % :param use_schema: If set to ``true``, the parsing of the dataset
  %                    will follow the bids-schema provided with bids-matlab.
  %                    If set to ``false`` files just have to be of the form
  %                    ``sub-label_[entity-label]_suffix.ext`` to be parsed.
  %                    If a folder path is provided, then the schema contained
  %                    in that folder will be used for parsing.
  % :type  use_schema: logical
  %
  % :param out_path:   path to directory containing the derivatives
  % :type  out_path:   string
  %
  % :param filter:     list of filters to choose what files to copy (see bids.query)
  % :type  filter:     structure or cell
  %
  % :param trial_type_col:    Optional. Name of the column containing the trial type.
  %                           Defaults to ``'trial_type'``.
  % :type  trial_type_col:    char
  %
  % :param verbose:    Optional. Set to false to not show the figure.
  %                           Defaults to ``true``.
  % :type  verbose:    logical
  %
  % Example
  % -------
  %
  % .. code-block:: matlab
  %
  %   BIDS = bids.layout(path_to_dataset);
  %   diagnostic_table = bids.diagnostic(BIDS, 'output_path', pwd);
  %   diagnostic_table = bids.diagnostic(BIDS, 'split_by', {'task'}, 'output_path', pwd);
  %
  %

  % (C) Copyright 2021 BIDS-MATLAB developers

  default_BIDS = pwd;
  default_schema = false;
  default_filter = struct();
  default_split = {''};
  default_output_path = '';
  default_verbose = true;

  args = inputParser;

  charOrStruct = @(x) ischar(x) || isstruct(x);

  addOptional(args, 'BIDS', default_BIDS, charOrStruct);
  addParameter(args, 'use_schema', default_schema, @islogical);
  addParameter(args, 'output_path', default_output_path, @ischar);
  addParameter(args, 'filter', default_filter, @isstruct);
  addParameter(args, 'split_by', default_split, @iscell);
  addParameter(args, 'trial_type_col', 'trial_type', @ischar);
  addParameter(args, 'verbose', default_verbose, @islogical);

  parse(args, varargin{:});

  %%
  BIDS = bids.layout(args.Results.BIDS, 'use_schema', args.Results.use_schema, ...
                     'index_dependencies', false);

  output_path = args.Results.output_path;

  filter = args.Results.filter;

  subjects = bids.query(BIDS, 'subjects', filter);

  headers = get_headers(BIDS, filter, args.Results.split_by);

  diagnostic_table = nan(numel(subjects), numel(headers));

  trial_type_col = args.Results.trial_type_col;

  verbose = args.Results.verbose;

  visible = 'on';
  if ~verbose
    visible = 'off';
  end

  row = 1;

  %%
  for i_sub = 1:numel(subjects)

    this_filter = get_clean_filter(filter, subjects{i_sub});

    sessions = bids.query(BIDS, 'sessions', this_filter);
    if isempty(sessions)
      sessions = {''};
    end

    for i_sess = 1:numel(sessions)

      this_filter = get_clean_filter(filter, subjects{i_sub});
      this_filter.ses = sessions{i_sess};

      files = bids.query(BIDS, 'data', this_filter);

      if size(files, 1) == 0
        continue
      end

      for i_col = 1:numel(headers)

        this_filter = get_clean_filter(filter, subjects{i_sub}, sessions{i_sess});
        this_filter.modality = headers{i_col}.modality;
        if isfield(headers{i_col}, 'task')
          this_filter.task = headers{i_col}.task;
        end
        if isfield(headers{i_col}, 'suffix')
          this_filter.suffix = headers{i_col}.suffix;
        end

        files = bids.query(BIDS, 'data', this_filter);

        diagnostic_table(row, i_col) = size(files, 1);

      end

      sub_ses{row} = ['sub-' this_filter.sub];
      if ~isempty(this_filter.ses)
        sub_ses{row} = ['sub-' this_filter.sub ' ses-' this_filter.ses];
      end

      row = row + 1;

    end

  end

  %%
  fig_name = base_fig_name(BIDS);
  if ~cellfun('isempty', args.Results.split_by)
    fig_name = [base_fig_name(BIDS) ' - split_by ' strjoin(args.Results.split_by, '-')];
  end

  bids.internal.plot_diagnostic_table(diagnostic_table, headers, sub_ses, ...
                                      strrep(fig_name, '_', ' '), ...
                                      visible);

  print_figure(output_path, fig_name);

  if verbose
    close(gcf);
  end
  %% events
  modalities = bids.query(BIDS, 'modalities', filter);
  tasks = bids.query(BIDS, 'tasks', filter);

  for i_modality = 1:numel(modalities)

    for i_task = 1:numel(tasks)

      [data, headers, y_labels] = bids.internal.list_events(BIDS, ...
                                                            modalities{i_modality}, ...
                                                            tasks{i_task}, ...
                                                            'filter', filter, ...
                                                            'trial_type_col', trial_type_col);
      if isempty(data)
        continue
      end

      fig_name = [base_fig_name(BIDS), ' - ', modalities{i_modality}, ' - ', tasks{i_task}];
      fig_name = strrep(fig_name, '_', ' ');

      bids.internal.plot_diagnostic_table(data, ...
                                          headers, ...
                                          y_labels, ...
                                          fig_name, ...
                                          visible);

      print_figure(output_path, fig_name);

    end

  end

end

function fig_name = base_fig_name(BIDS)
  fig_name = BIDS.description.Name;
  if isempty(fig_name) || strcmp(fig_name, ' ')
    fig_name = 'this_dataset';
  end
end

function print_figure(output_path, fig_name)
  if ~isempty(output_path)

    bids.util.mkdir(output_path);

    filename = regexprep([fig_name, '.png'], ' - ', '_');
    filename = regexprep(filename, ' ', '-');
    filename = regexprep(filename, '[\(\)]', '');
    filename = fullfile(output_path, filename);

    print(filename, '-dpng');
    fprintf('Figure saved:\n\t%s\n', filename);

  end
end

function headers = get_headers(BIDS, filter, split_by)
  %
  % Get the headers to include in the output table
  %

  % TODO will probably need to use a recursive way to build the header list

  headers = {};

  modalities = bids.query(BIDS, 'modalities', filter);

  for i_modality = 1:numel(modalities)

    this_filter = filter;
    this_filter.modality = modalities(i_modality);

    this_header = struct('modality', {modalities(i_modality)});

    if ismember('suffix', split_by)

      suffixes = bids.query(BIDS, 'suffixes', this_filter);

      for i_suffix = 1:numel(suffixes)

        this_filter.suffix = suffixes(i_suffix);

        this_header.suffix = suffixes(i_suffix);

        if ismember('task', split_by)
          headers = add_task_based_headers(BIDS, headers, this_filter, this_header, split_by);
        else
          headers{end + 1} = this_header; %#ok<*AGROW>
        end

      end

    else

      if ismember('task', split_by)
        headers = add_task_based_headers(BIDS, headers, this_filter, this_header, split_by);
      else
        headers{end + 1} = this_header;
      end

    end

  end

end

function this_filter = get_clean_filter(filter, sub, ses)
  this_filter = filter;
  this_filter.sub = sub;
  if nargin > 2
    this_filter.ses = ses;
  end
end

function headers = add_task_based_headers(BIDS, headers, this_filter, this_header, split_by)

  if ismember('task', split_by)

    tasks = bids.query(BIDS, 'tasks', this_filter);

    for i_task = 1:numel(tasks)
      this_header.task = tasks(i_task);
      headers{end + 1} = this_header;
    end

  end

end

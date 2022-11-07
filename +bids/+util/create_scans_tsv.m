function output_filenames = create_scans_tsv(varargin)
  %
  % Create a simple scans.tsv for each participant of a BIDS dataset.
  %
  %
  % USAGE::
  %
  %   output_filename = bids.util.create_scans_tsv(layout_or_path, ...
  %                                                'use_schema', true, ...
  %                                                'tolerant', true, ...
  %                                                'verbose', false)
  %
  %
  % :param layout_or_path:
  % :type  layout_or_path:  path or structure
  %
  % :param use_schema:
  % :type  use_schema: logical
  %
  % :param tolerant: Set to ``true`` to turn validation errors into warnings
  % :type  tolerant: logical
  %
  % :param verbose: Set to ``true`` to get more feedback
  % :type  verbose: logical
  %

  % (C) Copyright 2022 Remi Gau

  default_layout = pwd;
  default_tolerant = true;
  default_use_schema = true;
  default_verbose = false;

  is_dir_or_struct = @(x) (isstruct(x) || isdir(x));
  is_logical = @(x) islogical(x);

  args = inputParser();

  addOptional(args, 'layout_or_path', default_layout, is_dir_or_struct);
  addParameter(args, 'tolerant', default_tolerant, is_logical);
  addParameter(args, 'use_schema', default_use_schema, is_logical);
  addParameter(args, 'verbose', default_verbose, is_logical);

  parse(args, varargin{:});

  layout_or_path = args.Results.layout_or_path;
  tolerant = args.Results.tolerant;
  use_schema = args.Results.use_schema;
  verbose = args.Results.verbose;

  %%
  output_filenames = {};

  layout = bids.layout(layout_or_path, 'use_schema', use_schema);

  sessions_list = bids.query(layout, 'sessions');
  if isempty(sessions_list)
    msg = sprintf(['There are no session in this dataset:\n', ...
                   '\t%s'], layout.pth);
    bids.internal.error_handling(mfilename(), 'noSessionInDataset', msg, tolerant, verbose);
    return
  end

  subjects_list = bids.query(layout, 'subjects');

  for i_sub = 1:numel(subjects_list)

    sessions_file = fullfile(layout.pth, ...
                             ['sub-' subjects_list{i_sub}], ...
                             ['sub-' subjects_list{i_sub} '_sessions.tsv']);

    if exist(sessions_file, 'file')
      msg = sprintf(['"sessions.tsv" %s already exist for the following dataset.', ...
                     'Will not overwrite.\n', ...
                     '\t%s'], sessions_file, layout.pth);
      bids.internal.error_handling(mfilename(), 'participantFileExist', msg, true, verbose);
      continue
    end

    sessions_list = bids.query(layout, 'sessions', 'sub', subjects_list{i_sub});
    sessions_list = [repmat('ses-', numel(sessions_list), 1), char(sessions_list')];
    content = struct('session_id', {sessions_list}, ...
                     'acq_time', {cell(size(sessions_list, 1), 1)}, ...
                     'comments', {cell(size(sessions_list, 1), 1)});

    output_filenames{end + 1} = sessions_file; %#ok<AGROW>

    bids.util.tsvwrite(sessions_file, content);
  end

  if verbose
    fprintf(1, ['\nCreated "sessions.tsv" in the dataset.', ...
                '\n\t%s\n', ...
                'Please add any necessary information manually...\n', ...
                'See this section of the BIDS specification:\n\t%s\n'], ...
            bids.internal.create_unordered_list(sessions_file), ...
            bids.internal.url('sessions'));
  end

end

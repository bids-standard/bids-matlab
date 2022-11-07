function output_filenames = create_sessions_tsv(varargin)
  %
  % Create a simple sessions.tsv for each participant of a BIDS dataset.
  %
  %
  % USAGE::
  %
  %   output_filename = bids.util.create_sessions_tsv(layout_or_path);
  %
  %
  % :param layout_or_path:
  % :type  layout_or_path:  path or structure
  %
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

    sessions_list = bids.query(layout, 'sessions', 'sub', subjects_list{i_sub});
    sessions_list = [repmat('ses-', numel(sessions_list), 1), char(sessions_list')];
    sessions_list = struct('session_id', {sessions_list});

    sessions_file = fullfile(layout.pth, ...
                             ['sub-' subjects_list{i_sub}], ...
                             'sessions.tsv');

    output_filenames{end + 1} = sessions_file; %#ok<AGROW>

    bids.util.tsvwrite(sessions_file, sessions_list);
  end

  if verbose
    fprintf(1, ['\nCreated "sesssions.tsv" in the dataset.', ...
                '\n\t%s\n', ...
                'Please add any necessary information manually...\n', ...
                'See this section of the BIDS specification:\n\t%s\n'], ...
            bids.internal.create_unordered_list(sessions_file), ...
            bids.internal.url('sessions'));
  end

end

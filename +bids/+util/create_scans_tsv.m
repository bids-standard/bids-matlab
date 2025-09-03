function output_filenames = create_scans_tsv(varargin)
  %
  % Create a simple scans.tsv for each participant of a BIDS dataset.
  %
  % USAGE::
  %
  %   output_filename = bids.util.create_scans_tsv(layout_or_path, ...
  %                                                'use_schema', true, ...
  %                                                'tolerant', true, ...
  %                                                'verbose', false)
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

  is_dir_or_struct = @(x) (isstruct(x) || isfolder(x));
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

  % we only include recorindg files in the scans.tsv
  sc = bids.Schema();
  suffixes = fieldnames(sc.content.objects.suffixes);
  suffixes = setdiff(suffixes, {'aslcontext', ...
                                'asllabeling', ...
                                'channels', ...
                                'coordsystem', ...
                                'electrodes', ...
                                'events', ...
                                'headshape', ...
                                'markers', ...
                                'scans', ...
                                'sessions', ...
                                'stim'});

  extension_group = fieldnames(sc.content.objects.extensions);
  for i = 1:numel(extension_group)
    extensions{i} = sc.content.objects.extensions.(extension_group{i}).value; %#ok<*AGROW>
  end

  extensions = setdiff(extensions, {'.bval', ...
                                    '.bvec', ...
                                    '.jpg', ...
                                    '.json', ...
                                    '.txt'});
  %%
  output_filenames = {};

  layout = bids.layout(layout_or_path, ...
                       'use_schema', use_schema, ...
                       'index_dependencies', false, ...
                       'tolerant', tolerant, ...
                       'verbose', verbose);

  subjects_list = bids.query(layout, 'subjects');

  for i_sub = 1:numel(subjects_list)

    sessions_list = bids.query(layout, 'sessions', 'sub', subjects_list{i_sub});
    if isempty(sessions_list)
      sessions_list = {''};
    end

    for i_ses = 1:numel(sessions_list)

      scans_file = fullfile(['sub-' subjects_list{i_sub}], ...
                            ['sub-' subjects_list{i_sub} '_scans.tsv']);
      session_str = '';
      if ~isempty(sessions_list{i_ses})
        session_str = ['ses-' sessions_list{i_ses}];
        scans_file = fullfile(['sub-' subjects_list{i_sub}], ...
                              session_str, ...
                              ['sub-' subjects_list{i_sub}, ...
                               '_ses-' sessions_list{i_ses}, ...
                               '_scans.tsv']);
      end

      if exist(fullfile(layout.pth, scans_file), 'file')
        msg = sprintf(['"scans.tsv" %s already exist for the following dataset.', ...
                       'Will not overwrite.\n', ...
                       '\t%s'], ...
                      bids.internal.format_path(scans_file), ...
                      bids.internal.format_path(layout.pth));
        bids.internal.error_handling(mfilename(), 'scansFileExist', msg, true, verbose);
        continue
      end

      data = bids.query(layout, 'data', 'sub', subjects_list{i_sub}, ...
                        'ses', sessions_list{i_ses}, ...
                        'suffix', suffixes, ...
                        'extension', extensions);

      for i_file = 1:numel(data)
        data{i_file} = strrep(data{i_file}, ...
                              fullfile(layout.pth, ...
                                       ['sub-' subjects_list{i_sub}], ...
                                       [session_str filesep]), ...
                              '');
      end

      content = struct('filename', {data}, ...
                       'acq_time', {cell(numel(data), 1)}, ...
                       'comments', {cell(numel(data), 1)});

      output_filenames{end + 1} = scans_file;

      bids.util.tsvwrite(fullfile(layout.pth, scans_file), content);

    end
  end

  if verbose && ~isempty(output_filenames)
    fprintf(1, ['\nCreated "scans.tsv" in the dataset.', ...
                '\n\t%s\n', ...
                'Please add any extra information manually.\n', ...
                'See this section of the BIDS specification:\n\t%s\n'], ...
            bids.internal.create_unordered_list(output_filenames), ...
            bids.internal.url('scans'));
  end

end

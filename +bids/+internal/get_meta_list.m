function metalist = get_meta_list(varargin)
  %
  % Read a BIDS's file metadata according to the inheritance principle
  %
  % USAGE::
  %
  %    metalist = bids.internal.get_metadata(filename, ...
  %                                          pattern, ...
  %                                          use_inheritance)
  %
  % :param filename: fullpath name of file following BIDS standard
  % :type  filename: char
  %
  % :param pattern:  Regular expression matching the metadata file
  %                  default = ``'^.*%s\\.json$'``
  %                  If provided, it must at least be ``'%s'``.
  % :type  pattern:  char
  %
  % :return: metalist - list of paths to metafiles
  %
  %

  % (C) Copyright 2011-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % (C) Copyright 2018 BIDS-MATLAB developers

  args = inputParser;

  addRequired(args, 'filename', @ischar);
  % Default is to assume it is a JSON file
  addOptional(args, 'pattern', '^.*%s\\.json$', @ischar);
  addParameter(args, 'use_inheritance', true, @islogical);

  parse(args, varargin{:});

  filename = args.Results.filename;
  pattern = args.Results.pattern;
  use_inheritance = args.Results.use_inheritance;

  pth = fileparts(filename);
  metalist = {};
  p = bids.internal.parse_filename(filename);
  if isempty(p)
    return
  end

  % in deepest level look for file with only a change in extension
  basename = bids.internal.file_utils(filename, 'basename');
  if strcmp(bids.internal.file_utils(basename, 'ext'), 'nii')
    basename = bids.internal.file_utils(basename, 'basename');
  end
  ideal_metafile = bids.internal.file_utils('FPList', ...
                                            pth, ...
                                            sprintf(pattern, basename));

  % Default assumes we are dealing with a file in the root directory
  % like "participants.tsv".
  % If the file has underscore separated entities ("sub-01_T1w.nii")
  % then we look through the hierarchy for potential metadata file
  % associated with queried file.
  N = 1;
  if use_inheritance && isfield(p, 'entities')
    N = 3;
    % -There is a session level in the hierarchy
    if isfield(p.entities, 'ses') && ~isempty(p.entities.ses)
      N = N + 1;
    end
  end

  for n = 1:N

    % List the metadata files associated with this file
    metafile = bids.internal.file_utils('FPList', pth, sprintf(pattern, p.suffix));

    if isempty(metafile)
      metafile = {};
    else
      metafile = cellstr(metafile);
    end

    % in deepest level look for file with only a change in extension
    if n == 1  && ~isempty(ideal_metafile)
      metalist{end + 1, 1} = ideal_metafile; %#ok<*AGROW>
      % Go up to the parent folder
      pth = fullfile(pth, '..');
      continue
    end

    % For all those files we find which one is potentially associated
    % with the file of interest
    % TODO: not more than one file per level is allowed
    for i = 1:numel(metafile)

      p2 = bids.internal.parse_filename(metafile{i});
      if isempty(p2)
        continue
      end
      entities = {};
      if isfield(p2, 'entities')
        entities = fieldnames(p2.entities);
      end

      % Check if this metadata file contains
      %   - the same entity-label pairs
      %   - same suffix
      % as its data file counterpart
      ismeta = true;
      if ~strcmp(p.suffix, p2.suffix)
        % TODO is this necessary as we have already
        % only listed files with the same suffix
        ismeta = false;
      end
      for j = 1:numel(entities)
        if ~isfield(p.entities, entities{j}) || ...
                ~strcmp(p.entities.(entities{j}), p2.entities.(entities{j}))
          ismeta = false;
          break
        end
      end

      % append path to list
      if ismeta
        metalist{end + 1, 1} = metafile{i};
      end

    end

    % Go up to the parent folder
    pth = fullfile(pth, '..');
  end
end

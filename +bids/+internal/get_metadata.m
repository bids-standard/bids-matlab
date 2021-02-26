function meta = get_metadata(filename, pattern)
  %
  % Read a BIDS's file metadata according to the inheritance principle
  %
  % USAGE::
  %
  %    meta = bids.internal.get_metadata(filename, pattern = '^.*%s\\.json$')
  %
  % :param filename: fullpath name of file following BIDS standard
  % :type  filename: string
  % :param pattern:  Regular expression matching the metadata file (default is ``'^.*%s\\.json$'``)
  %                  If provided, it must at least be ``'%s'``.
  % :type  pattern:  string
  %
  %
  % meta        - metadata structure
  % __________________________________________________________________________

  % Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2018--, BIDS-MATLAB developers

  if nargin == 1
    pattern = '^.*_%s\\.json$';
  end

  pth = fileparts(filename);
  p = bids.internal.parse_filename(filename);

  meta = struct();

  N = 3;

  % -There is a session level in the hierarchy
  if isfield(p.entities, 'ses') && ~isempty(p.entities.ses)
    N = N + 1;
  end

  % -Loop from the directory where the file of interest is back to the
  % top level of the BIDS hierarchy
  for n = 1:N

    % -List the potential metadata files associated with this file suffix type
    % Default is to assume it is a JSON file
    metafile = bids.internal.file_utils('FPList', pth, sprintf(pattern, p.suffix));

    if isempty(metafile)
      metafile = {};
    else
      metafile = cellstr(metafile);
    end

    % -For all those files we find which one is potentially associated with
    % the file of interest
    for i = 1:numel(metafile)

      p2 = bids.internal.parse_filename(metafile{i});
      entities = {};
      if isfield(p2, 'entities')
        entities = fieldnames(p2.entities);
      end

      % -Check if this metadata file contains the same entity-label pairs as its
      % data file counterpart
      ismeta = true;
      for j = 1:numel(entities)
        if ~isfield(p.entities, entities{j}) || ...
                ~strcmp(p.entities.(entities{j}), p2.entities.(entities{j}))
          ismeta = false;
          break
        end
      end

      % -Read the content of the metadata file if it is a JSON file and update
      % the metadata concerning the file of interest otherwise store the filename
      if ismeta
        if strcmp(p2.ext, '.json')
          meta = update_metadata(meta, bids.util.jsondecode(metafile{i}), metafile{i});
        else
          meta.filename = metafile{i};
        end
      end

    end

    % -Go up to the parent folder
    pth = fullfile(pth, '..');

  end

  if isempty(meta)
    warning('No metadata for %s', filename);
  end

end

% ==========================================================================
% -Inheritance principle
% ==========================================================================
function s1 = update_metadata(s1, s2, file)
  if isempty(s2)
    return
  elseif ~isstruct(s2)
    error('Metadata file contents were neither struct nor empty. File: %s', file);
  end
  fn = fieldnames(s2);
  for i = 1:numel(fn)
    if ~isfield(s1, fn{i})
      s1.(fn{i}) = s2.(fn{i});
    end
  end
end

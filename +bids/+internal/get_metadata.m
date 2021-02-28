function meta = get_metadata(metafile)
  %
  % Read a BIDS's file metadata according to the inheritance principle
  %
  % USAGE::
  %
  %    meta = bids.internal.get_metadata(metafile)
  %
  % :param metafile: list of fullpath names of metafiles.
  % :type  metafile: string or array of strings
  %
  % :returns: - :meta: metadata structure
  %
  % .. todo
  %
  %    add explanation on how the inheritance principle is implemented.
  % __________________________________________________________________________

  % Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2018--, BIDS-MATLAB developers

  meta = struct();
  metafile = cellstr(metafile);

  for i = 1:numel(metafile)
    if bids.internal.endsWith(metafile{i}, '.json')
      meta = update_metadata(meta, bids.util.jsondecode(metafile{i}), metafile{i});
    else
      meta.filename = metafile{i};
    end
  end

  if isempty(meta)
    warning('No metadata for %s', metafile);
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

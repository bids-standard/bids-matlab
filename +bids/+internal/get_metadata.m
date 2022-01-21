function meta = get_metadata(metafile)
  %
  % Read a BIDS's file metadata according to the inheritance principle
  %
  % USAGE::
  %
  %    meta = bids.internal.get_metadata(metafile)
  %
  % :param metafile: list of fullpath names of metadata files.
  % :type  metafile: string or array of strings
  %
  % :returns: - :meta: metadata structure
  %
  % .. todo
  %
  %    add explanation on how the inheritance principle is implemented.
  %
  %
  % (C) Copyright 2011-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  meta = struct();
  metafile = cellstr(metafile);

  for i = 1:numel(metafile)
    if bids.internal.ends_with(metafile{i}, '.json')
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
function struct_one = update_metadata(struct_one, struct_two, file)
  if isempty(struct_two)
    return
  elseif ~isstruct(struct_two)
    error('Metadata file contents were neither struct nor empty. File: %s', file);
  end
  fn = fieldnames(struct_two);
  for i = 1:numel(fn)
    if ~isfield(struct_one, fn{i})
      struct_one.(fn{i}) = struct_two.(fn{i});
    end
  end
end

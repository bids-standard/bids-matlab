function pth = create_path(filename)
  %
  % Creates a relative path based on the content of a BIDS filename.
  %
  % If there is none, or more than one possibility for the datatype, the path will only
  % be based on the sub and ses entitiy.
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  pth = '';

  p = bids.internal.parse_filename(filename);
  if isempty(p)
    return;
  end

  if isfield(p.entities, 'sub')
    pth = ['sub-' p.entities.sub];
  end

  if isfield(p.entities, 'ses')
    pth = [pth, filesep, 'ses-', p.entities.ses];
  end

  schema = bids.schema();
  schema = schema.load();
  datatypes = schema.return_datatypes_for_suffix(p.suffix);
  if numel(datatypes) == 1
    pth = [pth, filesep, datatypes{1}];
  end

end

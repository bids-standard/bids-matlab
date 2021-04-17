function subject = append_to_layout(file, subject, modality, schema)
  %
  % appends a file to the BIDS layout by parsing it according to the provided schema
  %
  % USAGE::
  %
  %   subject = append_to_layout(file, subject, modality, schema == [])
  %
  % :param file:
  % :type  file: string
  % :param subject: subject sub-structure from the BIDS layout
  % :type  subject: strcture
  % :param modality:
  % :type  modality: string
  % :param schema:
  % :type  schema: strcture
  %
  %
  % Copyright (C) 2021--, BIDS-MATLAB developers

  if ~exist('schema', 'var')
    schema = [];
  end

  % Parse file fist to identify the suffix group in the template.
  % Then reparse the file using the entity-label pairs defined in the schema.
  p = bids.internal.parse_filename(file);

  idx = bids.schema.find_suffix_group(modality, p.suffix, schema);

  if ~isempty(schema)

    if isempty(idx)
      warning('append_to_structure:noMatchingSuffix', ...
              'Skipping file with no valid suffix in schema: %s', file);
      return
    end

    entities = bids.schema.return_modality_entities(schema.datatypes.(modality)(idx), schema);
    p = bids.internal.parse_filename(file, entities);

    % do not index json files when using the schema
    if ~isempty(p) && strcmp(p.ext, '.json')
      return
    end

  end

  % Check any new entity field that needs to be added into the layout or the output
  % of the parsing to make sure the 2 structures can be concatenated
  if ~isempty(subject.(modality))

    [subject.(modality), p] = bids.internal.match_structure_fields(subject.(modality), p);

  end

  if isempty(subject.(modality))
    subject.(modality) = p;
  else
    subject.(modality)(end + 1, 1) = p;
  end

end

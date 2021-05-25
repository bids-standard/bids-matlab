function [subject, p] = append_to_layout(file, subject, modality, schema)
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
  % (C) Copyright 2021 BIDS-MATLAB developers

  % Parse file fist to identify the suffix group in the template.
  % Then reparse the file using the entity-label pairs defined in the schema.
  p = bids.internal.parse_filename(file);

  if ~isempty(schema.content)

    idx = schema.find_suffix_group(modality, p.suffix);

    if isempty(idx)
      warning('append_to_structure:noMatchingSuffix', ...
              'Skipping file with no valid suffix in schema: %s', file);
      p = [];
      return
    end

    entities = schema.return_modality_entities(schema.content.datatypes.(modality)(idx));
    p = bids.internal.parse_filename(file, entities);

    % do not index json files when using the schema
    if isempty(p) || (~isempty(p) && strcmp(p.ext, '.json'))
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

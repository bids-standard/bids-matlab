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
      warning('append_to_layout:noMatchingSuffix', ...
              'Skipping file with no valid suffix in schema: %s', file);
      p = [];
      return
    end

    this_suffix_group = schema.content.datatypes.(modality)(idx);

    schema_entities = schema.return_entities_for_suffix_group(this_suffix_group);
    required_entities = schema.required_entities_for_suffix_group(this_suffix_group);

    present_entities = fieldnames(p.entities);
    missing_entities = ~ismember(required_entities, present_entities);
    unknown_entity = present_entities(~ismember(present_entities, schema_entities));

    extension = p.ext;
    if strcmp(p.suffix, 'meg') && strcmp(extension, '.ds')
      extension = [extension '/'];
    end

    if ~ismember('*', this_suffix_group.extensions) && ...
            ~ismember(extension, this_suffix_group.extensions)
      warning('append_to_layout:unknownExtension', msg, ...
              'Unknown extension %s in schema for file %s', extension, file);
      p = [];
      return
    end

    if ~isempty(unknown_entity)
      warning('append_to_layout:unknownEntity', ...
              'Unknown entities %s in schema for file: %s', file, ...
              strjoin(unknown_entity, ' '));
      p = [];
      return
    end

    if any(missing_entities)
      missing_entities = required_entities(missing_entities);
      warning('append_to_layout:missingRequiredEntity', ...
              'Skipping file %s.\nMissing REQUIRED entity: %s', file, ...
              strjoin(missing_entities, ' '));
      p = [];
      return
    end

    p = bids.internal.parse_filename(file, schema_entities);

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

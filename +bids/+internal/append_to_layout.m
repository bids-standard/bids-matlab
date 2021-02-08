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

  idx = find_suffix_group(modality, p.suffix, schema);

  if ~isempty(schema)

    if isempty(idx)
      warning('append_to_structure:noMatchingSuffix', ...
              'Skipping file with no valid suffix in schema: %s', file);
      return
    end

    entities = bids.schema.return_modality_entities(schema.datatypes.(modality)(idx), schema);
    p = bids.internal.parse_filename(file, entities);

  end

  % Check any new entity field that needs to be added into the layout or the output
  % of the parsing to make sure the 2 structures can be concatenated
  if ~isempty(subject.(modality))

    missing_fields = setxor(fieldnames(subject.(modality)), fieldnames(p));

    if ~isempty(missing_fields)
      for iField = 1:numel(missing_fields)
        p = add_missing_field(p, ...
                              missing_fields{iField});
        subject.(modality) = add_missing_field(subject.(modality), ...
                                               missing_fields{iField});
      end
    end

  end

  subject.(modality) = [subject.(modality) p];

end

function structure = add_missing_field(structure, field)
  if ~isfield(structure, field)
    structure(1).(field) = '';
  end
end

function idx = find_suffix_group(modality, suffix, schema)

  idx = [];

  if isempty(schema)
    return
  end

  % the following loop could probably be improved with some cellfun magic
  %   cellfun(@(x, y) any(strcmp(x,y)), {p.type}, suffix_groups)
  for i = 1:size(schema.datatypes.(modality), 1)

    this_suffix_group = schema.datatypes.(modality)(i);

    % for CI
    if iscell(this_suffix_group)
      this_suffix_group = this_suffix_group{1};
    end

    if any(strcmp(suffix, this_suffix_group.suffixes))
      idx = i;
      break
    end

  end

  if isempty(idx)
    warning('findSuffix:noMatchingSuffix', ...
            'No corresponding suffix in schema for %s for datatype %s', suffix, modality);
  end

end

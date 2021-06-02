function [subject, status, previous] = append_to_layout(file, subject, modality, schema, previous)
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

  if same_data(file, previous)

    % in case we are using the schema and faced with a file that
    % does have the same basename as the previous file
    % but not a recognized extension
    % - <match>_events.tsv
    % - <match>_events.mat
    %
    if ~isempty(schema.content) && ...
            ~any(ismember(file(previous.data_len:end), ...
                          previous.allowed_ext))
      status = 0;
      return
    end

    subject.(modality)(end + 1, 1) = subject.(modality)(end, 1);
    subject.(modality)(end, 1).ext = file(previous.data_len:end);
    subject.(modality)(end, 1).filename = file;

    dep_fname = fullfile(subject.path, modality, subject.(modality)(end - 1, 1).filename);
    subject.(modality)(end).dependencies.data{end + 1, 1} = dep_fname;
    status = 1;
    return

  else

    % Parse file fist to identify the suffix group in the template.
    % Then reparse the file using the entity-label pairs defined in the schema.
    p = bids.internal.parse_filename(file);

    if ~isempty(schema.content)

      % CHECK: not sure the following is necessary as json are not supposed to
      % be listed in the first place
      % do not index json files when using the schema
      if strcmp(p.ext, '.json')
        status = 0;
        return
      end

      idx = schema.find_suffix_group(modality, p.suffix);

      if isempty(idx)
        msg = sprintf('Skipping file with no valid suffix in schema: %s', file);
        bids.internal.error_handling(mfilename, 'noMatchingSuffix', msg, true, schema.verbose);
        status = 0;
        return
      end

      this_suffix_group = schema.content.datatypes.(modality)(idx);

      allowed_extensions = this_suffix_group.extensions;
      allowed_extensions(ismember(allowed_extensions, '.json')) = [];

      schema_entities = schema.return_entities_for_suffix_group(this_suffix_group);
      required_entities = schema.required_entities_for_suffix_group(this_suffix_group);

      present_entities = fieldnames(p.entities);
      missing_entities = ~ismember(required_entities, present_entities);
      unknown_entity = present_entities(~ismember(present_entities, schema_entities));

      extension = p.ext;
      if strcmp(p.suffix, 'meg') && strcmp(extension, '.ds')
        extension = [extension '/'];
      end
      if ~ismember('*', allowed_extensions) && ...
              ~ismember(extension, allowed_extensions)
        id = 'unknownExtension';
        msg = sprintf('Unknown extension %s in schema for file %s', extension, file);
      end

      if ~isempty(unknown_entity)
        id = 'unknownEntity';
        msg = sprintf('Unknown entities %s in schema for file: %s', file, ...
                      strjoin(unknown_entity, ' '));
      end

      if any(missing_entities)
        missing_entities = required_entities(missing_entities);
        id = 'missingRequiredEntity';
        msg = sprintf('Skipping file %s.\nMissing REQUIRED entity: %s', file, ...
                      strjoin(missing_entities, ' '));
      end

      if exist('id', 'var')
        bids.internal.error_handling(mfilename, id, msg, true, schema.verbose);
        status = 0;
        return
      end

      p = bids.internal.parse_filename(file, schema_entities);

      previous.allowed_ext = allowed_extensions;

    end

    p.metafile = bids.internal.get_meta_list(fullfile(subject.path, modality, file));

    p.dependencies.explicit = {};
    p.dependencies.data = {};
    p.dependencies.group = {};

    if ~isempty(subject.(modality))
      [subject.(modality), p] = bids.internal.match_structure_fields(subject.(modality), p);

    end

    if isempty(subject.(modality))
      subject.(modality) = p;

    else
      subject.(modality)(end + 1, 1) = p;

    end

    status = 1;

  end

end

function status = same_data(file, previous)

  status = strncmp(previous.data_base, file, previous.data_len);

end

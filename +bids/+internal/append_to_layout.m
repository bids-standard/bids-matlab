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

  pth = [subject.path, filesep, modality];

  % We speed up indexing by checking that the current file has the same basename
  % as the previous one.
  % In this case we can copy most of the info from the previous file
  if same_data(file, previous)

    % Skip file in case we are using the schema and faced with a file that
    % does have the same basename as the previous file
    % but not a recognized extension
    % - <match>_events.tsv
    % - <match>_events.mat
    %
    if ~isempty(schema.content) && ...
            ~any(ismember(file(previous.data.len:end), ...
                          previous.allowed_ext))
      [msg, id] = error_message('unknownExtension', file, file(previous.data.len:end));
      bids.internal.error_handling(mfilename, id, msg, true, schema.verbose);
      status = 0;
      return
    end

    subject.(modality)(end + 1, 1) = subject.(modality)(end, 1);
    subject.(modality)(end, 1).ext = file(previous.data.len:end);
    subject.(modality)(end, 1).filename = file;

    dep_fname = fullfile(pth, subject.(modality)(end - 1, 1).filename);
    subject.(modality)(end).dependencies.data{end + 1, 1} = dep_fname;
    status = 1;
    return

  else

    % Parse file fist to identify the suffix group in the template.
    % Then reparse the file using the entity-label pairs defined in the schema.
    p = bids.internal.parse_filename(file);
    if isempty(p)
      status = 0;
      return
    end

    if ~isempty(schema.content)

      idx = schema.find_suffix_group(modality, p.suffix);

      if isempty(idx)
        [msg, id] = error_message('unknownSuffix', file, p.suffix);
        bids.internal.error_handling(mfilename, id, msg, true, schema.verbose);
        status = 0;
        return
      end

      datatypes = schema.get_datatypes();

      this_suffix_group = datatypes.(modality)(idx);

      allowed_extensions = this_suffix_group.extensions;

      schema_entities = schema.return_entities_for_suffix_group(this_suffix_group);
      required_entities = schema.required_entities_for_suffix_group(this_suffix_group);

      present_entities = fieldnames(p.entities);
      missing_entities = ~ismember(required_entities, present_entities);
      unknown_entity = present_entities(~ismember(present_entities, schema_entities));

      extension = p.ext;
      % in case we are dealing with a folder
      % (can be the case for some MEG formats: .ds)
      if exist(fullfile(pth, p.filename), 'dir')
        extension = [extension '/'];
      end

      %% Checks that this file is BIDS compliant
      if ~ismember('*', allowed_extensions) && ...
              ~ismember(extension, allowed_extensions)
        [msg, id] = error_message('unknownExtension', file, extension);
      end

      if ~isempty(unknown_entity)
        [msg, id] = error_message('unknownEntity', file, ...
                                  strjoin(cellstr(unknown_entity), ' '));
      end

      if any(missing_entities)
        missing_entities = required_entities(missing_entities);
        [msg, id] = error_message('missingRequiredEntity', file, ...
                                  strjoin(cellstr(missing_entities), ' '));
      end

      if exist('id', 'var')
        bids.internal.error_handling(mfilename, id, msg, true, schema.verbose);
        status = 0;
        return
      end

      p = bids.internal.parse_filename(file, schema_entities);
      if isempty(p)
        status = 0;
        return
      end

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

  status = strncmp(previous.data.base, file, previous.data.len);

end

function [msg, msg_id] = error_message(msg_id, file, extra)

  msg = sprintf('Skipping file %s.\n', file);

  switch msg_id

    case 'unknownExtension'
      msg = sprintf('%s Unknown extension %s', msg, extra);

    case 'missingRequiredEntity'
      msg = sprintf('%s Missing REQUIRED entity: %s', msg, extra);

    case 'unknownEntity'
      msg = sprintf('%s Unknown entities: %s', msg, extra);

    case 'unknownSuffix'
      msg = sprintf('%s Unknown suffix: %s', msg, extra);

  end

end

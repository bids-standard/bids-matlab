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
    if ~isempty(schema) && ...
            ~any(ismember(file(previous.data.len:end), ...
                          previous.allowed_ext))
      id = 'unknownExtension';
      msg = sprintf('%s: Unknown extension %s', file, file(previous.data.len:end));
      bids.internal.error_handling(mfilename, id, msg, true, true);
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

    [status, content] = schema.test_name(p, modality);
    if ~status
      id = 'incorrectName';
      msg = sprintf('%s: Name do not follow BIDS', file);
      bids.internal.error_handling(mfilename, id, msg, true, true);
      return;
    end

    if schema.has_schema()
      p = bids.internal.parse_filename(file, content.entities);
      if isempty(p)
        status = 0;
        return
      end

      previous.allowed_ext = content.extensions;
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

  end

end

function status = same_data(file, previous)

  status = strncmp(previous.data.base, file, previous.data.len);

end

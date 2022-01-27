function p = parse_filename(filename, fields, tolerant)
  %
  % Split a filename into its building constituents
  %
  % USAGE::
  %
  %   p = bids.internal.parse_filename(filename, fields)
  %
  % :param filename: fielname to parse that follows the pattern
  %                  ``sub-label[_entity-label]*_suffix.extension``
  % :type  filename: string
  % :param fields:   cell of strings of the entities to use for parsing
  % :type  fields:   cell
  %
  % Example::
  %
  %   filename = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  %
  %   bids.internal.parse_filename(filename)
  %
  %   ans =
  %
  %   struct with fields:
  %
  %     'filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
  %     'suffix', 'T1w', ...
  %     'ext', '.nii.gz', ...
  %     'entities', struct('sub', '16', ...
  %                        'ses', 'mri', ...
  %                        'run', '1', ...
  %                        'acq', 'hd');
  %
  % Example::
  %
  %   filename = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  %   fields = {'sub', 'ses', 'run', 'acq', 'ce'};
  %   output = bids.internal.parse_filename(filename, fields);
  %
  % The output will have the following shape::
  %
  %   output = struct( ...
  %                     'filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
  %                     'suffix', 'T1w', ...
  %                     'ext', '.nii.gz', ...
  %                     'entities', struct('sub', '16', ...
  %                                        'ses', 'mri', ...
  %                                        'run', '1', ...
  %                                        'acq', 'hd', ...
  %                                        'ce', ''), ...
  %                     'prefix', '');
  %
  %
  % (C) Copyright 2011-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  if nargin < 2 || isempty(fields)
    fields = {};
  end

  if nargin < 3 || isempty(tolerant)
    tolerant = true;
  end

  fields_order = {'filename', 'ext', 'suffix', 'entities', 'prefix'};

  filename = bids.internal.file_utils(filename, 'filename');
  p.filename = filename;

  % identify an eventual prefix to the file
  % only look for comes before the first "sub-"
  p.prefix = '';
  pos = strfind(filename, 'sub-');
  if ~isempty(pos) && pos(1) > 1
    p.prefix = filename(1:pos(1) - 1);
  else
    pos = 1;
  end
  basename = filename(pos:end);

  % Identify extention
  [basename, p.ext] = strtok(basename, '.');

  p = parse_entity_label_pairs(p, basename, tolerant);

  % Extra fields can be added to the structure and ordered specifically.
  if ~isempty(fields)
    for i = 1:numel(fields)
      p.entities = bids.internal.add_missing_field(p.entities, fields{i});
    end
    try
      p = orderfields(p, fields_order);
      p.entities = orderfields(p.entities, fields);
    catch
      msg = sprintf('Ignoring file %s not matching template.', filename);
      bids.internal.error_handling(mfilename, 'noMatchingTemplate', msg, tolerant, true);
      p = struct([]);
    end
  end

end

function p = parse_entity_label_pairs(p, basename, tolerant)

  p.entities = struct();
  p.suffix = '';

  % -Identify all the BIDS entity-label pairs present in the filename (delimited by "_")
  [parts, dummy] = regexp(basename, '(?:_)+', 'split', 'match'); %#ok<ASGLU>

  % Separate the entity from the label for each pair identified above
  for i = 1:numel(parts)

    try

      if isempty(parts{i})
        error_id = 'emptyEntity';
        error('empty entity');
      end

      [d, dummy] = regexp(parts{i}, '(?:\-)+', 'split', 'match');

      switch size(dummy, 2)

        case 0 % no - in entity, may be suffix
          if i ~= numel(parts)
            error_id = 'missingDash';
            error('entity does not contain ''-''');
          end
          p.suffix = d{1};

        case 1 % normal entity
          if isempty(d{1})
            error_id = 'emptyEntity';
            error('entity key is empty');
          end

          if isempty(d{2})
            error_id = 'emptyLabel';
            error('entity label is empty');
          end

          for j = 1:2
            m = regexp(d{j}, '[^a-zA-Z0-9]', 'match');
            if ~isempty(m)
              error_id = 'invalidChar';
              error('entity and label must be alphanumeric');
            end
          end

          p.entities.(d{1}) = d{2};

        otherwise
          error_id = 'tooManyDashes';
          error('entity contains several ''-''');

      end

    catch ME

      msg = sprintf('Entity-label pair ''%s'' of file %s is not valid: %s.', ...
                    parts{i}, p.filename, ME.message);
      if tolerant
        msg = sprintf('%s\n\tThis file will be ignored.', msg);
      end

      bids.internal.error_handling(mfilename, error_id, ...
                                   msg, ...
                                   tolerant, ...
                                   true);

      if tolerant
        p = struct([]);
        return
      end

    end

  end

end

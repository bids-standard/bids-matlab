function p = parse_filename(filename, fields)
  % Split a filename into its building constituents
  % FORMAT p = bids.internal.parse_filename(filename, fields)
  %
  % Example:
  %
  % >> filename = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  % >> bids.internal.parse_filename(filename)
  %
  % ans =
  %
  %   struct with fields:
  %
  %     filename: 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz'
  %         suffix: 'T1w'
  %          ext: '.nii.gz'
  %          sub: '16'
  %          ses: 'mri'
  %          run: '1'
  %         acq: 'hd'
  % __________________________________________________________________________

  % Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2018--, BIDS-MATLAB developers

  filename = bids.internal.file_utils(filename, 'filename');

  % -Identify all the BIDS entity-label pairs present in the filename (delimited by "_")
  % https://bids-specification.readthedocs.io/en/stable/99-appendices/04-entity-table.html
  [parts, dummy] = regexp(filename, '(?:_)+', 'split', 'match'); %#ok<ASGLU>
  p.filename = filename;

  % -Identify the suffix and extension of this file
  % https://bids-specification.readthedocs.io/en/stable/02-common-principles.html#file-name-structure
  [p.suffix, p.ext] = strtok(parts{end}, '.');

  % -Separate the entity from the label for each pair identified above
  for i = 1:numel(parts) - 1
    [d, dummy] = regexp(parts{i}, '(?:\-)+', 'split', 'match'); %#ok<ASGLU>
    p.entities.(d{1}) = d{2};
  end

  % -Extra fields can be added to the structure and ordered specifically.
  if nargin == 2
    for i = 1:numel(fields)
      p.entities = bids.internal.add_missing_field(p.entities, fields{i});
    end
    try
      p = orderfields(p, {'filename', 'ext', 'suffix', 'entities'});
      p.entities = orderfields(p.entities, fields);
    catch
      warning('bidsMatlab:noMatchingTemplate', ...
              'Ignoring file %s not matching template.', filename);
      p = struct([]);
    end
  end

end

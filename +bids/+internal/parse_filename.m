function p = parse_filename(filename, fields)
  % Split a filename into its building constituents
  % FORMAT p = bids.internal.parse_filename(filename, fields)
  %
  % Example:
  %
  % >> filename = '../sub-16/anat/sub-16_ses-mri_run-1_echo-2_FLASH.nii.gz';
  % >> bids.internal.parse_filename(filename)
  %
  % ans =
  %
  %   struct with fields:
  %
  %     filename: 'sub-16_ses-mri_run-1_echo-2_FLASH.nii.gz'
  %         type: 'FLASH'
  %          ext: '.nii.gz'
  %           gz:  1
  %          tab: 0
  %       depend: {}
  %     intended: {}
  %       entity:          
  %              sub: '16'
  %              ses: 'mri'
  %              run: '1'
  %             echo: '2'
  % __________________________________________________________________________

  % Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2018--, BIDS-MATLAB developers

  filename = bids.internal.file_utils(filename, 'filename');

  % -Identify all the BIDS entity-label pairs present in the filename (delimited by "_")
  % https://bids-specification.readthedocs.io/en/stable/99-appendices/04-entity-table.html
  [parts, dummy] = regexp(filename, '(?:_)+', 'split', 'match'); %#ok<ASGLU>
  p.filename = filename;

  % filename without suffix, usefull to get accompagning files
  p.basename = strjoin(parts(1:end-1), '_');

  % -Identify the suffix and extension of this file
  % https://bids-specification.readthedocs.io/en/stable/02-common-principles.html#file-name-structure
  [p.type, p.ext] = strtok(parts{end}, '.');

  % are files zipped or tabulats
  p.gz = endsWith(p.ext, '.gz', 'IgnoreCase',true);
  p.tab = startsWith(p.ext, '.tsv', 'IgnoreCase',true);
  p.intended = {};

  % -Separate the entity from the label for each pair identified above
  for i = 1:numel(parts) - 1
    [d, dummy] = regexp(parts{i}, '(?:\-)+', 'split', 'match'); %#ok<ASGLU>
    p.entity.(d{1}) = d{2};
  end

  % -Extra fields can be added to the structure and ordered specifically.
  if nargin == 2
    for i = 1:numel(fields)
      if ~isfield(p.entity, fields{i})
        p.entity.(fields{i}) = '';
      end
    end
    try
      p = orderfields(p.entity, [fields]);
    catch
      warning('Ignoring file ''%s'' not matching template.', filename);
      p = struct([]);
    end
  end

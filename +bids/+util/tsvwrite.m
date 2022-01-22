function tsvwrite(filename, var)
  %
  % Save text and numeric data to tab-separated-value file
  %
  % USAGE::
  %
  %   tsvwrite(f, var)
  %
  % :param filename:
  % :type filename: string
  % :param var:
  % :type var: data array or structure
  %
  %
  % Based on spm_save.m from SPM12.
  %
  %
  % (C) Copyright 2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  delim = sprintf('\t');

  % If the input is a MATLAB table, the built-in functionality is used
  % otherwise export is performed manually
  if isstruct(var) || iscell(var) || isnumeric(var) || islogical(var)

    % Convert input to a common format we will use for writing
    % var will be a cell array where the first row is the header and all
    % following rows contains the values to write
    if isstruct(var)

      fn = fieldnames(var);
      var = struct2cell(var)';

      for i = 1:numel(var)

        if ~ischar(var{i})
          var{i} = var{i}(:);
        end

        if ~iscell(var{i})
          var{i} = cellstr(num2str(var{i}, 16));
          var{i} = strtrim(var{i});
          var{i}(cellfun(@(x) strcmp(x, 'NaN'), var{i})) = {'n/a'};
        end

      end

      var = [fn'; var{:}];

    elseif iscell(var) || isnumeric(var) || islogical(var)

      if isnumeric(var) || islogical(var)
        var = num2cell(var);
      end

      var = cellfun(@(x) num2str(x, 16), var, 'UniformOutput', false);
      var = strtrim(var);
      var(cellfun(@(x) strcmp(x, 'NaN'), var)) = {'n/a'};

    end

    write_to_file(filename, var, delim);

  elseif isa(var, 'table')
    writetable(var, filename, ...
               'FileType', 'text', ...
               'Delimiter', delim);

  else
    error('Unknown data type.');

  end

end

function write_to_file(filename, var, delim)

  fid = fopen(filename, 'Wt');

  if fid == -1
    error('Unble to write file %s.', filename);
  end

  for i = 1:size(var, 1)

    for j = 1:size(var, 2)

      to_print = var{i, j};

      if iscell(to_print)
        to_print = to_print{1};
      end

      if isempty(to_print)
        to_print = 'n/a';

      elseif any(to_print == delim)
        to_print = ['"' to_print '"'];

      end

      fprintf(fid, '%s', to_print);

      if j < size(var, 2)
        fprintf(fid, delim);
      end

    end

    fprintf(fid, '\n');
  end

  fclose(fid);
end

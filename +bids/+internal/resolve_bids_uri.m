function pth = resolve_bids_uri(uri, layout)
  %
  % Resolve a bids URI to a fullpath.
  %
  % USAGE::
  %
  %   res = bids.internal.endsWith(str, pattern)
  %
  % :param uri: BIDS URI (taken from an IntendedFor field)
  % :type  uri: char or cellstr
  %
  % :param layout: BIDS layout where the URI is resolved.
  % :type  layout: struct
  %
  %

  % (C) Copyright 2023 BIDS-MATLAB developers

  if ischar(uri)
    uri = {uri};
  end

  pth = {};
  for i = 1:numel(uri)

    if ~bids.internal.starts_with(uri{i}, 'bids')
      pth{i, 1} = uri{i}; %#ok<*AGROW>
      continue

    elseif bids.internal.starts_with(uri{i}, 'bids::')
      str = strrep(uri{i}, 'bids::', '');
      pth{i, 1} = fullfile(layout.pth, convert_path(str));
      continue

    elseif bids.internal.starts_with(uri{i}, 'bids:')

      src = strsplit(uri{i}, ':');
      src = src{2};

      if ~ismember(src, fieldnames(layout.description.DatasetLinks))
        warning(['Could not resolve: %s. ', ...
                 'No %s in dataset_description.DatasetLinks'], ...
                uri{i}, ...
                src);
        pth{i, 1} = uri{i};

      elseif bids.internal.starts_with(src, 'doi:')
        warning('Could not resolve doi URI: %s. ', uri{i});
        pth{i, 1} = uri{i};

      elseif bids.internal.starts_with(src, 'file:')
        warning('Could not resolve file URI: %s. ', uri{i});
        pth{i, 1} = uri{i};

      else

        src =  layout.description.DatasetLinks.(src);

        str = strsplit(uri{i}, ':');
        str = str{end};

        pth{i, 1} = fullfile(layout.pth, ...
                             convert_path(src), ...
                             convert_path(str));

      end

    end

  end

  if isscalar(pth)
    pth = pth{1};
  end

end

function pth = convert_path(pth)
  pth = strsplit(pth, '/');
  pth = strjoin(pth, filesep);
end

function extensions = return_modality_extensions(modality)
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  extensions = '(';

  % for CI
  if iscell(modality)
    modality = modality{1};
  end

  for iExt = 1:numel(modality.extensions)
    if ~strcmp(modality.extensions{iExt}, '.json')
      extensions = [extensions,  modality.extensions{iExt}, '|']; %#ok<AGROW>
    end
  end

  % Replace final "|" by a "){1}"
  extensions(end:end + 3) = '){1}';

end

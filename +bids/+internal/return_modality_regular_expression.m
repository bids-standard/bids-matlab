function regular_expression = return_modality_regular_expression(modality)
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  suffixes = bids.internal.return_modality_suffixes(modality);
  extensions = bids.internal.return_modality_extensions(modality);

  regular_expression = ['^%s.*' suffixes extensions '$'];

end

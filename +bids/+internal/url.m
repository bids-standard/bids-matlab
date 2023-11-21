function value = url(section)
  %
  % returns URL of some specific sections of the spec
  %
  % USAGE::
  %
  %   value = url(section)
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  supported_sections = {'base', 'agnostic-files', 'participants', 'samples', 'description'};

  switch section

    case 'base'
      value = 'https://bids-specification.readthedocs.io/en/latest/';

    case 'agnostic-files'
      value = [bids.internal.url('base'), '03-modality-agnostic-files.html'];

    case 'participants'
      value = [bids.internal.url('agnostic-files'), '#participants-file'];

    case 'samples'
      value = [bids.internal.url('agnostic-files'), '#samples-file'];

    case 'sessions'
      value = [bids.internal.url('agnostic-files'), '#sessions-file'];

    case 'scans'
      value = [bids.internal.url('agnostic-files'), '#scans-file'];

    case 'description'
      value = [bids.internal.url('agnostic-files'), '#dataset_descriptionjson'];

    otherwise
      bids.internal.error_handling(mfilename(), ...
                                   'unknownUrlRequest', ...
                                   sprintf('Section %s unsupported. Supported sections: %s', ...
                                           section, ...
                                           strjoin(supported_sections, ', ')), ...
                                   false);

  end
end

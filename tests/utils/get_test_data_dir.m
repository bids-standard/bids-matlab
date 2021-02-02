function data_dir = get_test_data_dir()

  % default for testing locally
  data_dir = fullfile(fileparts(mfilename('fullpath')), '..');

  PLATFORM  = getenv('PLATFORM');

  if strcmp(PLATFORM, 'GITHUB_ACTIONS')

    data_dir = '/github/workspace/tests/';

  end

  data_dir =  fullfile(data_dir, 'bids-examples');

  if exist(data_dir, 'dir') ~= 7
    msg = sprintf([ ...
                   'The bids-example folder %s was not found.\n', ...
                   'Install it in the tests folder with:\n', ...
                   'git clone git://github.com/bids-standard/bids-examples.git --depth 1']);
    error(msg); %#ok<SPERR>
  end

end

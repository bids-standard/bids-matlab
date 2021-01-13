function dataDir = get_test_data_dir()

  PLATFORM  = getenv('PLATFORM');

  if strcmp(PLATFORM, 'GITHUB_ACTIONS')

    dataDir = '/github/workspace/tests/';

  elseif isempty(PLATFORM)  % local

    dataDir = fullfile(fileparts(mfilename('fullpath')), '..');

  end

  dataDir =  fullfile(dataDir, 'bids-examples');

  fprintf(1, '\n Reading bids-examples data from: %s\n', dataDir);

end

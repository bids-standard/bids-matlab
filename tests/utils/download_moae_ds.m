function output_dir = download_moae_ds(downloadData)
  %
  % Will download the lightweight "Mother of all experiment" dataset from the
  %  SPM website.
  %
  % Copyright (C) 2021--, BIDS-MATLAB developers

  if nargin < 1
    downloadData = true();
  end

  output_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'data');

  if downloadData

    % URL of the data set to download
    URL = 'http://www.fil.ion.ucl.ac.uk/spm/download/data/MoAEpilot/MoAEpilot.bids.zip';

    % clean previous runs
    if exist(fullfile(output_dir, 'MoAEpilot'), 'dir')
      rmdir(fullfile(output_dir, 'MoAEpilot'), 's');
    end

    %% Get data
    fprintf('%-10s:', 'Downloading dataset...');
    urlwrite(URL, 'MoAEpilot.zip');
    fprintf(1, ' Done\n\n');

    fprintf('%-10s:', 'Unzipping dataset...');
    unzip('MoAEpilot.zip');
    delete('MoAEpilot.zip');
    movefile('MoAEpilot', fullfile(output_dir));
    fprintf(1, ' Done\n\n');

  end

end

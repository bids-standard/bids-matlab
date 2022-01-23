function output_dir = download_moae_ds(download_data, output_dir)
  %
  % Will download the lightweight "Mother of all experiment" dataset from the
  %  SPM website.
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  if nargin < 1
    download_data = true();
  end
  if nargin < 2
    output_dir = fullfile(bids.internal.root_dir(), 'examples');
  end

  if download_data

    % URL of the data set to download
    URL = 'http://www.fil.ion.ucl.ac.uk/spm/download/data/MoAEpilot/MoAEpilot.bids.zip';

    % clean previous runs
    if exist(fullfile(output_dir, 'MoAEpilot'), 'dir')
      if bids.internal.is_octave()
        confirm_recursive_rmdir(false, 'local');
      end
      rmdir(fullfile(output_dir, 'MoAEpilot'), 's');
    end

    %% Get data
    % Downloading dataset
    urlwrite(URL, 'MoAEpilot.zip');

    % Unzipping dataset
    unzip('MoAEpilot.zip');
    delete('MoAEpilot.zip');
    movefile('MoAEpilot', fullfile(output_dir));

  end

  output_dir = fullfile(output_dir, 'MoAEpilot');

end

function eeglab_01_download_ds(download_data)
  %
  % Creates a dummy EEG source dataset with 3 subjects and random session numbers and
  % days
  %
  % (C) Copyright 2021 Remi Gau

  if nargin < 1
    download_data = false;
  end

  subjects = {'MaBa', 'ReGa', 'CeBa'};
  ses_prefix = 'day';
  run_prefix = 'run';

  working_directory = fileparts(mfilename('fullpath'));

  if download_data
    dataset_url = 'http://sccn.ucsd.edu/mediawiki/images/9/9c/Eeglab_data.set'; %#ok<CTPCT>
    fprintf('%-10s:', 'Downloading dataset...');
    try
      system(['wget ' dataset_url]);
    catch
      error(['Could not download the dataset.', ...
             '\nDownload manually from %s \nin the directory %s.', ...
             '\nThen run "eeglab_01_download_ds(false)"'], dataset_url, working_directory);
    end
    fprintf(1, ' Done\n\n');
  end

  output_dir = fullfile(working_directory, '..', 'sourcedata');
  if exist(output_dir, 'dir')
    rmdir(output_dir, 's');
  end

  fprintf('%-10s:', 'Reorganize dataset...');

  for sub = 1:numel(subjects)
    sub_folder = fullfile(working_directory, '..', 'sourcedata', subjects{sub});

    for ses = 1:2
      this_ses = app_rand_nb(ses_prefix);

      % create 2 target directory in a session for runs with run number ranging 1-10
      bids.util.mkdir(sub_folder, ...
                      this_ses, ...
                      {app_rand_nb(run_prefix), app_rand_nb(run_prefix)});

      runs = bids.internal.file_utils('FPList', ...
                                      fullfile(sub_folder, this_ses), ...
                                      'dir', ...
                                      ['^' run_prefix '.*$']);
      runs = cellstr(runs);

      % we create some "random name for the target file"
      for i = 1:numel(runs)
        copyfile('Eeglab_data.set', ...
                 fullfile(runs{i}, [app_rand_nb(subjects{sub}) '.set']));
      end

    end

  end

  fprintf(1, ' Done\n\n');

end

function out = app_rand_nb(in)
  out = [in num2str(randi(100))];
end

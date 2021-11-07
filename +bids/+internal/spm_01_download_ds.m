function spm_01_download_ds(download_data, clean)
  %
  % (C) Copyright 2021 Remi Gau

  if nargin < 1
    download_data = true;
  end
  if nargin < 2
    clean = false;
  end

  working_directory = fileparts(mfilename('fullpath'));

  subject_dir = 'BB01';

  % clean previous runs
  output_dir = fullfile(working_directory, '..', 'sourcedata', subject_dir);

  fprintf('%-10s:', 'Unzipping dataset...');
  unzip('multimodal_eeg.zip');
  movefile('EEG', output_dir);
  fprintf(1, ' Done\n\n');

  fprintf('%-10s:', 'Reorganize dataset...');

  [~, ~, ~] = mkdir(fullfile(output_dir, 'run1'));
  movefile(fullfile(output_dir, 'faces_run1.bdf'), ...
           fullfile(output_dir, 'run1', 'faces_run1.bdf'));
  [~, ~, ~] = mkdir(fullfile(output_dir, 'run2'));
  movefile(fullfile(output_dir, 'faces_run2.bdf'), ...
           fullfile(output_dir, 'run2', 'faces_run2.bdf'));
  fprintf(1, ' Done\n\n');

end

% extracts confounds of interest from fmriprep timeseries.tsv
% and saves them for easier ingestion by SPM model specification
%

% (C) Copyright 2022 Remi Gau

path_to_fmriprep = fullfile(pwd, 'fmriprep');
output_folder = fullfile(pwd, 'spm12');

task_label = 'facerepetition';
space_label = 'MNI152NLin2009cAsym';

% set up some regular expression to identify the confounds we want to keep
confounds_of_interest = {'^rot_[xyz]$', '^trans_[xyz]$', '^*outlier*$'};

% index the content of the fmriprep data set and figure out which subjects we
% have
BIDS = bids.layout(path_to_fmriprep, 'use_schema', false);
subjects = bids.query(BIDS, 'subjects');

% prepare the output folder structure
folders = struct('subjects', {subjects}, 'modalities', {{'stats'}});
bids.init(output_folder, 'folders', folders);

for i_sub = 1:numel(subjects)

  % create the filter to
  filter = struct('sub', subjects{i_sub}, ...
                  'task', task_label, ...
                  'desc', 'confounds', ...
                  'suffix', 'timeseries');
  confound_files = bids.query(BIDS, 'data', filter);

  % loop through all the desc-confounds_timeseries.tsv
  % load it
  % get only the condounds we need
  % save it in the output folder as a mat file and a TSV
  for i = 1:numel(confound_files)

    % for mat file
    names = {};
    R = [];

    % for TSV
    new_content = struct();

    % load
    content = bids.util.tsvread(confound_files{i});
    confounds_names = fieldnames(content);

    % create a logical vector to identify which confounds to keep
    % and store confounds to keep in new variables
    confounds_to_keep = regexp(confounds_names, ...
                               strjoin(confounds_of_interest, '|'));
    confounds_to_keep = ~cellfun('isempty', confounds_to_keep);

    confounds_names = confounds_names(confounds_to_keep);

    for j = 1:numel(confounds_names)
      % for mat file
      names{j} = confounds_names{j};
      R(:, j) = content.(confounds_names{j});

      % for TSV
      new_content.(confounds_names{j}) = content.(confounds_names{j});
    end

    % save to mat and TSV
    output_file_name = bids.File(confound_files{i});
    output_file_name.entities.desc = '';
    output_file_name.suffix = 'confounds';

    output_file_name.path = fullfile(output_folder, ['sub-' subjects{i_sub}], 'stats');

    bids.util.tsvwrite(fullfile(output_file_name.path, output_file_name.filename), ...
                       new_content);

    output_file_name.extension = '.mat';
    save(fullfile(output_file_name.path, output_file_name.filename), 'names', 'R');

  end

end

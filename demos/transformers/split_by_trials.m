% Example of how to use transformers to:
%
% - "merge" certain trial type by renaming them using the Replace transformer
% - "split" the trials of certain conditions
%
% For MVPA analyses, this can be used to have 1 beta per trial (and not 1 per run per condition).
%
% (C) Copyright 2021 Remi Gau

clear;

tsv_file = fullfile(pwd, 'data', 'sub-03_task-VisuoTact_run-02_events.tsv');

data = bids.util.tsvread(tsv_file);

data;

% conditions_to_split = {'CONG_LEFT'
%                        'CONG_RIGHT'
%                        'INCONG_VL_PR'
%                        'INCONG_VR_PL'
%                        'P_LEFT'
%                        'P_RIGHT'
%                        'V_LEFT'
%                        'V_RIGHT'};

% same but expressed as regular expressions
conditions_to_split = {'^.*LEFT$'
                       '^.*RIGHT$'
                       '^INCONG.*$'};

% columns headers where to store the new conditions
headers = {'LEFT'
           'RIGHT'
           'INCONG'};

%% merge responses

transformers{1}.Name = 'Replace';
transformers{1}.Input = 'trial_type';
transformers{1}.Replace = struct('key', '^RESPONSE.*', 'value', 'RESPONSE');
transformers{1}.Attribute = 'value';

%% split by trial

for i = 1:numel(conditions_to_split)

  % create a new column where each event of a condition is labelled
  % creates a "tmp" and "label" columns that are deleted after.
  transformers{end + 1}.Name = 'Filter'; %#ok<*SAGROW>
  transformers{end}.Input = 'trial_type';
  transformers{end}.Query = ['trial_type==' conditions_to_split{i}];
  transformers{end}.Output = 'tmp';

  transformers{end + 1}.Name = 'LabelIdenticalRows';
  transformers{end}.Cumulative = true;
  transformers{end}.Input = {'tmp'};
  transformers{end}.Output = {'label'};

  transformers{end + 1}.Name = 'Concatenate';
  transformers{end}.Input = {'tmp', 'label'};
  transformers{end}.Output = headers(i);

  % clean up
  % insert actual NaN
  transformers{end + 1}.Name = 'Replace';
  transformers{end}.Input = headers(i);
  transformers{end}.Replace = struct('key', '^NaN.*', 'value', 'n/a');
  transformers{end}.Attribute = 'value';

  % remove temporary columns
  transformers{end + 1}.Name = 'Delete';
  transformers{end}.Input = {'tmp', 'label'};

end

[new_content, json] = bids.transformers(transformers, data);

% save the new TSV for inspection sto make sure it looks like what we expect
bids.util.tsvwrite(fullfile(pwd, 'new_events.tsv'), new_content);

% generate the transformation section that can be added to the bids stats model
bids.util.jsonencode(fullfile(pwd, 'transformers.json'), json);

% Example of how to use transformers to "split" the trials of certain condition
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

conditions_to_split = {'^.*LEFT$'
                       '^.*RIGHT$'
                       '^INCONG.*$'};

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

bids.util.tsvwrite(fullfile(pwd, 'new_events.tsv'), new_content);
bids.util.jsonencode(fullfile(pwd, 'transformers.json'), json);

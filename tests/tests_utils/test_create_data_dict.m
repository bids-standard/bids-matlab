function test_suite = test_create_data_dict %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_data_dict_several_tsv()

  %% WITH SCHEMA
  % data      time (sec)
  % eeg_face13      0.387
  % ds003     0.480
  % eeg_cbm     0.636
  % ds101     0.963
  % genetics_ukbb     0.989
  % ieeg_visual_multimodal      1.014
  % ds005     1.060
  % ds105     1.064
  % ds102     1.281
  % ds052     1.293
  % eeg_rishikesh     1.486
  % ds008     1.498
  % ds011     1.654
  % ds114     1.667
  % ds109     1.767
  % ds002     1.855
  % ds051     1.873
  % eeg_ds000117      1.900
  % ds116     1.975
  % ds007     2.356
  % ds107     2.386
  % ds113b      2.554
  % ds009     2.732
  % ds210     2.820
  % ds110     3.263
  % ds006     3.378
  % ds108     3.897
  % ds000117      5.958

  datasets = {'ds000248'; ...
              'ds000246'; ...
              'ieeg_visual'; ...
              'ieeg_epilepsy_ecog'; ...
              'eeg_matchingpennies'; ...
              'ds000247'; ...
              'ieeg_filtered_speech'; ...
              'eeg_face13'; ...
              'ds005'; ...
              'ds105'; ...
              'ds102'; ...
              'ds052'; ...
              'eeg_rishikesh'; ...
              'ds008'; ...
              'ds011'; ...
              'ds114'; ...
              'ds109'; ...
              'ds002'; ...
              'ds051'  };

  schema = bids.Schema();
  schema.load_schema_metadata = true;
  schema = schema.load();

  pth_bids_example = get_test_data_dir();

  for i_dataset = 1:numel(datasets)

    dataset = datasets{i_dataset};

    BIDS = bids.layout(fullfile(pth_bids_example, dataset), ...
                       'index_dependencies', false);

    tasks =  bids.query(BIDS, 'tasks');

    for i_task = 1:numel(tasks)

      tsv_files = bids.query(BIDS, 'data', ...
                             'task', tasks{i_task}, ...
                             'suffix', 'events');

      data_dict = bids.util.create_data_dict(tsv_files, ...
                                             'output', [dataset '_' tasks{i_task} '.json'], ...
                                             'schema', schema, ...
                                             'level_limit', 50, ...
                                             'verbose', false);
      teardown([dataset '_' tasks{i_task} '.json']);

    end

  end

end

function test_create_data_dict_participants_tsv()

  pth_bids_example = get_test_data_dir();

  tsv_file = fullfile(pth_bids_example, 'ds008', 'participants.tsv');
  data_dict = bids.util.create_data_dict(tsv_file, 'output', [], 'schema', true);
  assertEqual(fieldnames(data_dict), {'sex'; 'age'});

end

function test_create_data_dict_basic()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds001'), ...
                     'index_dependencies', false);

  tsv_files = bids.query(BIDS, 'data', ...
                         'sub', '01', ...
                         'suffix', 'events');

  % no file written
  bids.util.create_data_dict(tsv_files{1}, 'output', [], 'schema', true);
  assertEqual(exist('tmp.json', 'file'), 0);
  teardown();

  % file written
  data_dict = bids.util.create_data_dict(tsv_files{1}, 'output', 'tmp.json', 'schema', true);
  assertEqual(exist('tmp.json', 'file'), 2);
  assertEqual(data_dict.onset.Units, 's');
  teardown();

  % do not use schema
  data_dict = bids.util.create_data_dict(tsv_files{1}, 'output', [], 'schema', false);
  assertEqual(data_dict.onset.Units, 'TODO');
  teardown();

  % overwrite
  bids.util.create_data_dict(tsv_files{1}, 'output', 'tmp.json', 'schema', true);
  data_dict = bids.util.jsondecode('tmp.json');
  assertEqual(data_dict.onset.Units, 's');
  bids.util.create_data_dict(tsv_files{1}, 'output', 'tmp.json', 'schema', false, ...
                             'force', true);
  data_dict = bids.util.jsondecode('tmp.json');
  assertEqual(data_dict.onset.Units, 'TODO');
  teardown();

end

function test_create_data_dict_schema()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds001'), ...
                     'index_dependencies', false);

  tsv_files = bids.query(BIDS, 'data', ...
                         'suffix', 'events');

  schema = bids.Schema();
  schema.load_schema_metadata = true;
  schema = schema.load();

  data_dict = bids.util.create_data_dict(tsv_files{1}, 'output', 'tmp.json', 'schema', schema);
  teardown();

end

function test_create_data_dict_warning

  skip_if_octave('mixed-string-concat warning thrown');

  dataset = 'ds000248';

  schema = bids.Schema();
  schema.load_schema_metadata = true;
  schema = schema.load();

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, dataset), ...
                     'index_dependencies', false);

  tasks =  bids.query(BIDS, 'tasks');

  tsv_files = bids.query(BIDS, 'data', ...
                         'task', tasks{1}, ...
                         'suffix', 'events');

  assertWarning(@()bids.util.create_data_dict(tsv_files, ...
                                              'schema', schema, ...
                                              'level_limit', 50), ...
                'create_data_dict:modifiedLevel');

end

function teardown(files)
  if nargin < 1
    files = [];
  end
  if exist('tmp.json', 'file')
    delete('tmp.json');
  end
  if ~isempty(files) && exist(files, 'file')
    delete(files);
  end
  if exist('modified_levels.tsv', 'file') == 2
    delete('modified_levels.tsv');
  end
end

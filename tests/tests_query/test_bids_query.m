function test_suite = test_bids_query %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_query_phenotype()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'pet002'));

  phenotype = bids.query(BIDS,  'phenotype');

  assertEqual(phenotype, struct('name', [], 'data', [], 'metadata', []));

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'fnirs_automaticity'));

  phenotype = bids.query(BIDS,  'phenotype');

  assertEqual(phenotype(1).name, 'practicelogbook');

  assertEqual(fieldnames(phenotype(1).data), ...
              {'participant_id'
               'day'
               'hour'
               'practiceduration_finger'
               'practiceduration_foot'
               'selfassessment_finger'
               'selfassessment_foot'
               'notes'});

  assertEqual(fieldnames(phenotype(1).metadata), ...
              {'MeasurementToolMetadata'
               'day'
               'hour'
               'practiceduration_finger'
               'practiceduration_foot'
               'selfassessment_finger'
               'selfassessment_foot'
               'notes'});

end

function test_query_participants()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'pet002'));

  participants = bids.query(BIDS,  'participants');

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'asl001'));

  participants = bids.query(BIDS,  'participants');

end

function test_query_impossible_suffix_should_return_empty()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'synthetic'));

  % no suffix bold in anat
  filter = struct('sub', '01', ...
                  'ses', '01', ...
                  'modality', {'anat'}, ...
                  'suffix', 'bold');

  data = bids.query(BIDS, 'tasks', filter);

  assert(isempty(data));

end

function test_query_suffixes()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'pet002'));

  suffixes = {'T1w', 'pet'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'synthetic'));

  suffixes = {'T1w'};
  assertEqual(bids.query(BIDS, 'suffixes', 'modality', 'anat'), suffixes);

end

function test_query_subjects()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ieeg_visual'));

  subjs = arrayfun(@(x) sprintf('%02d', x), 1:2, 'UniformOutput', false);
  assertEqual(bids.query(BIDS, 'subjects'), subjs);

end

function test_query_regex_subjects_no_regex_by_default()

  if bids.internal.is_octave()
    return
    %
    %   failure: regexp: nothing to repeat at position 1 of expression
    %   query>check_label_with_regex:414 (/github/workspace/+bids/query.m)
    %   query>perform_query:259 (/github/workspace/+bids/query.m)
    %   query:130 (/github/workspace/+bids/query.m)
    %   test_bids_query>test_query_regex_subjects_no_regex_by_default:64
    %       (/github/workspace/tests/tests_query/test_bids_query.m)
    %
  end

  BIDS = bids.layout(fullfile(get_test_data_dir(), '..', 'data', 'synthetic'));

  data = bids.query(BIDS, 'subjects', 'sub', '01');

  assertEqual(numel(data), 1);

  data = bids.query(BIDS, 'subjects', 'sub', '*01');

  assertEqual(numel(data), 3);

end

function test_query_regex_subjects()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ds000247'));

  data = bids.query(BIDS, 'data', 'sub', '.*', 'suffix', 'T1w');

  assertEqual(size(data, 1), 5);

  data = bids.query(BIDS, 'data', 'sub', '000[36]', 'suffix', 'T1w');

  assertEqual(size(data, 1), 2);

end

function test_query_with_indices()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ds105'));

  data_1 = bids.query(BIDS, 'data', 'sub', '1', 'run', {3, 5, '7', '01'}, 'suffix', 'bold');
  data_2 = bids.query(BIDS, 'data', 'sub', '1', 'run', 1:2:7, 'suffix', 'bold');

  assertEqual(data_1, data_2);

end

function test_query_entities()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'qmri_qsm'));

  entities = bids.query(BIDS, 'entities');

  expected = {'part'
              'sub'};

  assertEqual(entities, expected);

  %%
  BIDS = bids.layout(fullfile(get_test_data_dir(), 'pet002'));

  entities = bids.query(BIDS, 'entities', 'suffix', 'pet');

  expected = {'ses'
              'sub'};

  assertEqual(entities, expected);

end

function test_query_events_tsv_in_root()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'synthetic'));

  data = bids.query(BIDS, 'data', 'sub', '01', 'ses', '01', 'task', 'nback', 'suffix', 'events');

  assertEqual(data, ...
              {bids.internal.file_utils(fullfile(get_test_data_dir(), ...
                                                 'synthetic', ...
                                                 'task-nback_events.tsv'), 'cpath')});

end

function test_query_exclude_entity()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ds000246'));

  filter = struct('sub', '0001');
  assertEqual(bids.query(BIDS, 'modalities', filter), {'anat', 'meg'});

  filter = struct('sub', '0001', 'suffix', 'photo');
  assertEqual(bids.query(BIDS, 'modalities', filter), {'meg'});

  filter = struct('sub', '0001', 'acq', 'NAS');
  assertEqual(bids.query(BIDS, 'modalities', filter), {'meg'});

  filter = struct('sub', '0001', 'acq', '');
  assertEqual(bids.query(BIDS, 'suffixes', filter), ...
              {'T1w', 'channels', 'headshape', 'meg', 'scans'});

end

function test_query_basic()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'pet005'));

  tasks = {'eyes'};
  assertEqual(bids.query(BIDS, 'tasks'), tasks);

  assert(isempty(bids.query(BIDS, 'runs', 'suffix', 'T1w')));

  sessions = {'baseline', 'intervention'};
  assertEqual(bids.query(BIDS, 'sessions'), sessions);
  assertEqual(bids.query(BIDS, 'sessions', 'suffix', 'pet'), sessions);

end

function test_query_data_filter()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'pet005'));

  % make sure that query can work with filter
  filters = {'sub', {'01'}; ...
             'task', {'eyes'}; ...
             'ses', 'intervention'};

  files_cell_filter = bids.query(BIDS, 'data', filters);
  assertEqual(size(files_cell_filter, 1), 2);

  filters = struct('sub', '01', ...
                   'suffix', 'pet');
  filters.ses = {'baseline', 'intervention'};

  files_struct_filter = bids.query(BIDS, 'data', filters);
  assertEqual(size(files_struct_filter, 1), 2);

end

function test_query_extension()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'qmri_tb1tfl'));

  extensions = bids.query(BIDS, 'extensions');

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'extension', '.nii.gz', ...
                    'suffix', 'TB1TFL');
  assertEqual(size(data, 1), 2);

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'extension', '.json');
  assertEqual(size(data, 1), 0);

end

function test_query_metadata()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'qmri_tb1tfl'));

  md = bids.query(BIDS, 'metadata', ...
                  'sub', '01', ...
                  'acq', 'anat', ...
                  'suffix', 'TB1TFL');
  assert(isstruct(md) & isfield(md, 'RepetitionTime') & isfield(md, 'SequenceName'));
  assert(strcmp(md.RepetitionTime, '6.8'));
  assert(strcmp(md.SequenceName, 'tfl_b1_map'));

end

function test_query_modalities()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'pet002'));

  modalities = {'anat', 'pet'};

  assertEqual(bids.query(BIDS, 'modalities'), modalities);
  assertEqual(bids.query(BIDS, 'modalities', 'sub', '01'), modalities);
  assertEqual(bids.query(BIDS, 'modalities', 'sub', '01', 'ses', 'rescan'), modalities);

end

function test_query_tsv_content()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'eeg_ds003645s_hed_inheritance'));

  tsv_content = bids.query(BIDS, 'tsv_content', 'suffix', 'events');

  assertEqual(numel(tsv_content), 3);
  assertEqual(fieldnames(tsv_content{1}), ...
              {'onset'; ...
               'duration'; ...
               'sample'; ...
               'event_type'; ...
               'face_type'; ...
               'rep_status'; ...
               'trial'; ...
               'rep_lag'; ...
               'value'; ...
               'stim_file'});

end

function test_query_tsv_content_error()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'qmri_tb1tfl'));
  assertExceptionThrown(@()bids.query(BIDS, 'tsv_content', 'extension', '.nii.gz'), ...
                        'query:notJustTsvFiles');

end

function test_query_sessions()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'synthetic'));
  sessions = {'01', '02'};
  assertEqual(bids.query(BIDS, 'sessions'), sessions);
  assertEqual(bids.query(BIDS, 'sessions', 'sub', '02'), sessions);

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'qmri_tb1tfl'));

  assert(isempty(bids.query(BIDS, 'sessions')));

end

function test_query_sessions_tsv()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'synthetic'));

  suffixes = bids.query(BIDS, 'suffixes');
  assert(ismember('sessions', suffixes));

  sessions_tsv = bids.query(BIDS, 'data', 'suffix', 'sessions');
  assertEqual(numel(sessions_tsv), 5);

  sessions_tsv = bids.query(BIDS, 'data', 'suffix', 'sessions', ...
                            'sub', '01');
  assertEqual(numel(sessions_tsv), 1);

  sessions_tsv = bids.query(BIDS, 'data', 'suffix', 'sessions', ...
                            'sub', '01', ...
                            'ses', 'joy');
  assertEqual(numel(sessions_tsv), 0);

  sessions_tsv = bids.query(BIDS, 'data', 'suffix', 'sessions', ...
                            'sub', '0[1-3]');
  assertEqual(numel(sessions_tsv), 3);

  data = bids.query(BIDS, 'data', 'sub', '01');
  assertEqual(numel(data), 23);
  assert(ismember('sub-01_sessions.tsv', ...
                  bids.internal.file_utils(data, 'filename')));

  data = bids.query(BIDS, 'data', 'sub', '01', ...
                    'suffix', 'events');
  assertEqual(numel(data), 1);
  assert(~ismember('sub-01_sessions.tsv', ...
                   bids.internal.file_utils(data, 'filename')));

  data = bids.query(BIDS, 'data', 'sub', '01', ...
                    'task', 'nback');
  assertEqual(numel(data), 13);
  assert(~ismember('sub-01_sessions.tsv', ...
                   bids.internal.file_utils(data, 'filename')));

end

function test_query_scans_tsv()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'motion_spotrotation'));

  suffixes = bids.query(BIDS, 'suffixes');
  assert(ismember('scans', suffixes));

  scans_tsv = bids.query(BIDS, 'data', 'suffix', 'scans');
  assertEqual(numel(scans_tsv), 10);

  scans_tsv = bids.query(BIDS, 'data', 'suffix', 'scans', ...
                         'sub', '01');
  assertEqual(numel(scans_tsv), 2);

  scans_tsv = bids.query(BIDS, 'data', 'suffix', 'scans', ...
                         'sub', '01', ...
                         'ses', 'joy');
  assertEqual(numel(scans_tsv), 1);

  scans_tsv = bids.query(BIDS, 'data', 'suffix', 'scans', ...
                         'sub', '0[1-3]', ...
                         'ses', '.*o.*');
  assertEqual(numel(scans_tsv), 6);

  data = bids.query(BIDS, 'data', 'sub', '01', ...
                    'ses', 'joy');
  assertEqual(numel(data), 9);
  assert(ismember('sub-01_ses-joy_scans.tsv', ...
                  bids.internal.file_utils(data, 'filename')));

  data = bids.query(BIDS, 'data', 'sub', '01', ...
                    'ses', 'joy', ...
                    'suffix', 'events');
  assertEqual(numel(data), 1);
  assert(~ismember('sub-01_ses-joy_scans.tsv', ...
                   bids.internal.file_utils(data, 'filename')));

  data = bids.query(BIDS, 'data', 'sub', '01', ...
                    'ses', 'joy', ...
                    'task', 'Rotation');
  assertEqual(numel(data), 7);
  assert(~ismember('sub-01_ses-joy_scans.tsv', ...
                   bids.internal.file_utils(data, 'filename')));
end

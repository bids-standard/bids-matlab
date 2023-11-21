function test_suite = test_bids_query_meg %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_meg_basic()
  %
  %   meg queries
  %

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ds000246'), ...
                     'index_dependencies', false);

  modalities = {'anat', 'meg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'channels', 'headshape', 'meg', 'photo', 'scans'};
  % missing: 'coordsystem'
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  % smoke tests
  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ds000248'), ...
                     'index_dependencies', false);

  dependencies = bids.query(BIDS, 'dependencies', 'sub', '01', 'suffix', 'meg');

  assertEqual(numel(dependencies.group), 2);

end

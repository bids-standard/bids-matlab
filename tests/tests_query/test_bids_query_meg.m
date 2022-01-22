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

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds000246'));

  modalities = {'anat', 'meg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'channels', 'headshape', 'meg', 'photo'};
  % missing: 'coordsystem'
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  % smoke tests
  BIDS = bids.layout(fullfile(pth_bids_example, 'ds000247'));

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds000248'));

  dependencies = bids.query(BIDS, 'dependencies', 'sub', '01', 'suffix', 'meg');

  assertEqual(numel(dependencies.group), 2);

end

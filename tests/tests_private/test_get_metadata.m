function test_suite = test_get_metadata %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_get_metadata_basic()

  % Small test to ensure that metadata are reported correctly
  % also tests inheritance principle: metadata are passed on to lower levels
  % unless they are overriden by metadate already present at lower levels

  pth = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'synthetic');

  % define the expected output from bids query metadata
  func.RepetitionTime = 7;
  anat.FlipAngle = 5;

  func_sub_01.RepetitionTime = 10;
  anat_sub_01.FlipAngle = 10;
  anat_sub_01.Manufacturer = 'Siemens';

  % try to get metadata
  BIDS = bids.layout(pth);

  %% test func metadata base directory
  metadata = bids.query(BIDS, 'metadata', 'suffix', 'bold');
  %   assert(metadata.RepetitionTime == func.RepetitionTime);

  %% test func metadata subject 01
  metadata = bids.query(BIDS, 'metadata', 'sub', '01', 'suffix', 'bold');
  assert(metadata.RepetitionTime == func_sub_01.RepetitionTime);

  %% test anat metadata base directory
  metadata = bids.query(BIDS, 'metadata', 'suffix', 'T1w');
  %   assert(metadata.FlipAngle == anat.FlipAngle);

  %% test anat metadata subject 01
  metadata = bids.query(BIDS, 'metadata', 'sub', '01', 'suffix', 'T1w');
  assertEqual(metadata.FlipAngle, anat_sub_01.FlipAngle);
  assertEqual(metadata.Manufacturer, anat_sub_01.Manufacturer);

end

function test_get_metadata_internal()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'qmri_tb1tfl'));

  bids.internal.get_metadata(BIDS(1).subjects(1).fmap(1).metafile);

end

function test_get_metadata_participants()
  % test files with no underscore in name.

  pth_bids_example = get_test_data_dir();

  file = fullfile(pth_bids_example, 'pet002', 'participants.tsv');
  side_car = fullfile(pth_bids_example, 'pet002', 'participants.json');

  metalist = bids.internal.get_meta_list(file);
  metadata = bids.internal.get_metadata(metalist);

  expected_metadata = bids.util.jsondecode(side_car);
  assertEqual(metadata, expected_metadata);

end

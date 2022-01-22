function test_suite = test_get_metadata_suffixes %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_get_metadata_suffixes_basic()
  % ensures that "similar" suffixes are distinguished

  data_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'surface_data');

  file = fullfile(data_dir, 'sub-06_hemi-R_space-individual_den-native_thickness.shape.gii');
  side_car = fullfile(data_dir, 'sub-06_hemi-R_space-individual_den-native_thickness.json');

  metalist = bids.internal.get_meta_list(file);
  metadata = bids.internal.get_metadata(metalist);

  expected_metadata = bids.util.jsondecode(side_car);

  assertEqual(metadata, expected_metadata);

  file = fullfile(data_dir, 'sub-06_hemi-R_space-individual_den-native_midthickness.surf.gii');
  side_car = fullfile(data_dir, 'sub-06_hemi-R_space-individual_den-native_midthickness.json');

  metalist = bids.internal.get_meta_list(file);
  metadata = bids.internal.get_metadata(metalist);

  expected_metadata = bids.util.jsondecode(side_car);
  assertEqual(metadata, expected_metadata);

  file = fullfile(data_dir, 'sub-06_space-individual_den-native_thickness.dscalar.nii');
  side_car = fullfile(data_dir, 'sub-06_space-individual_den-native_thickness.json');

  metalist = bids.internal.get_meta_list(file);
  metadata = bids.internal.get_metadata(metalist);

  expected_metadata = bids.util.jsondecode(side_car);

  assertEqual(metadata, expected_metadata);

end

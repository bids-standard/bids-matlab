function test_suite = test_bids_description %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_description()

  % generate dataset_description
  ds_desc = bids.Description();

  content = struct( ...
                   'Name', 'Multisubject, multimodal face processing', ...
                   'BIDSVersion', '1.0.2', ...
                   'Authors', 'Wakeman, DG', ...
                   'License', 'CC0', ...
                   'DatasetDOI', '10.18112/openneuro.ds000117.v1.0.4', ...
                   'Acknowledgements', ...
                   'This work was supported by the UK Medical Research Council', ...
                   'HowToAcknowledge', ...
                   'Cite this paper: https://www.ncbi.nlm.nih.gov/pubmed/25977808');

  content.Funding = {'UK Medical Research Council (SUAG/010 RG91365), Elekta Ltd.'};

  content.ReferencesAndLinks = {'https://www.ncbi.nlm.nih.gov/pubmed/25977808'; ...
                                'https://openfmri.org/dataset/ds000117/'};

  ds_desc = ds_desc.set_field(content);
  ds_desc = ds_desc.append('Authors', 'Henson, RN');
  ds_desc = ds_desc.append('ReferencesAndLinks', ...
                           ['ftp://ftp.mrc-cbu.cam.ac.uk/personal/rik.henson/', ...
                            'wakemandg_hensonrn/Publications/']);

  ds_desc = ds_desc.unset_field('HEDVersion');

  ds_desc.write();

  %%
  expected = fullfile(fileparts(mfilename('fullpath')), 'data', 'dataset_description.json');
  expected = bids.util.jsondecode(expected);

  actual = fullfile(pwd, 'dataset_description.json');
  actual  = bids.util.jsondecode(actual);

  assertEqual(actual, expected);

  delete(fullfile(pwd, 'dataset_description.json'));

end

function test_description_derivative()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds003'));

  ds_desc = bids.Description('my_pipeline', BIDS);

  ds_desc = ds_desc.append('GeneratedBy', struct('Name', 'Manual'));

  ds_desc.write();

  delete(fullfile(pwd, 'dataset_description.json'));

end

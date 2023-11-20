function test_suite = test_layout_bugs %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_inheritance_several_files_per_level()

  bids_dir = fullfile(get_test_data_dir(), 'asl001');

  verbose = false;

  BIDS = bids.layout(bids_dir, 'verbose', verbose);

  data = bids.query(BIDS, 'data', 'modality', 'anat');

  bf = bids.File(data{1});

  bf.entities.run = '1';
  bf.update();

  new_file = bids.internal.file_utils(data{1}, 'filename', bf.filename);
  copyfile(data{1}, new_file);

  new_json = fullfile(fileparts(bf.path), bf.json_filename);
  bids.util.jsonencode(new_json, bf.metadata);

  BIDS = bids.layout(bids_dir, 'verbose', verbose);
  assertEqual(numel(BIDS.subjects.anat(1).metafile), 1);
  assertEqual(numel(BIDS.subjects.anat(2).metafile), 1);

  BIDS = bids.layout(bids_dir, 'verbose', verbose, 'use_schema', false);
  assertEqual(numel(BIDS.subjects.anat(1).metafile), 1);
  assertEqual(numel(BIDS.subjects.anat(2).metafile), 1);

  delete(new_file);
  delete(new_json);

end

function test_inheritance_several_files_per_level_derivatives()

  bids_dir = tempname;
  mkdir(bids_dir);

  folders.subjects = {'01'};
  folders.sessions = {'01'};
  folders.modalities = {'anat'};

  bids.init(bids_dir, ...
            'folders', folders, ...
            'is_derivative', true, ...
            'is_datalad_ds', false);

  input = struct('ext', '.nii', ...
                 'suffix', 'T1w', ...
                 'modality', 'anat', ...
                 'entities', struct('sub', '01', ...
                                    'ses', '01', ...
                                    'desc',  'preproc'));
  bf = bids.File(input);
  bf = touch(bf, bids_dir);
  bf = bf.metadata_add('RepetitionTime', 1);
  bf.metadata_write();

  input.entities.space = 'MNI';
  bf = bids.File(input);
  bf = touch(bf, bids_dir);
  bf = bf.metadata_add('RepetitionTime', 1);
  bf.metadata_write();

  verbose = false;

  BIDS = bids.layout(bids_dir, 'verbose', verbose, 'use_schema', false);

  assertEqual(numel(BIDS.subjects.anat(1).metafile), 1);
  assertEqual(numel(BIDS.subjects.anat(2).metafile), 1);

end

function bf = touch(bf, bids_dir)
  bf.path = fullfile(bids_dir, bf.bids_path, bf.filename);
  bids.util.mkdir(fileparts(bf.path));

  fid = fopen(bf.path, 'w');
  fprintf(fid, 'foo');
  fclose(fid);
end

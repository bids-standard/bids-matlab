function test_suite = test_parse_filename_prefix %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_prefix()

  filename = 'asub-16_task-rest_run-1_bold.nii';
  output = bids.internal.parse_filename(filename);

  expected = struct('filename', 'asub-16_task-rest_run-1_bold.nii', ...
                    'suffix', 'bold', ...
                    'prefix', 'a', ...
                    'ext', '.nii', ...
                    'entities', struct('sub', '16', ...
                                       'task', 'rest', ...
                                       'run', '1'));

  assertEqual(output, expected);

  expectedEntities = fieldnames(expected.entities);
  entities = fieldnames(output.entities);
  assertEqual(entities, expectedEntities);

end

function test_prefix_repeated_entity()

  filename = 'asub-16_task-rest_wsub-1_bold.nii';
  output = bids.internal.parse_filename(filename);

  expected = struct('filename', 'asub-16_task-rest_wsub-1_bold.nii', ...
                    'suffix', 'bold', ...
                    'prefix', 'a', ...
                    'ext', '.nii', ...
                    'entities', struct('sub', '16', ...
                                       'task', 'rest', ...
                                       'wsub', '1'));

  assertEqual(output, expected);

  expectedEntities = fieldnames(expected.entities);
  entities = fieldnames(output.entities);
  assertEqual(entities, expectedEntities);

end

function test_prefix_sub_entity_later()
  % sub containing entity later in the filename
  % NOT SURE THIS IS THE EXPECTED BEHAVIOR
  filename = 'group-ctrl_wsub-1_bold.nii';
  output = bids.internal.parse_filename(filename);

  expected = struct('filename', 'group-ctrl_wsub-1_bold.nii', ...
                    'suffix', 'bold', ...
                    'prefix', 'group-ctrl_w', ...
                    'ext', '.nii', ...
                    'entities', struct('sub', '1'));

  assertEqual(output, expected);

  expectedEntities = fieldnames(expected.entities);
  entities = fieldnames(output.entities);
  assertEqual(entities, expectedEntities);

end

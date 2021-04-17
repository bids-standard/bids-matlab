function test_suite = test_create_filename %#ok<*STOUT>
  %
  % Copyright (C) 2021 BIDS-MATLAB developers
    
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_create_filename_basic()
    
    %% Create filename
    p.suffix = 'bold';
    p.ext = '.nii';
    p.entities = struct(...
                        'sub', '01', ...
                        'ses', 'test', ...
                        'task', 'face recognition', ...
                        'run', '02');
    
    filename = bids.util.create_filename(p);
    
    assertEqual(filename, 'sub-01_ses-test_task-faceRecognition_run-02_bold.nii');
    
    %% Modify existing filename
    p.entities = struct(...
        'sub', '02', ...
        'task', 'new task');
    
    filename = bids.util.create_filename(p, fullfile(pwd,filename));
    
    assertEqual(filename, 'sub-02_ses-test_task-newTask_run-02_bold.nii');    

    %% Remove entity from filename
    p.entities = struct('ses', '');

    filename = bids.util.create_filename(p, filename);
    
    assertEqual(filename, 'sub-02_task-newTask_run-02_bold.nii');
    
end
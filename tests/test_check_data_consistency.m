function test_suite = test_check_data_consistency()
    % This top function is necessary for mox unit to run tests.
    % DO NOT CHANGE IT except to adapt the name of the function.
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions(); %#ok<*NASGU>
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;
end

function test_function_to_test_basic()

    % empty entry
    assertExceptionThrown(@()bids.util.check_data_consistency([]), 'MATLAB:emptyStructure');

    % invalid option
    assertExceptionThrown(@()bids.util.check_data_consistency({'x'}, 'xxxx'),...
                          'MATLAB:invalidArgument');

    %% data to test against
    flist_1 = {'sub-001_acq-X_run-01_BOLD.nii.gz'; 'sub-001_acq-X_run-02_BOLD.nii.gz'};
    flist_2 = {'sub-001_acq-X_run-01_events.tsv'; 'sub-001_acq-X_run-02_events.tsv'};
    flist_3 = {'sub-001_acq-X_run-01_dwi.nii.gz'; 'sub-001_acq-X_run-02_dwi.nii.gz'};
    flist_4 = {'sub-001_acq-X_run-01_dwi.bval'; 'sub-001_acq-X_run-02_dwi.bval'};
    flist_5 = {'sub-001_acq-Y_run-01_BOLD.nii.gz'; 'sub-001_acq-Y_run-02_BOLD.nii.gz'};

    % succesful run
    assertTrue(bids.util.check_data_consistency([flist_1, flist_2]));
    assertExceptionThrown(@()bids.util.check_data_consistency([flist_1, flist_5]), ...
                          'BIDS:invalidEntity');

    % duplicated files
    assertExceptionThrown(@()bids.util.check_data_consistency([flist_1, flist_1]),...
                          'BIDS:duplicatedFile');
    assertTrue(bids.util.check_data_consistency([flist_1, flist_1], 'allow_duplicates'));

    % same suffix
    assertTrue(bids.util.check_data_consistency([flist_3, flist_4],...
                                                'same_suffix'));
    assertExceptionThrown(@()bids.util.check_data_consistency([flist_1, flist_3],...
                                                              'same_suffix'),...
                          'BIDS:invalidSuffix');
                        
    % same extension
    assertTrue(bids.util.check_data_consistency([flist_1, flist_3],...
                                                'same_extension'));
    assertExceptionThrown(@()bids.util.check_data_consistency([flist_3, flist_4],...
                                                              'same_extension'),...
                          'BIDS:invalidExtension');

    % empty suffix
    flist_1 = {'sub-001.nii.gz'; 'sub-001.nii.gz'};
    flist_2 = {'sub-001.tsv'; 'sub-001.tsv'};
    assertTrue(bids.util.check_data_consistency([flist_1, flist_2]));
end

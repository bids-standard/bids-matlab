function test_suite = test_plot_diagnostic_table %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_plot_diagnostic_table_2X2()

  headers{1}.modality = 'anat';
  headers{2}.modality = 'func';
  headers{2}.task = 'rhyme';

  data = [0, 1; ...
          4, 10];

  y_labels = {'sub-01 ses-02'; ...
              'sub-02 ses-02'};

  bids.internal.plot_diagnostic_table(data, ...
                                      headers, ...
                                      y_labels, ...
                                      'ds dummy');

end

function test_plot_diagnostic_table_2X3()

  headers{1}.modality = 'anat';
  headers{2}.modality = 'func';
  headers{2}.task = 'rhyme';
  headers{3}.modality = 'func';
  headers{3}.task = 'listen';

  data = [0, 1, 3; ...
          4, 10, 5];

  y_labels = {'sub-01 ses-02'; ...
              'sub-02 ses-02'};

  bids.internal.plot_diagnostic_table(data, ...
                                      headers, ...
                                      y_labels, ...
                                      'ds dummy');

end

function test_plot_diagnostic_table_3X3()

  headers{1}.modality = 'anat';
  headers{1}.modality = 'adwi';
  headers{2}.modality = 'func';
  headers{2}.task = 'rhyme';
  headers{3}.modality = 'func';
  headers{3}.task = 'listen';

  data = [0, 1, 3; ...
          4, 10, 5; ...
          1, 2, 2];

  y_labels = {'sub-01 ses-02'; ...
              'sub-02 ses-02'
              'sub-02 ses-01'};

  bids.internal.plot_diagnostic_table(data, ...
                                      headers, ...
                                      y_labels, ...
                                      'ds dummy');

end

function test_plot_diagnostic_table_error()

  headers{1}.modality = 'anat';
  headers{2}.modality = 'func';

  data = 0;

  assertExceptionThrown(@()bids.internal.plot_diagnostic_table(data, ...
                                                               headers, ...
                                                               {'sub-01 ses-02'}, ...
                                                               'ds dummy'), ...
                        'plot_diagnostic_table:tableLabelsMismatch');

end

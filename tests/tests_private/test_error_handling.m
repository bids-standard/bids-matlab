function test_suite = test_error_handling %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_basic()

  function_name = mfilename;
  id = 'unspecified';
  msg = 'warning';
  tolerant = true;
  verbose = true;

  bids.internal.error_handling(function_name, id, msg, tolerant, verbose);

  assertWarning( ...
                @()bids.internal.error_handling(function_name, id, msg, tolerant, verbose), ...
                'test_error_handling:unspecified');

  tolerant = false;

  assertExceptionThrown( ...
                        @()bids.internal.error_handling(function_name, ...
                                                        id, ...
                                                        msg, ...
                                                        tolerant, ...
                                                        verbose), ...
                        'test_error_handling:unspecified');

end

% function test_bids_query_tolerant_layout()
%
%     use_schema =  true;
%     index_derivatives = false;
%     tolerant = true;
%     verbose = true;
%
%     pth_bids_example = get_test_data_dir();
%
%     %%
%     BIDS = bids.layout(fullfile(pth_bids_example, 'eeg_face13'),...
%         use_schema, ...
%         index_derivatives, ...
%         tolerant, ...
%         verbose);
% end

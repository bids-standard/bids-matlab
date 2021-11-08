close all;

pth_bids_example = get_test_data_dir();

examples = bids.internal.file_utils('FPList', get_test_data_dir(), 'dir', '^ds.*[0-9]$');
examples = bids.internal.file_utils('FPList', get_test_data_dir(), 'dir', '^ds0002.*$');

for i = 1:size(examples, 1)

  BIDS = bids.layout(deblank(examples(i, :)));

  diagnostic_table = bids.diagnostic(BIDS);

end

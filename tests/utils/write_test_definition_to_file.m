function write_test_definition_to_file(input, output, trans, test_name, test_type)

  if strfind(test_name, 'multi') %#ok<STRIFCND>
    return
  end

  test_name =  strrep(test_name, 'test_', '');

  output_dir = fullfile(pwd, 'tmp', test_type, test_name);
  bids.util.mkdir(output_dir);

  input_file = fullfile(output_dir, 'input.tsv');
  bids.util.tsvwrite(input_file, input);

  input_file = fullfile(output_dir, 'output.tsv');
  bids.util.tsvwrite(input_file, output);

  trans_file = fullfile(output_dir, 'transformation.json');
  content = struct('Description', strrep(test_name, '_', ' '), ...
                   'Instruction', {{trans}});
  bids.util.jsonencode(trans_file, content);

end

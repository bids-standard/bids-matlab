function layout_timing
  %
  % runs bids.layout on the bids-examples
  % and gives an estimate of the timing for each
  %

  DEBUG = false;

  use_schema_list = [true false];
  index_dependencies_list = [true false];

  output = struct('name', {{}});

  for j = 1:numel(use_schema_list)
    use_schema =  use_schema_list(j);

    for k = 1:numel(index_dependencies_list)
      index_dependencies = index_dependencies_list(k);

      output.(field(use_schema, index_dependencies, '_nb_files')) = [];
      output.(field(use_schema, index_dependencies, '_time')) = [];
    end
  end

  d = dir(get_test_data_dir());
  d(arrayfun(@(x) ~x.isdir || ismember(x.name, ...
                                       {'.', '..', '.git', '.github', ...
                                        'docs', 'tools'}), ...
             d)) = [];

  for i = 1:numel(d)

    if DEBUG && i > 4
      break
    end

    output.name{i} = d(i).name;
    fprintf(1, '%s\n', d(i).name);

    for j = 1:numel(use_schema_list)
      use_schema =  use_schema_list(j);

      for k = 1:numel(index_dependencies_list)
        index_dependencies = index_dependencies_list(k);

        [time, nb_files] = run_on_examples(d(i).name, use_schema, index_dependencies);

        output.(field(use_schema, index_dependencies, '_nb_files'))(end + 1) = nb_files;
        output.(field(use_schema, index_dependencies, '_time'))(end + 1) = time;
      end
    end

  end

  bids.util.tsvwrite('timing.tsv', output);

end

function value = field(use_schema, index_dependencies, suffix)
  pattern = 'schema_%i_depedencies_%i';
  value = sprintf([pattern suffix], ...
                  use_schema, ...
                  index_dependencies);
end

function [time, nb_files] = run_on_examples(name, use_schema, index_dependencies)

  if use_schema && exist(fullfile(get_test_data_dir(), name, '.SKIP_VALIDATION'), 'file')
    time = nan;
    nb_files = nan;
    return
  end

  tic;
  BIDS = bids.layout(fullfile(get_test_data_dir(), name), ...
                     'use_schema', use_schema, ...
                     'index_dependencies', index_dependencies, ...
                     'verbose', false);
  time = toc;
  nb_files = numel(bids.query(BIDS, 'data'));

end

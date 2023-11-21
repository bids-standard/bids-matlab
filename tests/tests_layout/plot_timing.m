close all;
clear;

use_schema_list = [true false];
index_dependencies_list = [true false];

data = bids.util.tsvread('timing.tsv');

figure();

hold on;

legend_name = {};

for j = 1:numel(use_schema_list)
  use_schema =  use_schema_list(j);

  for k = 1:numel(index_dependencies_list)
    index_dependencies = index_dependencies_list(k);

    legend_name{end + 1} = strrep(field(use_schema, index_dependencies, ''), ...
                                  '_', ' '); %#ok<*SAGROW>

    nb_files = data.(field(use_schema, index_dependencies, '_nb_files'));
    time = data.(field(use_schema, index_dependencies, '_time'));

    s = scatter(nb_files, time, 100, '.');

  end
end

xlabel('number of files');
ylabel('time (sec)');

% axis([0 50 0 2.5])

legend(legend_name, 'location', 'NorthWest');

print(gcf, 'timing.png', '-dpng');

%%
function value = field(use_schema, index_dependencies, suffix)
  pattern = 'schema_%i_depedencies_%i';
  value = sprintf([pattern suffix], ...
                  use_schema, ...
                  index_dependencies);
end

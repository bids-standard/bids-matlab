function plot_diagnostic_table(diagnostic_table, headers, yticklabel, fig_name)
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  if ~all(size(diagnostic_table) == [numel(yticklabel), numel(headers)])

    bids.internal.error_handling(mfilename(), ...
                                 'tableLabelsMismatch', ...
                                 sprintf(['table dimensions [%i, %i] does not match', ...
                                          ' number of rows (%i) and columns labels (%i)\n'], ...
                                         size(diagnostic_table, 1), size(diagnostic_table, 2), ...
                                         numel(yticklabel), numel(headers)), ...
                                 false);

  end

  % prepare x tick labels
  for col = 1:numel(headers)
    xticklabel{col} = [headers{col}.modality];
    if isfield(headers{col}, 'task')
      xticklabel{col} = sprintf('%s - task: %s', headers{col}.modality,  headers{col}.task);
    end
    if length(xticklabel{col}) > 43
      xticklabel{col} = [xticklabel{col}(1:40) '...'];
    end
  end

  nb_rows = size(diagnostic_table, 1);
  nb_cols = size(diagnostic_table, 2);

  figure('name', 'diagnostic_table', 'position', [1000 1000 50 + 350 * nb_cols 50 + 100 * nb_rows]);

  hold on;

  colormap('gray');

  imagesc(diagnostic_table, [0, max(diagnostic_table(:))]);

  % x axis
  set(gca, 'XAxisLocation', 'top', ...
      'xTick', 1:nb_cols, ...
      'xTickLabel', xticklabel, ...
      'TickLength', [0.001 0.001]);

  if any(cellfun('length', xticklabel) > 40)
    set(gca, ...
        'xTick', (1:nb_cols) - 0.25, ...
        'XTickLabelRotation', 25);
  end

  % y axis
  set(gca, 'yTick', 1:nb_rows);

  if nb_rows < 50
    set(gca, 'yTickLabel', yticklabel);
  end

  box(gca, 'on');

  % TODO
  % fix diagnonal line that appear for some table dimensions

  % add horizontal borders
  x_borders = [0 nb_cols] + 0.5;
  y_borders = [[2:nb_rows]', [2:nb_rows]'] - 0.5;
  plot(x_borders, y_borders, '-w');

  % add vertical borders
  y_borders = [0 nb_rows] + 0.5;
  x_borders = [[2:nb_cols]', [2:nb_cols]'] - 0.5;
  plot(x_borders, y_borders, '-w');

  %   % tried using grid to use as borders
  %   % but there seems to always be the main grid overlaid on the values
  %
  %   set(gca, 'XMinorGrid', 'on', 'YMinorGrid', 'off', ...
  %             'MinorGridColor', 'w', ...
  %             'MinorGridAlpha', 0.5, ...
  %             'MinorGridLineStyle', '-', ...
  %             'LineWidth', 2, ...
  %             'Layer', 'top');
  %
  %   ca = gca;
  %
  %   % the following lines crash on Octave
  %   ca.XAxis.MinorTickValues = ca.XAxis.TickValues(1:) + 0.5;
  %   ca.YAxis.MinorTickValues = ca.YAxis.TickValues + 0.5;

  axis tight;

  % plot actual values if there are not too many
  if numel(diagnostic_table) < 600
    for col = 1:nb_cols
      for row = 1:nb_rows
        t = text(col, row, sprintf('%i', diagnostic_table(row, col)));
        set(t, 'Color', 'blue');
        if diagnostic_table(row, col) == 0
          set(t, 'Color', 'red');
        end
      end
    end
  end

  colorbar();

  title(fig_name);

end
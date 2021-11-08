function diagnostic_table = diagnostic(varargin)
    %
    %
    %
    %
    % (C) Copyright 2021 BIDS-MATLAB developers

    default_BIDS = pwd;
    default_schema = true;
    default_filter = struct();
    default_output_path = '';

    p = inputParser;

    charOrStruct = @(x) ischar(x) || isstruct(x);

    addOptional(p, 'BIDS', default_BIDS, charOrStruct);
    addParameter(p, 'use_schema', default_schema);
    addParameter(p, 'output_path', default_output_path, @ischar);
    addParameter(p, 'filter', default_filter, @isstruct);

    parse(p, varargin{:});

    BIDS = bids.layout(p.Results.BIDS);

    filter = p.Results.filter;

    subjects = bids.query(BIDS, 'subjects', filter);

    sessions = bids.query(BIDS, 'sessions', filter);
    if isempty(sessions)
        sessions = {''};
    end

    modalities = bids.query(BIDS, 'modalities', filter);

    tasks = bids.query(BIDS, 'tasks', filter);

    headers = {};
    for i_modality = 1:numel(modalities)

        if ismember(modalities(i_modality), {'func', 'eeg', 'meg', 'ieeg', 'pet', 'beh'})
            for i_task = 1:numel(tasks)
                headers{end + 1} = struct('modality', modalities(i_modality), ...
                    'task', tasks(i_task));
            end

        else
            headers{end + 1} = struct('modality', modalities(i_modality));

        end
    end

    diagnostic_table = nan(numel(subjects) * numel(sessions), numel(modalities));

    row = 1;

    for i_sub = 1:numel(subjects)

        for i_sess = 1:numel(sessions)

            this_filter = filter;
            this_filter.sub = subjects{i_sub};
            this_filter.ses = sessions{i_sess};

            files = bids.query(BIDS, 'data', this_filter);

            if size(files, 1) == 0
                continue
            end

            for i_col = 1:numel(headers)

                this_filter.modality = headers{i_col}.modality;
                if isfield(headers{i_col}, 'task')
                    this_filter.task = headers{i_col}.task;
                end

                files = bids.query(BIDS, 'data', this_filter);

                diagnostic_table(row, i_col) = size(files, 1);

            end

            sub_ses{row} = ['sub-' this_filter.sub];
            if ~isempty(this_filter.ses)
                sub_ses{row} = ['sub-' this_filter.sub ' ses-' this_filter.ses];
            end

            row = row + 1;

        end

    end

    plot_diagnostic_table(diagnostic_table, headers, sub_ses, BIDS.description.Name)

end

function plot_diagnostic_table(diagnostic_table, headers, yticklabel, fig_name)

    for col = 1:numel(headers)
        xticklabel{col} = [headers{col}.modality];
        if isfield(headers{col}, 'task')
            xticklabel{col} = sprintf('%s - task: %s', headers{col}.modality,  headers{col}.task);
        end
        if length(xticklabel{col}) > 50
            xticklabel{col} = [xticklabel{col}(1:40) '...'];
        end
    end

    nb_rows = size(diagnostic_table, 1);
    nb_cols = size(diagnostic_table, 2);

    figure('name', 'diagnostic_table', 'position', [1000 1000 50 + 350 * nb_cols 50 + 100 * nb_rows]);

    colormap('gray');

    imagesc(diagnostic_table, [0, max(diagnostic_table(:))]);

    set(gca, 'XAxisLocation', 'top', ...
        'xTick', 1:nb_cols, ...
        'xTickLabel', xticklabel, ...
        'TickLength', [0.005 0.005]);

    if any(cellfun('length', xticklabel) > 40)
        set(gca, ...
            'xTick', (1:nb_cols) - 0.25, ...
            'XTickLabelRotation', 25);
    end

    set(gca, 'yTick', 1:nb_rows);
    if nb_rows < 50
        set(gca, 'yTick', 1:nb_rows, 'yTickLabel', yticklabel);
    end

    if numel(diagnostic_table) < 200
        for col = 1:nb_cols
            for row = 1:nb_rows
                t = text(col, row, sprintf('%i', diagnostic_table(row, col)));
                if diagnostic_table(row, col) == 0
                    set(t, 'Color', 'red');
                end
            end
        end
    end

    colorbar();

    title(fig_name);

end

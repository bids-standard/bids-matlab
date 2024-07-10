classdef Model
  %
  % Class to deal with BIDS stats models
  %
  % See the `BIDS stats model website
  % <https://bids-standard.github.io/stats-models>`_
  % for more information.
  %
  % USAGE:: matlab
  %
  %   bm = bids.Model('init', true, ...
  %                   'file', path_to_bids_stats_model_file, ...
  %                   'tolerant', true,
  %                   'verbose', false);
  %
  % :param init: if ``true`` this will initialize an empty model. Defaults to ``false``.
  % :type init: logical
  %
  % :param file: fullpath the JSON file containing the BIDS stats model
  % :type file: path
  %
  % :param tolerant: turns errors into warning
  % :type tolerant: logical
  %
  % :param verbose: silences warnings
  % :type verbose: logical
  %
  % Examples
  % --------
  %
  % .. code-block:: matlab
  %
  %   % initialize and write an empty model
  %   bm = bids.Model('init', true);
  %   filename = fullfile(pwd, 'model-foo_smdl.json');
  %   bm.write(filename);
  %
  % .. code-block:: matlab
  %
  %   % load a stats model from a file
  %   model_file = fullfile(get_test_data_dir(), ...
  %                         '..', ...
  %                         'data', ...
  %                         'model', ['model-narps_smdl.json']);
  %
  %   bm = bids.Model('file', model_file, 'verbose', false);
  %
  %

  % (C) Copyright 2022 Remi Gau

  properties

    content = '' % "raw" content of a loaded JSON

    Name = 'REQUIRED' % Name of the model

    Description = 'RECOMMENDED' % Description of the model

    BIDSModelVersion = '1.0.0' % Version of the model

    Input = 'REQUIRED' % Input of the model

    Nodes =  {'REQUIRED'} % Nodes of the model

    Edges = {} % Edges of the model

    tolerant = true % if ``true`` turns error into warning

    verbose = true % hides warning if ``false``

    dag_built = false % if the directed acyclic graph has been built

  end

  methods

    function obj = Model(varargin)

      args = inputParser;

      is_file = @(x) exist(x, 'file');

      args.addParameter('init', false, @islogical);
      args.addParameter('file', '', is_file);
      args.addParameter('tolerant', obj.tolerant, @islogical);
      args.addParameter('verbose', obj.verbose, @islogical);

      args.parse(varargin{:});

      obj.tolerant = args.Results.tolerant;
      obj.verbose = args.Results.verbose;

      if args.Results.init || strcmp(args.Results.file, '')

        obj.Name = 'empty_model';
        obj.Description = 'This is an empty BIDS stats model.';
        obj.Input = struct('task', {{''}});
        obj.Nodes{1} = bids.Model.empty_node('run');

        obj = update(obj);

        return
      end

      if ~isempty(args.Results.file)

        obj.content = bids.util.jsondecode(args.Results.file);

        if ~isfield(obj.content, 'Name')
          bids.internal.error_handling(mfilename(), ...
                                       'nameRequired', ...
                                       'Name field required', ...
                                       obj.tolerant, ...
                                       obj.verbose);
        else
          obj.Name = obj.content.Name;
        end

        if isfield(obj.content, 'Description')
          obj.Description = obj.content.Description;
        end

        if ~isfield(obj.content, 'BIDSModelVersion')
          bids.internal.error_handling(mfilename(), ...
                                       'BIDSModelVersionRequired', ...
                                       'BIDSModelVersion field required', ...
                                       obj.tolerant, ...
                                       obj.verbose);
        else
          obj.BIDSModelVersion = obj.content.BIDSModelVersion;
        end

        if ~isfield(obj.content, 'Input')
          bids.internal.error_handling(mfilename(), ...
                                       'InputRequired', ...
                                       'Input field required', ...
                                       obj.tolerant, ...
                                       obj.verbose);
        else
          obj.Input = obj.content.Input;
        end

        % Nodes are coerced into cells
        % to make easier to deal with them later
        if ~isfield(obj.content, 'Nodes')
          bids.internal.error_handling(mfilename(), ...
                                       'NodesRequired', ...
                                       'Nodes field required', ...
                                       obj.tolerant, ...
                                       obj.verbose);
        else

          if iscell(obj.content.Nodes)
            obj.Nodes = obj.content.Nodes;
          elseif isstruct(obj.content.Nodes)
            for iNode = 1:numel(obj.content.Nodes)
              obj.Nodes{iNode, 1} = obj.content.Nodes(iNode);
            end
          end

        end

        % Contrasts are coerced into cells
        % to make easier to deal with them later
        for iNode = 1:numel(obj.content.Nodes)
          if isfield(obj.Nodes{iNode, 1}, 'Contrasts') && isstruct(obj.Nodes{iNode, 1}.Contrasts)
            for iCon = 1:numel(obj.Nodes{iNode, 1}.Contrasts)
              tmp{iCon, 1} = obj.Nodes{iNode, 1}.Contrasts(iCon);
            end
            obj.Nodes{iNode, 1}.Contrasts = tmp;
            clear tmp;
          end
        end

        % Edges are coerced into cells
        % to make easier to deal with them later
        if isfield(obj.content, 'Edges')
          if iscell(obj.content.Edges)
            obj.Edges = obj.content.Edges;
          elseif isstruct(obj.content.Edges)
            for i = 1:numel(obj.content.Edges)
              obj.Edges{i, 1} = obj.content.Edges(i);
            end
          end

        else
          obj = get_edges_from_nodes(obj);

        end

        obj = obj.build_dag;
        obj.validate();

      end

    end

    %% Setters
    function obj = set.Name(obj, name)
      obj.Name = name;
    end

    function obj = set.Description(obj, desc)
      obj.Description = desc;
    end

    function obj = set.BIDSModelVersion(obj, version)
      obj.BIDSModelVersion = version;
    end

    function obj = set.Input(obj, input)
      obj.Input = input;
    end

    function obj = set.Nodes(obj, nodes)
      obj.Nodes = nodes;
    end

    function obj = set.Edges(obj, edges)
      if nargin < 2
        edges = [];
      end
      if isempty(edges)
        % assume nodes follow each other linearly
        obj = get_edges_from_nodes(obj);
      else
        obj.Edges = edges;
      end
    end

    %% Getters
    function value = get.Name(obj)
      value = obj.Name;
    end

    function value = get.Input(obj)
      value = obj.Input;
    end

    function value = get.Nodes(obj)
      value = obj.Nodes;
    end

    function value = get.Edges(obj)
      value = obj.Edges;
    end

    function [value, idx] = get_nodes(obj, varargin)
      %
      % Get a specific node from the model given its Level and / or Name.
      %
      % USAGE::
      %
      %   [value, idx] = bm.get_nodes('Level', '', 'Name', '')
      %
      %
      % :param Level: Must be one of ``Run``, ``Session``, ``Subject``, ``Dataset``.
      %               Default to ``''``
      % :type init: char
      %
      % :param Name: Default to ``''``
      % :type file: path
      %
      % Returns: value - Node(s) as struct if there is only one or a cell if more
      %          idx   - Node index
      %
      % Example
      % -------
      %
      % .. code-block:: matlab
      %
      %   bm = bids.Model('file', model_file('narps'), 'verbose', false);
      %
      %   % Get all nodes
      %   bm.get_nodes()
      %
      %   % Get run level node
      %   bm.get_nodes('Level', 'Run')
      %
      %   % Get the "Negative" node
      %   bm.get_nodes('Name', 'negative')
      %
      %
      if isempty(varargin)
        value = obj.Nodes;
        idx = 1:numel(value);

        value = format_output(value, idx);

        return

      end

      value = {};

      allowed_levels = @(x) all(ismember(lower(x), {'', 'run', 'session', 'subject', 'dataset'}));

      args = inputParser;
      args.addParameter('Level', '', allowed_levels);
      args.addParameter('Name', '');
      args.parse(varargin{:});

      Level = lower(args.Results.Level);
      Name = lower(args.Results.Name);  %#ok<*PROPLC>

      % return all nodes if no argument is given
      if strcmp(Name, '') && strcmp(Level, '')
        value = obj.Nodes;
        idx = 1:numel(value);

        value = format_output(value, idx);

        return

      end

      % otherwise we identify them by the arguments given
      % Name takes precedence as Name are supposed to be unique
      if ~strcmp(Level, '')
        if ischar(Level)
          Level = {Level};
        end
        levels = cellfun(@(x) lower(x.Level), obj.Nodes, 'UniformOutput', false);
        idx = ismember(levels, Level);
      end

      if ~strcmp(Name, '')
        if ischar(Name)
          Name = {Name};
        end
        names = cellfun(@(x) lower(x.Name), obj.Nodes, 'UniformOutput', false);
        idx = ismember(names, Name);
      end

      % TODO merge idx when both Level and Name are passed as parameters ?
      if any(idx)
        idx = find(idx);
        for i = 1:numel(idx)
          value{end + 1} = obj.Nodes{idx(i)};
        end

      else
        for i = 1:numel(obj.Nodes)
          tmp{i} = ['Name: "', obj.Nodes{i}.Name '"; ', ...
                    'Level: "' obj.Nodes{i}.Level '"']; %#ok<AGROW>
        end
        msg = sprintf(['Could not find a corresponding Node with', ...
                       '\n  Name: "%s"; Level: "%s"', ...
                       '\n\n  Available nodes:%s'], ...
                      char(Name), char(Level), ...
                      bids.internal.create_unordered_list(tmp));

        bids.internal.error_handling(mfilename(), 'missingNode', msg, ...
                                     obj.tolerant, ...
                                     obj.verbose);
      end

      value = format_output(value, idx);

      % local subfunction to ensure that cells are returned if more than one
      % node and struct otherwise
      function value = format_output(value, idx)
        if ~iscell(value) && numel(idx) > 1
          value = {value};
        elseif iscell(value) && numel(value) == 1
          value = value{1};
        end
      end

    end

    function source_nodes = get_parent(obj, node_name)
      source_nodes = obj.get_source_node(node_name);
    end

    function source_nodes = get_source_node(obj, node_name)

      obj = obj.build_dag;

      source_nodes = {};

      % The root node cannot have a source
      [~, root_node_name] = obj.get_root_node();
      if strcmp(node_name, root_node_name)
        return
      end

      node = obj.get_nodes('Name', node_name);
      source_nodes = obj.get_nodes('Name', node.parent);

    end

    function [root_node, root_node_name] = get_root_node(obj)

      obj = obj.build_dag;
      edges = obj.Edges;

      if isempty(edges)
        % assume a serial model
        root_node = obj.Nodes(1);
        if iscell(root_node)
          root_node = root_node{1};
        end
        root_node_name = root_node.Name;
        return
      end

      % start from the first edge and go up the DAG
      if iscell(edges)
        current_node_name = edges{1}.Source;
      elseif isstruct(edges(1))
        current_node_name = edges(1).Source;
      end

      while true

        current_node = obj.get_nodes('Name', current_node_name);
        has_parent = isfield(current_node, 'parent');

        if ~has_parent
          root_node_name = current_node.Name;
          break
        end

        current_node_name = current_node.parent;
      end

      root_node = current_node;

      if iscell(root_node)
        root_node = root_node{1};
      end

    end

    function edge = get_edge(obj, field, value)
      %
      % USAGE::
      %
      %     edge = bm.get_edges(field, value)
      %
      % field can be any of {'Source', 'Destination'}
      %

      edge = {};

      if ~ismember(field, {'Source', 'Destination'})
        bids.internal.error_handling(mfilename(), ...
                                     'wrongEdgeQuery', ...
                                     'Can only query Edges based on Source or Destination', ...
                                     obj.tolerant, ...
                                     obj.verbose);
      end

      if isempty(obj.Edges)
        obj = obj.get_edges_from_nodes;
      end

      % for 'Destination' we should only get a single value
      % for 'Source' we can get several
      for i = 1:numel(obj.Edges)
        if strcmp(obj.Edges{i}.(field), value)
          edge{end + 1} = obj.Edges{i};
        end
      end

      if isempty(edge)
        msg = sprintf('Could not find a corresponding Edge.');
        bids.internal.error_handling(mfilename(), 'missingEdge', msg, ...
                                     obj.tolerant, ...
                                     obj.verbose);
      end

      if strcmp(field, 'Destination') && numel(edge) > 1
        msg = sprintf('Getting more than one Edge with Destination %s.', value);
        bids.internal.error_handling(mfilename(), 'tooManyEdges', msg, ...
                                     obj.tolerant, ...
                                     obj.verbose);
      end

      if numel(edge) == 1
        edge = edge{1};
      end

    end

    function obj = get_edges_from_nodes(obj)
      %
      % Generates all the default edges from the list of nodes in the model.
      %
      % USAGE::
      %
      %   bm = bm.get_edges_from_nodes();
      %   edges = bm.Edges();
      %
      if numel(obj.Nodes) <= 1
        return
      end
      for i = 1:(numel(obj.Nodes) - 1)
        obj.Edges{i, 1} = struct('Source', obj.Nodes{i, 1}.Name, ...
                                 'Destination', obj.Nodes{i + 1, 1}.Name);
      end
    end

    function value = node_names(obj)
      value = cellfun(@(x) x.Name, obj.Nodes, 'UniformOutput', false);
    end

    function obj = build_dag(obj)
      if  obj.dag_built
        return
      end
      if isempty(obj.Edges)
        obj = obj.get_edges_from_nodes;
      end
      for iEdge = 1:numel(obj.Edges)
        source = obj.Edges{iEdge}.Source;
        destination = obj.Edges{iEdge}.Destination;
        [~, idx] = obj.get_nodes('Name', destination);
        % assume can only have a single parent
        % so we use a char and note cellstr
        obj.Nodes{idx}.parent = source;
      end
      obj.dag_built = true;
    end

    function validate(obj)
      %
      % Very light validation of fields that were not checked on loading.
      % Automatically run on loaoding of a dataset.
      %
      % USAGE::
      %
      %  bm.validate()
      %

      REQUIRED_NODES_FIELDS = {'Level', 'Name', 'Model'};
      REQUIRED_TRANSFORMATIONS_FIELDS = {'Transformer', 'Instructions'};
      REQUIRED_MODEL_FIELDS = {'Type', 'X'};
      REQUIRED_HRF_FIELDS = {'Variables', 'Model'};
      REQUIRED_CONTRASTS_FIELDS = {'Name', 'ConditionList', 'Weights', 'Test'};
      REQUIRED_DUMMY_CONTRASTS_FIELDS = {'Contrasts'};

      % Nodes
      nodes = obj.Nodes;
      for i = 1:(numel(nodes))

        this_node = nodes{i, 1};

        fields_present = fieldnames(this_node);
        if any(~ismember(REQUIRED_NODES_FIELDS, fields_present))
          obj.model_validation_error('Nodes', REQUIRED_NODES_FIELDS);
        end

        check = struct('Model', {REQUIRED_MODEL_FIELDS}, ...
                       'Transformations', {REQUIRED_TRANSFORMATIONS_FIELDS}, ...
                       'DummyConstrasts', {REQUIRED_DUMMY_CONTRASTS_FIELDS}, ...
                       'Contrasts', {REQUIRED_CONTRASTS_FIELDS});

        field_to_check = fieldnames(check);

        for j = 1:numel(field_to_check)

          if ~isfield(this_node, field_to_check{j})
            continue
          end

          if strcmp(field_to_check{j}, 'Contrasts')

            for contrast = 1:numel(this_node.Contrasts)

              fields_present = bids.Model.get_keys(this_node.Contrasts(contrast));
              if ~iscellstr(fields_present)
                fields_present = fields_present{1};
              end

              if any(~ismember(check.Contrasts, fields_present))
                obj.model_validation_error('Contrasts', check.Contrasts);
              end

              obj.validate_constrasts(this_node);

            end

          else

            fields_present = bids.Model.get_keys(this_node.(field_to_check{j}));

            if any(~ismember(check.(field_to_check{j}), fields_present))
              obj.model_validation_error(field_to_check{j}, check.(field_to_check{j}));
            end

          end

          if strcmp(field_to_check{j}, 'Model')

            if isfield(this_node.Model, 'HRF') && ~isempty(this_node.Model.HRF)

              fields_present = fieldnames(this_node.Model.HRF);
              if any(~ismember(REQUIRED_HRF_FIELDS, fields_present))
                obj.model_validation_error('HRF', REQUIRED_HRF_FIELDS);
              end

            end

          end

        end

      end

      if numel(nodes) > 1
        obj.validate_edges();
      end

    end

    function validate_edges(obj)
      %
      % USAGE::
      %
      %  bm.validate_edges()
      %

      REQUIRED_EDGES_FIELDS = {'Source', 'Destination'};

      edges = obj.Edges;

      if ~isempty(edges)

        all_nodes = {};

        for i = 1:(numel(edges))

          this_edge = edges{i, 1};

          all_nodes{end + 1} = this_edge.Source;
          all_nodes{end + 1} = this_edge.Destination;

          if ~isstruct(this_edge)
            obj.model_validation_error('Edges', REQUIRED_EDGES_FIELDS);
            continue

          end

          fields_present = fieldnames(this_edge);
          if any(~ismember(REQUIRED_EDGES_FIELDS, fields_present))
            obj.model_validation_error('Edges', REQUIRED_EDGES_FIELDS);
          end

          if ~ismember(this_edge.Source, obj.node_names()) || ...
              ~ismember(this_edge.Destination, obj.node_names())

            bids.internal.error_handling(mfilename(), ...
                                         'edgeRefersToUnknownNode', ...
                                         sprintf(['Edge refers to unknown Node. ', ...
                                                  'Available Nodes: %s.'], ...
                                                 strjoin(obj.node_names(), ', ')), ...
                                         obj.tolerant, ...
                                         obj.verbose);

          end

        end

        all_nodes = unique(all_nodes);
        node_names = obj.node_names();
        missing_nodes = ~ismember(obj.node_names(), all_nodes);
        if any(missing_nodes)
          bids.internal.error_handling(mfilename(), ...
                                       'nodeMissingFromEdges', ...
                                       sprintf(['\nNodes named "%s" missing from "Edges":', ...
                                                'they will not be run.'], ...
                                               strjoin(node_names(missing_nodes), ', ')), ...
                                       obj.tolerant, ...
                                       obj.verbose);
        end

      end

    end

    %% Node level methods
    % assumes that only one node is being queried
    function [value, idx] = get_transformations(obj, varargin)
      %
      % USAGE::
      %
      %   transformations = bm.get_transformations('Name', 'node_name')
      %
      % :param Name: name of the node whose transformations we want
      % :type Name: char
      %
      value = [];
      [node, idx] = get_nodes(obj, varargin{:});
      assert(numel(node) == 1);
      if isfield(node, 'Transformations')
        value = node.Transformations;
      end
    end

    function [value, idx] = get_dummy_contrasts(obj, varargin)
      %
      % USAGE::
      %
      %   dummy_contrasts = bm.get_dummy_contrasts('Name', 'node_name')
      %
      % :param Name: name of the node whose dummy contrasts we want
      % :type Name: char
      %
      value = [];
      [node, idx] = get_nodes(obj, varargin{:});
      assert(numel(node) == 1);
      if isfield(node, 'DummyContrasts')
        value = node.DummyContrasts;
      end
    end

    function [value, idx] = get_contrasts(obj, varargin)
      %
      % USAGE::
      %
      %   contrasts = bm.get_contrasts('Name', 'node_name')
      %
      % :param Name: name of the node whose contrasts we want
      % :type Name: char
      %
      value = [];
      [node, idx] = get_nodes(obj, varargin{:});
      assert(numel(node) == 1);
      if isfield(node, 'Contrasts')
        value = node.Contrasts;
      end
    end

    function [value, idx] = get_model(obj, varargin)
      %
      % USAGE::
      %
      %   model = bm.get_model('Name', 'node_name')
      %
      % :param Name: name of the node whose model we want
      % :type Name: char
      %
      [node, idx] = get_nodes(obj, varargin{:});
      assert(numel(node) == 1);
      value = node.Model;
    end

    function value = get_design_matrix(obj, varargin)
      %
      % USAGE::
      %
      %   matrix = bm.get_design_matrix('Name', 'node_name')
      %
      % :param Name: name of the node whose model matrix we want
      % :type Name: char
      %
      model = get_model(obj, varargin{:});
      value = model.X;
    end

    %% Other
    function obj = default(obj, varargin)
      %
      % Generates a default BIDS stats model for a given data set
      %
      % USAGE::
      %
      %   bm = bm.default(BIDS, tasks)
      %
      % :param BIDS: fullpath to a BIDS dataset or output structure from ``bids.layout``
      % :type  BIDS: path or structure
      %
      % :param tasks: tasks to include in the model
      % :type  tasks: char or cellstr
      %
      % Example
      % -------
      %
      % .. code-block:: matlab
      %
      %   pth_bids_example = get_test_data_dir();
      %   BIDS = bids.layout(fullfile(pth_bids_example, 'ds003'));
      %   bm = bids.Model();
      %   bm = bm.default(BIDS, 'rhymejudgement');
      %   filename = fullfile(pwd, 'model-rhymejudgement_smdl.json');
      %   bm.write(filename);
      %

      is_dir_or_struct = @(x) isstruct(x) || isdir(x);  %#ok<*ISDIR>
      is_char_or_cellstr = @(x) ischar(x) || iscellstr(x); %#ok<*ISCLSTR>

      args = inputParser;
      args.addRequired('layout', is_dir_or_struct);
      args.addOptional('tasks', '', is_char_or_cellstr);

      args.parse(varargin{:});

      tasks = args.Results.tasks;
      if ischar(tasks)
        tasks =  cellstr(tasks);
      end
      if strcmp(tasks{1}, '')
        tasks = bids.query(args.Results.layout, 'tasks');
      end
      if isempty(tasks)
        msg = sprintf('No task found in dataset %s', ...
                      bids.internal.format_path(args.Results.layout.pth));
        bids.internal.error_handling(mfilename(), ...
                                     'noTaskDetected', ...
                                     msg, ...
                                     obj.tolerant, ...
                                     obj.verbose);
      end
      sessions = bids.query(args.Results.layout, 'sessions');

      GroupBy_level_1 = {'run', 'subject'};
      if ~isempty(sessions)
        GroupBy_level_1 = {'run', 'session', 'subject'};
      end

      obj.Input.task = tasks;
      obj.Name = sprintf('default_%s_model', strjoin(tasks, '_'));
      obj.Description = sprintf('default BIDS stats model for %s task', strjoin(tasks, '/'));

      % Define design matrix by including all trial_types and a constant
      trial_type_list = bids.internal.list_all_trial_types(args.Results.layout, tasks, ...
                                                           'verbose', obj.verbose, ...
                                                           'tolerant', obj.tolerant);
      trial_type_list = cellfun(@(x) strjoin({'trial_type.', x}, ''), ...
                                trial_type_list, ...
                                'UniformOutput', false);
      obj.Nodes{1}.Model.X = cat(1, trial_type_list, '1');

      obj.Nodes{1}.GroupBy = GroupBy_level_1;
      obj.Nodes{1}.Model.HRF.Variables = trial_type_list;
      obj.Nodes{1}.DummyContrasts.Contrasts = trial_type_list;

      sessions = bids.query(args.Results.layout, 'sessions', 'task', tasks);
      if ~isempty(sessions)
        obj.Nodes{end + 1, 1} = bids.Model.empty_node('session');
      end
      obj.Nodes{end + 1, 1} = bids.Model.empty_node('subject');
      obj.Nodes{end, 1} = rmfield(obj.Nodes{end, 1}, 'Transformations');
      obj.Nodes{end, 1}.Model = rmfield(obj.Nodes{end, 1}.Model, 'HRF');
      obj.Nodes{end + 1, 1} = bids.Model.empty_node('dataset');
      obj.Nodes{end, 1} = rmfield(obj.Nodes{end, 1}, 'Transformations');
      obj.Nodes{end, 1}.Model = rmfield(obj.Nodes{end, 1}.Model, 'HRF');

      obj = get_edges_from_nodes(obj);
      obj.validate();
      obj = obj.update();

    end

    function obj = update(obj)
      %
      % Update ``content`` for writing
      %
      % USAGE::
      %
      %   bm = bm.update()
      %

      obj.content.Name = obj.Name;
      obj.content.BIDSModelVersion = obj.BIDSModelVersion;
      obj.content.Description = obj.Description;
      obj.content.Input = obj.Input;

      % coerce some fields of Nodes to make sure the output JSON is valid
      obj.content.Nodes = obj.Nodes;

      for i = 1:numel(obj.content.Nodes)

        this_node = obj.content.Nodes{i};

        if isnumeric(this_node.Model.X) && numel(this_node.Model.X) == 1
          this_node.Model.X = {this_node.Model.X};
        end

        if isfield(this_node, 'Contrasts')
          for j = 1:numel(this_node.Contrasts)

            this_contrast = this_node.Contrasts{j};

            if ~isempty(this_contrast.Weights) && ...
                ~iscell(this_contrast.Weights) && ...
                numel(this_contrast.Weights) == 1
              this_contrast.Weights = {this_contrast.Weights};
            end

            if isnumeric(this_contrast.ConditionList) && ...
                numel(this_contrast.ConditionList) == 1
              this_contrast.ConditionList = {this_contrast.ConditionList};
            end

            this_node.Contrasts{j} = this_contrast;

          end
        end

        if isfield(this_node, 'parent')
          this_node = rmfield(this_node, 'parent');
        end

        obj.content.Nodes{i} = this_node;

      end

      obj.content.Edges = obj.Edges;

    end

    function write(obj, filename)
      %
      % USAGE::
      %
      %   bm.write(filename)
      %

      obj = update(obj);
      bids.util.mkdir(fileparts(filename));
      bids.util.jsonencode(filename, obj.content);

    end

    function validate_constrasts(obj, node)

      if ~isfield(node, 'Contrasts')
        return
      end

      for iCon = 1:numel(node.Contrasts)

        if ~isfield(node.Contrasts{iCon}, 'Weights')
          msg = sprintf('No weights specified for Contrast %s of Node %s', ...
                        node.Contrasts{iCon}.Name, node.Name);
          bids.internal.error_handling(mfilename(), ...
                                       'weightsRequired', ...
                                       msg, ...
                                       obj.tolerant, ...
                                       obj.verbose);
        end

        switch node.Contrasts{iCon}.Test
          case 't'
            nb_weights = numel(node.Contrasts{iCon}.Weights);
          case 'F'
            nb_weights = size(node.Contrasts{iCon}.Weights, 2);
        end

        if nb_weights ~= numel(node.Contrasts{iCon}.ConditionList)
          msg = sprintf('Number of Weights and Conditions unequal for Contrast %s of Node %s', ...
                        node.Contrasts{iCon}.Name, node.Name);
          bids.internal.error_handling(mfilename(), ...
                                       'numelWeightsConditionMismatch', ...
                                       msg, ...
                                       obj.tolerant, ...
                                       obj.verbose);
        end

      end

    end

  end

  methods (Static)

    function node = empty_node(level)
      %
      % USAGE::
      %
      %   node = Model.empty_node('run')
      %

      node =  struct('Level', [upper(level(1)) level(2:end)], ...
                     'Name', level, ...
                     'GroupBy', {{''}}, ...
                     'Transformations', {bids.Model.empty_transformations()}, ...
                     'Model', bids.Model.empty_model(), ...
                     'Contrasts', {{bids.Model.empty_contrast()}}, ...
                     'DummyContrasts',  struct('Test', 't', ...
                                               'Contrasts', {{''}}));

    end

    function contrast = empty_contrast()
      contrast = struct('Name', '', ...
                        'ConditionList', {{''}}, ...
                        'Weights', {{''}}, ...
                        'Test', 't');
    end

    function transformations = empty_transformations()
      %
      % USAGE::
      %
      %   transformations = Model.empty_transformations()
      %

      transformations = struct('Transformer', '', ...
                               'Instructions', {{
                                                 struct('Name', '', ...
                                                        'Inputs', {{''}})
                                                }});

    end

    function model = empty_model()
      %
      % USAGE::
      %
      %   model = Model.empty_model()
      %

      model = struct('X', {{''}}, ...
                     'Type', 'glm', ...
                     'HRF', struct('Variables', {{''}}, ...
                                   'Model', 'DoubleGamma'), ...
                     'Options', struct('HighPassFilterCutoffHz', 0.008, ...
                                       'Mask', struct('desc', {{'brain'}}, ...
                                                      'suffix', {{'mask'}})), ...
                     'Software', {{}});

    end

    function values = get_keys(cell_or_struct)
      if iscell(cell_or_struct)
        values = cellfun(@(x) fieldnames(x), cell_or_struct, 'UniformOutput', false);
      elseif isstruct(cell_or_struct)
        values = fieldnames(cell_or_struct);
      end
    end

  end

  methods (Access = protected)

    function model_validation_error(obj, key, required_fields)
      bids.internal.error_handling(mfilename(), ...
                                   'missingField', ...
                                   sprintf('%s require the fields: %s.', ...
                                           key, ...
                                           strjoin(required_fields, ', ')), ...
                                   obj.tolerant, ...
                                   obj.verbose);
    end

  end

end

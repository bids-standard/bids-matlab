classdef Model
  %
  % Class to deal with BIDS stats models
  %
  % See the `BIDS stats model website
  % <https://bids-standard.github.io/stats-models/intro.html>`_
  % for more information.
  %
  % USAGE::
  %
  %   bm = bids.Model('init', true, ...
  %                    'file', path_to_bids_stats_model_file, ...
  %                    'tolerant', true,
  %                    'verbose', false);
  %
  % :param init: if ``true`` this will initialize an empty model. Defauts to ``false``.
  % :type init: boolean
  %
  % :param file: fullpath the JSON file containing the BIDS stats model
  % :type file: path
  %
  % :param tolerant: turns errors into warning
  % :type tolerant: boolean
  %
  % :param verbose: silences warnings
  % :type verbose: boolean
  %
  % EXAMPLE::
  %
  %   % initialize and write an empty model
  %   bm = bids.Model('init', true);
  %   filename = fullfile(pwd, 'model-foo_smdl.json');
  %   bm.write(filename);
  %
  % EXAMPLE::
  %
  %   % load a stats model from a file
  %   model_file = fullfile(get_test_data_dir(), ...
  %                         '..', ...
  %                         'data', ...
  %                         'model', ['model-narps_smdl.json']);
  %
  %   bm = bids.Model('file', model_file('narps'), 'verbose', false);
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

    Edges % Edges of the model

    tolerant = true % if ``true`` turns error into warning

    verbose = true % hides warning if ``false``

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

        if ~isfield(obj.content, 'Nodes')
          bids.internal.error_handling(mfilename(), ...
                                       'NodesRequired', ...
                                       'Nodes field required', ...
                                       obj.tolerant, ...
                                       obj.verbose);
        else
          obj.Nodes = obj.content.Nodes;
        end

        if isfield(obj.content, 'Edges')
          obj.Edges = obj.content.Edges;
        else
          obj = get_edges_from_nodes(obj);
        end

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

    function [value, idx] = get_nodes(obj, varargin)
      %
      % Get a specific node from the model given its Level and / or Name
      %
      % USAGE::
      %
      %   [value, idx] = bm.get_nodes('Level', '', ...
      %                               'Name', '')
      %
      %
      % :param Level: Must be one of ``Run``, ``Session``, ``Subject``, ``Dataset``.
      %               Default to ``''``
      % :type init: string
      %
      % :param Name: Default to ``''``
      % :type file: path
      %
      %
      % EXAMPLE::
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
      if isempty(varargin)
        value = obj.Nodes;
        idx = 1:numel(value);

      else

        value = {};

        allowed_levels = @(x) all(ismember(lower(x), {'run', 'session', 'subject', 'dataset'}));

        args = inputParser;
        args.addParameter('Level', '', allowed_levels);
        args.addParameter('Name', '');
        args.parse(varargin{:});

        Level = lower(args.Results.Level);
        if ~strcmp(Level, '')
          if ischar(Level)
            Level = {Level};
          end
          if iscell(obj.Nodes)
            levels = cellfun(@(x) lower(x.Level), obj.Nodes, 'UniformOutput', false);
          elseif isstruct(obj.Nodes)
            levels = lower({obj.Nodes.Level}');
          end
          idx = ismember(levels, Level);
        end

        Name = lower(args.Results.Name);  %#ok<*PROPLC>
        if ~strcmp(Name, '')
          if ischar(Name)
            Name = {Name};
          end
          if iscell(obj.Nodes)
            names = cellfun(@(x) lower(x.Name), obj.Nodes, 'UniformOutput', false);
          elseif isstruct(obj.Nodes)
            names = lower({obj.Nodes.Name}');
          end
          idx = ismember(names, Name);
        end

        % TODO merge idx when both Level and Name are passed as parameters
        if any(idx)
          idx = find(idx);
          for i = 1:numel(idx)
            if iscell(obj.Nodes)
              value{end + 1} = obj.Nodes{idx(i)};
            elseif isstruct(obj.Nodes)
              value{end + 1} = obj.Nodes(idx(i));
            end
          end
        else
          msg = sprintf('Could not find a corresponding Node.');
          bids.internal.error_handling(mfilename(), 'missingNode', msg, ...
                                       obj.tolerant, ...
                                       obj.verbose);
        end

      end

      if ~iscell(value)
        value = {value};
      end
    end

    function value = get.Edges(obj)
      value = obj.Edges;
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
      if iscell(obj.Nodes)
        value = cellfun(@(x) x.Name, obj.Nodes, 'UniformOutput', false);
      else
        value = {obj.Nodes.Name};
      end
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
      REQUIRED_CONTRASTS_FIELDS = {'Name', 'ConditionList'};
      REQUIRED_DUMMY_CONTRASTS_FIELDS = {'Contrasts'};

      % Nodes
      nodes = obj.Nodes;
      for i = 1:(numel(nodes))

        if iscell(nodes)
          this_node = nodes{i, 1};
        elseif isstruct(nodes)
          this_node = nodes(i);
        end

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

        for i = 1:(numel(edges))

          if iscell(edges)

            this_edge = edges{i, 1};

            if ~isstruct(this_edge)
              obj.model_validation_error('Edges', REQUIRED_EDGES_FIELDS);
              continue

            end

          elseif isstruct(edges)

            this_edge = edges(1);

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
      %
      % :param Name: name of the node whose transformations we want
      % :type Name: char
      %
      value = [];
      [node, idx] = get_nodes(obj, varargin{:});
      assert(numel(node) == 1);
      if isfield(node{1}, 'Transformations')
        value = node{1}.Transformations;
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
      if isfield(node{1}, 'DummyContrasts')
        value = node{1}.DummyContrasts;
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
      if isfield(node{1}, 'Contrasts')
        value = node{1}.Contrasts;
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
      value = node{1}.Model;
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
      %   bm = bm.default(BIDS)
      %
      % :param BIDS: fullpath to a BIDS dataset or output structure from ``bids.layout``
      % :type file: path or structure
      %
      % EXAMPLE::
      %
      %   pth_bids_example = get_test_data_dir();
      %   BIDS = bids.layout(fullfile(pth_bids_example, 'ds003'));
      %   bm = bids.Model();
      %   bm = bm.default(BIDS);
      %   filename = fullfile(pwd, 'model-rhymejudgement_smdl.json');
      %   bm.write(filename);
      %

      args = inputParser;
      args.addRequired('layout');
      args.parse(varargin{:});

      tasks = bids.query(args.Results.layout, 'tasks');
      sessions = bids.query(args.Results.layout, 'sessions');

      GroupBy_level_1 = {'run', 'subject'};
      if ~isempty(sessions)
        GroupBy_level_1 = {'run', 'session', 'subject'};
      end

      obj.Input.task = tasks;
      obj.Name = sprintf('default_%s_model', strjoin(tasks, '_'));
      obj.Description = sprintf('default BIDS stats model for %s task', strjoin(tasks, '/'));

      % Define design matrix by including all trial_types and a constant
      trial_type_list = bids.internal.list_all_trial_types(args.Results.layout, tasks);
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
      obj.content.Nodes = obj.Nodes;
      obj.content.Edges = obj.Edges;
    end

    function write(obj, filename)
      %
      % USAGE::
      %
      %   bm.write(filename)
      %

      bids.util.mkdir(fileparts(filename));
      bids.util.jsonencode(filename, obj.content);

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

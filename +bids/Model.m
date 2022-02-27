classdef Model
  %
  %
  % (C) Copyright 2020 CPP_SPM developers

  properties

    content = ''

    Name = 'REQUIRED'
    Description = 'RECOMMENDED'
    BIDSModelVersion = '1.0.0'
    Input = 'REQUIRED'
    Nodes =  {'REQUIRED'}
    Edges = {'RECOMMENDED'}

  end

  properties (SetAccess = private)
    tolerant = true
    verbose = true

  end

  methods

    function obj = Model(varargin)

      args = inputParser;

      is_file = @(x) exist(x, 'file');

      args.addParameter('init', false, @islogical);
      args.addParameter('file', false, is_file);
      args.addParameter('tolerant', obj.tolerant, @islogical);
      args.addParameter('verbose', obj.verbose, @islogical);

      args.parse(varargin{:});

      obj.tolerant = args.Results.tolerant;
      obj.verbose = args.Results.verbose;

      if args.Results.init

        obj.Name = 'empty_model';
        obj.Description = 'This is an empty BIDS stats model.';
        obj.Input = struct('task', '');
        obj.Nodes{1} = Model.empty_node('run');

        obj = update(obj);

        return
      end

      if ~isempty(args.Results.file)

        obj.content = bids.util.jsondecode(args.Results.file);

        if ~isfield(obj.content, 'Name')
          error('Name required');
        else
          obj.Name = obj.content.Name;
        end

        if isfield(obj.content, 'Description')
          obj.Description = obj.content.Description;
        end

        if ~isfield(obj.content, 'BIDSModelVersion')
          error('BIDSModelVersion required');
        else
          obj.BIDSModelVersion = obj.content.BIDSModelVersion;
        end

        if ~isfield(obj.content, 'Input')
          error('Input required');
        else
          obj.Input = obj.content.Input;
        end

        if ~isfield(obj.content, 'Nodes')
          error('Nodes required');
        else
          obj.Nodes = obj.content.Nodes;
        end

        obj;

        if isfield(obj.content, 'Edges')
          obj.Edges = obj.content.Edges;
          % TODO when no Edges assume all Nodes follow each other
        end
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
      obj.Edges = edges;
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
      if isempty(varargin)
        value = obj.Nodes;
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

        Name = lower(args.Results.Name);
        if ~strcmp(Name, '')
          if ischar(Name)
            Name = {Name};
          end
          if iscell(obj.Nodes)
            names = cellfun(@(x) lower(x.Name), obj.Nodes, 'UniformOutput', false);
          elseif isstruct(obj.Nodes)
            levels = lower({obj.Nodes.Name}');
          end
          idx = ismember(names, Name);
        end

        % TODO merge idx when both Level and Name are passed as parameters
        if any(idx)
          idx = find(idx);
          for i = 1:numel(idx)
            value{end + 1} = obj.Nodes{idx};
          end
        else
          msg = sprintf('Could not find a corresponding Node.');
          errorHandling(mfilename(), 'missingNode', msg, obj.tolerant, obj.verbose);
        end

      end
    end

    %% Node level methods
    % assumes that only one node is being queried
    function value = get_transformations(obj, varargin)
      value = [];
      node = get_nodes(obj, varargin{:});
      assert(numel(node) == 1);
      if isfield(node{1}, 'Transformations')
        value = node{1}.Transformations;
      end
    end

    function value = get_dummy_contrasts(obj, varargin)
      value = [];
      node = get_nodes(obj, varargin{:});
      assert(numel(node) == 1);
      if isfield(node{1}, 'DummyContrasts')
        value = node{1}.DummyContrasts;
      end
    end

    function value = get_contrasts(obj, varargin)
      value = [];
      node = get_nodes(obj, varargin{:});
      assert(numel(node) == 1);
      if isfield(node{1}, 'Contrasts')
        value = node{1}.Contrasts;
      end
    end

    function value = get_model(obj, varargin)
      node = get_nodes(obj, varargin{:});
      assert(numel(node) == 1);
      value = node{1}.Model;
    end

    function value = get_design_matrix(obj, varargin)
      model = get_model(obj, varargin{:});
      value = model.X;
    end

    %% Update content and write

    function obj = update(obj)
      obj.content.Name = obj.Name;
      obj.content.BIDSModelVersion = obj.BIDSModelVersion;
      obj.content.Description = obj.Description;
      obj.content.Input = obj.Input;
      obj.content.Nodes = obj.Nodes;
      obj.content.Edges = obj.Edges;
    end

    function write(obj, filename)
      bids.util.mkdir(fileparts(filename));
      bids.util.jsonencode(filename, obj.content);
    end

  end

  methods(Static)
    function node = empty_node(level)

      node =  struct('Level', [upper(level(1)) level(2:end)], ...
                     'Name', [level], ...
                     'Transformations', {Model.empty_transformations()}, ...
                     'Model', Model.empty_model(), ...
                     'Contrasts', struct('Name', '', ...
                                         'ConditionList', {{''}}, ...
                                         'Weights', {{''}}, ...
                                         'Test', ''), ...
                     'DummyContrasts',  struct('Test', 't', ...
                                               'Contrasts', {{''}}));
    
    end

    function transformations = empty_transformations()

      transformations = struct('Transformer', '', ...
                              'Instructions', {{
                                                struct('Name', '', ...
                                                       'Inputs', {{''}})
                                               }});
    
    end

    function model = empty_model()

      model = struct('X', {{''}}, ...
                     'Type', 'glm', ...
                     'HRF', struct('Variables', {{''}}, ...
                                   'Model', 'DoubleGamma'), ...
                     'Options', struct('HighPassFilterCutoffHz', 0.008, ...
                                       'LowPassFilterCutoffHz', nan, ...
                                       'Mask', struct('desc', 'brain', ...
                                                      'suffix', 'mask')), ...
                     'Software', '');

    end


  end


end

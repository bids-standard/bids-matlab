function new_content = transformers(varargin)
  %
  % Apply transformers to a structure
  %
  % USAGE::
  %
  %   new_content = transformers(data, transformers)
  %
  % :param data:
  % :type data: structure
  %
  % :param transformers:
  % :type transformers: structure
  %
  % :returns: - :new_content: (structure)
  %
  % EXAMPLE::
  %
  %     tsvFile = fullfile(path_to_tsv);
  %     data = bids.util.tsvread(tsvFile);
  %
  %     % load transformation instruction from a model file
  %     bm = bids.Model('file', model_file);
  %     transformers = bm.get_transformations('Level', 'Run');
  %
  %     new_content = bids.transformers(data, transformers);
  %     bids.util.tsvwrite(path_to_new_tsv, new_content)
  %
  %
  % See also: bids.Model
  %
  %
  % (C) Copyright 2022 Remi Gau

  SUPPORTED_TRANSFORMERS = {'Add', 'Subtract', 'Multiply', 'Divide', ...
                            'Filter', ...
                            'And', 'Or', ...
                            'Rename', 'Concatenate', 'Delete', 'Select', 'Copy', ...
                            'Constant', ...
                            'Replace', ...
                            'Threshold'};

  p = inputParser;

  default_transformers = 'transformers';

  isStructOrCell = @(x) isstruct(x) || iscell(x);

  addRequired(p, 'data', @isstruct);
  addOptional(p, 'transformers', default_transformers, isStructOrCell);

  parse(p, varargin{:});

  data = p.Results.data;
  transformers = p.Results.transformers;

  if isempty(transformers) || isempty(data)
    new_content = data;
    return
  end

  % apply all the transformers sequentially
  for iTrans = 1:numel(transformers)

    if iscell(transformers)
      this_transformer = transformers{iTrans};
    elseif isstruct(transformers)
      this_transformer = transformers(iTrans);
    end

    if ~ismember(this_transformer.Name, SUPPORTED_TRANSFORMERS)
      notImplemented(mfilename(), ...
                     sprintf('Transformer %s not implemented', this_transformer.Name), ...
                     true);
      return
    end

    data = apply_transformer(this_transformer, data);
    new_content = data;

  end

end

function output = apply_transformer(transformer, data)

  transformerName = lower(transformer.Name);

  switch transformerName

    case {'add', 'subtract', 'multiply', 'divide'}
      output = bids.transformers.basic(transformer, data);

    case 'filter'
      output = bids.transformers.filter(transformer, data);

    case 'threshold'
      output = bids.transformers.threshold(transformer, data);

    case 'rename'
      output = bids.transformers.rename(transformer, data);

    case 'concatenate'
      output = bids.transformers.concatenate_columns(transformer, data);

    case 'replace'
      output = bids.transformers.replace(transformer, data);

    case 'constant'
      output = bids.transformers.constant(transformer, data);

    case 'copy'
      output = bids.transformers.copy(transformer, data);

    case 'delete'
      output = bids.transformers.delete(transformer, data);

    case 'select'
      output = bids.transformers.select(transformer, data);

    case {'and', 'or', 'not'}
      output = bids.transformers.logical(transformer, data);

    otherwise
      notImplemented(mfilename(), ...
                     sprintf('Transformer %s not implemented', transformer.Name), ...
                     true);

  end

end

function new_content = transformers(varargin)
  %
  % Apply transformers to a structure
  %
  % USAGE::
  %
  %   new_content = transformers(transformers, data)
  %
  % :param transformers:
  % :type transformers: structure
  %
  % :param data:
  % :type data: structure
  %
  % :returns: - :new_content: (structure)
  %
  % EXAMPLE::
  %
  %     data = bids.util.tsvread(path_to_tsv);
  %
  %     % load transformation instruction from a model file
  %     bm = bids.Model('file', model_file);
  %     transformers = bm.get_transformations('Level', 'Run');
  %
  %     % apply transformers
  %     new_content = bids.transformers(data, transformers);
  %
  %     % if all fields in the structure have the same number of rows one
  %     % create a new tsv file
  %     bids.util.tsvwrite(path_to_new_tsv, new_content)
  %
  %
  % See also: bids.Model
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  SUPPORTED_TRANSFORMERS = lower(cat(1, basic_transfomers, ...
                                     munge_transfomers, ...
                                     logical_transfomers, ...
                                     compute_transfomers));

  p = inputParser;

  isStructOrCell = @(x) isstruct(x) || iscell(x);

  addRequired(p, 'transformers', isStructOrCell);
  addRequired(p, 'data', @isstruct);

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

    if ~ismember(lower(this_transformer.Name), SUPPORTED_TRANSFORMERS)
      not_implemented(this_transformer.Name);
      return
    end

    data = apply_transformer(this_transformer, data);
    new_content = data;

  end

end

function output = apply_transformer(transformer, data)

  transformerName = lower(transformer.Name);

  switch transformerName

    case lower(basic_transfomers)
      output = bids.transformers.basic(transformer, data);

    case lower(logical_transfomers)
      output = bids.transformers.logical(transformer, data);

    case lower(munge_transfomers)
      output = apply_munge(transformer, data);

    case lower(compute_transfomers)
      output = apply_compute(transformer, data);

    otherwise
      not_implemented(transformer.Name);

  end

end

function output = apply_munge(transformer, data)

  transformerName = lower(transformer.Name);

  switch transformerName

    case 'assign'
      output = bids.transformers.assign(transformer, data);

    case 'concatenate'
      output = bids.transformers.concatenate(transformer, data);

    case 'constant'
      output = bids.transformers.constant(transformer, data);

    case 'copy'
      output = bids.transformers.copy(transformer, data);

    case 'delete'
      output = bids.transformers.delete(transformer, data);

    case 'dropna'
      output = bids.transformers.drop_na(transformer, data);

    case 'factor'
      output = bids.transformers.factor(transformer, data);

    case 'filter'
      output = bids.transformers.filter(transformer, data);

    case 'rename'
      output = bids.transformers.rename(transformer, data);

    case 'select'
      output = bids.transformers.select(transformer, data);

    case 'replace'
      output = bids.transformers.replace(transformer, data);

    case 'split'
      output = bids.transformers.split(transformer, data);

    otherwise

      not_implemented(transformer.Name);

  end

end

function output = apply_compute(transformer, data)

  transformerName = lower(transformer.Name);

  switch transformerName

    case 'sum'
      output = bids.transformers.sum(transformer, data);

    case 'product'
      output = bids.transformers.product(transformer, data);

    case 'mean'
      output = bids.transformers.mean(transformer, data);

    case 'stddev'
      output = bids.transformers.std(transformer, data);

    case 'scale'
      output = bids.transformers.scale(transformer, data);

    case 'threshold'
      output = bids.transformers.threshold(transformer, data);

    otherwise

      not_implemented(transformer.Name);

  end

end

function not_implemented(name)
  bids.internal.error_handling(mfilename(), 'notImplemented', ...
                               sprintf('Transformer %s not implemented', name), ...
                               false);
end

function BASIC = basic_transfomers()
  BASIC = {'Add'
           'Divide'
           'Multiply'
           'Power'
           'Subtract'};
end

function LOGICAL = logical_transfomers()
  LOGICAL = {'And'
             'Or'
             'Not'};
end

function MUNGE = munge_transfomers()
  MUNGE = {'Assign'
           'Concatenate'
           'Constant'
           'Copy'
           'Delete'
           'DropNA'
           'Filter'
           'Factor'
           'Rename'
           'Replace'
           'Select'
           'Split'};
end

function COMPUTE = compute_transfomers()
  COMPUTE = {'Mean'
             'Product'
             'Scale'
             'StdDev'
             'Sum'
             'Threshold'};
end

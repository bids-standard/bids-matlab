function [new_content, json] = transformers(varargin)
  %
  % Apply transformers to a structure.
  %
  % USAGE::
  %
  %   new_content = transformers(trans, data)
  %
  % :param transformers:
  % :type transformers: structure
  %
  % :param data:
  % :type data: structure
  %
  % :returns: - :new_content: (structure)
  %           - :json: (structure) json equivalent of the transformers
  %
  % Example
  % -------
  %
  % .. code-block:: matlab
  %
  %     data = bids.util.tsvread(path_to_tsv);
  %
  %     % load transformation instruction from a model file
  %     bm = bids.Model('file', model_file);
  %     transformers = bm.get_transformations('Level', 'Run');
  %
  %     % apply transformers
  %     new_content = bids.transformers(transformers.Instructions, data);
  %
  %     % if all fields in the structure have the same number of rows one
  %     % create a new tsv file
  %     bids.util.tsvwrite(path_to_new_tsv, new_content)
  %
  % See also: bids.Model
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  SUPPORTED_TRANSFORMERS = lower(cat(1, basic_transformers, ...
                                     munge_transformers, ...
                                     logical_transformers, ...
                                     compute_transformers));

  p = inputParser;

  isStructOrCell = @(x) isstruct(x) || iscell(x);

  addRequired(p, 'trans', isStructOrCell);
  addRequired(p, 'data', @isstruct);

  parse(p, varargin{:});

  data = p.Results.data;
  trans = p.Results.trans;

  json =  struct('Transformer', ['bids-matlab_' bids.internal.get_version], ...
                 'Instructions', trans);
  if iscell(trans)
    json =  struct('Transformer', ['bids-matlab_' bids.internal.get_version], ...
                   'Instructions', {trans});
  end

  if isempty(trans) || isempty(data)
    new_content = data;
    return
  end

  % apply all the transformers sequentially
  for iTrans = 1:numel(trans)

    if iscell(trans)
      this_transformer = trans{iTrans};
    elseif isstruct(trans)
      this_transformer = trans(iTrans);
    end

    if ~ismember(lower(this_transformer.Name), SUPPORTED_TRANSFORMERS)
      not_implemented(this_transformer.Name);
      return
    end

    data = apply_transformer(this_transformer, data);
    new_content = data;

  end

end

function output = apply_transformer(trans, data)

  transformerName = lower(trans.Name);

  if ~isfield(trans, 'verbose')
  end

  switch transformerName

    case lower(basic_transformers)
      output = bids.transformers_list.Basic(trans, data);

    case lower(logical_transformers)
      output = bids.transformers_list.Logical(trans, data);

    case lower(munge_transformers)
      output = apply_munge(trans, data);

    case lower(compute_transformers)
      output = apply_compute(trans, data);

    otherwise
      not_implemented(trans.Name);

  end

end

function output = apply_munge(trans, data)

  transformerName = lower(trans.Name);

  switch transformerName

    case 'assign'
      output = bids.transformers_list.Assign(trans, data);

    case 'concatenate'
      output = bids.transformers_list.Concatenate(trans, data);

    case 'constant'
      output = bids.transformers_list.Constant(trans, data);

    case 'copy'
      output = bids.transformers_list.Copy(trans, data);

    case 'delete'
      output = bids.transformers_list.Delete(trans, data);

    case 'dropna'
      output = bids.transformers_list.Drop_na(trans, data);

    case 'factor'
      output = bids.transformers_list.Factor(trans, data);

    case 'filter'
      output = bids.transformers_list.Filter(trans, data);

    case 'labelidenticalrows'
      output = bids.transformers_list.Label_identical_rows(trans, data);

    case 'mergeidenticalrows'
      output = bids.transformers_list.Merge_identical_rows(trans, data);

    case 'rename'
      output = bids.transformers_list.Rename(trans, data);

    case 'select'
      output = bids.transformers_list.Select(trans, data);

    case 'replace'
      output = bids.transformers_list.Replace(trans, data);

    case 'split'
      output = bids.transformers_list.Split(trans, data);

    otherwise

      not_implemented(transformer.Name);

  end

end

function output = apply_compute(trans, data)

  transformerName = lower(trans.Name);

  switch transformerName

    case 'sum'
      output = bids.transformers_list.Sum(trans, data);

    case 'product'
      output = bids.transformers_list.Product(trans, data);

    case 'mean'
      output = bids.transformers_list.Mean(trans, data);

    case 'stddev'
      output = bids.transformers_list.Std(trans, data);

    case 'scale'
      output = bids.transformers_list.Scale(trans, data);

    case 'threshold'
      output = bids.transformers_list.Threshold(trans, data);

    otherwise

      not_implemented(trans.Name);

  end

end

function not_implemented(name)
  bids.internal.error_handling(mfilename(), 'notImplemented', ...
                               sprintf('Transformer %s not implemented', name), ...
                               false);
end

function BASIC = basic_transformers()
  BASIC = {'Add'
           'Divide'
           'Multiply'
           'Power'
           'Subtract'};
end

function LOGICAL = logical_transformers()
  LOGICAL = {'And'
             'Or'
             'Not'};
end

function MUNGE = munge_transformers()
  MUNGE = {'Assign'
           'Concatenate'
           'Constant'
           'Copy'
           'Delete'
           'DropNA'
           'Filter'
           'Factor'
           'LabelIdenticalRows'
           'MergeIdenticalRows'
           'Rename'
           'Replace'
           'Select'
           'Split'};
end

function COMPUTE = compute_transformers()
  COMPUTE = {'Mean'
             'Product'
             'Scale'
             'StdDev'
             'Sum'
             'Threshold'};
end

function new_content = transformers(varargin)
  %
  % Apply transformers to a structure
  %
  % USAGE::
  %
  %   new_content = transformers(tsv_content, transformers)
  %
  % :param tsv_content:
  % :type tsv_content: structure
  %
  % :param transformers:
  % :type transformers: structure
  %
  % :returns: - :new_content: (structure)
  %
  % EXAMPLE::
  %
  %     tsvFile = fullfile(path_to_tsv);
  %     tsv_content = bids.util.tsvread(tsvFile);
  %
  %     % load transformation instruction from a model file
  %     bm = bids.Model('file', model_file);
  %     transformers = bm.get_transformations('Level', 'Run');
  %
  %     new_content = bids.transformers(tsv_content, transformers);
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

  addRequired(p, 'tsv_content', @isstruct);
  addOptional(p, 'transformers', default_transformers, isStructOrCell);

  parse(p, varargin{:});

  tsv_content = p.Results.tsv_content;
  transformers = p.Results.transformers;

  if isempty(transformers) || isempty(tsv_content)
    new_content = tsv_content;
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

    tsv_content = apply_transformer(this_transformer, tsv_content);
    new_content = tsv_content;

  end

end

function varargout = apply_transformer(transformer, tsv_content)

  transformerName = lower(transformer.Name);

  switch transformerName

    case {'add', 'subtract', 'multiply', 'divide'}

      varargout = {bids.transformers.basic(transformer, tsv_content)};

    case 'filter'

      varargout = {bids.transformers.filter(transformer, tsv_content)};

    case 'threshold'

      varargout = {bids.transformers.threshold(transformer, tsv_content)};

    case 'rename'

      varargout = {bids.transformers.rename(transformer, tsv_content)};

    case 'concatenate'

      varargout = {bids.transformers.concatenate_columns(transformer, tsv_content)};

    case 'replace'

      varargout = {bids.transformers.replace(transformer, tsv_content)};

    case 'constant'

      varargout = {bids.transformers.constant(transformer, tsv_content)};

    case 'copy'

      varargout = {bids.transformers.copy(transformer, tsv_content)};

    case 'delete'

      varargout = {bids.transformers.delete(transformer, tsv_content)};

    case 'select'

      varargout = {bids.transformers.select(transformer, tsv_content)};

    case {'and', 'or'}

      varargout = {bids.transformers.and_or(transformer, tsv_content)};

    otherwise
      notImplemented(mfilename(), ...
                     sprintf('Transformer %s not implemented', transformer.Name), ...
                     true);

  end

end

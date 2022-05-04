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

  inputs = get_input(transformer);
  outputs = get_output(transformer);

  switch transformerName

    case {'add', 'subtract', 'multiply', 'divide'}

      varargout = {basic_transformers(transformer, tsv_content)};

    case 'filter'

      varargout = {filter_transformer(transformer, tsv_content)};

    case 'threshold'

      varargout = {threshold_transformer(transformer, tsv_content)};

    case 'rename'

      for i = 1:numel(inputs)
        tsv_content.(outputs{i}) = tsv_content.(inputs{i});
        tsv_content = rmfield(tsv_content, inputs{i});
      end

      varargout = {tsv_content};

    case 'concatenate'

      tsv_content = concatenate_columns(transformer, tsv_content);

      varargout = {tsv_content};

    case 'replace'

      varargout = {replace_transformers(transformer, tsv_content)};

    case 'constant'

      value = 1;
      if isfield(transformer, 'Value')
        value = transformer.Value;
      end

      tsv_content.(outputs{1}) = ones(size(tsv_content.onset)) * value;

      varargout = {tsv_content};

    case 'copy'

      for i = 1:numel(inputs)
        tsv_content.(outputs{i}) = tsv_content.(inputs{i});
      end

      varargout = {tsv_content};

    case 'delete'

      for i = 1:numel(inputs)
        if isfield(tsv_content, inputs{i})
          tsv_content = rmfield(tsv_content, inputs{i});
        end
      end

      varargout = {tsv_content};

    case 'select'

      for i = 1:numel(inputs)
        tmp.(inputs{i}) = tsv_content.(inputs{i});
      end

      varargout = {tmp};

    case {'and', 'or'}

      varargout = {and_or_transformer(transformer, tsv_content)};

    otherwise
      notImplemented(mfilename(), ...
                     sprintf('Transformer %s not implemented', transformer.Name), ...
                     true);

  end

end

function tsv_content = concatenate_columns(transformer, tsv_content)

  inputs = get_input(transformer);
  outputs = get_output(transformer);

  for row = 1:numel(tsv_content.onset)
    tmp1 = {};
    for i = 1:numel(inputs)
      if isnumeric(tsv_content.(inputs{i}))
        tmp1{1, i} = num2str(tsv_content.(inputs{i})(row));
      elseif iscellstr(tsv_content.(inputs{i}))
        tmp1{1, i} = tsv_content.(inputs{i}){row};
      end
    end
    tmp2{row, 1} = strjoin(tmp1, '_');
  end

  tsv_content.(outputs{1}) = tmp2;

end

function tsv_content = replace_transformers(transformer, tsv_content)

  inputs = get_input(transformer);
  outputs = get_output(transformer);

  attributes =  get_attribute_to_replace(transformer);

  replace = transformer.Replace;

  for i = 1:numel(inputs)

    if ~isfield(tsv_content, inputs{i})
      continue
    end

    for ii = 1:numel(attributes)

      switch lower(attributes{ii})
        case 'value'
          if strcmp(inputs{i}, outputs{i})
            this_output = tsv_content.(inputs{i});
          else
            this_output = tsv_content.(outputs{i});
          end
        case 'onset'
          this_output = tsv_content.onset;
          if strcmp(inputs{i}, outputs{i})
            outputs{i} = 'onset';
          end
        case 'duration'
          this_output = tsv_content.duration;
          if strcmp(inputs{i}, outputs{i})
            outputs{i} = 'duration';
          end
      end

      toReplace = fieldnames(replace);

      for iii = 1:numel(toReplace)

        switch lower(attributes{ii})
          case 'value'
            this_input = tsv_content.(inputs{i});
          case 'onset'
            this_input = tsv_content.onset;
          case 'duration'
            this_input = tsv_content.duration;
        end

        key = get_key_to_replace(inputs{i}, attributes{ii}, toReplace{iii});
        value = replace.(toReplace{iii});

        if ischar(key)
          idx = strcmp(key, this_input);
        elseif isnumeric(key)
          idx = this_input == key;
        end

        if isnumeric(this_output)
          if ischar(value)
            this_output = num2cell(this_output);
          end
          this_output(idx) = value;

        elseif iscellstr(this_output)
          if isnumeric(value)
            value = num2str(value);
          end
          this_output(idx) = repmat({value}, sum(idx), 1);

        end

      end

      tsv_content.(outputs{i}) = this_output;
    end

  end

end

function key = get_key_to_replace(input, attribute, to_replace)
  % because matlab keys in structure cannot be numbers
  % it won't be easily possible to replace
  % when the value to replace is a number,
  % but it could be sort of OK for onset and duration
  key = to_replace;
  if ismember(lower(attribute), {'onset', 'duration'})
    key = strrep(key, [lower(attribute) '_'], '');
    key = str2num(key);
  end
  if bids.internal.starts_with(key, [input '_'])
    key = strrep(key, [input '_'], '');
    key = str2num(key);
  end

end

function attributes =  get_attribute_to_replace(transformer)
  attributes = {'value'};
  if isfield(transformer, 'Attribute')
    attributes = transformer.Attribute;
  end
  if ~iscell(attributes)
    attributes = {attributes};
  end
  if strcmp(attributes, 'all')
    attributes =  {'values', 'onset', 'duration'};
  end
end

function tsv_content = basic_transformers(transformer, tsv_content)

  inputs = get_input(transformer);
  outputs = get_output(transformer);

  transformerName = lower(transformer.Name);

  for i = 1:numel(inputs)

    if ~isfield(tsv_content, inputs{i})
      continue
    end

    value = transformer.Value;

    switch transformerName

      case 'add'
        tmp = tsv_content.(inputs{i}) + value;

      case 'subtract'
        tmp = tsv_content.(inputs{i}) - value;

      case 'multiply'
        tmp = tsv_content.(inputs{i}) * value;

      case 'divide'
        tmp = tsv_content.(inputs{i}) / value;

    end

    tsv_content.(outputs{i}) = tmp;

  end

end

function tsv_content = filter_transformer(transformer, tsv_content)

  inputs = get_input(transformer);
  outputs = get_output(transformer);

  if isfield(transformer, 'By')
    % TODO
    by = transformer.By;
  end

  for i = 1:numel(inputs)

    tokens = regexp(inputs{i}, '\.', 'split');

    query = transformer.Query;
    if isempty(regexp(query, tokens{1}, 'ONCE'))
      return
    end

    queryTokens = regexp(query, '==', 'split');
    if numel(queryTokens) > 1

      if iscellstr(tsv_content.(tokens{1}))
        idx = strcmp(queryTokens{2}, tsv_content.(tokens{1}));
        tmp(idx, 1) = tsv_content.(tokens{1})(idx);
        tmp(~idx, 1) = repmat({''}, sum(~idx), 1);
      end

      if isnumeric(tsv_content.(tokens{1}))
        idx = tsv_content.(tokens{1}) == str2num(queryTokens{2});
        tmp(idx, 1) = tsv_content.(tokens{1})(idx);
        tmp(~idx, 1) = nan;
      end

      tmp(idx, 1) = tsv_content.(tokens{1})(idx);
      tsv_content.(outputs{i}) = tmp;

    end

  end

end

function tsv_content = and_or_transformer(transformer, tsv_content)

  inputs = get_input(transformer);
  outputs = get_output(transformer);

  for i = 1:numel(inputs)

    if ~isfield(tsv_content, inputs{i})
      return
    end

    if iscellstr(tsv_content.(inputs{i}))
      tmp(:, i) = cellfun('isempty', tsv_content.(inputs{i}));

    else
      tmp2 = tsv_content.(inputs{i});
      tmp2(isnan(tmp2)) = 0;
      tmp(:, i) = logical(tmp2);

    end

  end

  switch lower(transformer.Name)
    case 'and'
      tsv_content.(outputs{1}) = all(tmp, 2);
    case 'or'
      tsv_content.(outputs{1}) = any(tmp, 2);
  end

end

function tsv_content = threshold_transformer(transformer, tsv_content)

  inputs = get_input(transformer);
  outputs = get_output(transformer);

  threshold = 0;
  binarize = false;
  above = true;
  signed = true;

  if isfield(transformer, 'Threshold')
    threshold = transformer.Threshold;
  end

  if isfield(transformer, 'Binarize')
    binarize = transformer.Binarize;
  end

  if isfield(transformer, 'Above')
    above = transformer.Above;
  end

  if isfield(transformer, 'Signed')
    signed = transformer.Signed;
  end

  for i = 1:numel(inputs)

    if ~isfield(tsv_content, inputs{i})
      continue
    end

    valuesToThreshold = tsv_content.(inputs{i});

    if ~signed
      valuesToThreshold = abs(valuesToThreshold);
    end

    if above
      idx = valuesToThreshold > threshold;
    else
      idx = valuesToThreshold < threshold;
    end

    tmp = zeros(size(tsv_content.(inputs{i})));
    tmp(idx) = tsv_content.(inputs{i})(idx);

    if binarize
      tmp(idx) = 1;
    end

    tsv_content.(outputs{i}) = tmp;
  end

end

function input = get_input(transformer)

  if isfield(transformer, 'Input') && ~isempty(transformer.Input)
    input = transformer.Input;
  else
    input = {};
  end

  if ~iscell(input)
    input = {input};
  end

end

function output = get_output(transformer)
  if isfield(transformer, 'Output') && ~isempty(transformer.Output)
    output = transformer.Output;
    if ~iscell(output)
      output = {output};
    end
  else
    % will overwrite input columns
    output = get_input(transformer);
  end
end

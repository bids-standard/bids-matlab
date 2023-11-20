function js = update_struct(js, varargin)
  %
  % Updates structure with new values.
  % Can add new fields, replace field values, remove fields,
  %  and append  new values to a cellarray.
  %
  % Designed for manipulating json structures and will not work
  % on structarrays.
  %
  % USAGE::
  %
  %  js = update_struct(key1, value1, key2, value2);
  %  js = update_struct(struct(key1, value1, ...
  %                            key2, value2));
  %
  % Examples:
  % ---------
  % Adding and replacing existing fields:
  %   update_struct(struct('a', 'val_a'),...
  %                 'a', 'new_val', 'b', 'val_b')
  %   struct with fields:
  %      a: 'new_val'
  %      b: 'val_b'
  % Removing field from structure:
  %   update_struct(struct('a', 'val_a', 'b', 'val_b'),
  %                 'b', [])
  %   struct with fields:
  %      a: 'val_a'
  % Appending values to existing field:
  %   update_struct(struct('a', 'val_a', 'b', 'val_b'),
  %                 'b-add', 'val_b2')
  %   struct with fields:
  %      a: 'val_a'
  %      b: {'val_b'; 'val_b2'}
  %

  % (C) Copyright 2023 BIDS-MATLAB developers

  if numel(varargin) == 0
    % Nothing to do
    return
  end

  if numel(varargin) > 1
    key_list = varargin(1:2:end);
    val_list = varargin(2:2:end);
  elseif isstruct(varargin{1})
    key_list = fieldnames(varargin{1});
    val_list = cell(size(key_list));
    for i = 1:numel(key_list)
      val_list{i} = varargin{1}.(key_list{i});
    end
  else
    id = bids.internal.camel_case('invalidInput');
    msg = 'Not list of parameters or structure';
    bids.internal.error_handling(mfilename(), id, msg, false, true);
  end

  for ii = 1:numel(key_list)
    par_key = key_list{ii};
    try
      par_value = val_list{ii};

      % Removing field from json structure
      % Should use only empty double ([]) or any empth object?
      if isempty(par_value) && isnumeric(par_value)
        if isfield(js, par_key)
          js = rmfield(js, par_key);
        end
        continue
      end

      if bids.internal.ends_with(par_key, '-add')
        par_key = par_key(1:end - 4);
        if isfield(js, par_key)
          if ischar(js.(par_key))
            par_value = {js.(par_key); par_value}; %#ok<AGROW>
          else
            par_value = [js.(par_key); par_value]; %#ok<AGROW>
          end
        end
      end
      js(1).(par_key) = par_value;

    catch ME
      id = bids.internal.camel_case('structError');
      msg = sprintf('''%s'' (%d) -- %s', par_key, ii, ME.message);
      bids.internal.error_handling(mfilename(), id, msg, false, true);
    end
  end
end

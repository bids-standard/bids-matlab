classdef JSONFile < bids.File

  properties
    json_struct = []
  end

  methods (Static = true)

    function js = static_update_json(js, varargin)
      for ii = 1:2:size(varargin, 2)
        par_key = varargin{ii};
        try
          par_value = varargin{ii + 1};

          % Removing field from json structure
          if isempty(par_value)
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
          js.(par_key) = par_value;

        catch ME
          err_msg = sprintf('''%s'' (%d) -- %s', par_key, ii, ME.msg);
          obj.bids_file_error('jsonStructure', err_msg);
        end
      end
    end

  end

  methods (Access = public)

    function obj = JSONFile(varargin)
      obj@bids.File(varargin{:});

      obj = obj.load_json();
    end

    function obj = load_json(obj)
      [path, ~, ~] = fileparts(obj.path);
      f_json = fullfile(path, obj.json_filename);
      if exist(f_json, 'file')
        obj.json_struct = bids.util.jsondecode(f_json);
      else
        obj.json_struct = struct();
      end
    end

    function obj = update_json(obj, varargin)
      obj.json_struct = bids.JSONFile.static_update_json(obj.json_struct, varargin{:});
    end

    function write_json(obj, varargin)
      [path, ~, ~] = fileparts(obj.path);
      out_file = fullfile(path, obj.json_filename);

      der_json = obj.static_update_json(obj.json_struct, varargin{:});
      bids.util.jsonencode(out_file, der_json, 'indent', '  ');
    end

  end

end

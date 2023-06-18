function data = Copy(transformer, data)
  %
  % Clones/copies each of the input columns to a new column with identical values
  % and a different name. Useful as a basis for subsequent transformations that need
  % to modify their input in-place.
  %
  % JSON EXAMPLE
  % ------------
  %
  % .. code-block:: json
  %
  %     {
  %       "Name": "Copy",
  %       "Input": [
  %           "sex_m",
  %           "age_gt_twenty"
  %       ],
  %       "Output": [
  %           "tmp_sex_m",
  %           "tmp_age_gt_twenty"
  %       ]
  %     }
  %
  % Arguments:
  %
  % :param Input: **mandatory**.  Column names to copy.
  % :type  Input: char or array
  %
  % :param Output: Optional. Names to copy the input columns to.
  %                          Must be same length as input, and columns are mapped one-to-one
  %                          from the input array to the output array.
  % :type Output: char or array
  %
  % CODE EXAMPLE
  % ------------
  %
  % .. code-block:: matlab
  %
  %   transformer = struct('Name', 'Copy', ...
  %                         'Input', 'onset', ...
  %                         'Ouput', 'onset_copy');
  %
  %   data.onset = [1,2,3];
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.onset_copy
  %
  %   ans = [1,2,3]
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data);

  assert(numel(input) == numel(output));

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    data.(output{i}) = data.(input{i});
  end

end

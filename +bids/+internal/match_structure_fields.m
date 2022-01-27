function [struct_one, struct_two] = match_structure_fields(struct_one, struct_two)
  %
  % Update list of fields of a structure so it matches that of another.
  %
  % USAGE::
  %
  %   [struct_one, struct_two] = match_structure_fields(struct_one, struct_two)
  %
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  missing_fields = setxor(fieldnames(struct_one), fieldnames(struct_two));

  if ~isempty(missing_fields)
    for iField = 1:numel(missing_fields)

      struct_one = bids.internal.add_missing_field(struct_one, missing_fields{iField});
      struct_two = bids.internal.add_missing_field(struct_two, missing_fields{iField});

    end
  end

end

function [s1, s2] = match_structure_fields(s1, s2)
  %
  % Update field content of a structure so it matches that of another.
  %
  % USAGE::
  %
  %   [s1, s2] = match_structure_fields(s1, s2)
  %
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  missing_fields = setxor(fieldnames(s1), fieldnames(s2));

  if ~isempty(missing_fields)
    for iField = 1:numel(missing_fields)

      s1 = bids.internal.add_missing_field(s1, missing_fields{iField});
      s2 = bids.internal.add_missing_field(s2, missing_fields{iField});

    end
  end

end

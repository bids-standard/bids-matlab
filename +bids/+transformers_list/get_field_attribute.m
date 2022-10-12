function attr = get_field_attribute(data, field, type)
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  if nargin < 3
    type = {'value'};
  end

  switch type

    case 'value'

      attr = data.(field);

    case {'onset', 'duration'}

      attr = data.(type);

    otherwise

      bids.internal.error_handling(mfilename(), 'wrongAttribute', ...
                                   'Attribute must be one of "value", "onset", "duration"', ...
                                   false);

  end

end

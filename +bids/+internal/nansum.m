function y = nansum(varargin)
  %
  % nansum wrapper to deal with missing toolbox or octave

  % (C) Copyright 2023 Remi Gau

  if ~isempty(which('nansum'))
    y = nansum(varargin{:});
    return
  end

  if bids.internal.is_octave()
    tolerant = false;
    bids.internal.error_handling(mfilename(), ...
                                 'notImplemented', ...
                                 'nansum not implemented', tolerant);
    return
  end

  y = sum(varargin{:}, 'omitnan');

end

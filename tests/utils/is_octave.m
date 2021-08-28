function status = is_octave()
  %
  % Returns true if the environment is Octave.
  %
  % USAGE::
  %
  %   status = isOctave()
  %
  % :returns: :status: (boolean)
  %
  % (C) Copyright 2020 Agah Karakuzu

  persistent cacheval   % speeds up repeated calls

  if isempty (cacheval)
    cacheval = (exist ('OCTAVE_VERSION', 'builtin') > 0);
  end

  status = cacheval;
end

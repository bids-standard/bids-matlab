function [sts, msg] = validate(root)
  % BIDS Validator
  %
  % USAGE::
  %
  %         [sts, msg] = bids.validate(root)
  %
  % :param root: directory formatted according to BIDS [Default: pwd]
  % :type strig:
  %
  % :returns:
  %
  % - :sts: ``0`` if successful
  % - :msg: warning and error messages
  %
  % Command line version of the BIDS-Validator:
  % https://github.com/bids-standard/bids-validator
  %
  % Web version:
  % https://bids-standard.github.io/bids-validator/
  %
  %
  %
  % (C) Copyright 2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  [sts, ~] = system('bids-validator --version');
  if sts
    msg = 'Require bids-validator from https://github.com/bids-standard/bids-validator';
  else
    [sts, msg] = system(['bids-validator "' strrep(root, '"', '\"') '"']);
  end

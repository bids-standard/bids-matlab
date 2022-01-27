function sts = mkdir(varargin)
  %
  % Make new directory trees
  %
  % USAGE::
  %
  %   sts = bids.util.mkdir(dir, ...)
  %
  %
  % :param dir: directory structure to create
  % :type dir: character array, or cell array of strings
  %
  %
  % :returns:
  %   - :sts: status is ``true`` if all directories were successfully created or already
  %                   existing, ``false`` otherwise.
  %
  % EXAMPLE::
  %
  %   bids.util.mkdir('dataset', {'sub-01', 'sub-02'}, {'mri', 'eeg'});
  %
  % Based on spm_mkdir from SPM12
  %
  %
  % (C) Copyright 2017-2021 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  sts = true;

  if nargin > 0

    d1 = cellstr(varargin{1});

    for i = 1:numel(d1)

      if ~exist(bids.internal.file_utils(d1{i}, 'cpath'), 'dir')
        status = mkdir(d1{i});
        sts = sts & status;
      end

      if nargin > 1
        d2 = cellstr(varargin{2});
        for j = 1:numel(d2)
          status = bids.util.mkdir(fullfile(d1{i}, d2{j}), varargin{3:end});
          sts = sts & status;
        end
      end

    end

  else
    error('Not enough input arguments.');

  end

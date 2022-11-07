function create_readme(varargin)
  %
  % Create a README in a BIDS dataset.
  %
  %
  % USAGE::
  %
  %   bids.util.create_readme(layout_or_path, is_datalad_ds);
  %
  %
  % :param layout_or_path:
  % :type  layout_or_path:  path or structure
  %
  %

  % (C) Copyright 2022 Remi Gau

  default_layout = pwd;
  default_tolerant = true;
  default_verbose = false;

  is_dir_or_struct = @(x) (isstruct(x) || isdir(x));
  is_logical = @(x) islogical(x);

  args = inputParser();

  addOptional(args, 'layout_or_path', default_layout, is_dir_or_struct);
  addOptional(args, 'is_datalad_ds', default_layout, is_logical);
  addParameter(args, 'tolerant', default_tolerant, is_logical);
  addParameter(args, 'verbose', default_verbose, is_logical);

  parse(args, varargin{:});

  layout_or_path = args.Results.layout_or_path;
  is_datalad_ds = args.Results.is_datalad_ds;
  tolerant = args.Results.tolerant;
  verbose = args.Results.verbose;

  pth_to_readmes = fullfile(bids.internal.root_dir(), 'templates');
  src = fullfile(pth_to_readmes, 'README');
  if is_datalad_ds
    src = fullfile(pth_to_readmes, 'README_datalad');
  end

  pth = layout_or_path;
  if isstruct(layout_or_path)
    if isfield(layout_or_path, 'dir')
      pth = layout_or_path.dir;
    else
      msg = 'Input structure is not a bids layout. Run bids.layout first.';
      bids.internal.error_handling(mfilename(), 'notBidsDatasetLayout', ...
                                   msg, ...
                                   tolerant, ...
                                   verbose);
    end
  end

  copyfile(src, fullfile(pth, 'README'));
end

function out_path = download_ds(varargin)
  %
  % Downloads a BIDS data for a demo from a given source
  %
  % USAGE::
  %
  %   output_dir = download_moae_ds('source', 'spm', ...
  %                                 'demo', 'moae', ...
  %                                 'out_path', fullfile(bids.internal.root_dir(), 'demos'), ...
  %                                 'force', false, ...
  %                                 'verbose', true, ...
  %                                 'delete_previous', true);
  %
  % SPM::
  %
  %     bids.util.download_ds('source', 'spm', 'demo', 'moae')
  %     bids.util.download_ds('source', 'spm', 'demo', 'facerep')
  %     bids.util.download_ds('source', 'spm', 'demo', 'eeg')
  %
  % ---
  %
  % BRAINSTORM::
  %
  %     bids.util.download_ds('source', 'brainstorm', 'demo', 'ieeg')
  %     bids.util.download_ds('source', 'brainstorm', 'demo', 'meg')
  %
  % ieeg: SEEG+MRI: 190 Mb
  %
  %     https://neuroimage.usc.edu/brainstorm/Tutorials/Epileptogenicity
  %     ftp://neuroimage.usc.edu/pub/tutorials/tutorial_epimap_bids.zip
  %
  % meg: MEG+MRI+DWI: 208 Mb
  %
  %     https://neuroimage.usc.edu/brainstorm/Tutorials/FemMedianNerve
  %     ftp://neuroimage.usc.edu/pub/tutorials/sample_fem.zip
  %
  % ecog: SEEG+ECOG+MRI: 897 Mb
  %
  %     https://neuroimage.usc.edu/brainstorm/Tutorials/ECoG
  %     ftp://neuroimage.usc.edu/pub/tutorials/sample_ecog.zip
  %
  % meg_rest: MEG resting-state: 5.2 Gb
  %
  %     https://neuroimage.usc.edu/brainstorm/Tutorials/RestingOmega
  %     ftp://neuroimage.usc.edu/pub/tutorials/sample_omega.zip
  %
  %

  % (C) Copyright 2021 BIDS-MATLAB developers

  % TODO
  %
  % Brainstorm
  % Fieldtrip
  % EEGlab ?

  default_source = 'spm';
  default_demo = 'moae';

  default_out_path = '';
  default_force = false;
  default_verbose = true;
  default_delete_previous = false;

  args = inputParser;

  addParameter(args, 'source', default_source, @ischar);
  addParameter(args, 'demo', default_demo, @ischar);
  addParameter(args, 'out_path', default_out_path, @ischar);
  addParameter(args, 'delete_previous', default_delete_previous, @islogical);
  addParameter(args, 'force', default_force, @islogical);
  addParameter(args, 'verbose', default_verbose, @islogical);

  parse(args, varargin{:});

  verbose = args.Results.verbose;

  source = args.Results.source;

  demo = args.Results.demo;

  out_path = args.Results.out_path;
  if isempty(out_path)
    out_path = fullfile(bids.internal.root_dir, 'demos');
    out_path = fullfile(out_path, source, demo);
  end

  % clean previous runs
  if isfolder(out_path)
    if args.Results.force
      if args.Results.delete_previous
        rmdir(out_path, 's');
      end
    else
      bids.internal.error_handling(mfilename(), 'dataAlreadyHere', ...
                                   ['The dataset is already present.' ...
                                    'Use "force, true" to overwrite.'], ...
                                   true, verbose);
    end
  end
  bids.util.mkdir(out_path);

  [URL] = get_URL(source, demo, verbose);
  filename = bids.internal.download(URL, bids.internal.root_dir(), verbose);

  % Unzipping dataset
  [~, basename, ext] = fileparts(filename);
  if strcmp(ext, '.zip')

    msg = sprintf('Unzipping dataset:\n %s to \n %s \n\n', ...
                  bids.internal.format_path(filename), ...
                  bids.internal.format_path(out_path));
    print_to_screen(msg, verbose);

    if ~is_valid_zip(filename)
      error(['Invalid ZIP file "%s". The download may have failed or ' ...
             'the file is corrupted.'], filename);
    end

    unzip(filename, out_path);
    if strcmpi(source, 'spm') && strcmpi(demo, 'moae')
      bids.util.create_participants_tsv(out_path);
    end
    delete(filename);

    switch demo
      case {'moae', 'facerep'}
      case 'eeg'
        copyfile(fullfile(bids.internal.root_dir, 'EEG', '*'), out_path);
      otherwise
        movefile(fullfile(bids.internal.root_dir, basename), out_path);
    end

  end

end

function [URL, ftp_server, demo_path] = get_URL(source, demo, verbose)

  sources = {'spm', 'brainstorm'};
  demos = {'moae', 'facerep', ...
           'ieeg', 'ecog', 'meg', 'meg_rest'};

  switch source

    case 'spm'

      base_url = 'https://files.de-1.osf.io/v1/resources/3vufp/providers/osfstorage/';

    case 'brainstorm'
      ftp_server = 'neuroimage.usc.edu';
      base_url = ['ftp://' ftp_server];

    otherwise
      msg  =  sprintf('Unknown demo source.\nPossible sources are:\n\t%s', ...
                      strjoin(sources, ', '));
      bids.internal.error_handling(mfilename(), 'unknownSource', ...
                                   msg, ...
                                   false, verbose);
  end

  switch demo

    % spm
    case 'moae'
      demo_path = '6239d943938b48080c97b6d4/?zip=';

      %     case 'eeg'
      %       demo_path = '/mmfaces/multimodal_eeg.zip';

    case 'facerep'
      demo_path = '63ecdf3ea3fade062fe7d3f7/?zip=';

      % brainstorm
    case 'ieeg'
      demo_path = '/pub/tutorials/tutorial_epimap_bids.zip';
      % ds_size = '190 Mb';

    case 'meg'
      demo_path = '/pub/tutorials/sample_fem.zip';
      % ds_size = '210 Mb';

    case 'ecog'
      demo_path = '/pub/tutorials/sample_ecog.zip';

    case 'meg_rest'
      demo_path = '/pub/tutorials/sample_omega.zip';

    otherwise
      msg  =  sprintf('Unknown demo.\nPossible demos are:\n\t%s', ...
                      strjoin(demos, ', '));
      bids.internal.error_handling(mfilename(), 'unknownDemos', ...
                                   msg, ...
                                   false, verbose);

  end

  URL = [base_url, demo_path];

end

function print_to_screen(msg, verbose)
  if verbose
    fprintf(1, msg);
  end
end

function valid = is_valid_zip(zipfile)
  try
    unzip(zipfile, tempname);
    valid = true;
  catch
    valid = false;
  end
end

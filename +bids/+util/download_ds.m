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
  %                                 'verbose', true);
  %
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

  p = inputParser;

  addParameter(p, 'source', default_source, @ischar);
  addParameter(p, 'demo', default_demo, @ischar);
  addParameter(p, 'out_path', default_out_path, @ischar);
  addParameter(p, 'force', default_force);
  addParameter(p, 'verbose', default_verbose);

  parse(p, varargin{:});

  verbose = p.Results.verbose;

  out_path = p.Results.out_path;
  if isempty(out_path)
    out_path = fullfile(bids.internal.root_dir, 'demos');
    out_path = fullfile(out_path, p.Results.source, p.Results.demo);
  elseif ~exist(out_path, 'dir')
    bids.util.mkdir(out_path);
  end

  % clean previous runs
  if isdir(out_path)
    if p.Results.force
      rmdir(out_path, 's');
    else
      bids.internal.error_handling(mfilename(), 'dataAlreadyHere', ...
                                   ['The dataset is already present.' ...
                                    'Use "force, true" to overwrite.'], ...
                                   true, verbose);
      return
    end
  end

  if strcmp(p.Results.source, 'spm')
    if strcmp(p.Results.demo, 'facerep')
      bids.internal.ds_spm_face_rep(fileparts(out_path));
      return
    end
  end

  [URL] = get_URL(p.Results.source, p.Results.demo, verbose);
  filename = bids.internal.download(URL, bids.internal.root_dir(), verbose);

  % Unzipping dataset
  [~, basename, ext] = fileparts(filename);
  if strcmp(ext, '.zip')

    msg = sprintf('Unzipping dataset:\n %s\n\n', filename);
    print_to_screen(msg, verbose);

    unzip(filename);
    delete(filename);

    switch basename
      case 'MoAEpilot.bids'
        movefile('MoAEpilot', fullfile(out_path));
      case 'multimodal_eeg'
        movefile('EEG', fullfile(out_path));
      otherwise
        movefile(basename, fullfile(out_path));
    end

  end

end

function [URL, ftp_server, demo_path] = get_URL(source, demo, verbose)

  sources = {'spm', 'brainstorm'};
  demos = {'moae', 'facep', 'eeg', ...
           'ieeg', 'ecog', 'meg', 'meg_rest'};

  switch source

    case 'spm'
      base_url = 'http://www.fil.ion.ucl.ac.uk/spm/download/data';

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
      demo_path = '/MoAEpilot/MoAEpilot.bids.zip';

    case 'eeg'
      demo_path = '/mmfaces/multimodal_eeg.zip';

      % brainstorm
    case 'ieeg'
      demo_path = '/pub/tutorials/tutorial_epimap_bids.zip';
      ds_size = '190 Mb';

    case 'meg'
      demo_path = '/pub/tutorials/sample_fem.zip';
      ds_size = '210 Mb';

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

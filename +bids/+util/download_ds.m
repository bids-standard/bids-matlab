function out_path = download_ds(varargin)
  %
  % output_dir = download_moae_ds(download_data, output_dir)
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  % output_dir = download_moae_ds(download_data, output_dir)

  % TODO
  %
  % SPM face
  % Brainstorm
  % Fieldtrip
  % EEGlab ?

  % returns if data is already there if no force is used

  % display URL downloaded (and ETA ?)

  default_source = 'spm';
  default_demo = 'moae';

  default_out_path = fullfile(bids.internal.root_dir, 'demos');
  default_force = false;
  default_verbose = true;

  p = inputParser;

  addParameter(p, 'source', default_source, @ischar);
  addParameter(p, 'demo', default_demo, @ischar);
  addParameter(p, 'out_path', default_out_path, @ischar);
  addParameter(p, 'force', default_force);
  addParameter(p, 'verbose', default_verbose);

  parse(p, varargin{:});

  out_path = p.Results.out_path;
  verbose = p.Results.verbose;

  % URL of the data set to download
  URL = 'http://www.fil.ion.ucl.ac.uk/spm/download/data/MoAEpilot/MoAEpilot.bids.zip';

  out_path = fullfile(out_path, 'MoAE');

  % clean previous runs
  if exist(out_path, 'dir')
      if p.Results.force
        rmdir(out_path, 's');
      else
        bids.internal.error_handling(mfilename(), 'dataAlredyHere', ...
            'The dataset is already present. Use "force, true" to overwrite.', ...
             true, verbose)
        return
      end
  end

  filename = download(URL, verbose);

  % Unzipping dataset
  unzip(filename);
  delete(filename);
  movefile('MoAEpilot', fullfile(out_path));

%   SEEG+ECOG+MRI:
% https://neuroimage.usc.edu/brainstorm/Tutorials/ECoG
% ftp://neuroimage.usc.edu/pub/tutorials/sample_ecog.zip
% SEEG+MRI:
% https://neuroimage.usc.edu/brainstorm/Tutorials/Epileptogenicity
% ftp://neuroimage.usc.edu/pub/tutorials/tutorial_epimap.zip
% MEG+MRI+DWI:
% https://neuroimage.usc.edu/brainstorm/Tutorials/FemMedianNerve
% ftp://neuroimage.usc.edu/pub/tutorials/sample_fem.zip
% MEG resting-state:
% https://neuroimage.usc.edu/brainstorm/Tutorials/RestingOmega
% ftp://neuroimage.usc.edu/pub/tutorials/sample_omega.zip

end

function filename = download(URL, verbose)

  msg = sprintf('Downloading dataset from\n %s\n\n', URL);
  print_to_screen(msg, verbose)

  filename = bids.internal.file_utils(URL, 'filename');

  try
      if isunix()
          system(sprintf('wget %s', URL));
      else
        urlwrite(URL, filename);
      end
  catch
  end

end

function print_to_screen(msg, verbose)
    if verbose
        fprintf(1, msg);
    end
end

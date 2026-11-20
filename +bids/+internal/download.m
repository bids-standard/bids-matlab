function filename = download(URL, output_dir, verbose)
  %
  % USAGE::
  %
  %   filename = download(URL, output_dir, verbose)
  %

  % (C) Copyright 2021 BIDS-MATLAB developers
  if nargin < 2
    output_dir = pwd;
  end
  bids.util.mkdir(output_dir);

  msg = sprintf('Downloading dataset from:\n %s\n\n', URL);
  print_to_screen(msg, verbose);

  tokens = regexp(URL, '/', 'split');
  protocol = tokens{1};

  filename = tokens{end};
  if strcmp(filename, '?zip=')
    [~, filename] = fileparts(tempname);
    filename = [filename '.zip'];
  end

  if exist(filename, 'file')
    delete(filename);
  end

  if ismember(protocol, {'http:', 'https:'})

    try
      urlwrite(URL, filename); %#ok<*URLWR>
    catch
      % urlwrite can fail on large files
      % (e.g. Octave >= 11 times out after a few seconds),
      % so fall back on wget and make sure it writes to the expected file
      options = '';
      if ~verbose
        options = '-q';
      end
      % save to the expected filename:
      % by default wget would use the last part of the URL (e.g. 'index.html?zip=')
      status = system(sprintf('wget %s -O "%s" "%s"', options, filename, URL));
      if status ~= 0
        msg = sprintf('Failed to download:\n %s', URL);
        bids.internal.error_handling(mfilename(), 'downloadFailed', msg, false, true);
      end
    end

    % move file in case it was not downloaded in the root dir
    if ~exist(fullfile(output_dir, filename), 'file')
      print_to_screen([bids.internal.format_path(filename), ...
                       ' --> ', ...
                       bids.internal.format_path(output_dir)], verbose);
      movefile(filename, fullfile(output_dir, filename));
    end
    filename = fullfile(output_dir, filename);

  else

    ftp_server = tokens{3};
    ftpobj = ftp(ftp_server);

    filename = strjoin(tokens(4:end), '/');
    filename = mget(ftpobj, filename, output_dir);

  end

  if iscell(filename)
    filename = filename{1};
  end

  print_to_screen(' Done\n\n', verbose);

end

function print_to_screen(msg, verbose)
  if verbose
    fprintf(1, msg);
  end
end

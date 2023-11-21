function sub_idx = return_subject_index(BIDS, filename)
  %
  % For a given filename, it returns the subject index in BIDS structure so
  % that: ``BIDS.subjects(sub_idx)``
  %
  % USAGE::
  %
  %   sub_idx = return_subject_index(BIDS, filename)
  %
  %

  % (C) Copyright 2021 BIDS-MATLAB developers

  parsed_file = bids.internal.parse_filename(filename);

  % for files in the root folder with no sub entity we return immediately
  if ~isfield(parsed_file, 'entities') || ~isfield(parsed_file.entities, 'sub')
    sub_idx = [];
    return
  end
  sub = parsed_file.entities.sub;

  sub_idx = strcmp(['sub-' sub], {BIDS.subjects.name}');

  ses_idx = true(size(sub_idx));
  if isfield(parsed_file.entities, 'ses')
    ses = parsed_file.entities.ses;
    ses_idx = strcmp(['ses-' ses], {BIDS.subjects.session}');
  end

  sub_idx = find(all([sub_idx, ses_idx], 2));

end

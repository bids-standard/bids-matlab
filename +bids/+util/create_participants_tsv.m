function output_filename = create_participants_tsv(layout_or_path)
  %
  % Creates a simple participants tsv for a BIDS dataset.
  %
  %
  % USAGE::
  %
  %   output_filename = bids.util.create_participants_tsv(layout_or_path);
  %
  %
  % :param layout_or_path:
  % :type  layout_or_path:  path or structure
  %
  %
  % (C) Copyright 2022 Remi Gau

  layout = bids.layout(layout_or_path);

  if ~isempty(layout.participants)
    msg = sprintf(['"participant.tsv" already exist for the following dataset.', ...
                   'Will not overwrite.\n', ...
                   '\t%s'], layout.pth);
    bids.internal.error_handling(mfilename(), 'participantFileExist', msg, true, true);
    return
  end

  subjects_list = bids.query(layout, 'subjects');

  subjects_list = [repmat('sub-', numel(subjects_list), 1), char(subjects_list')];

  output_structure = struct('participant_id', subjects_list);

  output_filename = fullfile(layout.pth, 'participants.tsv');

  bids.util.tsvwrite(fullfile(layout.pth, 'participants.tsv'), output_structure);

  fprintf(1, ['\nCreated "participants.tsv" to the dataset.', ...
              '\n\t%s\n', ...
              'Please add participant age, gender...\n', ...
              'See this section of the BIDS specification:\n\t%s\n'], ...
          layout.pth, ...
          bids.internal.url('participants'));

end

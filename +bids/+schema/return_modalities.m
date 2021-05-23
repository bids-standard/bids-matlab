function modalities = return_modalities(subject, schema, modality_group)
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  % if we go schema-less we list directories in the subject/session folder
  % as proxy of the modalities that we have to parse
  modalities = cellstr(bids.internal.file_utils('List', ...
                                                subject.path, ...
                                                'dir', ...
                                                '.*'));
  if ~isempty(schema)
    modalities = schema.modalities.(modality_group).datatypes;
  end

end

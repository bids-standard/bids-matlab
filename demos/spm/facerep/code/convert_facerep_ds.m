function output_dir = convert_facerep_ds(input_dir, output_dir)
  %
  % downloads the face repetition dataset from SPM and convert it to BIDS
  %
  % requires BIDS matlab
  %
  % Adapted from its counterpart for MoAE
  % <https://www.fil.ion.ucl.ac.uk/spm/download/data/MoAEpilot/MoAE_convert2bids.m>
  %

  % (C) Copyright 2021 Remi Gau

  % TODO
  % recode the lag column so that the identity of each stimulus is captured
  % in another column and lag can be recomputed

  if nargin < 1
    input_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'sourcedata');
  end
  if nargin < 2
    output_dir = fullfile(input_dir, '..');
  end

  subject = 'sub-01';
  task_name = 'face repetition';
  nb_slices = 24;
  repetition_time = 2;
  echo_time = 0.04;

  opt.indent = '  ';

  %% Create output folder structure
  spm_mkdir(output_dir, subject, {'anat', 'func'});

  %% Structural MRI
  anat_hdr = spm_vol(fullfile(input_dir, 'Structural', 'sM03953_0007.img'));
  anat_data  = spm_read_vols(anat_hdr);
  anat_hdr.fname = fullfile(output_dir, 'sub-01', 'anat', 'sub-01_T1w.nii');
  spm_write_vol(anat_hdr, anat_data);

  %% Functional MRI
  func_files = spm_select('FPList', fullfile(input_dir, 'RawEPI'), '^sM.*\.img$');
  spm_file_merge( ...
                 func_files, ...
                 fullfile(output_dir, 'sub-01', 'func', ...
                          ['sub-01_task-' strrep(task_name, ' ', '') '_bold.nii']), ...
                 0, ...
                 repetition_time);
  delete(fullfile(output_dir, 'sub-01', 'func', ...
                  ['sub-01_task-' strrep(task_name, ' ', '') '_bold.mat']));

  %% And everything else
  create_events_tsv_file(input_dir, output_dir, task_name, repetition_time);
  create_events_json(output_dir, task_name, opt);
  create_readme(output_dir);
  create_changelog(output_dir);
  create_datasetdescription(output_dir, opt);
  create_bold_json(output_dir, task_name, repetition_time, nb_slices, echo_time, opt);
  bids.util.create_participants_tsv(output_dir);

end

function create_events_tsv_file(input_dir, output_dir, task_name, repetition_time)

  load(fullfile(input_dir, 'all_conditions.mat'), ...
       'names', 'onsets', 'durations');

  load(fullfile(input_dir, 'sots.mat'), ...
       'itemlag');

  % fill in with zeros as we can't have empty cells in tsv files
  itemlag{1} = nan(size(onsets{1}))';
  itemlag{3} = nan(size(onsets{3}))';

  onset_column = [];
  duration_column = [];
  trial_type_column = [];
  lag_column = [];

  for iCondition = 1:numel(names)
    onset_column = [onset_column; onsets{iCondition}]; %#ok<*USENS>
    duration_column = [duration_column; durations{iCondition}']; %#ok<*AGROW>
    trial_type_column = [trial_type_column; repmat(names{iCondition}, ...
                                                   size(onsets{iCondition}, 1), 1)];
    lag_column = [lag_column, itemlag{iCondition}];
  end

  lag_column = lag_column';

  event_type_column = repmat('show_face', size(onset_column));

  repetition_type_column = [];
  face_type_column = {};

  % Build 2 columns:
  % - one for face type (famous, unfamiliar)
  % - one for 1rst and 2nd presentation
  % to make the the 2X2 design more explicit in the TSV and be able to have
  % single TSV for parametric and non parametric models
  for i = 1:size(trial_type_column, 1)

    if strcmp(trial_type_column(i, 2), '1')
      repetition_type_column{i, 1} = 'first_show';
    else
      repetition_type_column{i, 1} = 'delayed_repeat';
    end

    if strcmp(trial_type_column(i, 1), 'N')
      face_type_column{i, 1} = 'unfamiliar';
    else
      face_type_column{i, 1} = 'famous';
    end

  end

  % sort trials by their presentation time
  [onset_column, idx] = sort(onset_column);
  duration_column = duration_column(idx);
  lag_column = lag_column(idx, :);
  repetition_type_column = repetition_type_column(idx, :);
  face_type_column = face_type_column(idx, :);

  onset_column = repetition_time * onset_column;

  tsv_content = struct('onset', onset_column, ...
                       'duration', duration_column, ...
                       'trial_type', {cellstr(event_type_column)}, ....
                       'repetition_type', {cellstr(repetition_type_column)}, ...
                       'face_type', {cellstr(face_type_column)}, ...
                       'lag', lag_column);

  spm_save(fullfile(output_dir, 'sub-01', 'func', ...
                    ['sub-01_task-' strrep(task_name, ' ', '') '_events.tsv']), ...
           tsv_content);

end

function create_events_json(output_dir, task_name, opt)

  onset_desc = ['Onset of the event measured from the beginning ' ...
                'of the acquisition of the first volume ', ...
                'in the corresponding task imaging data file.'];

  lag_desc = ['the Lags code, for each second presentation of a face, ', ...
              'the number of trials intervening between this (repeated) presentation ', ...
              'and its previous (first) presentation.', ...
              'A value of 0 means this is the first presentation.'];

  repetition_type_desc = 'Factor indicating whether this image has been already seen.';
  first_show_desc =  'indicates the first display of this face.';
  delayed_repeat_desc = 'indicates the second display of this face.';

  face_type_desc = 'Factor indicating type of face image being displayed.';
  famous_face_desc = 'A face that should be recognized by the participants.';
  unfamiliar_face_desc = 'A face that should not be recognized by the participants.';

  event_type_HED = struct('show_face', ...
                          'Sensory-event, Experimental-stimulus, (Def/Face-image, Onset)');

  repetition_type_levels = struct('first_show', first_show_desc, ...
                                  'delayed_repeat', delayed_repeat_desc);
  repetition_type_HED = struct('first_show', 'Def/First-show-cond', ...
                               'delayed_repeat', 'Def/Delayed-repeat-cond');

  face_type_levels = struct('famous', famous_face_desc, ...
                            'unfamiliar', unfamiliar_face_desc);
  face_type_HED = struct('famous', 'Def/Famous-face-cond', ...
                         'unfamiliar', 'Def/Unfamiliar-face-cond');

  hed_face_image_def =  ['(Definition/Face-image, ', ...
                         '(Visual-presentation, ', ...
                         '(Foreground-view, ', ...
                         '((Image, Face, Hair), Color/Grayscale), ', ...
                         '((White, Cross), (Center-of, Computer-screen))), ', ...
                         '(Background-view, Black), ', ...
                         'Description/', ...
                         'A happy or neutral face in frontal or 3/4 frontal pose ', ...
                         'with long hair ', ...
                         'cropped presented as an achromatic foreground image ', ...
                         'on a black background ', ...
                         'with a white fixation cross superposed.)', ...
                         ')'];
  hed_def_sensory = struct('Description', 'Dictionary for gathering sensory definitions', ...
                           'HED', struct('Face_image_def', hed_face_image_def));

  % pattern to use to create condition HED definitions
  cdt_hed_def = '(Definition/%s, (Condition-variable/%s, %s, Description/%s))';
  create_def = @(x) sprintf(cdt_hed_def, x.def, x.label, x.tags, x.desc);

  label = 'Face-type';

  famous.def = 'Famous-face-cond';
  famous.label = label;
  famous.tags = '(Image, (Face, Famous))';
  famous.desc = famous_face_desc;

  unfamiliar.def = 'Unfamiliar-face-cond';
  unfamiliar.label = label;
  unfamiliar.tags = '(Image, (Face, Unfamiliar))';
  unfamiliar.desc = unfamiliar_face_desc;

  famous_def = create_def(famous);
  unfamiliar_def = create_def(unfamiliar);

  label = 'Repetition-type';

  first_show.def = 'First-show-cond';
  first_show.label = label;
  first_show.tags = '(Item-count/1, Face)';
  first_show.desc = first_show_desc;

  delayed_repeat.def = 'Delayed-repeat-cond';
  delayed_repeat.label = label;
  delayed_repeat.tags = '(Item-count/2, Face)';
  delayed_repeat.desc = delayed_repeat_desc;

  first_show_def = create_def(first_show);
  delayed_repeat_def = create_def(delayed_repeat);

  hed_def_conds = struct( ...
                         'Description', ...
                         'Dictionary for gathering experimental condition definitions', ...
                         'HED', struct( ...
                                       'Famous_face_cond_def', famous_def, ...
                                       'Unfamiliar_face_cond_def', unfamiliar_def, ...
                                       'First_show_cond_def', first_show_def, ...
                                       'Delayed_repeat_cond_def', delayed_repeat_def));

  content = struct( ...
                   'onset', struct('Description', onset_desc), ...
                   'duration', struct('Description', ...
                                      'Duration of the event (measured from onset).', ...
                                      'units', 'seconds'), ...
                   'trial_type', struct('Description', ...
                                        ['Primary categorisation of each trial to identify', ...
                                         ' them as instances of the experimental conditions.']), ...
                   'lag', struct('Description', lag_desc), ...
                   'event_type', struct('LongName', 'Event category', ...
                                        'Description', 'The main category of the event.', ...
                                        'Levels', struct('show_face', ...
                                                         ['Display a face to mark', ...
                                                          ' end of pre-stimulus and' ...
                                                          ' start of blink-inhibition.']), ...
                                        'HED', event_type_HED), ...
                   'repetition_type', struct('Description', repetition_type_desc, ...
                                             'Levels', repetition_type_levels, ...
                                             'HED',  repetition_type_HED), ...
                   'face_type', struct('Description', face_type_desc, ...
                                       'Levels', face_type_levels, ...
                                       'HED',  face_type_HED), ...
                   'hed_def_sensory', hed_def_sensory, ...
                   'hed_def_conds', hed_def_conds ...
                  );

  spm_save(fullfile(output_dir, ['task-', strrep(task_name, ' ', ''), '_events.json']), ...
           content, ...
           opt);

end

function create_readme(output_dir)

  rdm = {
         ' ___  ____  __  __'
         '/ __)(  _ \(  \/  )  Statistical Parametric Mapping'
         '\__ \ )___/ )    (   Wellcome Centre for Human Neuroimaging'
         '(___/(__)  (_/\/\_)  https://www.fil.ion.ucl.ac.uk/spm/'

         ''
         '               Face repetition example event-related fMRI dataset'
         '________________________________________________________________________'
         ''
         '???'
         ''
         'Summary:'
         '7 Files, 79.32MB'
         '1 - Subject'
         '1 - Session'
         ''
         'Available Tasks:'
         'face repetition'
         ''
         'Available Modalities:'
         'T1w'
         'bold'
         'events'
         ''
         'These whole brain BOLD/EPI images were acquired on a modified ???T'
         'Siemens MAGNETOM Vision system.'
         '351 acquisitions were made.'
         'Each EPI acquisition consisted of 24 descending slices:'
         '- matrix size: 64x64'
         '- voxel size: 3mm x 3mm x 3mm with 1.5mm gap'
         '- repetition time: 2s'
         '- echo time: 40ms'
         ''
         'Experimental design:'
         '- 2x2 factorial event-related fMRI'
         '- One session (one subject)'
         '- (Famous vs. Nonfamous) x (1st vs 2nd presentation) of faces '
         '  against baseline of checkerboard'
         '- 2 presentations of 26 Famous and 26 Nonfamous Greyscale photographs, '
         '  for 0.5s, randomly intermixed, for fame judgment task '
         '  (one of two right finger key presses).'
         '- Parametric factor "lag" = number of faces intervening '
         '  between repetition of a specific face + 1'
         '- Minimal SOA=4.5s, with probability 2/3 (ie 1/3 null events)'
         ''
         'A structural image was also acquired.'};

  % TODO
  % use spm_save to actually write this file?
  fid = fopen(fullfile(output_dir, 'README'), 'wt');
  for i = 1:numel(rdm)
    fprintf(fid, '%s\n', rdm{i});
  end
  fclose(fid);

end

function create_changelog(output_dir)

  cg = { ...
        '1.0.1 2020-11-26', ' - BIDS version.', ...
        '1.0.0 1999-05-13', ' - Initial release.'};
  fid = fopen(fullfile(output_dir, 'CHANGES'), 'wt');

  for i = 1:numel(cg)
    fprintf(fid, '%s\n', cg{i});
  end
  fclose(fid);

end

function create_datasetdescription(output_dir, opt)

  descr = struct( ...
                 'BIDSVersion', '1.8.0', ...
                 'Name', 'Mother of All Experiments', ...
                 'Authors', {{ ...
                              'Henson, R.N.A.', ...
                              'Shallice, T.', ...
                              'Gorno-Tempini, M.-L.', ...
                              'Dolan, R.J.'}}, ...
                 'ReferencesAndLinks', ...
                 {{'https://www.fil.ion.ucl.ac.uk/spm/data/face_rep/', ...
                   ['Henson, R.N.A., Shallice, T., Gorno-Tempini, M.-L. ' ...
                    'and Dolan, R.J. (2002),', ...
                    'Face repetition effects in implicit and explicit memory tests as', ...
                    'measured by fMRI. Cerebral Cortex, 12, 178-186.'], ...
                   'doi:10.1093/cercor/12.2.178'}}, ...
                 'HEDVersion', '8.0.0');

  spm_save(fullfile(output_dir, 'dataset_description.json'), ...
           descr, ...
           opt);

end

function create_bold_json(output_dir, task_name, repetition_time, nb_slices, echo_time, opt)

  acquisition_time = repetition_time - repetition_time / nb_slices;
  slice_timing = linspace(acquisition_time, 0, nb_slices);

  task = struct( ...
                'RepetitionTime', repetition_time, ...
                'EchoTime', echo_time, ...
                'SliceTiming', slice_timing, ...
                'NumberOfVolumesDiscardedByScanner', 0, ...
                'NumberOfVolumesDiscardedByUser', 0, ...
                'TaskName', task_name, ...
                'TaskDescription', ...
                ['2 presentations of 26 Famous and 26 Nonfamous Greyscale photographs, ', ...
                 'for 0.5s, randomly intermixed, for fame judgment task ', ...
                 '(one of two right finger key presses).'], ...
                'Manufacturer', 'Siemens', ...
                'ManufacturersModelName', 'MAGNETOM Vision', ...
                'MagneticFieldStrength', 2);

  spm_save(fullfile(output_dir, ...
                    ['task-' strrep(task_name, ' ', '') '_bold.json']), ...
           task, ...
           opt);

end

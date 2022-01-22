function layout_timing
  %
  % runs bids.layout on the bids-examples and gives an estimate of the timing
  % for each
  %

  %% WITH SCHEMA
  % data      time (sec)
  % micr_SPIM     0.066
  % micr_SEM      0.069
  % qmri_tb1tfl     0.073
  % qmri_qsm      0.075
  % qmri_sa2rage      0.076
  % pet004      0.082
  % qmri_vfa      0.084
  % pet003      0.087
  % qmri_irt1     0.090
  % pet001      0.092
  % hcp_example_bids      0.094
  % asl005      0.098
  % asl003      0.098
  % qmri_mtsat      0.099
  % asl002      0.100
  % asl001      0.104
  % qmri_mp2rage      0.107
  % asl004      0.112
  % pet005      0.113
  % ds000248      0.125
  % qmri_megre      0.129
  % ds000246      0.141
  % eeg_ds003654s_hed_inheritance     0.144
  % qmri_mp2rageme      0.153
  % pet002      0.155
  % ieeg_visual     0.183
  % ieeg_epilepsy_ecog      0.186
  % eeg_ds003654s_hed_longform      0.188
  % eeg_ds003654s_hed     0.194
  % ieeg_epilepsy     0.197
  % eeg_rest_fmri     0.228
  % eeg_matchingpennies     0.318
  % ds000247      0.360
  % ieeg_filtered_speech      0.363
  % eeg_face13      0.387
  % ds003     0.480
  % qmri_mese     0.537
  % eeg_cbm     0.636
  % ieeg_motorMiller2007      0.818
  % synthetic     0.959
  % ds101     0.963
  % genetics_ukbb     0.989
  % ieeg_visual_multimodal      1.014
  % ds001     1.035
  % ds005     1.060
  % ds105     1.064
  % ds102     1.281
  % ds052     1.293
  % qmri_mpm      1.299
  % eeg_rishikesh     1.486
  % ds008     1.498
  % ds011     1.654
  % ds114     1.667
  % ds109     1.767
  % ds002     1.855
  % ds051     1.873
  % eeg_ds000117      1.900
  % ds116     1.975
  % ds007     2.356
  % ds107     2.386
  % ds113b      2.554
  % ds009     2.732
  % ds210     2.820
  % ds110     3.263
  % ds006     3.378
  % ds108     3.897
  % 7t_trt      5.685
  % ds000117      5.958
  % ds000001-fmriprep     NaN

  %% WITHOUT SCHEMA
  %  sorted results
  % data      time (sec)
  % qmri_qsm      0.020
  % qmri_tb1tfl     0.021
  % qmri_sa2rage      0.026
  % pet004      0.032
  % pet003      0.033
  % micr_SEM      0.034
  % qmri_vfa      0.035
  % qmri_irt1     0.037
  % hcp_example_bids      0.037
  % pet001      0.042
  % asl001      0.047
  % qmri_mp2rage      0.047
  % asl003      0.047
  % qmri_mtsat      0.048
  % asl005      0.051
  % asl002      0.054
  % pet005      0.054
  % asl004      0.055
  % ds000248      0.070
  % qmri_megre      0.070
  % micr_SPIM     0.077
  % ds000246      0.077
  % eeg_ds003654s_hed_inheritance     0.079
  % pet002      0.089
  % ieeg_epilepsy_ecog      0.104
  % qmri_mp2rageme      0.105
  % ieeg_epilepsy     0.115
  % eeg_ds003654s_hed     0.119
  % eeg_ds003654s_hed_longform      0.120
  % ieeg_visual     0.128
  % eeg_rest_fmri     0.151
  % eeg_matchingpennies     0.227
  % ieeg_filtered_speech      0.247
  % ds000247      0.250
  % eeg_face13      0.256
  % ds003     0.340
  % qmri_mese     0.402
  % eeg_cbm     0.449
  % ieeg_motorMiller2007      0.657
  % ds101     0.700
  % synthetic     0.715
  % ds001     0.742
  % genetics_ukbb     0.753
  % ds005     0.783
  % ds105     0.815
  % ds052     0.818
  % ieeg_visual_multimodal      0.856
  % ds102     0.928
  % eeg_rishikesh     1.078
  % ds011     1.169
  % qmri_mpm      1.184
  % ds008     1.194
  % ds114     1.240
  % ds109     1.263
  % ds002     1.366
  % ds051     1.383
  % ds116     1.430
  % eeg_ds000117      1.520
  % ds007     1.684
  % ds113b      1.872
  % ds107     1.879
  % ds210     2.124
  % ds009     2.204
  % ds110     2.371
  % ds006     2.691
  % ds108     2.918
  % 7t_trt      4.566
  % ds000117      6.760
  % ds000001-fmriprep     NaN

  pth_bids_example = get_test_data_dir();

  d = dir(pth_bids_example);
  d(arrayfun(@(x) ~x.isdir || ismember(x.name, {'.', '..', '.git', '.github'}), d)) = [];

  tab = '\t\t\t';

  fprintf('\n');
  fprintf(['data' tab 'time (sec)\n']);
  fprintf('\n');
  for i = 1:numel(d)

    ds{i} = d(i).name;

    fprintf(1, '%s', d(i).name);

    if exist(fullfile(pth_bids_example, d(i).name, '.SKIP_VALIDATION'), 'file')
      fprintf([tab 'skip\n']);
      T(i) = nan;
      continue
    end

    tic;
    bids.layout(fullfile(pth_bids_example, d(i).name), 'use_schema', true, 'verbose', false);
    T(i) = toc;

    fprintf(1, [tab '%0.3f\n'], T(i));

  end
  fprintf('\n');

  [T, I] = sort(T);
  ds = ds(I);
  fprintf('\n sorted results\n');
  fprintf(['data' tab 'time (sec)\n']);

  for i = 1:numel(ds)
    fprintf(1, ['%s' tab '%0.3f\n'], ds{i}, T(i));
  end

end

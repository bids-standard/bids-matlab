function layout_timing
  %
  % runs bids.layout on the bids-examples and gives an estimate of the timing
  % for each
  %

  use_schema =  false;

  %% WITH SCHEMA
  % data      time (sec)
  % qmri_tb1tfl     0.090
  % qmri_qsm      0.090
  % qmri_sa2rage      0.093
  % pet004      0.105
  % pet003      0.106
  % asl003      0.106
  % qmri_irt1     0.107
  % qmri_vfa      0.110
  % micr_SEMzarr      0.112
  % qmri_mtsat      0.115
  % hcp_example_bids      0.116
  % pet001      0.117
  % fnirs_tapping     0.117
  % asl005      0.118
  % qmri_mp2rage      0.121
  % asl002      0.123
  % asl004      0.124
  % micr_SEM      0.128
  % qmri_megre      0.138
  % eeg_ds003654s_hed_inheritance     0.151
  % ds000246      0.152
  % pet002      0.159
  % asl001      0.163
  % pet005      0.166
  % micr_SPIM     0.176
  % ieeg_epilepsy_ecog      0.183
  % ds000248      0.188
  % ieeg_visual     0.191
  % qmri_mp2rageme      0.192
  % eeg_ds003654s_hed     0.201
  % ieeg_epilepsy     0.204
  % eeg_ds003654s_hed_library     0.212
  % eeg_rest_fmri     0.224
  % eeg_ds003654s_hed_longform      0.226
  % fnirs_automaticity      0.229
  % eeg_matchingpennies     0.308
  % ds000247      0.321
  % ieeg_filtered_speech      0.325
  % eeg_face13      0.379
  % ds003     0.410
  % qmri_mese     0.473
  % eeg_cbm     0.599
  % ieeg_motorMiller2007      0.722
  % synthetic     0.806
  % ds101     0.807
  % ds001     0.864
  % ds005     0.865
  % genetics_ukbb     0.882
  % ieeg_visual_multimodal      0.907
  % ds052     0.945
  % ds105     0.961
  % ds102     1.018
  % qmri_mpm      1.174
  % eeg_rishikesh     1.289
  % ds011     1.310
  % ds008     1.400
  % ds109     1.462
  % ds114     1.464
  % ds051     1.526
  % ds002     1.555
  % ds116     1.749
  % eeg_ds000117      1.777
  % ds007     1.920
  % ds107     2.171
  % ds113b      2.232
  % ds210     2.336
  % ds009     2.476
  % ds110     2.583
  % ds006     2.866
  % ds108     3.218
  % ds000117      5.198
  % 7t_trt      5.443
  % ds000001-fmriprep     NaN

  %% WITHOUT SCHEMA
  % data      time (sec)
  % asl001      0.089
  % asl003      0.092
  % asl005      0.094
  % asl002      0.097
  % asl004      0.099
  % qmri_qsm      0.103
  % qmri_tb1tfl     0.106
  % pet004      0.113
  % qmri_sa2rage      0.113
  % hcp_example_bids      0.116
  % ds000248      0.117
  % qmri_vfa      0.119
  % pet003      0.120
  % qmri_mp2rage      0.122
  % ds000246      0.125
  % micr_SEMzarr      0.128
  % qmri_mtsat      0.132
  % pet001      0.133
  % eeg_ds003654s_hed_inheritance     0.135
  % qmri_irt1     0.141
  % pet005      0.148
  % micr_SEM      0.149
  % eeg_ds003654s_hed_longform      0.174
  % eeg_ds003654s_hed     0.176
  % eeg_ds003654s_hed_library     0.176
  % pet002      0.182
  % qmri_megre      0.183
  % micr_SPIM     0.185
  % ieeg_epilepsy     0.195
  % ieeg_visual     0.196
  % ieeg_epilepsy_ecog      0.199
  % qmri_mp2rageme      0.212
  % eeg_rest_fmri     0.216
  % fnirs_tapping     0.219
  % ds000247      0.264
  % eeg_matchingpennies     0.283
  % eeg_face13      0.335
  % ds003     0.375
  % ieeg_filtered_speech      0.385
  % eeg_cbm     0.476
  % qmri_mese     0.592
  % ds001     0.720
  % ds005     0.789
  % ieeg_motorMiller2007      0.808
  % ds101     0.813
  % ds105     0.829
  % genetics_ukbb     0.902
  % synthetic     0.963
  % ds102     0.970
  % ds052     0.993
  % ds008     1.127
  % eeg_rishikesh     1.144
  % ds011     1.190
  % ieeg_visual_multimodal      1.194
  % ds114     1.213
  % ds109     1.245
  % ds002     1.338
  % ds051     1.353
  % qmri_mpm      1.358
  % ds116     1.461
  % eeg_ds000117      1.518
  % ds007     1.586
  % ds113b      1.774
  % ds009     1.986
  % ds107     2.048
  % ds210     2.191
  % ds006     2.359
  % ds110     2.416
  % ds108     2.917
  % 7t_trt      3.905
  % fnirs_automaticity      5.766
  % ds000117      6.191
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
    bids.layout(fullfile(pth_bids_example, d(i).name), ...
                'use_schema', use_schema, ...
                'verbose', false);
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

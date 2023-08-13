function layout_timing
  %
  % runs bids.layout on the bids-examples and gives an estimate of the timing
  % for each
  %

  use_schema =  false;

  %% WITH SCHEMA
  % data      time (sec)
  % asl001      0.084
  % asl005      0.094
  % asl003      0.095
  % asl002      0.098
  % asl004      0.109
  % pet004      0.114
  % pet003      0.127
  % qmri_tb1tfl     0.137
  % qmri_qsm      0.138
  % qmri_irt1     0.139
  % qmri_sa2rage      0.153
  % micr_SEMzarr      0.159
  % pet001      0.165
  % qmri_mp2rage      0.174
  % pet005      0.182
  % qmri_vfa      0.185
  % qmri_mtsat      0.187
  % micr_SEM      0.198
  % ds000246      0.215
  % qmri_megre      0.217
  % hcp_example_bids      0.244
  % eeg_ds003645s_hed_inheritance     0.257
  % pet002      0.259
  % ds000248      0.292
  % micr_SPIM     0.312
  % qmri_mp2rageme      0.334
  % eeg_ds003645s_hed_longform      0.383
  % ieeg_visual     0.396
  % eeg_ds003645s_hed_library     0.405
  % ieeg_epilepsy_ecog      0.475
  % fnirs_tapping     0.557
  % eeg_rest_fmri     0.602
  % ds000247      0.693
  % ieeg_epilepsyNWB      0.752
  % motion_systemvalidation     0.817
  % eeg_matchingpennies     0.819
  % qmri_mese     0.862
  % eeg_face13      0.871
  % ieeg_epilepsy     1.097
  % ds004332      1.127
  % eeg_ds003645s_hed     1.209
  % ieeg_filtered_speech      1.783
  % ds005     1.904
  % ds003     2.030
  % ds101     2.090
  % qmri_mpm      2.333
  % ds105     2.390
  % motion_spotrotation     2.525
  % ieeg_visual_multimodal      2.544
  % ds052     2.627
  % ds001     2.692
  % genetics_ukbb     2.812
  % synthetic     3.061
  % ds011     3.139
  % ds008     3.390
  % eeg_cbm     3.691
  % ds051     3.726
  % ds114     3.818
  % ds002     3.877
  % ds102     4.276
  % ds007     4.544
  % ds109     4.726
  % ds116     5.002
  % eeg_rishikesh     5.175
  % ieeg_motorMiller2007      5.342
  % ds009     5.821
  % ds006     6.574
  % ds107     6.991
  % ds110     7.362
  % ds113b      7.766
  % eeg_ds000117      8.033
  % ds210     8.614
  % motion_dualtask     8.633
  % ds108     10.668
  % ds000117      15.543
  % 7t_trt      15.960
  % fnirs_automaticity      19.642
  % docs      NaN
  % ds000001-fmriprep     NaN
  % tools     NaN

  %% WITHOUT SCHEMA
  % qmri_qsm      0.071
  % qmri_tb1tfl     0.073
  % qmri_sa2rage      0.081
  % qmri_vfa      0.105
  % qmri_irt1     0.108
  % hcp_example_bids      0.113
  % asl001      0.120
  % pet004      0.122
  % pet001      0.126
  % qmri_mp2rage      0.128
  % asl003      0.128
  % qmri_mtsat      0.132
  % asl002      0.133
  % asl005      0.135
  % pet003      0.145
  % micr_SEMzarr      0.152
  % qmri_megre      0.176
  % asl004      0.177
  % micr_SEM      0.183
  % eeg_ds003645s_hed_inheritance     0.217
  % pet005      0.220
  % qmri_mp2rageme      0.243
  % ds000248      0.264
  % pet002      0.268
  % micr_SPIM     0.292
  % ds000246      0.307
  % ieeg_epilepsyNWB      0.333
  % eeg_ds003645s_hed_longform      0.335
  % ieeg_visual     0.351
  % eeg_ds003645s_hed_library     0.359
  % eeg_ds003645s_hed     0.362
  % ieeg_epilepsy     0.380
  % fnirs_tapping     0.463
  % ieeg_epilepsy_ecog      0.468
  % motion_systemvalidation     0.508
  % eeg_rest_fmri     0.523
  % qmri_mese     0.716
  % eeg_face13      0.767
  % ieeg_filtered_speech      0.775
  % eeg_matchingpennies     0.813
  % ds003     1.049
  % ds000247      1.092
  % ds004332      1.406
  % qmri_mpm      1.735
  % ieeg_motorMiller2007      1.781
  % motion_spotrotation     1.857
  % genetics_ukbb     1.915
  % ieeg_visual_multimodal      2.170
  % ds005     2.202
  % ds101     2.350
  % synthetic     2.446
  % ds052     2.544
  % eeg_cbm     2.554
  % ds001     2.638
  % eeg_rishikesh     2.776
  % ds102     2.939
  % ds105     3.204
  % ds109     3.461
  % ds114     3.507
  % ds011     4.585
  % ds051     4.758
  % ds002     4.927
  % ds008     5.239
  % ds116     5.307
  % eeg_ds000117      5.373
  % ds107     6.259
  % ds113b      6.300
  % ds210     7.619
  % ds110     7.992
  % motion_dualtask     8.380
  % ds108     8.887
  % ds007     10.000
  % ds009     10.363
  % ds006     10.371
  % fnirs_automaticity      14.192
  % 7t_trt      15.023
  % ds000117      23.928
  % docs      NaN
  % ds000001-fmriprep     NaN
  % tools     NaN

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

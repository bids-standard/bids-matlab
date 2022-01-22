function layout_timing
  %
  % runs bids.layout on the bids-examples and gives an estimate of the timing
  % for each
  %

  %% WITH SCHEMA
  %      sorted results
  % qmri_qsm      0.029
  % qmri_tb1tfl     0.029
  % qmri_sa2rage      0.033
  % pet002      0.034
  % pet004      0.036
  % pet003      0.039
  % qmri_vfa      0.039
  % qmri_irt1     0.040
  % hcp_example_bids      0.042
  % qmri_mp2rage      0.043
  % pet001      0.047
  % qmri_mtsat      0.048
  % asl003      0.055
  % pet005      0.057
  % asl005      0.058
  % asl002      0.062
  % qmri_megre      0.064
  % ds000248      0.066
  % asl001      0.068
  % asl004      0.073
  % ds000246      0.085
  % qmri_mp2rageme      0.086
  % ieeg_epilepsy_ecog      0.103
  % ieeg_visual     0.105
  % ieeg_epilepsy     0.106
  % eeg_rest_fmri     0.139
  % ieeg_filtered_speech      0.184
  % eeg_matchingpennies     0.204
  % eeg_face13      0.224
  % ds000247      0.250
  % qmri_mese     0.327
  % ds003     0.332
  % eeg_cbm     0.436
  % ieeg_motorMiller2007      0.567
  % synthetic     0.593
  % genetics_ukbb     0.659
  % ieeg_visual_multimodal      0.663
  % ds101     0.666
  % ds001     0.730
  % ds105     0.730
  % ds005     0.737
  % ds052     0.766
  % qmri_mpm      0.824
  % ds102     0.852
  % eeg_rishikesh     1.006
  % ds008     1.059
  % ds011     1.071
  % ds114     1.106
  % ds109     1.192
  % ds051     1.259
  % ds116     1.295
  % eeg_ds000117      1.328
  % ds002     1.330
  % ds007     1.568
  % ds113b      1.692
  % ds107     1.760
  % ds210     1.819
  % ds009     1.979
  % ds110     2.103
  % ds006     2.377
  % ds108     2.619
  % 7t_trt      4.294
  % ds000117      4.464
  % ds000001-fmriprep     NaN
  % schemaless      NaN

  %% WITHOUT SCHEMA
  %  sorted results
  % data      time (sec)
  % qmri_tb1tfl     0.017
  % qmri_qsm      0.018
  % pet002      0.023
  % qmri_sa2rage      0.024
  % pet004      0.024
  % qmri_vfa      0.027
  % qmri_irt1     0.028
  % pet003      0.029
  % hcp_example_bids      0.030
  % pet001      0.033
  % qmri_mp2rage      0.034
  % asl001      0.036
  % asl005      0.038
  % asl003      0.039
  % qmri_mtsat      0.040
  % asl002      0.041
  % pet005      0.045
  % asl004      0.046
  % qmri_megre      0.053
  % ds000248      0.058
  % ds000246      0.072
  % ieeg_epilepsy_ecog      0.090
  % qmri_mp2rageme      0.093
  % ieeg_visual     0.095
  % ieeg_epilepsy     0.098
  % eeg_rest_fmri     0.109
  % eeg_matchingpennies     0.160
  % ds000247      0.225
  % ieeg_filtered_speech      0.241
  % eeg_face13      0.245
  % ds003     0.256
  % qmri_mese     0.312
  % eeg_cbm     0.353
  % synthetic     0.488
  % ds101     0.535
  % genetics_ukbb     0.548
  % ds005     0.585
  % ds001     0.589
  % ds105     0.590
  % ds052     0.616
  % ieeg_motorMiller2007      0.635
  % ieeg_visual_multimodal      0.668
  % ds102     0.683
  % eeg_rishikesh     0.850
  % ds011     0.880
  % ds008     0.900
  % ds114     0.931
  % ds109     0.973
  % ds051     1.039
  % ds116     1.077
  % ds002     1.085
  % qmri_mpm      1.150
  % eeg_ds000117      1.219
  % ds007     1.286
  % ds113b      1.429
  % ds107     1.450
  % ds210     1.521
  % ds009     1.649
  % ds110     1.771
  % ds006     2.007
  % ds108     2.202
  % 7t_trt      3.585
  % ds000117      5.439
  % ds000001-fmriprep     NaN
  % schemaless      NaN

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
    bids.layout(fullfile(pth_bids_example, d(i).name), 'use_schema', false, 'verbose', false);
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

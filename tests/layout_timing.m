function layout_timing
  %
  % runs bids.layout on the bids-examples and gives an estimate of the timing
  % for each
  %

  %      sorted results
  % data      time (sec)
  % qmri_tb1tfl     0.030
  % qmri_qsm      0.030
  % qmri_sa2rage      0.033
  % pet002      0.036
  % pet004      0.039
  % pet003      0.040
  % qmri_vfa      0.041
  % qmri_irt1     0.042
  % hcp_example_bids      0.044
  % asl001      0.045
  % qmri_mp2rage      0.045
  % asl005      0.049
  % pet001      0.049
  % asl002      0.049
  % asl003      0.049
  % qmri_mtsat      0.051
  % asl004      0.055
  % pet005      0.065
  % qmri_megre      0.067
  % ds000248      0.080
  % ds000246      0.087
  % qmri_mp2rageme      0.089
  % ieeg_epilepsy_ecog      0.125
  % ieeg_epilepsy     0.153
  % ieeg_visual     0.154
  % eeg_rest_fmri     0.234
  % ieeg_filtered_speech      0.283
  % ds000247      0.283
  % eeg_face13      0.288
  % eeg_matchingpennies     0.300
  % qmri_mese     0.347
  % ds003     0.402
  % eeg_cbm     0.543
  % synthetic     0.662
  % genetics_ukbb     0.750
  % ds101     0.786
  % ieeg_motorMiller2007      0.810
  % ds105     0.815
  % ds001     0.823
  % ds005     0.832
  % qmri_mpm      0.849
  % ds052     0.861
  % ieeg_visual_multimodal      0.933
  % ds102     0.990
  % ds008     1.192
  % ds011     1.203
  % eeg_rishikesh     1.218
  % ds114     1.220
  % ds109     1.398
  % ds051     1.404
  % ds116     1.458
  % ds002     1.467
  % ds007     1.737
  % ds113b      1.877
  % eeg_ds000117      1.968
  % ds210     1.987
  % ds107     2.017
  % ds009     2.213
  % ds110     2.385
  % ds006     2.651
  % ds108     2.947
  % 7t_trt      4.337
  % ds000117      4.742
  % ds000001-fmriprep     NaN
  % schemaless      NaN

  use_schema = true;
  verbose = false;

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
    bids.layout(fullfile(pth_bids_example, d(i).name), use_schema, verbose);
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

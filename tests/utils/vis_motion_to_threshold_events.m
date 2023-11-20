function value = vis_motion_to_threshold_events()
  %

  % (C) Copyright 2022 Remi Gau

  value.onset = [2; 4; 6; 8];
  value.duration = [2; 2; 2; 2];
  value.trial_type = {'VisMot'; 'VisStat'; 'VisMot'; 'VisStat'};
  value.to_threshold = [1; 2; -1; -2];

end

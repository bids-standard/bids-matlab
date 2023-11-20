function value = participants()
  %

  % (C) Copyright 2022 Remi Gau

  value.sex_m = [true; true; false; false; false];
  value.handedness = {'right'; 'left'; nan; 'left'; 'right'};
  value.sex = {'M'; 'M'; 'F'; 'F'; 'F'};
  value.age_gt_twenty = [true; false; true; false; false];
  value.age = [21; 18; 46; 10; nan];

end

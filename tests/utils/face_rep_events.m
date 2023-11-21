function value = face_rep_events()

  value.onset = [2; 4; 5; 8];
  value.duration = [2; 2; 2; 2];
  value.repetition = [1; 1; 2; 2];
  value.familiarity = {'Famous face'; 'Unfamiliar face'; 'Famous face'; 'Unfamiliar face'};
  value.trial_type = {'Face'; 'Face'; 'Face'; 'Face'};
  value.response_time = [1.5; 2; 1.56; 2.1];

end

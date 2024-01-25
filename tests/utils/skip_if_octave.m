function skip_if_octave(msg)
  if bids.internal.is_octave()
    moxunit_throw_test_skipped_exception(['Octave:', msg]);
  end

end

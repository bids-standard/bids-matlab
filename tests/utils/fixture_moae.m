function bu_folder = fixture_moae()

  % back up content
  bu_folder = tempname;
  copyfile(moae_dir(), bu_folder);

end

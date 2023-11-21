function teardown_moae(bu_folder)

  % remove data
  rmdir(moae_dir(), 's');

  % bring backup back
  copyfile(bu_folder, moae_dir());

end

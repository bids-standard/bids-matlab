function [is_github, pth] = is_github_ci()
  % (C) Copyright 2021 Remi Gau
  is_github = false;

  GITHUB_WORKSPACE = getenv('HOME');

  if strcmp(GITHUB_WORKSPACE, '/home/runner')

    is_github = true;
    pth = GITHUB_WORKSPACE;

  end

end

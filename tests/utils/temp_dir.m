function value = temp_dir()
  value = tempname();
  mkdir(value);
end

function boilerplate_text = replace_placeholders(boilerplate_text, metadata)
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  placeholders = return_list_placeholders(boilerplate_text);

  for i = 1:numel(placeholders)

    this_placeholder = placeholders{i}{1};

    if isfield(metadata, this_placeholder) && ...
            ~isempty(metadata.(this_placeholder))

      text_to_insert = metadata.(this_placeholder);

      if isnumeric(text_to_insert)
        text_to_insert = num2str(text_to_insert);
      end

      boilerplate_text = regexprep(boilerplate_text, ...
                                   ['{{' this_placeholder '}}'],  ...
                                   text_to_insert);

    end

  end

end

function placeholders = return_list_placeholders(boilerplate_text)
  placeholders = regexp(boilerplate_text, '{{(\w*)}}', 'tokens');
end

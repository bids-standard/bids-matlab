function json = derivatives_json(varargin)
  %
  % Creates dummy content for a given BIDS derivative file.
  %
  % USAGE::
  %
  %   json = derivatives_json(derivative_filename, 'force', false)
  %
  % :param derivative_filename:
  % :type derivative_filename: string
  % :param force: when `true` it will force the creation of a json content even
  %  when the filename contains no BIDS derivatives entity.
  % :type force: boolean
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  %
  %     %% Common
  %     Description RECOMMENDED
  %     Sources OPTIONAL
  %     RawSources OPTIONAL
  %     SpatialReference REQUIRED if no space entity, or if non standard space RECOMMENDED otherwise
  %
  %     %% preprocessed
  %     SkullStripped REQUIRED for preprocessed data
  %     Resolution REQUIRED if "res" entity
  %     Density REQUIRED if "den" entity
  %
  %     %% Mask
  %     RawSources REQUIRED
  %     Type RECOMMENDED (Brain, Lesion, Face, ROI)
  %     Atlas REQUIRED if "label" entity
  %     Resolution REQUIRED if "res" entity
  %     Density REQUIRED if "den" entity
  %
  %     %% Segmentation
  %     Manual OPTIONAL
  %     Atlas OPTIONAL
  %     Resolution REQUIRED if "res" entity
  %     Density REQUIRED if "den" entity

  default_force = false;

  args = inputParser;
  addRequired(args, 'derivative_filename');
  addParameter(args, 'force', default_force);

  parse(args, varargin{:});

  derivative_filename = args.Results.derivative_filename;
  force = args.Results.force;

  p = bids.internal.parse_filename(derivative_filename);

  json =  struct('filename', '', 'content', '');

  if force || ...
          any(ismember(fieldnames(p.entities), {'desc', 'res', 'label', 'den', 'space'})) || ...
          any(ismember(p.suffix, {'mask', 'dseg', 'probseg'}))

    content = struct('Description', 'RECOMMENDED');

    content.Sources = {{'OPTIONAL'}};
    content.RawSources = {{'OPTIONAL'}};
    content.SpatialReference = {{ ['REQUIRED if no space entity ', ...
                                   'or if non standard space RECOMMENDED otherwise'] }};

    %% entity related content
    if any(ismember(fieldnames(p.entities), 'res'))
      content.Resolution = {{ struct(p.entities.res, 'REQUIRED if "res" entity') }};
    end

    if any(ismember(fieldnames(p.entities), 'den'))
      content.Density = {{ struct(p.entities.den, 'REQUIRED if "den" entity') }};
    end

    %% suffix related content
    if any(ismember(p.suffix, {'dseg', 'probseg'}))
      content.Manual = {{'OPTIONAL'}};
      content.Atlas = {{'OPTIONAL'}};
    end

    if any(ismember(p.suffix, {'mask'}))
      content.RawSources = {{'REQUIRED'}};
      content.Atlas = {{'OPTIONAL'}};
      content.Type = {{'OPTIONAL'}};
    end

    % TODO
    % preprocessed
    %     SkullStripped REQUIRED for preprocessed data

    json.content = content;
    json.filename = strrep(derivative_filename, p.ext, '.json');

  end

end

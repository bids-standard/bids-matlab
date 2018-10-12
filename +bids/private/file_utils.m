function str = file_utils(str,varargin)
% Character array (or cell array of strings) handling facility
% FORMAT str = file_utils(str,option)
% str        - character array, or cell array of strings
% option     - string of requested item - one among:
%              {'path', 'basename', 'ext', 'filename'}
%
% FORMAT str = file_utils(str,opt_key,opt_val,...)
% str        - character array, or cell array of strings
% opt_key    - string of targeted item - one among:
%              {'path', 'basename', 'ext', 'filename', 'prefix', 'suffix'}
% opt_val    - string of new value for feature
%__________________________________________________________________________

% Copyright (C) 2011-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging


needchar = ischar(str);
options = varargin;

str = cellstr(str);

%-Get item
%==========================================================================
if numel(options) == 1
    for n=1:numel(str)
        [pth,nam,ext] = fileparts(deblank(str{n}));
        switch lower(options{1})
            case 'path'
                str{n} = pth;
            case 'basename'
                str{n} = nam;
            case 'ext'
                str{n} = ext(2:end);
            case 'filename'
                str{n} = [nam ext];
            otherwise
                error('Unknown option.');
        end
    end
    options = {};
end

%-Set item
%==========================================================================
while ~isempty(options)
    for n=1:numel(str)
        [pth,nam,ext] = fileparts(deblank(str{n}));
        switch lower(options{1})
            case 'path'
                pth = char(options{2});
            case 'basename'
                nam = char(options{2});
            case 'ext'
                ext = char(options{2});
                if ~isempty(ext) && ext(1) ~= '.'
                    ext = ['.' ext];
                end
            case 'filename'
                nam = char(options{2});
                ext = '';
            case 'prefix'
                nam = [char(options{2}) nam];
            case 'suffix'
                nam = [nam char(options{2})];
            otherwise
                warning('Unknown item ''%s'': ignored.',lower(options{1}));
        end
        str{n} = fullfile(pth,[nam ext]);
    end
    options([1 2]) = [];
end

if needchar
    str = char(str);
end

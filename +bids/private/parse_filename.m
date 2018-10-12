function p = parse_filename(filename,fields)
filename = file_utils(filename,'filename');
[parts, dummy] = regexp(filename,'(?:_)+','split','match');
p.filename = filename;
[p.type, p.ext] = strtok(parts{end},'.');
for i=1:numel(parts)-1
    [d, dummy] = regexp(parts{i},'(?:\-)+','split','match');
    p.(d{1}) = d{2};
end
if nargin == 2
    for i=1:numel(fields)
        if ~isfield(p,fields{i})
            p.(fields{i}) = '';
        end
    end
    try
        p = orderfields(p,['filename','ext','type',fields]);
    catch
        warning('Ignoring file "%s" not matching template.',filename);
        p = struct([]);
    end
end

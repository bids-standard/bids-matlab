function meta = get_metadata(filename, pattern)
if nargin == 1, pattern = '^.*_%s\\.json$'; end
pth = fileparts(filename);
p = parse_filename(filename);

meta = struct();

if isfield(p,'ses') && ~isempty(p.ses)
    N = 4; % there is a session level in the hierarchy
else
    N = 3;
end
    
for n=1:N
    metafile = spm_select('FPList',pth, sprintf(pattern,p.type));
    if isempty(metafile), metafile = {}; else metafile = cellstr(metafile); end
    for i=1:numel(metafile)
        p2 = parse_filename(metafile{i});
        fn = setdiff(fieldnames(p2),{'filename','ext','type'});
        ismeta = true;
        for j=1:numel(fn)
            if ~isfield(p,fn{j}) || ~strcmp(p.(fn{j}),p2.(fn{j}))
                ismeta = false;
                break;
            end
        end
        if ismeta
            if strcmp(p2.ext,'.json')
                meta = update_metadata(meta,spm_jsonread(metafile{i}));
            else
                meta.filename = metafile{i};
            end
        end
    end
    pth = fullfile(pth,'..');
end


%==========================================================================
%-Inheritance principle
%==========================================================================
function s1 = update_metadata(s1,s2)
fn = fieldnames(s2);
for i=1:numel(fn)
    if ~isfield(s1,fn{i})
        s1.(fn{i}) = s2.(fn{i});
    end
end

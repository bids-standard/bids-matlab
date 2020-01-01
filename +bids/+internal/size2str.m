function out = size2str(sz)
%SIZE2STR Convert an array size to a string description
%
% out = bids.internal.size2str(sz)
%
% Returns a single string as charvec.

strs = cell(size(sz));
for i = 1:numel(sz)
    strs{i} = sprintf('%d',sz(i));
end
out = strjoin(strs,'-by-');

end

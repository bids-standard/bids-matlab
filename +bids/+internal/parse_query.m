function query = parse_query(query)
% PARSE_QUERY Parse query filter input into our standard form

if numel(query) == 1 && isstruct(query{1})
    query = [fieldnames(query{1}), struct2cell(query{1})];
else
    if mod(numel(query),2)
        error('Invalid input syntax: each BIDS entity requires an associated label');
    end
    query = reshape(query,2,[])';
end
for i=1:size(query,1)
    if ischar(query{i,2})
        query{i,2} = cellstr(query{i,2});
    end
    for j=1:numel(query{i,2})
        if iscellstr(query{i,2})
            query{i,2}{j} = regexprep(query{i,2}{j},sprintf('^%s-',query{i,1}),'');
        end
    end
end

end
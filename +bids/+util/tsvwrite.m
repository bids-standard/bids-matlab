function tsvwrite(f, var)
% Save text and numeric data to .tsv file
% FORMAT tsvwrite(f,var,opts,...)
% f     - filename
% var   - data array or structure
% opts  - optional inputs to be passed on to lower level function
%
% Adapted from spm_save.m
%__________________________________________________________________________
% Copyright (C) 2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2018--, BIDS-MATLAB developers


delim = sprintf('\t');

% if the input is a matlab table format we will use built-in function
% otherwise there is a bit of reformating to do
if isstruct(var) || iscell(var) || isnumeric(var) || islogical(var)
    
    %% convert input to a common format we will use for writing
    % var will be a 'table' where the first row is the header and all
    % following rows contains the values to write
    if isstruct(var)
        
        fn = fieldnames(var);
        var = struct2cell(var)';
        
        for i=1:numel(var)
            
            if ~ischar(var{i})
                var{i} = var{i}(:);
            end
            
            if ~iscell(var{i})
                var{i} = cellstr(num2str(var{i},16));
                var{i}(cellfun(@(x) strcmp(x,'NaN'),var{i})) = {'n/a'};
            end
            
        end
        
        var = [fn'; var];
        
    elseif iscell(var)
        var = cellfun(@(x) num2str(x,16), var, 'UniformOutput',false);
        
    elseif isnumeric(var) || islogical(var)
        var = num2cell(var);
        var = cellfun(@(x) num2str(x,16), var, 'UniformOutput',false);
        
    end
    
    try 
        var = strtrim(var);
    catch
    end
    
    %% Actually write to file
    fid = fopen(f,'Wt');
    
    if fid == -1
        error('Unble to write file %s.', f);
    end
    
    for i=1:size(var,1)
        
        for j=1:size(var,2)
            
            if isempty(var{i,j})
                var{i,j} = 'n/a';
            elseif any(var{i,j} == delim)
                var{i,j} = ['"' var{i,j} '"'];
            end
            
            fprintf(fid,'%s',var{i,j});
            
            if j < size(var,2)
                fprintf(fid,delim);
            end
            
        end
        
        fprintf(fid,'\n');
    end
    
    fclose(fid);
    
elseif isa(var,'table')
    writetable( var, f, ...
                'FileType', 'text', ...
                'Delimiter', delim);
            
else
    error('Unknown data type.');
    
end

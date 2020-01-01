classdef BIDSLayout
    %BIDSLAYOUT Layout class representing an entire BIDS dataset
    %
    % BIDSLayout is the main class representing a BIDS dataset on disk and
    % its contents.
    
    properties (SetAccess = private)
        % The root directory of the BIDS layout
        dir
        % The name of the dataset
        name
        % The BIDS Version of the dataset
        bidsVersion
        % Data content of dataset_description.json, as struct
        description = struct([])
        % List of sessions, as cellstr
        sessions = {}
        % content of sub-<participant_label>_scans.tsv (should go within subjects)
        scans = struct([])
        % content of sub-<participants_label>_sessions.tsv (should go within subjects)
        sess = struct([])
        % content of participants.tsv
        participants = struct([])
        % structure array of subjects
        subjects = struct([])
    end
    
    methods
        out = query(this, varargin)
        report(this)
    end
    
    methods (Static)
        out = fromPath(root)
    end
    
    methods
        function this = BIDSLayout()
            %BIDSLAYOUT Construct an instance of this class
            %
            % You should not call this constructor directly. Instead, use
            % the bids.layout.BIDSLayout.fromPath() method or bids.layout()
            % function.
            if nargin == 0
                return
            end
        end
        
        function disp(this)
            if isscalar(this)
                fprintf('  %s with peroperties:\n',class(this));
                fprintf('\n');
                fprintf('         name: %s\n',this.name);
                fprintf('          dir: %s\n',this.dir);
                fprintf('  bidsVersion: %s\n',this.bidsVersion);
            else
                fprintf('%s %s array\n',bids.internal.size2str(size(this)), ...
                    class(this));
            end
        end
        
        function [sts, msg] = validate(this)
            % VALIDATE Validate this layout with the bids-validator program
            %
            % [sts, msg] = validate(this)
            %
            % sts     - 0 if successful, nonzero if unsuccessful
            % msg     - warning and error messages, as char
            %
            % This requires the command line version of BIDS-Validator to be installed
            % on your system.
            %__________________________________________________________________________
            %
            % Command line version of the BIDS-Validator:
            %   https://github.com/bids-standard/bids-validator
            %__________________________________________________________________________
            
            [sts, ~] = system('bids-validator --version');
            if sts
                msg = 'Requires bids-validator from https://github.com/bids-standard/bids-validator';
            else
                [sts, msg] = system(['bids-validator "' strrep(this.dir,'"','\"') '"']);
            end
            
        end
    end
    
end
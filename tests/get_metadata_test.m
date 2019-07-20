% small test to ensure that metadata are reported correctly
% also tests inheritance principle: metadata are passed on to lower levels 
% unless they are overriden by metadate already present at lower levels
base_dir = fullfile(pwd, '..');
cd(base_dir)

% define the expected output from bids query metadata
func.RepetitionTime = 7;

func_sub_01.RepetitionTime = 10;

anat.FlipAngle = 5;

anat_sub_01.FlipAngle = 10;
anat_sub_01.Manufacturer = 'Siemens';

% try to get metadata
BIDS = bids.layout(fullfile(base_dir, 'tests', 'data', 'MoAEpilot'));


%% test func metadata base directory
metadata = bids.query(BIDS, 'metadata', 'type', 'bold');
assert(metadata.RepetitionTime == func.RepetitionTime);


%% test func metadata subject 01
metadata = bids.query(BIDS, 'metadata', 'sub', '01', 'type', 'bold');
assert(metadata.RepetitionTime == func_sub_01.RepetitionTime);


%% test anat metadata base directory
metadata = bids.query(BIDS, 'metadata', 'type', 'T1w');
assert(metadata.FlipAngle == anat.FlipAngle);


%% test anat metadata subject 01
metadata = bids.query(BIDS, 'metadata', 'sub', '01', 'type', 'T1w');
assert(metadata.FlipAngle == anat_sub_01.FlipAngle);
assert(strcmp(metadata.Manufacturer, anat_sub_01.Manufacturer));


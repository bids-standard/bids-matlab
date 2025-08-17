import json
from pathlib import Path
import pandas as pd

# Base directory
start_dir = Path(__file__).parent
raw_dir = start_dir / "data" / "dummy" / "raw"

# Subjects and sessions
subject_list = ["ctrl01", "blind01", "01"]
session_list = ["01", "02"]


def create_raw_func_vismotion(target_dir: Path, subject, ses):
    suffix = "_bold"
    task_name = "vismotion"
    this_dir = target_dir / f"sub-{subject}" / f"ses-{ses}" / "func"
    this_dir.mkdir(parents=True, exist_ok=True)

    # Two runs
    for run in range(1, 3):
        filename = this_dir / f"sub-{subject}_ses-{ses}_task-{task_name}_run-{run}{suffix}.nii"
        filename.touch()

    # Events run 1
    events_run1 = this_dir / f"sub-{subject}_ses-{ses}_task-{task_name}_run-1_events.tsv"
    df1 = pd.DataFrame(
        {
            "onset": [2, 4],
            "duration": [2, 2],
            "trial_type": ["VisMotUp", "VisMotDown"],
        }
    )
    df1.to_csv(events_run1, sep="\t", index=False)

    # Events run 2
    events_run2 = this_dir / f"sub-{subject}_ses-{ses}_task-{task_name}_run-2_events.tsv"
    df2 = pd.DataFrame(
        {
            "onset": [3, 6],
            "duration": [2, 2],
            "trial_type": ["VisMotDown", "VisMotUp"],
        }
    )
    df2.to_csv(events_run2, sep="\t", index=False)

    # Additional acquisitions
    (this_dir / f"sub-{subject}_ses-{ses}_task-{task_name}_acq-1p60mm_run-1{suffix}.nii").touch()
    (this_dir / f"sub-{subject}_ses-{ses}_task-{task_name}_acq-1p60mm_dir-PA_run-1{suffix}.nii").touch()


def create_raw_func_vislocalizer(target_dir, subject, ses):
    suffix = "_bold"
    task_name = "vislocalizer"
    this_dir = target_dir / f"sub-{subject}" / f"ses-{ses}" / "func"
    this_dir.mkdir(parents=True, exist_ok=True)

    # Functional file
    (this_dir / f"sub-{subject}_ses-{ses}_task-{task_name}{suffix}.nii").touch()

    # Events file
    events_file = this_dir / f"sub-{subject}_ses-{ses}_task-{task_name}_events.tsv"
    df = pd.DataFrame(
        {
            "onset": [2, 25],
            "duration": [15, 15],
            "trial_type": ["VisMot", "VisStat"],
        }
    )
    df.to_csv(events_file, sep="\t", index=False)


def create_raw_func_rest(target_dir, subject, ses):
    suffix = "_bold"
    task_name = "rest"
    this_dir = target_dir / f"sub-{subject}" / f"ses-{ses}" / "func"
    this_dir.mkdir(parents=True, exist_ok=True)

    (this_dir / f"sub-{subject}_ses-{ses}_task-{task_name}{suffix}.nii").touch()


def create_raw_fmap(target_dir, subject, ses):
    this_dir = target_dir / f"sub-{subject}" / f"ses-{ses}" / "fmap"
    this_dir.mkdir(parents=True, exist_ok=True)

    fmap_suffix_list = ["_phasediff", "_magnitude1", "_magnitude2"]
    for suffix in fmap_suffix_list:
        (this_dir / f"sub-{subject}_ses-{ses}_run-1{suffix}.nii").touch()
        (this_dir / f"sub-{subject}_ses-{ses}_run-2{suffix}.nii").touch()

    EchoTime1 = 0.006
    EchoTime2 = 0.00746
    suffix = "_bold"

    # JSON for vislocalizer
    task_name = "vislocalizer"
    intended_for = f"ses-{ses}/func/sub-{subject}_ses-{ses}_task-{task_name}{suffix}.nii"
    json_dict = {"EchoTime1": EchoTime1, "EchoTime2": EchoTime2, "IntendedFor": intended_for}
    json_file = this_dir / f"sub-{subject}_ses-{ses}_run-1_phasediff.json"
    json_file.write_text(json.dumps(json_dict))

    # JSON for vismotion
    task_name = "vismotion"
    intended_for = f"ses-{ses}/func/sub-{subject}_ses-{ses}_task-{task_name}_run-1{suffix}.nii"
    json_dict = {"EchoTime1": EchoTime1, "EchoTime2": EchoTime2, "IntendedFor": intended_for}
    json_file = this_dir / f"sub-{subject}_ses-{ses}_run-2_phasediff.json"
    json_file.write_text(json.dumps(json_dict))


def create_raw_anat(target_dir, subject):
    ses = "01"
    suffix = "_T1w"
    this_dir = target_dir / f"sub-{subject}" / f"ses-{ses}" / "anat"
    this_dir.mkdir(parents=True, exist_ok=True)

    (this_dir / f"sub-{subject}_ses-{ses}{suffix}.nii").touch()


# Main loop
for subject in subject_list:
    for ses in session_list:
        create_raw_func_vismotion(raw_dir, subject, ses)
        create_raw_func_vislocalizer(raw_dir, subject, ses)
        create_raw_func_rest(raw_dir, subject, ses)
        create_raw_fmap(raw_dir, subject, ses)
    create_raw_anat(raw_dir, subject)

print("Dummy BIDS dataset created at:", raw_dir)

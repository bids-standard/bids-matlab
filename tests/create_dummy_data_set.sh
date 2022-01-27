#!/bin/bash

# small bash script to create a dummy BIDS data set

# defines where the BIDS data set will be created
start_dir=$(pwd) # relative to starting directory
raw_dir=${start_dir}/data/dummy/raw

subject_list='ctrl01 blind01 01' # subject list
session_list='01 02'             # session list

create_raw_func_vismotion() {

	target_dir=$1
	subject=$2
	ses=$3

	suffix='_bold'
	task_name='vismotion'

	this_dir=${target_dir}/sub-${subject}/ses-${ses}/func

	mkdir -p "${this_dir}"

	for run in $(seq 1 2); do
		filename=${this_dir}/sub-${subject}_ses-${ses}_task-${task_name}_run-${run}${suffix}.nii
		touch "${filename}"
	done

	filename=${this_dir}/sub-${subject}_ses-${ses}_task-${task_name}_run-1_events.tsv
	echo "onset\tduration\ttrial_type" >"${filename}"
	echo "2\t2\tVisMotUp" >>"${filename}"
	echo "4\t2\tVisMotDown" >>"${filename}"

	filename=${this_dir}/sub-${subject}_ses-${ses}_task-${task_name}_run-2_events.tsv
	echo "onset\tduration\ttrial_type" >"${filename}"
	echo "3\t2\tVisMotDown" >>"${filename}"
	echo "6\t2\tVisMotUp" >>"${filename}"

	touch "${this_dir}/sub-${subject}_ses-${ses}_task-${task_name}_acq-1p60mm_run-1${suffix}.nii"
	touch "${this_dir}/sub-${subject}_ses-${ses}_task-${task_name}_acq-1p60mm_dir-PA_run-1${suffix}.nii"
}

create_raw_func_vislocalizer() {

	target_dir=$1
	subject=$2
	ses=$3

	suffix='_bold'
	task_name='vislocalizer'

	this_dir=${target_dir}/sub-${subject}/ses-${ses}/func

	mkdir -p ${this_dir}

	filename=${this_dir}/sub-${subject}_ses-${ses}_task-${task_name}${suffix}.nii
	touch "${filename}"

	filename=${this_dir}/sub-${subject}_ses-${ses}_task-${task_name}_events.tsv
	echo "onset\tduration\ttrial_type" >"${filename}"
	echo "2\t15\tVisMot" >>"${filename}"
	echo "25\t15\tVisStat" >>"${filename}"

}

create_raw_func_rest() {

	target_dir=$1
	subject=$2
	ses=$3

	suffix='_bold'
	task_name='rest'

	this_dir=${target_dir}/sub-${subject}/ses-${ses}/func

	mkdir -p "${this_dir}"

	touch "${this_dir}/sub-${subject}_ses-${ses}_task-${task_name}${suffix}.nii"

}

create_raw_fmap() {

	target_dir=$1
	subject=$2
	ses=$3

	this_dir=${target_dir}/sub-${subject}/ses-${ses}/fmap

	mkdir -p "${this_dir}"

	fmap_suffix_list='_phasediff _magnitude1 _magnitude2'
	for suffix in ${fmap_suffix_list}; do
		touch "${this_dir}/sub-${subject}_ses-${ses}_run-1${suffix}.nii"
		touch "${this_dir}/sub-${subject}_ses-${ses}_run-2${suffix}.nii"
	done

	EchoTime1=0.006
	EchoTime2=0.00746
	template='{"EchoTime1":%f, "EchoTime2":%f, "IntendedFor":"%s"}'

	suffix='_bold'

	task_name='vislocalizer'
	IntendedFor=$(echo ses-${ses}/func/sub-${subject}_ses-${ses}_task-${task_name}${suffix}.nii)
	json_string=$(printf "$template" "$EchoTime1" "$EchoTime2" "$IntendedFor")
	echo "$json_string" >${this_dir}/sub-${subject}_ses-${ses}_run-1_phasediff.json

	task_name='vismotion'
	IntendedFor=$(echo ses-${ses}/func/sub-${subject}_ses-${ses}_task-${task_name}_run-1${suffix}.nii)
	json_string=$(printf "$template" "$EchoTime1" "$EchoTime2" "$IntendedFor")
	echo "$json_string" >"${this_dir}/sub-${subject}_ses-${ses}_run-2_phasediff.json"

}

create_raw_anat() {

	target_dir=$1
	subject=$2

	ses='01'
	suffix='_T1w'

	this_dir=${target_dir}/sub-${subject}/ses-01/anat
	mkdir -p ${this_dir}

	touch ${this_dir}/sub-${subject}_ses-${ses}${suffix}.nii
}

# RAW DATASET
for subject in ${subject_list}; do
	for ses in ${session_list}; do
		create_raw_func_vismotion ${raw_dir} ${subject} ${ses}
		create_raw_func_vislocalizer ${raw_dir} ${subject} ${ses}
		create_raw_func_rest ${raw_dir} ${subject} ${ses}
		create_raw_fmap ${raw_dir} ${subject} ${ses}
	done

	create_raw_anat ${raw_dir} ${subject}
done

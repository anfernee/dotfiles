#!/bin/bash

function save()
{
	local file back_file
	file=$1

	if [ -e $file ] && [ ! -h $file ]; then
		back_file=$file.$(date +%s).back

		echo Backing up $file to $back_file
		mv $file $back_file
	fi
}

function update()
{
	local file newfile
	file=$1

	echo Updating $file

	if [[ "$file" =~ ^_ ]]; then
		# Why this doesn't work?
		# newfile=${file//^_/.}

		newfile=$(echo $file | sed 's/^_/./g')
		newfile=~/$newfile
	fi

	save $newfile

	[ ! -e $newfile ] && ln -sf $PWD/$file $newfile
}

git submodule update --init

pushd files

for file in `ls`; do
	update $file
done

popd

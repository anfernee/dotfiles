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

vundle_path=~/.vim/bundle/Vundle.vim
if [ ! -f $vundle_path ]; then
	git clone https://github.com/gmarik/Vundle.vim.git $vundle_path
fi

pushd files
for file in `ls`; do
	update $file
done
popd

# Vundle install
vim +PluginInstall +qall

ln -sf $PWD/bin ~/

# oh-my-zsh
sudo apt install -y zsh
sudo apt install -y curl

# Update claude configuration
save ~/.claude/CLAUDE.md && cp files/CLAUDE.md ~/.claude/CLAUDE.md

# Link skills to ~/.claude/skills
for file in `ls agent/skills`; do
	if [ ! -e ~/.claude/skills/$file ]; then
		echo Linking skill $file to ~/.claude/skills/$file
		ln -sf $PWD/agent/skills/$file ~/.claude/skills/$file
	else
		echo Skill $file already exists in ~/.claude/skills/$file, skipping
	fi
done


sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo 'Add "plugins=(zsh-autosuggestions)" in ~/.zshrc'


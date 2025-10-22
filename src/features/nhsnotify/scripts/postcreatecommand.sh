#!/bin/bash
CURRENT_DIR=$(pwd)

echo "Starting post create command script"
echo "Update from template variable is set to: ${UPDATEFROMTEMPLATE}"
update_from_template="${UPDATEFROMTEMPLATE:-true}"

REPO=https://github.com/NHSDigital/nhs-notify-repository-template.git
DEST=$HOME/nhsengland/repository-template
CURRENT_TIMESTAMP=$(date +%Y%m%d%H%M%S)
CHECKOUT_BRANCH="devcontainer-base"
UPDATE_BRANCH="updating-the-default-files-$CURRENT_TIMESTAMP"

get_repo_template(){
    echo "copying defaults"
    echo "getting nhse repo template"
    echo "Cloning $REPO into $DEST"
    mkdir -p $DEST
    echo "created destination directory $DEST"
    echo "Cloning repository from $REPO to $DEST"
    git clone -b $CHECKOUT_BRANCH $REPO $DEST
    echo "cloned repository $REPO branch $CHECKOUT_BRANCH to $DEST"
}

switch_to_update_branch(){
    echo "switching to update branch $UPDATE_BRANCH"
    CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
    echo "current branch is $CURRENT_BRANCH"
    git switch -C $UPDATE_BRANCH
}

copy_folder_if_not_exists(){
    local FOLDER=$1
    echo "checking for folder $FOLDER"
    mkdir -p $DEST/$FOLDER && \
    \cp -r --update=none $DEST/$FOLDER ./ && \
    echo "Copied $FOLDER" \
    || echo "Not copying $FOLDER, already exist"
}

copy_folder_overwrite(){
    local FOLDER=$1
    echo "copying folder $FOLDER"
    \cp -rf $DEST/$FOLDER ./
    echo "Copied $FOLDER"
}

copy_file_overwrite(){
    local FILE=$1
    echo "copying file $FILE"
    \cp -f $DEST/$FILE ./
    echo "Copied $FILE"
}

copy_file_dont_overwrite(){
    local FILE=$1
    echo "checking for file $FILE"
    \cp --update=none $DEST/$FILE ./
    echo "Copied $FILE if it did not exist"
}

update_from_template(){
    copy_folder_if_not_exists ".github"
    copy_folder_if_not_exists "docs"
    copy_folder_if_not_exists "infrastructure"
    copy_folder_if_not_exists ".vscode"

    copy_folder_overwrite "scripts"
    
    copy_file_overwrite "Makefile"
    copy_file_overwrite ".tool-versions"
    copy_file_overwrite ".editorconfig"
    copy_file_overwrite ".gitattributes"
    copy_file_overwrite ".gitignore"
    copy_file_overwrite ".gitleaksignore"

    copy_file_dont_overwrite "VERSION"
    copy_file_dont_overwrite "README.md"
    copy_file_dont_overwrite "LICENCE.md"

    echo "$REPO template update complete"
}

execute_update_from_template(){
    if [ "${update_from_template}" = "true" ]; then
        echo "Updating from template as per configuration"
        get_repo_template
        switch_to_update_branch
        update_from_template
    else
        echo "Skipping update from template as per configuration"
    fi
}


add_asdf_to_path(){
    echo "adding asdf to path"
    export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
    echo "added asdf to path"
}

sort_certs(){
    sudo cp -r --update=none /home/ca-certificates/. /usr/local/share/ca-certificates
    sudo update-ca-certificates
    echo "sorted certs"
}

configure_ohmyzsh(){
    echo "configuring ohmyzsh"
    echo "############################################################"
    echo "before ohmyzsh zshrc content:"
    cat ~/.zshrc
    echo "############################################################"
    echo ""

    echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> ~/.zshrc
    sed -i "/^plugins=/c\plugins=(git ssh-agent sudo terraform dirhistory)" ~/.zshrc
    
    echo "############################################################"
    echo "after ohmyzsh zshrc content:"
    cat ~/.zshrc
    echo "############################################################"
    echo ""
    echo "configured ohmyzsh"
}

add_gpg_tty_to_zshrc(){
    echo "adding gpg tty to zshrc"
    echo 'export GPG_TTY=$(tty)' >> ~/.zshrc
    echo "added gpg tty to zshrc"
}

echo "starting post create command script"

execute_update_from_template
add_asdf_to_path
sort_certs
configure_ohmyzsh
add_gpg_tty_to_zshrc
cd $CURRENT_DIR

echo "completed post create command script"
#!/bin/bash
set -o pipefail
#
# Author: Sebastien Wains https://github.com/sebw
# Heavily inspired by https://git.suckless.org/sites/file/tools.suckless.org/dmenu/scripts/todo.html
#
# Description: git and dmenu based CLI tasks manager.
#
# Tasks are stored in projects.
# Projects are git branches. Switching from one project == switching branch.
#
# Requirements:
#
# - dmenu
# - git
# - awk
# - sed
#
# Todo:
# - give possibility to pass tasks at the CLI --task "blah"
# - test with zero git config
# - bash/zsh autocompletion

### Enable debug with "true" if script acts up. Will output to /tmp/task.sh.log
DEBUG="false"

### Some functions used throughout the script
Logger () {
    if [ "$DEBUG" == "true" ]; then
        git status $TASK_DIR >> /tmp/task.sh.log
        echo $1 >> /tmp/task.sh.log
    fi
}

SanitizeBranch () {
    echo "$@" | sed 's/ /_/g'
}

ListBranch () {
    git --no-pager branch | grep -v master | sed 's/* //g' | awk '{print $1}'
}

CurrentBranch() {
    git rev-parse --abbrev-ref HEAD
}

ProjectExist() {
    Logger "Checking if $1 exists."
    git --no-pager branch | grep $1
    if [ "$?" == "0" ]; then
        Logger "$1 exists"
        PROJECT_EXIST=true
    else
        Logger "$1 doesn't exist"
        PROJECT_EXIST=false
    fi
}

CountLine() {
    wc -l "$1" | awk '{print $1}'
}

CheckRequirements () {
    which ${1} 2> /dev/null > /dev/null
    if [ "$?" != "0" ]; then
        Logger "Not finding $1, exiting."
        echo "${1} not found"
        exit 1
    else
        Logger "Found $1."
    fi
}

### Fail hard if requirements are not met
CheckRequirements dmenu
CheckRequirements git
CheckRequirements awk
CheckRequirements sed

### Location of configuration, change to your liking
CONFIG_DIR="${HOME}/.config/task.sh"
CONFIG="${CONFIG_DIR}/config"

### Check if config exists, or create it
if [ -e "${CONFIG}" ]; then
    Logger "${CONFIG} found, sourcing it."
    source ${CONFIG}
else
    Logger "${CONFIG} not found, creating and sourcing."
    mkdir -p ${CONFIG_DIR}
    cat << EOF > ${CONFIG}
TASK_DIR="\${HOME}/.task.sh"
TASK_TASK="\${TASK_DIR}/task.txt"
TASK_BAK="\${TASK_DIR}/task.txt.last"
TASK_DONE="\${TASK_DIR}/done.txt"
TASK_BRANCH="/tmp/task.sh_branch.txt"
TASK_normal_background="#0E5357"
TASK_normal_foreground="#FFFFFF"
TASK_selected_background="#002C39"
TASK_selected_foreground="#EEE8D5"
EOF
source ${CONFIG}
fi

# Always work inside the task directory

### Create task folder if it doesn't exist
### The script should ALWAYS work inside $TASK_DIR
if [ ! -e $TASK_DIR ]; then
    Logger "$TASK_DIR doesn't exist, creating."
    echo "$TASK_DIR doesn't exist"
    mkdir $TASK_DIR
    cd $TASK_DIR
    Logger "$TASK_DIR git init."
    git init
    touch "$TASK_TASK"
    touch "$TASK_BAK"
    touch "$TASK_DONE"
    git add .
    git commit -m "init"  
else
    Logger "Moving to $TASK_DIR"
    cd $TASK_DIR
fi

Menu () {
    dmenu -nb "$TASK_normal_background" -nf "$TASK_normal_foreground" -sb "$TASK_selected_background" -sf "$TASK_selected_foreground" -l "$height" -p "$prompt"
}

Task () {
    Logger "Task function called."
    cp $TASK_TASK $TASK_BAK
    height=$(CountLine $TASK_TASK)
    current_branch=$(CurrentBranch)
    Logger "Current branch $current_branch"
    if [ "$current_branch" == "master" ]; then
        # the master branch is immutable, give menu to switch or create a project
        ListBranch > $TASK_BRANCH
        height=$(CountLine $TASK_BRANCH)
        sort $TASK_BRANCH -o $TASK_BRANCH
        prompt="You are in the master project that is immutable. Please choose/create a project > "
        cmd=$(Menu "${@:2}" < $TASK_BRANCH)
        if [ "$cmd" != "" ]; then
            # We passed a project name, let's create it
            Logger "We choose $cmd from the list."
            Project "$cmd"
        else
            # We probably pressed escape
            Logger "We pressed escape."
            exit 1
        fi
    else
        # if we're already in a project, give menu to add tasks
        prompt="Add/Delete a task in project $current_branch > "
        cmd=$(Menu "${@:2}" < "$TASK_TASK")

        while [ -n "$cmd" ]; do
         	if grep -q "^$cmd\$" "$TASK_TASK"; then
                date=$(date)
        		echo "$cmd [Finished: $date]" >> "$TASK_DONE"
        		grep -v "^$cmd\$" "$TASK_TASK" > "$TASK_TASK.$$"
        		mv "$TASK_TASK.$$" "$TASK_TASK"
                height=$(( height - 1 ))
         	else
        		echo "$cmd" >> "$TASK_TASK"
        	    height=$(( height + 1 ))
         	fi

            sort $TASK_TASK -o $TASK_TASK
            sort $TASK_DONE -o $TASK_DONE
        
        	cmd=$(Menu "${@:2}" < "$TASK_TASK")
        done

        Logger "Committing tasks to $current_branch"
        git commit -a -m "Changed task."
    fi


}

Done () {
    Logger "Done function called."
    height=$(CountLine $TASK_DONE)
    branch=$(CurrentBranch)
    Logger "Branches are $branch"
    prompt="Tasks done in project $branch > "
    if [ "$height" == "0" ]; then
        Logger "There are no task done."
        height=1
        echo "You don't have any task done. Let's get to work!" | Menu "${@:2}"
    else
        cmd=$(Menu "${@:2}" < "$TASK_DONE")
        Logger "Choose $cmd but we're not doing anything with that."
    fi
}

Project () {
    Logger "Project function called."
    ListBranch > $TASK_BRANCH
    height=$(CountLine $TASK_BRANCH)
    sort $TASK_BRANCH -o $TASK_BRANCH
    if [ "$1" ]; then
        # if Project is called from Task function, create or switch to the branch passed as argument
        Logger "Project called from another function with arg $1"
        if [ $(ListBranch | grep "$1") ]; then
            git checkout "$1"
            count=$(CountLine $TASK_TASK)
            Logger "Project $1 exists with $count tasks. Just switched to it."
            Task
        else
            Logger "Project $1 doesn't exist. Create it."
            cmd_clean=$(SanitizeBranch "$1")
            Logger "Checking out master branch"
            git checkout master
            Logger "Creating branch $cmd_clean"
            git branch "$cmd_clean" 
            git checkout "$cmd_clean"
            if [ $"cmd_clean" != "" ]; then
                Task
            fi
        fi
    else
        Logger "--project called"
        # if Project is called from the CLI without argument, give a menu
        prompt="Choose/Create project > "
        cmd=$(Menu < "$TASK_BRANCH")
        if [ "$cmd" == "" ]; then
            Logger "Pressed Escape."
            exit 0
        else
            ProjectExist "$cmd"
            if [ "$PROJECT_EXIST" == "true" ]; then
                Logger "Project $cmd exists. Switching to it."
                git checkout "$cmd"
            else
                Logger "Project $cmd doesn't exists. Creating it."
                cmd_clean=$(SanitizeBranch "$cmd")
                git commit -a -m "update" > /dev/null
                git checkout master > /dev/null
                Logger "Creating branch $cmd_clean"
                git branch "$cmd_clean" > /dev/null
                git checkout "$cmd_clean" > /dev/null
            fi
        fi
    fi

    if [ "$cmd_clean" == ""  ]; then
        # avoids switching to master if Esc is pressed
        exit
    fi
}

DelProject () {
    Logger "DelProject function called."
    ListBranch > $TASK_BRANCH
    Logger "Projects are $(cat $TASK_BRANCH)"
    height=$(CountLine $TASK_BRANCH)
    Logger "Number of branches $height"
    sort $TASK_BRANCH -o $TASK_BRANCH
    prompt="Delete the project > "
    cmd=$(Menu < "$TASK_BRANCH")
    if [ "$?" == "0" ]; then
        Logger "Choose $cmd project to delete."
        prompt="Are you sure you want to delete project $cmd > "
        height="2"
        confirm=$(printf "no\nyes" | Menu)
        if [ "$confirm" == "yes" ]; then
            Logger "Deleting $cmd branch"
            git checkout "$cmd" > /dev/null
            rm -f $TASK_TASK $TASK_DONE $TASK_BAK $TASK_BRANCH
            git checkout master > /dev/null
            git branch -D "$cmd" > /dev/null
            Logger "Checking out to a clean master branch."
            git checkout master > /dev/null
            git restore $TASK_TASK > /dev/null
            git restore $TASK_BAK > /dev/null
            git restore $TASK_DONE > /dev/null
        fi
    fi
}

case "$1" in
    --task)
        Task
        ;;
    --project)
        Project
        ;;
    --task-done)
        Done
        ;;
    --delete-project)
        DelProject
        ;;
    *)
        echo $"Usage: task.sh

    Dmenu and git based command-line utility to manage task lists.

    Todos are called tasks, todo lists are called projects.

    --task: 
        Add tasks to a project.
        If you are on the master project, suggests to switch or create a project.

    --project: 
        Add a project or allows to switching to an existing one.

    --task-done:
        List tasks done in the current project.

    --delete-project:
        Delete a project.
        "

        exit 1
esac 

exit 0
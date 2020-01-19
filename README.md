# task.sh

A dmenu and git based command-line utility to manage task lists.

## Requirements

- dmenu
- git
- awk
- sed

## Installation

Copy `task.sh` somewhere in your `$PATH`.

## Usage

```
"Usage: task.sh

    --task: 
        Add tasks to a project.
        If you are on the master project, suggests to switch or create a project.

    --project: 
        Add a project or allows to switching to an existing one.

    --task-done:
        List tasks done in the current project.

    --delete-project:
        Delete a project.
```

## i3wm shortcuts

Suggested shortcuts for i3wm users:

```
for_window [window_role="task_dialog"] floating enable
bindsym $meta+t exec "~/bin/task.sh --task"
bindsym $meta+shift+t exec "~/bin/task.sh --task-done"
bindsym $meta+y exec "~/bin/task.sh --project"
bindsym $meta+shift+y exec "~/bin/task.sh --delete-project"
```

## Screenshots

## Screencast

## Known issues

- can conflict with personal git configuration

## Roadmap

- give possibility to pass tasks directly at the CLI `--task "my new task"` and bypassing dmenu
- bash/zsh autocompletion

# task.sh

A dmenu and git based command-line utility to manage task lists.

## Requirements

- dmenu
- git
- awk
- sed

## Why task.sh? How does it work?

I'm a huge keyboard shortcuts user.

I have searched for a simple todo application for a few hours and couldn't find
any that was lightweight, simple, and easily accessible from keyboard shortcuts.

Then I found a script on [suckless.org](https://git.suckless.org/sites/file/tools.suckless.org/dmenu/scripts/todo.html) that was very close to what I wanted.
The script was very simple and limited to one list.

I decided to extend it to multiple lists, with Git as the storage backend.

Lists are called projects, and a project is actually a git branch.

Anytime you add a task, it is committed to the branch.

Deleting a project equals a branch delete.

## Installation

Copy `task.sh` somewhere in your `$PATH`.

## Usage

```
Usage: task.sh

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

## Configuration

By default, tasks will be stored in `$HOME/.task.sh`.

A configuration file is created under `$HOME/.config/task.sh/config`.

## i3wm shortcuts

Suggested shortcuts for i3wm users:

```bash
for_window [class="floating"] floating enable
bindsym $meta+t exec "~/bin/task.sh --task"
bindsym $meta+shift+t exec "~/bin/task.sh --task-done"
bindsym $meta+y exec "~/bin/task.sh --project"
bindsym $meta+shift+y exec "~/bin/task.sh --delete-project"
bindsym $meta+u exec "gedit --class=floating ~/.task.sh/task.txt"
```

## Screencast

![](https://github.com/sebw/task.sh/blob/master/demo.gif)

## Known issues

- can conflict with personal git configuration

## Roadmap

- give possibility to pass tasks directly at the CLI `--task "my new task"` and bypassing dmenu
- bash/zsh autocompletion

## Troubleshooting

Change `DEBUG=false` to `DEBUG=true`.

Debug logs are stored in `/tmp/task.sh.log`.

# i3blocks Script

## Installation

For i3blocks users, place `i3blocks_task` in your script folder.

Add this section to `i3blocks.conf`:

```ini
[i3blocks_task]
interval=3
separator=true
markup=pango
```

## Screenshots

![](https://raw.githubusercontent.com/sebw/task.sh/master/i3blocks1.png)

![](https://raw.githubusercontent.com/sebw/task.sh/master/i3blocks2.png)

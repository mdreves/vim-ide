# Overview

The IDE plug-in provides a framework around which common development features
can be integrated into VIM. The plugin offers a number of features for opening
common "views" similar to other IDE environments. Although fully customizable,
many features have default implementations based on other commonly used VIM
plugins.

# Requirements

To make the most of this plugin, the following should be installed:

  - [projux](https://github.com/mdreves/projux)
  - [syntastic](https://github.com/scrooloose/syntastic)
  - [vim-fugative](https://github.com/tpope/vim-fugitive)
  - [vim-session](https://github.com/xolox/vim-session)
  - [taglist.vim](https://github.com/vim-scripts/taglist.vim)
  - [nerdtree](https://github.com/scrooloose/nerdtree)

Optional, but highly recommended plugins:
  - [vim-pyref (Python)](https://github.com/xolox/vim-pyref)
  - [vim-scaladoc (Scala)](https://github.com/mdreves/vim-scaladoc)
  - [eclim](http://eclim.org/)

# Installation

If you are using [pathogen](https://github.com/tpope/vim-pathogen), then
simply copy and paste:

    cd ~/.vim/bundle
    git clone git://github.com/mdreves/vim-ide.git

# Documentation

Once help tags have been generated, you can view the manual with
`:help ide`.

# Quickstart

Here's a quick summary of just some of the avaiable features:

  - Buffers:

        tj                      Toggle buffer list display
        :open :test             Open test file (from source)
        :open :src              Open source file (from test)
        :open :h                Open c header file

  - Diffing:

        :diff :saved            Diff current buffer with last save
        :diff :head             Diff current file with GIT head
        :diff :staged           Diff current file with GIT staged data

  - Docs:

        :doc <tag>              Launch browser to source code reference

  - Formatting:

        <leader>f               Format (current buffer)
        gq                      Format selected text

  - Building:

        <leader>b               Build in second TMUX window

  - Linting:

        <leader>l               Lint in second TMUX window

  - Errors:

        <leader>e               Errors (syntastic) for previous lint/build
        tl                      Toggle location (errors, grep) list display

        NOTE: If running vim from projux's pvim, build/lint errors are
              auto-loaded

  - Testing:

        <leader>t               Run test for current file

  - Running:

        <leader>r               Run program

  - Find/Grep:

        :Find <glob>            Find files in current project
        :Grep <pat>             Find files with pattern in current project

  - Sessions:

        :save :session          Save current VIM session under project name

  - TMUX:

        gt                      Send selected text to second tmux window


# License

Copyright 2012 Mike Dreves

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at:

    http://opensource.org/licenses/eclipse-1.0.php

By using this software in any fashion, you are agreeing to be bound
by the terms of this license. You must not remove this notice, or any
other, from this software. Unless required by applicable law or agreed
to in writing, software distributed under the License is distributed
on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied.

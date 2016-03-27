# extf.vim: Extended Vim's f/F key

A comparison of different schemes of jumping efficiently inside the current line:

| Plugin | N | Cycling & How to Exit | 
| --------- | --------- | --------- | 
| `f F ; ,` | 1 | Cycling through choices. No extract keystroke to exit "searching mode". | 
| [EasyMotion](https://github.com/easymotion/vim-easymotion) | >1 | No cycling through choices. One extra keystroke to exit "searching mode", and sometimes need one more read-and-press, which blocks type-without-thinking. | 
| extf.vim | >1 | Cycling through choices. (Feels like) no extract keystroke to exit "searching mode". | 

__N__: Number of character that can be inputed to filter the line.

## Installation

### Vundle

    Plugin 'hijack111/extf.vim'

### Command Line

    git clone https://github.com/hijack111/extf.vim.git
    cp extf.vim/plugin/extf.vim ~/.vim/plugin

## Screenshot
![Screenshot](../images/showcase_1.gif)

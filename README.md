# My Yaml helper

## Introduction

This is a plugin that adds some methods for traversing Yaml files:

- Moving to the parent node ( `:YamlGoToParent` ),
- Getting the full path to the current element ( `:YamlGetFullPath` ),
- Moving to an element, given the path ( `:YamlGoToKey` )

By default root is not displayed, if you want to turn it on put this in your `.vimrc`:
```
let g:vim_yaml_helper_show_root = 0
```

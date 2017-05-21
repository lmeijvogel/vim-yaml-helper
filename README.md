# My Yaml helper

## Introduction

This is a plugin that adds some methods for traversing Yaml files:

- Moving to the parent node ( `:YamlGoToParent` ),
- Getting the full path to the current element ( `:YamlGetFullPath` ),
- Moving to an element, given the path ( `:YamlGoToKey` )

If you want to always display and copy root when using `:YamlGetFullPath`, put this in your `.vimrc`:
```
let g:vim_yaml_helper#always_get_root = 1
```

To enable auto display of path to node under cursor put this in your `.vimrc`:
```
let g:vim_yaml_helper#auto_display_path = 1
```

## Testing

The plugin uses the vim-vspec plugin for testing. Add it to your vim bundle
(for Vundle, `Plugin 'kana/vim-vspec'`).

Then install a recent Ruby (I use 2.3.3) and install the required gems:

```
$ gem install bundler
$ bundle install --path vendor/bundle
```

You should now be able to run

```
bundle exec rake
```

to run the tests.

# My Yaml helper

# NOT MAINTAINED

This plugin is not maintained anymore.

## Introduction

This is a plugin that adds some methods for traversing Yaml files:

- Getting the full path to the current element ( `:YamlGetFullPath` ),
- Moving to an element, given the path ( `:YamlGoToKey` )

It also has a command for moving to the parent node ( `:YamlGoToParent` ),
but [vim-indentwise](https://github.com/jeetsukumaran/vim-indentwise) is
a lot better for this.

By default, `:YamlGetFullPath` does not include the root node since I developed it for
Rails `i18n`, where the root node is always the locale name.
If you want to always display and copy root when using `:YamlGetFullPath`, add this to your `.vimrc`:
```
let g:vim_yaml_helper#always_get_root = 1
```

To enable auto display of path to node under cursor, add this to your `.vimrc`:
```
let g:vim_yaml_helper#auto_display_path = 1
```

## Testing

The plugin uses the vim-vspec plugin for testing. Add it to your vim bundle
(for Vundle, `Plugin 'kana/vim-vspec'`).

Then install a recent Ruby (I use 2.5.5) and install the required gems:

```
$ gem install bundler
$ bundle install --path vendor/bundle
```

You should now be able to run

```
bundle exec rake
```

to run the tests.

source plugin/vim-yaml-helper.vim

describe 'vim-yaml-helper'
  before
    new
  end

  after
    close!
  end

  describe 'YamlGetFullPath'
    context 'with single root'
      before
        put!= [ 'aaa:',
             \ '  bbb: \"smart text\"',
             \ '  ccc:',
             \ '    ddd: \"tricky phrase\"']
      end

      it 'displays the path'
        normal! 4gg
        redir @x
        YamlGetFullPath
        redir END

        Expect getreg("x") =~ "ccc.ddd"

      end

      context 'when the root element is skipped'
        before
          let g:vim_yaml_helper#always_get_root = 0
        end

        it 'copies the path except the root element'
          normal! 4gg

          YamlGetFullPath

          Expect getreg('"') == "ccc.ddd"
        end
      end

      context 'when the root element is included'
        before
          let g:vim_yaml_helper#always_get_root = 1
        end

        it 'copies the whole path'
        " HERE
          normal! 4gg

          YamlGetFullPath

          Expect getreg('"') == "aaa.ccc.ddd"
        end
      end
    end
    context 'with multiple roots'
      before
        put!= [ 'aaa:',
              \ '  bbb: \"smart text\"',
              \ 'ccc:',
              \ '  ddd: \"tricky phrase\"']
      end

      it 'displays the path'
        normal! 4gg
        redir @x
        YamlGetFullPath
        redir END
        Expect getreg("x") =~ "ddd"
      end

      context 'when the root element is skipped'
        before
          let g:vim_yaml_helper#always_get_root = 0
        end

        it 'copies the path except the root element'
          normal! 4gg
          YamlGetFullPath
          Expect getreg('"') == "ccc.ddd"
        end
      end

      context 'when the root element is included'
        before
          let g:vim_yaml_helper#always_get_root = 1
        end

        it 'copies the whole path'
          normal! 4gg
          YamlGetFullPath
          Expect getreg('"') == "ccc.ddd"
        end
      end
    end
  end

  describe 'YamlGoToPath'
    before
      put!= [ 'aaa:',
           \ '  bbb: \"smart text\"',
           \ '  ccc:',
           \ '    ddd: \"tricky phrase\"',
           \ '  eee:',
           \ '    ddd: \"tricky phrase\"',
           \ '  fff:',
           \ '    ddd: \"tricky phrase\"',
           \ '      eee: \"tricky phrase\"',
           \ '        fff: \"tricky phrase\"']
    end

    context 'when the key exists'
      it 'moves to the correct line'
        YamlGoToKey eee.ddd

        Expect line('.') == 6
      end
    end

    context 'when the key does not exist'
      it 'moves to the most specific existing parent'
        YamlGoToKey fff.ddd.eee.xxx

        Expect getline('.') =~ "^\\s*eee:"

        YamlGoToKey fff.aaa.bbb.ccc

        Expect getline('.') =~ "^\\s*fff:"
      end
    end
  end

  describe 'YamlGoToParent'
    before
      put!= [ 'aaa:',
           \ '  bbb: \"smart text\"',
           \ '  ccc:',
           \ '    ddd: \"tricky phrase\"',
           \ '  eee:',
           \ '    ddd: \"tricky phrase\"',
           \ '  fff:',
           \ '    ddd: \"tricky phrase\"',
           \ '      eee: \"tricky phrase\"',
           \ '        fff: \"tricky phrase\"']
    end

    it 'moves to the parent'
      YamlGoToKey fff.ddd.eee.fff

      Expect getline('.') =~ "^\\s*fff:"

      YamlGoToParent

      Expect getline('.') =~ "^\\s*eee:"

      YamlGoToParent

      Expect getline('.') =~ "^\\s*ddd:"

      YamlGoToParent

      Expect getline('.') =~ "^\\s*fff:"

      YamlGoToParent

      Expect getline('.') =~ "^\\s*aaa:"
    end
  end
end


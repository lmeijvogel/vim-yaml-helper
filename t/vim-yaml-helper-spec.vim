source plugin/vim-yaml-helper.vim

describe 'vim-yaml-helper'
  before
    new
  end

  after
    close!
  end

  describe 'YamlGetFullPath'
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
        let g:vim_yaml_helper_show_root = 0
      end

      it 'copies the path except the root element'
        normal! 4gg

        YamlGetFullPath

        Expect getreg('"') == "ccc.ddd"
      end
    end

    context 'when the root element is included'
      before
        let g:vim_yaml_helper_show_root = 1
      end

      it 'copies the whole path'
        normal! 4gg

        YamlGetFullPath

        Expect getreg('"') == "aaa.ccc.ddd"
      end
    end
  end
end

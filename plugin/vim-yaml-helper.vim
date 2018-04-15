"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Published methods
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Go to the first line with less indenting than the current one.
" This only counts lines that start with a letter, so comments and
" empty lines will be skipped.
function! s:GoToParent()
  " Store this position in the jump list
  mark '

  " Find the current indent
  call s:MoveToParent()

  call search("\\a", "Wc", line("."))
endfunction

" Get the full Yaml path of the current line.
" This echoes the full path and optionally puts it in the default
" register so it can be pasted.
function! s:GetFullPath(copy_to_clipboard)
  let startPosition = getpos(".")

  let keys = []

  " Poor man's do-while loop :)
  let key = s:GetCurrentKey()
  while key != ""
    call add(keys, key)

    let parentFound = s:MoveToParent()

    if !parentFound
      break
    endif

    let key = s:GetCurrentKey()
  endwhile

  if len(keys) == 0
    echo ""
    return
  endif

  call reverse(keys)

  " This is done to work with Rails translations: The yaml file contains a
  " toplevel node (e.g. 'en') that should not end up in any I18n::translate
  " call arguments.
  call s:OptionallyRemoveToplevelNode(keys)

  let result = join(keys, ".")

  call setpos(".", startPosition)

  if a:copy_to_clipboard
    if &clipboard =~ '\<unnamed'
      let @+ = result
    else
      let @@ = result
    endif
  endif

  echo result
endfunction

" Given a key, go to the corresponding entry.
" If the key doesn't exist in the document, the search stops at the closest
" existing ancestor.
"
" This method also works in ActiveRecord-style translation files: If a key
" cannot be found, it tries again including the toplevel node. For example:
"
" Given a key 'datetime.format.default', it will first try 'datetime' as the
" toplevel node. If that doesn't work, it checks whether there's a single root
" node (e.g. 'en', 'nl', 'de') and tries it again with that.
function! s:GoToKey( key )
  let keyParts = split(a:key, "\\.")

  " This is done to work with Rails translations: The yaml file contains a
  " toplevel node (e.g. 'en') but any references to translation keys do not.
  call s:OptionallyAddToplevelNode(keyParts)

  let firstKey = remove(keyParts, 0)

  let foundFirstKey = s:FindFirstKey(firstKey)

  if foundFirstKey
    let currentIndent = 0

    for part in keyParts
      let currentIndent = s:MoveToChildKey(part, currentIndent)
    endfor
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Internal methods
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Move to the given child of the node at the current line
function! s:MoveToChildKey( key, currentIndent )
  " Determine where we'll need to stop searching (when the first sibling
  " is found, we don't have to look further)
  let firstSiblingRegex = s:MakeIndentRegex("equal", a:currentIndent)
  let siblingLineNumber = search(firstSiblingRegex, "Wn")

  " Now look for a corresponding child node between the current position
  " and the next sibling
  let childrenIndent = s:DetermineChildrenIndent(siblingLineNumber)

  let wantedChildRegex = s:MakeIndentRegex("equal", childrenIndent, a:key)
  let foundChild = search(wantedChildRegex, "W", siblingLineNumber)

  return childrenIndent
endfunction

function! s:MoveToParent()
  let indent = s:GetCurrentIndent()

  if indent == 0
    return 0
  endif

  let parentRegex = s:MakeIndentRegex("smaller", indent)

  return (search(parentRegex, "bW") != 0)
endfunction

function! s:GetCurrentIndent()
  return indent(line("."))
endfunction

function! s:GetCurrentKey()
  let currentLine = getline(".")

  let keyRegex = "^ *\\(.\\{-\\}\\):"

  let matches = matchlist(currentLine, keyRegex)
  try
    let key = matches[1]
  catch
    return ""
  endtry

  return key
endfunction

function! s:MakeIndentRegex(matchSizes, indent, ...)
  if a:0 > 0
    let text = a:1 .":"
  else
    let text = "\\a[^ ]"
  endif

  if a:matchSizes == "smaller"
    let min = ""
    let max = a:indent-1
  elseif a:matchSizes == "larger"
    let min = a:indent+1
    let max = ""
  elseif a:matchSizes == "equal"
    let min = a:indent
    let max = min
  endif

  return "^ \\{". min .",". max ."}".text
endfunction

" Move the cursor to the first toplevel node.
" Return 0 if it cannot be found.
function! s:FindFirstKey( key )
  call cursor(1,1)

  let regex = s:MakeIndentRegex("equal", 0, a:key)
  let matchPosition = search(regex, "Wc")

  return matchPosition != 0
endfunction

" It does not change the cursor position
function! s:DetermineChildrenIndent( stopLine )
  let currentIndent = s:GetCurrentIndent()

  " First get the first child to determine what indentation we want to find
  let candidateChildRegex = s:MakeIndentRegex("larger", currentIndent)

  " Since we might find empty lines, search all the way to the first sibling
  let firstChildLine = search(candidateChildRegex, "Wn", a:stopLine)

  if (firstChildLine == 0)
    return -1
  endif

  return indent(firstChildLine)
endfunction

" Add the toplevel node to the list of keys, but only if there's only one
" It does not change the cursor position
function! s:OptionallyAddToplevelNode( keyParts )
  let toplevelNodes = s:GetNodesWithIndent(0)

  if len(toplevelNodes) == 1
    let toplevelNode = toplevelNodes[0]

    if (toplevelNode != a:keyParts[0])
      call insert(a:keyParts, toplevelNode)
    endif
  endif
endfunction

" Remove the toplevel node if there's only one in the document.
" It does not change the cursor position.
"
" It assumes that the toplevel node is at the start of the list
function! s:OptionallyRemoveToplevelNode( keyParts )
  let toplevelNodes = s:GetNodesWithIndent(0)

  if len(toplevelNodes) == 1 && !get(g:, 'vim_yaml_helper#always_get_root', 0)
    let toplevelNode = toplevelNodes[0]

    if a:keyParts[0] == toplevelNode
      call remove(a:keyParts, 0)
    endif
  endif
endfunction

" This method is used to determine the root level nodes.
" It is not suitable for finding the any child elements since it only looks at indenting.
" It does not change the cursor position
function! s:GetNodesWithIndent( indent )
  let position = getpos(".")

  " Start at the top
  call cursor(1,1)

  let result = []
  let regex = s:MakeIndentRegex("equal", a:indent)

  " Poor man's do-while loop :)
  let matchAtCurrentLine = search(regex, "Wc")
  while matchAtCurrentLine != 0
    let foundKey = s:GetCurrentKey()
    call add(result, foundKey)

    " Move cursor down (if possible) - This is necessary since we're including
    " the current line in the search
    let nextNonBlank = nextnonblank(line(".")+1)
    if nextNonBlank > 0
      call cursor(nextNonBlank, 0)
    else
      break
    endif

    let matchAtCurrentLine = search(regex, "Wc")
  endwhile

  call setpos(".", position)

  return result
endfunction

function! s:commands()
	command! -buffer YamlGoToParent call s:GoToParent()
	command! -buffer YamlGetFullPath call s:GetFullPath(1)
	command! -buffer YamlDisplayFullPath call s:GetFullPath(0)
	command! -buffer -nargs=1 YamlGoToKey call s:GoToKey("<args>")
endfunction

augroup vim-yaml-helper
	autocmd!
	autocmd Filetype yaml call s:commands()

	if get(g:, 'vim_yaml_helper#auto_display_path', 1)
		autocmd CursorHold *.yml,*.yaml YamlDisplayFullPath
	end
augroup end

let s:ROOT_DIR = fnamemodify(resolve(expand('<sfile>:p')), ':h')

" Find the local Prettier install and return a command to run it.
function! prettier#resolver#executable#getCmd() abort
  let l:packagePath = s:FindNearestPackageWithPrettier()
  if l:packagePath == -1
    return -1
  end

  let l:nodeModulesBin = l:packagePath . '/node_modules/.bin/prettier'
  if executable(l:nodeModulesBin)
    return l:nodeModulesBin
  endif

  let l:pnpPath = l:packagePath . '/.pnp.cjs'
  if filereadable(l:pnpPath)
    let l:script =<< trim END
      const base = require('pnpapi').resolveToUnqualified('prettier', 'workspace:.');
      const { bin } = require(base + 'package.json');
      require(base + (bin.prettier || bin));
    END
    " The extra ` -- prettier` is so `process.argv[1]` contains a script name.
    return 'node -r ' . shellescape(l:pnpPath) . ' -e ' . shellescape(join(l:script)) . ' -- prettier'
  endif

  return -1
endfunction

" Find the nearest `package.json` that has Prettier as a (dev)dependency.
function! s:FindNearestPackageWithPrettier() abort
  let l:root = getcwd()
  while 1
    let l:packageJsonPath = l:root . '/package.json'
    if filereadable(l:packageJsonPath)
      let l:packageJson = json_decode(readfile(l:packageJsonPath))
      if type(l:packageJson) == v:t_dict
        if type(get(l:packageJson, 'dependencies')) == v:t_dict && !empty(get(l:packageJson.dependencies, 'prettier'))
          return l:root
        endif
        if type(get(l:packageJson, 'devDependencies')) == v:t_dict && !empty(get(l:packageJson.devDependencies, 'prettier'))
          return l:root
        endif
      endif
    endif

    let l:parent = fnamemodify(l:root, ':h')
    if l:parent == l:root
      return -1
    endif

    let l:root = l:parent
  endwhile
endfunction

function sqlfmt --wraps='pbpaste | bin/rails format:sql' --description 'alias sqlfmt=pbpaste | bin/rails format:sql'
  pbpaste | bin/rails format:sql $argv
        
end

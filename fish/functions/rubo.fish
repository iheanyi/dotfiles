function rubo --wraps='bundle exec rubocop -a --cache true --server' --description 'alias rubo=bundle exec rubocop -a --cache true --server'
  bundle exec rubocop -a --cache true --server $argv
        
end

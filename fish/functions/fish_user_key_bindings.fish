function fish_user_key_bindings
  # Bind ! and $ for bash-like history expansion
  # ! followed by ! gives previous command
  # $ expands to last argument of previous command
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end

def validate_email(input)
  re = /^[\w\-\.]+@([\w-]+\.)+[\w-]{2,}$/ # https://regex101.com/r/lHs2R3/1
  return re.match?(input)
end

def validate_username(input)
  if input.length < 4 or input.length > 20
    return false
  end

  return true
end

def validate_password(input)
  if input.length < 8 or input.length > 50
    return false
  end

  return true
end

def validate_thread_title(input)
  if input.length < 1 or input.length > 50
    return false
  end

  return true
end

def validate_thread_content(input)
  if input.length < 1 or input.length > 2000
    return false
  end

  return true
end

def validate_thread_reply(input)
  if input.length < 1 or input.length > 2000
    return false
  end

  return true
end

def validate_category_title(input)
  if input.length < 1 or input.length > 50
    return false
  end

  return true
end
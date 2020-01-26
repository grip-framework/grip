macro res(status_code, content)
  req.response.status_code = {{status_code}}.to_i
  {{content}}
end
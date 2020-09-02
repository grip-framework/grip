# File upload

```ruby
require "grip"

class UploadController < Grip::Controllers::Http
  def post(context)
    # The file is not stored anywhere, it is in a temporary state which can be saved
    # afterwards by you.
    file =
      context
        .fetch_file_params
        .["image"]
        .tempfile

    context
      .put_status(201)
      .json({"status" => "OK", "file_size" => file.size})
  end
end

class Application < Grip::Application
  def initialize
    post "/", UploadController
  end
end

app = Application.new
app.run
```
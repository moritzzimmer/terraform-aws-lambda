import os

print("Hello world from CodePipeline stage: " + os.environ.get("FOO", "default value"))

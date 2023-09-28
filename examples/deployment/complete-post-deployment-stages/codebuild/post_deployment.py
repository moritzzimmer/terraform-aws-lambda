import os

print("Hello World from Post Deployment Stage: " + os.environ.get("FOO", "No FOO env var found"))

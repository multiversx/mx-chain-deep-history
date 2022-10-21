FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    wget \ 
    python3.10 python-is-python3

COPY "./bootstrap.py" "/bootstrap.py"
ENTRYPOINT ["python", "/bootstrap.py", "--workspace", "/workspace"]

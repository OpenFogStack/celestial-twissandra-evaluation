from __future__ import print_function

import json
import multiprocessing
import os

workers_per_core_str = os.getenv("WORKERS_PER_CORE", "2")
web_concurrency_str = os.getenv("WEB_CONCURRENCY", None)
host = os.getenv("HOST", "0.0.0.0")
port = os.getenv("PORT", "80")
bind_env = os.getenv("BIND", None)
use_loglevel = os.getenv("LOG_LEVEL", "info")
cores_str = os.getenv("CORES", str(multiprocessing.cpu_count()))
if bind_env:
    use_bind = bind_env
else:
    use_bind = "{host}:{port}".format(host=host, port=port)

cores = float(cores_str)
workers_per_core = float(workers_per_core_str)
default_web_concurrency = workers_per_core * cores
if web_concurrency_str:
    web_concurrency = int(web_concurrency_str)
    assert web_concurrency > 0
else:
    web_concurrency = int(default_web_concurrency)

# Gunicorn config variables
loglevel = use_loglevel
workers = web_concurrency
max_requests=512
max_requests_jitter=128
bind = use_bind
keepalive = 120
errorlog = "-"

# For debugging and testing
log_data = {
    "loglevel": loglevel,
    "workers": workers,
    "bind": bind,
    # Additional, non-gunicorn variables
    "cores": cores,
    "workers_per_core": workers_per_core,
    "host": host,
    "port": port,
}
print(json.dumps(log_data))
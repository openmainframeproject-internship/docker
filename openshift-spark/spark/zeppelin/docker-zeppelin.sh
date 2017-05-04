#!/bin/bash

# Copyright 2015 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export ZEPPELIN_HOME=/opt/zeppelin
export ZEPPELIN_CONF_DIR="${ZEPPELIN_HOME}/conf"

mkdir -p /opt/zeppelin/vol/{conf,webapps,logs,run,notebook,local-repo}

#
# If this is the first time we've started up then copy the 
# initial configuration files from the template area
#
if [ ! -e /opt/zeppelin/vol/conf/interpreter.json ]; then
    cp -a /opt/zeppelin/conf_tmpl/* /opt/zeppelin/vol/conf/.
    cp -a /opt/zeppelin/notebook_tmpl/* /opt/zeppelin/vol/notebook/.
fi

echo "=== Launching Zeppelin under Docker ==="
/opt/zeppelin/bin/zeppelin.sh "${ZEPPELIN_CONF_DIR}"

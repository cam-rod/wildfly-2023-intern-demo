DEMOBD=$(buildah from quay.io/wildfly/wildfly:28.0.0.Final-jdk20)

buildah run --user root $DEMOBD -- microdnf makecache
buildah run --user root $DEMOBD -- microdnf -y install python3 java-17-openjdk-devel git maven
buildah run --user root $DEMOBD -- chown -R jboss /opt/jboss
buildah run $DEMOBD -- bash -c "curl -sSL https://install.python-poetry.org | python3 -"

# Build Elytron tool with integrity command
buildah run --workingdir /opt/jboss/wildfly $DEMOBD -- git clone -b ELY-2496 https://github.com/cam-rod/wildfly-elytron.git elytron
buildah run $DEMOBD -- bash -c 'cd /opt/jboss/wildfly/elytron && JAVA_HOME=/usr/lib/jvm/java-11 mvn clean install -DskipTests'

# Setup WildFly demo
buildah run $DEMOBD -- mkdir wildfly/wildfly-demo
buildah run --workingdir /opt/jboss/wildfly $DEMOBD -- \
  cp elytron/tool/target/wildfly-elytron-tool-shaded-2.1.1.CR1-SNAPSHOT.jar wildfly-demo
buildah run --workingdir /opt/jboss/wildfly $DEMOBD -- \
  cp elytron/tool/src/test/resources/filesystem-integrity/fsKeyStore.pfx wildfly-demo
buildah run --workingdir /opt/jboss/wildfly $DEMOBD -- \
  cp -r elytron/tool/src/test/resources/filesystem-integrity/fs-unsigned-realms/fsRealm wildfly-demo

buildah copy $DEMOBD configure-wildfly.cli commands.sh /opt/jboss/wildfly/wildfly-demo/

# Setup Python demo
buildah run $DEMOBD -- mkdir wildfly/python-demo
buildah copy $DEMOBD main.py pyproject.toml poetry.lock /opt/jboss/wildfly/python-demo
buildah run --workingdir /opt/jboss/wildfly/python-demo $DEMOBD -- /opt/jboss/.local/bin/poetry install

buildah copy $DEMOBD commands.sh /opt/jboss/wildfly/wildfly-demo/

buildah config --workingdir /opt/jboss/wildfly/wildfly-demo --author 'Cameron Rodriguez <dev@camrod.me>' \
  --entrypoint 'bash' $DEMOBD
buildah commit $DEMOBD wildfly-2023-intern-demo
buildah rm $DEMOBD
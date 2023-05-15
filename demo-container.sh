#!/bin/bash
set -e
export BUILDAH_HISTORY=1


# Create setup container for building Elytron
export DEMOBD_SETUP=$(buildah from registry.access.redhat.com/ubi9/ubi-minimal:9.2-484)
buildah run $DEMOBD_SETUP -- microdnf -y --refresh install git maven

# Build Elytron tool with integrity command. If this command fails, replace line 13 with the commented line
# buildah run --workingdir /opt/jboss/wildfly $DEMOBD_SETUP -- git clone https://github.com/wildfly-security/wildfly-elytron.git elytron
buildah run $DEMOBD_SETUP -- git clone -b ELY-2496 https://github.com/cam-rod/wildfly-elytron.git /elytron
buildah run $DEMOBD_SETUP -- bash -c 'cd /elytron && JAVA_HOME=/usr/lib/jvm/java-11 mvn clean install -DskipTests'


# Create demo container and copy repo scripts for WildFly demo
export DEMOBD=$(buildah from quay.io/wildfly/wildfly:28.0.0.Final-jdk20)
buildah run --user root $DEMOBD -- microdnf -y --refresh install python3 vi less
buildah run --user root $DEMOBD -- chown -R jboss /opt/jboss
buildah run $DEMOBD -- bash -c "curl -sSL https://install.python-poetry.org | python3 -"
buildah run $DEMOBD -- mkdir wildfly/wildfly-demo
buildah copy $DEMOBD configure-wildfly.cli commands.sh /opt/jboss/wildfly/wildfly-demo/

# Copy Elytron Tool to WildFly demo container
export DEMOBD_SETUP_MNT=$(buildah mount $DEMOBD_SETUP)
buildah copy $DEMOBD \
  "$DEMOBD_SETUP_MNT/elytron/tool/target/wildfly-elytron-tool-shaded-2.1.1.CR1-SNAPSHOT.jar" \
  /opt/jboss/wildfly/wildfly-demo
buildah copy $DEMOBD \
  "$DEMOBD_SETUP_MNT/elytron/tool/src/test/resources/filesystem-integrity/fsKeyStore.pfx" \
  /opt/jboss/wildfly/wildfly-demo
buildah copy $DEMOBD \
  "$DEMOBD_SETUP_MNT/elytron/tool/src/test/resources/filesystem-integrity/fs-unsigned-realms/fsRealm" \
  /opt/jboss/wildfly/wildfly-demo/fsRealm

# Remove setup container
buildah unmount $DEMOBD_SETUP
buildah rm $DEMOBD_SETUP


# Setup Python demo
buildah run $DEMOBD -- mkdir wildfly/python-demo
buildah copy $DEMOBD commands.sh main.py pyproject.toml poetry.lock /opt/jboss/wildfly/python-demo
buildah run --workingdir /opt/jboss/wildfly/python-demo $DEMOBD -- /opt/jboss/.local/bin/poetry install

# Configure image
buildah config --author 'Cameron Rodriguez <dev@camrod.me>' \
  -a 'org.opencontainers.image.title=wildfly-2023-intern-demo' \
  -a 'org.opencontainers.image.description=Demo for cryptographic signatures used in 2023 PEY presentation for WildFly Elytron' \
  -a 'org.opencontainers.image.version=1.0.0' \
  -a 'org.opencontainers.image.source=https://github.com/cam-rod/wildfly-2023-intern-demo' \
  -a 'org.opencontainers.image.licenses=Apache-2.0' \
  $DEMOBD
buildah config --workingdir /opt/jboss/wildfly/wildfly-demo --entrypoint '/bin/bash' $DEMOBD


# Commit image
buildah commit $DEMOBD ghcr.io/cam-rod/wildfly-2023-intern-demo:latest
buildah rm $DEMOBD
## Setup ##
# Clone the image
podman pull ghcr.io/cam-rod/wildfly-2023-intern-demo:latest

# OR build the container image for the demo (10-15 minutes)
buildah unshare ./demo-container.sh

## WildFly Demo ##
# Start the server
podman run --rm -it ghcr.io/cam-rod/wildfly-2023-intern-demo:latest
/opt/jboss/wildfly/bin/standalone.sh >/dev/null 2>&1 &
/opt/jboss/wildfly/bin/jboss-cli.sh -c --file=/opt/jboss/wildfly/wildfly-demo/configure-wildfly.cli

# CLI - view the identity before signing (use 'q' key to exit)
/opt/jboss/wildfly/bin/jboss-cli.sh -c
/subsystem=elytron/filesystem-realm=fsRealm:read-identity(identity=alice)
exit

# View unsigned file (use 'q' key to exit)
less /opt/jboss/wildfly/wildfly-demo/fsRealm/a/l/alice-MFWGSY3F.xml

# Elytron Tool - sign the identity
java -jar /opt/jboss/wildfly/wildfly-demo/wildfly-elytron-tool-shaded-2.1.1.CR1-SNAPSHOT.jar filesystem-realm-integrity \
    -i /opt/jboss/wildfly/wildfly-demo/fsRealm \
    -o /opt/jboss/wildfly/wildfly-demo \
    -r fsRealmSigned \
    -k /opt/jboss/wildfly/wildfly-demo/fsKeyStore.pfx \
    -p Guk]i%Aua4-wB

# Load new realm to server
/opt/jboss/wildfly/bin/jboss-cli.sh -c --file=/opt/jboss/wildfly/wildfly-demo/fsRealmSigned.cli

# Show signed file (use 'q' key to exit)
less /opt/jboss/wildfly/wildfly-demo/fsRealmSigned/a/l/alice-MFWGSY3F.xml

# CLI - view the identity after signing (use 'q' key to exit)
/opt/jboss/wildfly/bin/jboss-cli.sh -c
/subsystem=elytron/filesystem-realm=fsRealmSigned:verify-integrity()
/subsystem=elytron/filesystem-realm=fsRealmSigned:read-identity(identity=alice)
exit


## Python demo ##
# Run demo
cd ../python-demo
~/.local/bin/poetry run python main.py

## Shutdown ##
# Stop the server and the container
kill %1
exit

# Optional - remove the container image
podman rmi ghcr.io/cam-rod/wildfly-2023-intern-demo:latest
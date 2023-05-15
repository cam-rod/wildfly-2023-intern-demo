## WildFly Demo ##
/opt/jboss/wildfly/bin/jboss-cli.sh -c

# Start the server
/opt/jboss/wildfly/bin/standalone.sh >/dev/null 2>&1 &
/opt/jboss/wildfly/bin/jboss-cli.sh -c --file=/opt/jboss/wildfly/wildfly-demo/configure-wildfly.cli

# Before CLI
/subsystem=elytron/filesystem-realm=fsRealm:read-identity(identity=alice)

# Elytron Tool
java -jar /opt/jboss/wildfly/wildfly-demo/wildfly-elytron-tool-shaded-2.1.1.CR1-SNAPSHOT.jar filesystem-realm-integrity \
    -i /opt/jboss/wildfly/wildfly-demo/fsRealm \
    -o /opt/jboss/wildfly/wildfly-demo \
    -r fsRealmSigned \
    -k /opt/jboss/wildfly/wildfly-demo/fsKeyStore.pfx \
    -p Guk]i%Aua4-wB
/opt/jboss/wildfly/bin/jboss-cli.sh -c --file=/opt/jboss/wildfly/wildfly-demo/fsRealmSigned.cli

# After CLI
/subsystem=elytron/filesystem-realm=fsRealmSigned:verify-integrity()
/subsystem=elytron/filesystem-realm=fsRealmSigned:read-identity(identity=alice)



## Python demo ##

cd ../python-demo

# Run demo
~/.local/bin/poetry run python main.py
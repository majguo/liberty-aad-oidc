FROM open-liberty

# Use this if WebSphere Liberty is desired.
# FROM websphere-liberty

# Tell Liberty not to generate a default keystore.
ENV KEYSTORE_REQUIRED "false"

# Define build variables which will be passed in during image building time.
ARG keyStoreName
ARG keyStorePassword

# Copy user supplied keystore.
COPY --chown=1001:0 ${keyStoreName} /config/resources/security/

# Import the custom keystore into Java CA certificates to 
# enable REST invocations within the application over SSL.
USER root
RUN  $JAVA_HOME/bin/keytool -importkeystore -noprompt \
    -srckeystore /config/resources/security/${keyStoreName} \
    -srcstorepass ${keyStorePassword} \
    -destkeystore $JAVA_HOME/lib/security/cacerts \
    -deststorepass changeit
USER 1001

# Copy deployment artifacts.
COPY --chown=1001:0 postgresql-42.2.4.jar /opt/ibm/wlp/usr/shared/resources/
COPY --chown=1001:0 server.xml /config/
COPY --chown=1001:0 javaee-cafe/target/javaee-cafe.war /config/apps/
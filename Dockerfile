FROM websphere-liberty

# tell WebSphere Liberty not to generate a default keystore
ENV KEYSTORE_REQUIRED "false"

# define build variables which will be passed in during image building time
# also assign defaultKeyStoreName to env variable which will be used during container runtime 
ARG defaultKeyStoreName
ENV DEFAULT_KEYSTORE_NAME=${defaultKeyStoreName}
ARG defaultKeyStorePass
ARG javaTrustStorePass

# copy user prepared default keystore
COPY --chown=1001:0 ${defaultKeyStoreName} /config/resources/security/

# import the default keystore into JAVA cacerts to 
# enable http requests within application server via SSL
USER root
RUN  $JAVA_HOME/bin/keytool -importkeystore -noprompt \
    -srckeystore /config/resources/security/${defaultKeyStoreName} \
    -srcstorepass ${defaultKeyStorePass} \
    -destkeystore $JAVA_HOME/lib/security/cacerts \
    -deststorepass ${javaTrustStorePass}
USER 1001

# copy other artifacts
COPY --chown=1001:0 postgresql-42.2.4.jar /opt/ibm/wlp/usr/shared/resources/
COPY --chown=1001:0 server.xml /config/
COPY --chown=1001:0 javaee-cafe/target/javaee-cafe.war /config/apps/
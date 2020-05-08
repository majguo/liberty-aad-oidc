FROM websphere-liberty

# tell WebSphere Liberty not to generate a default keystore
ENV KEYSTORE_REQUIRED "false"

# define build variables which will be passed in during image building time
# also assign them to environment variables which will be used during container runtime 
ARG defaultKeyStoreName=key.jks
ENV DEFAULT_KEYSTORE_NAME=${defaultKeyStoreName}
ARG defaultKeyStorePass
ENV DEFAULT_KEYSTORE_PASS=${defaultKeyStorePass}
ARG javaTrustStorePass
ENV JAVA_TRUSTSTORE_PASS=${javaTrustStorePass}

# generate a default keystore with a self-signed certificate used for SSL & JWT
RUN mkdir -p /config/resources/security && \
    $JAVA_HOME/bin/keytool -genkeypair -noprompt -alias default \
    -keyalg RSA -keysize 2048 -validity 365 -storetype jks \
    -dname "CN=localhost, OU=liberty-aad-oidc, O=ibm, L=Unknown, S=Unknown, C=US" \
    -keystore /config/resources/security/${defaultKeyStoreName} \
    -storepass ${defaultKeyStorePass} \
    -keypass ${defaultKeyStorePass} && \
    chown 1001:0 /config/resources/security/${defaultKeyStoreName}

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
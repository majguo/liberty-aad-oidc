FROM websphere-liberty

ENV KEYSTORE_REQUIRED "false"

COPY --chown=1001:0 key.jks /config/resources/security/
COPY --chown=1001:0 postgresql-42.2.4.jar /opt/ibm/wlp/usr/shared/resources/
COPY --chown=1001:0 server.xml /config/
COPY --chown=1001:0 target/javaee-cafe.war /config/apps/
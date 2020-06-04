FROM openliberty/open-liberty:kernel-java8-openj9-ubi
#FROM openliberty/open-liberty:kernel-java11-openj9-ubi

COPY --chown=1001:0 postgresql-42.2.4.jar /opt/ibm/wlp/usr/shared/resources/
COPY --chown=1001:0 javaee-cafe/src/main/liberty/config/server.xml /config/
COPY --chown=1001:0 javaee-cafe/target/javaee-cafe.war /config/apps/

RUN configure.sh

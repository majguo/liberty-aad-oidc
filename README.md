# Securing Liberty Applications with Azure Active Directory via OpenID Connect

## Introduction
This project demonstrates how to secure your Java EE application on Open Liberty/WebSphere Liberty using Azure Active Directory and OpenID Connect. The following is how you run the demo.

## Prerequisites
* Install Java SE 8 (we used [AdoptOpenJDK OpenJDK 8 LTS/OpenJ9](https://adoptopenjdk.net)).
* Install [Maven](https://maven.apache.org/download.cgi) 3.5.0 or higher.
* Install [Docker](https://docs.docker.com/get-docker/) for your OS.
* You will need an Azure subscription. If you don't have one, you can get one for free for one year [here](https://azure.microsoft.com/en-us/free).
* Download this repository somewhere in your file system (easiest way might be to download as a zip and extract).

## Setup Azure Active Directory
* You will first need to [get an Azure Active Directory tenant](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-create-new-tenant). It is very likely your Azure account already has a tenant. Please note down your tenant/directory ID.
* Although this isn't absolutely necessary, you can [create a few Azure Active Directory users](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/add-users-azure-active-directory). You can use these accounts or your own to test the application. Do note down email addresses and passwords for login.
* You will need to create an admin group to enable JWT RBAC (role-based-access-control) functionality. Follow [create a basic group and add members using Azure Active Directory](https://docs.microsoft.com/azure/active-directory/fundamentals/active-directory-groups-create-azure-portal) to create a group with type as **Security** and add one or more members. Note down group ID.
* You will need to [create a new application registration](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app) in Azure Active Directory. Please specify the redirect URI to be: https://localhost:9443/oidcclient/redirect/liberty-aad-oidc-javaeecafe. Please note down the application (client) ID.
* You will need to create a new client secret. In the newly created application registration, find 'Certificates & secrets'. Select 'New client secret'. Provide a description and hit 'Add'. Note down the generated client secret value.
* You will need to add **groups claim** into ID token. In the newly created application registration, find 'Token configuration'. Click 'Add groups claim'. Select 'Security groups' as group types to include in ID token. Expand 'ID' and select 'Group ID' in 'Customize token properties by type' section.

## Start the Database instance
The first step to getting the application running is getting the database up. Please follow the instructions below to get the database running.
* Ensure that all running Docker containers are shut down. You may want to do this by restarting Docker. The demo depends on containers started in a specific order.
* Make sure Docker is running. Open a console.
* Enter the following command and wait for the database to come up fully.
  ```
  docker run -it --rm --name javaee-cafe-db -v pgdata:/var/lib/postgresql/data -p 5432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust postgres
  ```
* The database is now ready (to stop it, simply press Control-C after the Java EE application is shutdown).

Now we can get the application up and running.  The following steps show two different ways to do so: Docker and maven.

### Start the Application with Docker

* Open a console. Navigate to where you have this repository downloaded on your local machine.
* Run `mvn clean package --file javaee-cafe/pom.xml`. This will generate a war deployment under `./javaee-cafe/target`.
* Build a Docker image tagged `javaee-cafe` by running one of the following commands.
  ```
  # build from open liberty base image
  docker build -t javaee-cafe --pull .
  # build from websphere liberty base image
  docker build -t javaee-cafe --pull --file=Dockerfile-wlp .
  ```
* To run the newly built image, execute the following command. These are the parameters required:
  * `POSTGRESQL_SERVER_NAME`: For Mac and Windows users, 'host.docker.internal' may be used. For other operating systems, use the IP 172.17.0.2 (note, this depends on the fact that the database is the first container to start).
  * `POSTGRESQL_USER`: Use `postgres`.
  * `POSTGRESQL_PASSWORD`: Keep it empty.
  * `CLIENT_ID`: The application/client ID you noted down.
  * `CLIENT_SECRET`: The client secret value you noted down.
  * `TENANT_ID`: The tenant/directory ID you noted down.
  * `ADMIN_GROUP_ID`: The admin group ID you noted down.
  ```
  docker run -it --rm -p 9080:9080 -p 9443:9443 -e POSTGRESQL_SERVER_NAME=<...> -e POSTGRESQL_USER=postgres -e POSTGRESQL_PASSWORD= -e CLIENT_ID=<...> -e CLIENT_SECRET=<...> -e TENANT_ID=<...> -e ADMIN_GROUP_ID=<...> javaee-cafe
  ```
* Wait for Liberty to start and the application to deploy successfully (to stop the application and Liberty, simply press Control-C).

### Start the Application with Maven
You can also get the application up and running using the `mvn` command.
* Open a console. Navigate to where you have this repository downloaded on your local machine.
* Run `mvn clean package --file javaee-cafe/pom.xml`.
* Execute the following command with required parameters (Windows PowerShell uses a slight variant):
  * `postgresql.server.name`: Use `localhost`.
  * `postgresql.user`: Use `postgres`.
  * `postgresql.password`: Keep it empty.
  * `client.id`: The application/client ID you noted down.
  * `client.secret`: The client secret value you noted down.
  * `tenant.id`: The tenant/directory ID you noted down.
  * `admin.group.id`: The admin group ID you noted down.
  ```
  mvn -Dpostgresql.server.name=localhost -Dpostgresql.user=postgres -Dpostgresql.password= -Dclient.id=<...> -Dclient.secret=<...> -Dtenant.id=<...> -Dadmin.group.id=<...> liberty:run --file javaee-cafe/pom.xml
  ```
* Note: if you want to run from Windows PowerShell, please use the following command:
  ```
  mvn --file javaee-cafe/pom.xml liberty:run "-Dpostgresql.server.name=localhost" "-Dpostgresql.user=postgres" "-Dpostgresql.password=" "-Dclient.id=<...>" "-Dclient.secret=<...>" "-Dtenant.id=<...>" "-Dadmin.group.id=<...>"
  ```
* Wait for Liberty to start and the application to deploy successfully (to stop the application and Liberty, simply press Control-C).

### Visit the Application
* Once the application starts, you can visit the JSF client at
  * [https://localhost:9443/javaee-cafe](https://localhost:9443/javaee-cafe)
  * [http://localhost:9080/javaee-cafe](http://localhost:9080/javaee-cafe)
* Logging in with user who doesn't belong to the admin group, you're not allowed to remove coffee as **Delete** coffee button is disabled.
* Logging in with user who belong to the admin group, you're allowed to remove coffee as **Delete** coffee button is enabled.

## References
* [Configuring an OpenID Connect Client in Liberty](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_config_oidc_rp.html)
* [Enabling SSL communication in Liberty](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_sec_ssl.html)
* [Configuring authorization for applications in Liberty](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_sec_rolebased.html)
* [SSL configuration values in Open Liberty](https://openliberty.io/docs/ref/config/#ssl.html)
* [Building and consuming JSON Web Token (JWT) tokens in Liberty](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_sec_config_jwt.html)
* [Configuring the MicroProfile JSON Web Token](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_sec_json.html)

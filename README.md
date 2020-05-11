# Secure Liberty Application with Azure AD OpenID Connect

## Introduction
This project provides a demo on how to secure your application which is running on WebSphere Liberty server by using Azure Active Directory OpenID Connect.</br>
The`javaee-cafe` demo shows using Java EE thin wars with Docker repositories, layering, and caching. It uses Liberty server under Docker using the `websphere-liberty` image that is available from the online Docker Hub repository. The following is how you run the demo.

## Prerequisites
* Register an [Azure subscription](https://azure.microsoft.com/en-us/)
* Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
* Install [Oracle JDK 8](https://www.oracle.com/java/technologies/javase-jdk8-downloads.html)
* Download [Maven](https://maven.apache.org/download.cgi)

## Setup Azure Active Directory
* [Create a new Azure AD tenant](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-create-new-tenant#create-a-new-azure-ad-tenant) if not existing, log down Directory (tenant) ID
* [Create Azure AD users](https://docs.microsoft.com/en-us/azure/openshift/howto-aad-app-configuration#create-a-new-azure-active-directory-user) if not existing, log down their emial addresses & passwords
* [Optional] [Create Azure AD security groups](https://docs.microsoft.com/en-us/azure/openshift/howto-aad-app-configuration#create-an-azure-ad-security-group) "admin" & "users" if not existing, add created users as group members, log down group IDs 
* [Create an Azure AD app registration for authentication](https://docs.microsoft.com/en-us/azure/openshift/configure-azure-ad-ui#create-an-azure-active-directory-application-for-authentication) if not existing, log down Application (client) ID & client secret. Fill in <b>Redirect URI</b> with the redirect URI of applicatoins to be deployed later:
  * https://<span></span>localhost:9643/oidcclient/redirect/liberty-aad-oidc-javaeecafe
* [Configure optional claims](https://docs.microsoft.com/en-us/azure/openshift/configure-azure-ad-ui#configure-optional-claims)
  * Add optional claim > Select ID then check the email and upn claims
  * [Optional] Add groups claim > Select Security groups then select Group ID for each token type

## Build & run application
### Start the Database instance
The first step to getting the application running is getting the database up. Please follow the instructions below to get the database running.
#### Start with Docker
This is the easiest way to start PostgreSQL server with your local Docker:
* Ensure that all running Docker containers are shut down. You may want to do this by restarting Docker. The demo depends on containers started in the exact order as below (this will be less of a problem when we start using Kubernetes).
* Make sure Docker is running. Open a console.
* Enter the following command and wait for the database to come up fully.
  ```
  docker run -it --rm --name javaee-cafe-db -v pgdata:/var/lib/postgresql/data -p 5432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust postgres
  ```
* The database is now ready (to stop it, simply press Control-C after the Java EE application is shutdown).
  * Note, we are depending on the fact that the database is the first container to start and has the IP `172.17.0.2`. For Mac and Windows users the serverName could be changed to `host.docker.internal`. That will make the container start order less significant.
  * The PostgreSQL server running as Docker container will generate a user named `postgres` with empty password. You will use them to connect to PostgreSQL server when starting applicatoin later.

#### Start with Azure Database for PostgreSQL
Instead of running PostgreSQL server as local Docker container, you can also deploy and run PostgreSQL server on Azure:
* Go to [Azure Database for PostgreSQL ](https://ms.portal.azure.com/#create/Microsoft.PostgreSQLServer)
* Select "Single server" > Create
* Specify necessary inputs in "Basic" tab, log down value of `Password` specified for Administrator account
* Leave others as defaults > Next: Tags > Next: Review + Create > Create
* Wait a few minutes until the deployment completes > Go to new instance of Azure Database for PostgreSQL server
* Switch to Settings > Connection security > Create a firewall rule by adding "0.0.0.0 - 255.255.255.255"
  * Note: use this rule only temporarily and only on test clusters that do not contain sensitive data. You can replace it with a new rule that only allowing IP address of your local applicatoin container later for security consideration
* Switch to Settings > Connection strings > Copy connection strings for Web App
* Log down value of `Data Source` & `User Id`, which will be used to connect to PostgreSQL server when starting applicatoin later 

### Start the Application with Docker
The next step is to get the application up and running. Follow the steps below to do so.
* Clone [this repo](https://github.com/majguo/liberty-aad-oidc) if not done before
* Change directory to `<path-to-repo>/javaee-cafe`
* Run `mvn clean package`. The generated war file is under `./target`
* Change directory back to `<path-to-repo>`
* You should explore the Dockerfile in this directory used to build the Docker image. It simply starts from the `websphere-liberty` image, copy the pre-generated default keystore & import it to JAVA cacerts, adds the `javaee-cafe.war` from `./target` into the `apps` directory, copies the PostgreSqQL driver `postgresql-42.2.4.jar` into the `shared/resources` directory and replaces the defaultServer configuration file `server.xml`.
* Notice how the data source properties in the `server.xml` file looks like:
  ```
  databaseName="postgres"
  portNumber="5432"
  ssl="${POSTGRESQL_SSL_ENABLED}"         # configured during container runtime
  serverName="${POSTGRESQL_SERVER_NAME}"  # configured during container runtime 
  user="${POSTGRESQL_USER}"               # configured during container runtime
  password="${POSTGRESQL_PASSWORD}"       # configured during container runtime
  ```
* Open a console. Build a Docker image tagged `javaee-cafe` by running the following command after replacing `<...>` with valid values:
  ```
  docker build -t javaee-cafe --build-arg defaultKeyStoreName=<...> --build-arg defaultKeyStorePass=<...> --build-arg javaTrustStorePass=<...> .
  ```
  * `defaultKeyStoreName`: the name of default keystore, which is prepared by user and should be located in `<path-to-repo>` directory. <b>The password for keystore and key requires to be same</b>, the type of keystore should be <b>JKS</b>. For demo purpose, run the following `keytool` command to generate a default keystore `key.jks` with a self-signed certificate:
    * `keytool -genkeypair -keyalg RSA -storetype jks -keystore key.jks`
  * `defaultKeyStorePass`: password for default keystore
  * `javaTrustStorePass`: password for JAVA cacerts which is used as default trust store, located in `${JAVA_HOME}/lib/security/cacerts`, the default password is `changeit`
* To run the newly built image, replace `<...>` with the valid values and execute the command:
  ```
  docker run -it --rm -p 9080:9080 -p 9643:9643 -e POSTGRESQL_SSL_ENABLED=<...> -e POSTGRESQL_SERVER_NAME=<...> -e POSTGRESQL_USER=<...> -e POSTGRESQL_PASSWORD=<...> -e CLIENT_ID=<...> -e CLIENT_SECRET=<...> -e TENANT_ID=<...> javaee-cafe
  ```
  * `POSTGRESQL_SSL_ENABLED`: `false` if using PostgreSQL server in local Docker container, `true` if using Azure Database for PostgreSQL
  * `POSTGRESQL_SERVER_NAME`: `172.17.0.2` if using PostgreSQL server in local Docker container, value of `Data Source` logged down before if using Azure Database for PostgreSQL
  * `POSTGRESQL_USER`: `postgres` if using PostgreSQL server in local Docker container, value of `User Id` logged down before if using Azure Database for PostgreSQL
  * `POSTGRESQL_PASSWORD`: keep it empty if using PostgreSQL server in local Docker container, value of `Password` specified for Administrator account logged down before if using Azure Database for PostgreSQL
  * `DEFAULT_KEYSTORE_PASS`: provide same value for `defaultKeyStorePass`, which was mentioned above
  * `JAVA_TRUSTSTORE_PASS`: provide same value for `javaTrustStorePass`, which was mentioned above
  * `CLIENT_ID`: the one you logged down before
  * `CLIENT_SECRET`: the one you logged down before
  * `TENANT_ID`: the one you logged down before
* Wait for WebSphere Liberty to start and the application to deploy sucessfully (to stop the application and Liberty, simply press Control-C).
* Once the application starts, you can visit the JSF client at
  * [https://localhost:9643/javaee-cafe](https://localhost:9643/javaee-cafe)
  * [http://localhost:9080/javaee-cafe](http://localhost:9080/javaee-cafe)

## References
* [Securing Open Liberty apps and microservices with MicroProfile JWT and Social Media login](https://openliberty.io/blog/2019/08/29/securing-microservices-social-login-jwt.html)
* [Configuring an OpenID Connect Client in Liberty](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_config_oidc_rp.html)

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
### Start the Database with Docker
The first step to getting the application running is getting the database up. Please follow the instructions below to get the database running.
* Ensure that all running Docker containers are shut down. You may want to do this by restarting Docker. The demo depends on containers started in the exact order as below (this will be less of a problem when we start using Kubernetes).
* Make sure Docker is running. Open a console.
* Enter the following command and wait for the database to come up fully.
```
docker run -it --rm --name javaee-cafe-db -v pgdata:/var/lib/postgresql/data -p 5432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust postgres
```
* The database is now ready (to stop it, simply press Control-C after the Java EE application is shutdown).

### Start the Application with Docker
The next step is to get the application up and running. Follow the steps below to do so.
* Clone [this repo](https://github.com/majguo/liberty-aad-oidc) if not done before
* Change directory to `<path-to-repo>/javaee-cafe`
* Run `mvn clean package`. The generated war file is under `./target`
* Change directory back to `<path-to-repo>`
* You should explore the Dockerfile in this directory used to build the Docker image. It simply starts from the `websphere-liberty` image, generate default keystore & import it to JAVA cacerts, adds the `javaee-cafe.war` from `./target` into the `apps` directory, copies the PostgreSqQL driver `postgresql-42.2.4.jar` into the `shared/resources` directory and replaces the defaultServer configuration file `server.xml`.
* Notice how the data source properties in the `server.xml` file looks like:
  ```
  serverName="172.17.0.2"
  portNumber="5432"
  databaseName="postgres"
  user="postgres"
  password=""
  ```
* Note, we are depending on the fact that the database is the first container to start and has the IP 172.17.0.2. For Mac and Windows users the serverName could be changed to `host.docker.internal`. That will make the container start order less significant.
* Open a console. Build a Docker image tagged `javaee-cafe` by running the following command after replacing `<...>` with valid values:
  ```
  docker build -t javaee-cafe --build-arg defaultKeyStorePass=<...> --build-arg javaTrustStorePass=<...> .
  ```
  * `defaultKeyStorePass`: specify password for default keystore
  * `javaTrustStorePass`: password for JAVA cacerts which is used as default trust store, located in `${JAVA_HOME}/lib/security/cacerts`, the default password is `changeit`
* To run the newly built image, replace `<...>` with the valid values and execute the command:
  ```
  docker run -it --rm -p 9643:9643 -e CLIENT_ID=<...> -e CLIENT_SECRET=<...> -e TENANT_ID=<...> javaee-cafe
  ```
  * `CLIENT_ID`: the one you logged down before
  * `CLIENT_SECRET`: the one you logged down before
  * `TENANT_ID`: the one you logged down before
* Wait for WebSphere Liberty to start and the application to deploy sucessfully (to stop the application and Liberty, simply press Control-C).
* Once the application starts, you can visit the JSF client at [https://localhost:9643/javaee-cafe](https://localhost:9643/javaee-cafe) or [http://localhost:9080/javaee-cafe](http://localhost:9080/javaee-cafe).

## References
* [Securing Open Liberty apps and microservices with MicroProfile JWT and Social Media login](https://openliberty.io/blog/2019/08/29/securing-microservices-social-login-jwt.html)
* [Configuring an OpenID Connect Client in Liberty](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_config_oidc_rp.html)

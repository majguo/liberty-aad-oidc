# Introduction
This demo shows using Java EE thin wars with Docker repositories, layering, and caching. It uses Liberty server under Docker using the `websphere-liberty` image that is available from the online Docker Hub repository. The following is how you run the demo.

## Start the Database with Docker
The first step to getting the application running is getting the database up. Please follow the instructions below to get the database running.

* Ensure that all running Docker containers are shut down. You may want to do this by restarting Docker. The demo depends on containers started in the exact order as below (this will be less of a problem when we start using Kubernetes).
* Make sure Docker is running. Open a console.
* Enter the following command and wait for the database to come up fully.
```
docker run -it --rm --name javaee-cafe-db -v pgdata:/var/lib/postgresql/data -p 5432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust postgres
```
* The database is now ready (to stop it, simply press Control-C after the Java EE application is shutdown).

## Start the Application with Docker
The next step is to get the application up and running. Follow the steps below to do so.

* Clone [this repo](https://github.com/majguo/liberty-aad-oidc) if not done before
* Change directory to `<path-to-repo>/javaee-cafe`
* Replace the placeholders for the following properties in `server.xml` with valid values:
  * `${default.keystore.pass}`: password for default keystore, make sure it imported root certificate of host "login.microsoftonline.com" for SSL traffic. You can use "key.jks" included in the repo for testing purpose, "secret" as password
  * `${client.id}`: the one you logged down in previous step
  * `${client.secret}`: the one you logged down in previous step
  * `${tenant.id}`: the one you logged down in previous step
* Run `mvn clean package`. The generated war file is under `./target`
* You should explore the Dockerfile in this directory used to build the Docker image. It simply starts from the `websphere-liberty` image, adds the `javaee-cafe.war` from `./target` into the `dropins` directory, copies the PostgreSqQL driver `postgresql-42.2.4.jar` into the `shared/resources` directory and replaces the defaultServer configuration file `server.xml`.
* Notice how the data source properties in the `server.xml` file looks like:

<pre>serverName="172.17.0.2"
portNumber="5432"
databaseName="postgres"
user="postgres"
password=""</pre>

* Note, we are depending on the fact that the database is the first container to start and has the IP 172.17.0.2. For Mac and Windows users the serverName could be changed to `host.docker.internal`. That will make the container start order less significant.
* Open a console. Build a Docker image tagged `javaee-cafe` by running the following command:

	```
	docker build -t javaee-cafe .
	```
* To run the newly built image, use the command:

	```
	docker run -it --rm -p 9643:9643 javaee-cafe
	```
* Wait for WebSphere Liberty to start and the application to deploy sucessfully (to stop the application and Liberty, simply press Control-C).
* Once the application starts, you can visit the JSF client at [https://localhost:9643/javaee-cafe/index.xhtml](https://localhost:9643/javaee-cafe/index.xhtml).

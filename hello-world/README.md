# Introduction
This demo shows using Java EE thin wars with Docker repositories, layering, and caching. It uses Liberty server under Docker using the `websphere-liberty` image that is available from the online Docker Hub repository. The following is how you run the demo.

## Start the Application with Docker
Follow the steps below to get the application up and running.

* Clone [this repo](https://github.com/majguo/liberty-aad-oidc) if not done before
* Change directory to `<path-to-repo>/hello-world`
* Replace the placeholders for the following properties in `server.xml` with valid values:
  * `${default.keystore.pass}`: specify password for default keystore
  * `${java.truststore.pass}`: password for java default trust store, located in `${JAVA_HOME}/lib/security/cacerts`, the default is `changeit`
  * `${client.id}`: the one you logged down in previous step
  * `${client.secret}`: the one you logged down in previous step
  * `${tenant.id}`: the one you logged down in previous step
* Run `mvn clean package`. The generated war file is under `./target`
* You should explore the Dockerfile in this directory used to build the Docker image. It simply starts from the `websphere-liberty` image, adds the `hello-wrold.war` from `./target` into the `apps` directory, and replaces the defaultServer configuration file `server.xml`.
* Open a console. Build a Docker image tagged `hello-world` by running the following command:
	```
	docker build -t hello-world .
	```
* To run the newly built image, use the command:
	```
	docker run -it --rm -p 9543:9543 hello-world
	```
* Wait for WebSphere Liberty to start and the application to deploy sucessfully (to stop the application and Liberty, simply press Control-C).
* Once the application starts, you can visit the `HelloWorldServlet` at [https://localhost:9543/hello-world](https://localhost:9543/hello-world).

# Introduction
This demo shows using Java EE thin wars with Docker repositories, layering, and caching. It uses Liberty server under Docker using the `websphere-liberty` image that is available from the online Docker Hub repository. The following is how you run the demo.

## Start the Application with Docker
Follow the steps below to get the application up and running.

* Clone [this repo](https://github.com/majguo/liberty-aad-oidc) if not done before
* Change directory to `<path-to-repo>/hello-world`
* Run `mvn clean package`. The generated war file is under `./target`
* You should explore the Dockerfile in this directory used to build the Docker image. It simply starts from the `websphere-liberty` image, adds the `hello-wrold.war` from `./target` into the `apps` directory, and replaces the defaultServer configuration file `server.xml`.
* Open a console. Build a Docker image tagged `hello-world` by running the following command:
	```
	docker build -t hello-world .
	```
* To run the newly built image, replace `<...>` with the valid values and execute the command:
	```
	docker run -it --rm -p 9543:9543 -e DEFAULT_KEYSTORE_PASS=<...> -e JAVA_TRUSTSTORE_PASS=<...> -e CLIENT_ID=<...> -e CLIENT_SECRET=<...> -e TENANT_ID=<...> hello-world
	```
  * `DEFAULT_KEYSTORE_PASS`: specify password for default keystore
  * `JAVA_TRUSTSTORE_PASS`: password for java default trust store, located in `${JAVA_HOME}/lib/security/cacerts`, the default is `changeit`
  * `CLIENT_ID`: the one you logged down in previous step
  * `CLIENT_SECRET`: the one you logged down in previous step
  * `TENANT_ID`: the one you logged down in previous step
* Wait for WebSphere Liberty to start and the application to deploy sucessfully (to stop the application and Liberty, simply press Control-C).
* Once the application starts, you can visit the `HelloWorldServlet` at [https://localhost:9543/hello-world](https://localhost:9543/hello-world).

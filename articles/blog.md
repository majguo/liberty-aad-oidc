# Securing Open Liberty Application with Azure Active Directory via OpenID Connect

Long gone are the days when you had to create your own user account management, authentication, and authorization for your web delivered software.  Instead, contemporary applications leverage these functions (Identity and Access Management, IAM for short) from an external provider.  Java EE has powerful standard abstractions for these functions and IBM Open Liberty, being a full Java EE runtime, has great options for externally provided IAM.  Open Liberty also supports IAM mainstays such as [Social Media Login](https://openliberty.io/docs/ref/feature/#socialLogin-1.0.html), [SAML Web Single Sign-on](https://openliberty.io/docs/ref/feature/#samlWeb-2.0.html) and [OpenID Connect Client](https://openliberty.io/docs/ref/feature/#openidConnectClient-1.0.html). In Bruce Tiffany's blog post "[Securing Open Liberty apps and micro-services with MicroProfile JWT and Social Media login](https://openliberty.io/blog/2019/08/29/securing-microservices-social-login-jwt.html)", you have a solid example on how to use the Open Liberty Social Media Login feature to authenticate users using their existing social media credentials. In this blog post, let's take a look at another example about how to use Open Liberty OpenID Connect Client feature to secure apps with [Azure Active Directory](https://docs.microsoft.com/azure/active-directory/develop/v2-protocols-oidc) using the existing Java EE IAM APIs.

<!-- IMPORTANT: find a way to capture this activation action to count against our OKRs.  DO NOT PUBLISH without this. -->
The sample code used in this blog is hosted on this [GitHub repo](https://github.com/Azure-Samples/liberty-aad-oidc), feel free to check it out and follow its user guide to run the demo application before or after reading this blog.

## Set up Azure Active Directory

Azure Active Directory (Azure AD) implements OpenID Connect (OIDC), an authentication protocol built on OAuth 2.0, which lets you securely sign in a user from Azure AD to an application.  Before going into the sample code, you must first set up an Azure AD tenant and create an application registration with redirect URL and client secret. The tenant id, application (client) id & client secret are used by the Open Liberty OIDC Client to negotiate with Azure AD to complete an [OAuth 2.0 authorization code flow](https://docs.microsoft.com/azure/active-directory/develop/v2-oauth2-auth-code-flow).

Learn how to set up Azure AD from these articles:

- [Create a new tenant](https://docs.microsoft.com/azure/active-directory/develop/quickstart-create-new-tenant)
- [Register an application](https://docs.microsoft.com/azure/active-directory/develop/quickstart-register-app)
- [Add a new client secret](https://docs.microsoft.com/azure/active-directory/develop/howto-create-service-principal-portal#create-a-new-application-secret)

## Configure OpenID Connect Client

The following sample code shows how a Jakarta EE application running on an Open Liberty server is configured with the OIDC Client (openidConnectClient-1.0) **feature** to authenticate a user from an OpenID Connect Provider, with Azure AD as the designated security provider.

The relevant server configuration in `server.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<server description="defaultServer">
  <!-- Enable features -->
  <featureManager>
    <feature>openidConnectClient-1.0</feature>
    <feature>transportSecurity-1.0</feature>
    <feature>appSecurity-3.0</feature>
  </featureManager>

  <!-- trust JDK’s default truststore -->
  <ssl id="defaultSSLConfig"  trustDefaultCerts="true" />

  <!-- add your tenant id, client ID and secret from Azure AD -->
  <openidConnectClient
    id="liberty-aad-oidc-javaeecafe" clientId="${client.id}"
    clientSecret="${client.secret}"
    discoveryEndpointUrl="https://login.microsoftonline.com/${tenant.id}/v2.0/.well-known/openid-configuration"
    signatureAlgorithm="RS256"
    userIdentityToCreateSubject="preferred_username"
    inboundPropagation="supported" />

  <!-- grant role "users" to all authenticated users -->
  <webApplication id="javaee-cafe"
    location="${server.config.dir}/apps/javaee-cafe.war">
    <application-bnd>
      <security-role name="users">
        <special-subject type="ALL_AUTHENTICATED_USERS" />
      </security-role>
    </application-bnd>
  </webApplication>

  <!-- define http endpoints -->
  <httpEndpoint id="defaultHttpEndpoint" host="*"
    httpPort="9080" httpsPort="9443" />
</server>
```

Using Azure AD allows your application to use a certificate with a root CA signed by Microsoft's public certificate.  This certificate is added to the default `cacerts` of the JVM.  Trusting JVM default `cacerts` ensures a successful SSL handshake between OIDC Client and Azure AD.

## Use OpenID Connect to authenticate users

The sample application exposes a [JSF](https://www.oracle.com/java/technologies/javaserverfaces.html) client which defines a Java EE security constraint that only user's with role "users" can access.

The relevant configuration in `web.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app>
    <security-role>
        <role-name>users</role-name>
    </security-role>

    <security-constraint>
        <web-resource-collection>
            <web-resource-name>javaee-cafe</web-resource-name>
            <url-pattern>/*</url-pattern>
        </web-resource-collection>
        <auth-constraint>
            <role-name>users</role-name>
        </auth-constraint>
    </security-constraint>
</web-app>
```

### Workflow

![authorization-code-flow](convergence-scenarios-webapp.svg)
*Picture 1: OpenID Connect sign-in and token acquisition flow, from [Microsoft identity platform and OpenID Connect protocol](https://docs.microsoft.com/azure/active-directory/develop/v2-protocols-oidc#protocol-diagram-access-token-acquisition)*

This is just standard Java EE security.  When an unauthenticated user attempt's to access the JSF client, they are redirected to Microsoft to provide their Azure AD credentials. Upon success, the browser gets redirected back to the client with an authorization code. The client then contacts the Microsoft again with authorization code, client Id & secret to obtain an ID token & access token, and finally create an authenticated user on the client, which then gets access to the JSF client.

To get authenticated user information, use the [CDI standard](http://cdi-spec.org/) `@Named` with the [AtInject](https://jcp.org/en/jsr/detail?id=330) standard `@Inject` annotations to obtain a reference to the `javax.security.enterprise.SecurityContext` and call its method `getCallerPrincipal()`:

```java
@Named
@SessionScoped
public class Cafe implements Serializable {

  @Inject
  private transient SecurityContext securityContext;

  public String getLoggedOnUser() {
    return securityContext.getCallerPrincipal().getName();
  }
}
```

## Secure internal REST calls using JWT RBAC

The `Cafe` bean depends on `CafeResource`, a REST service built with [JAX-RS](https://en.wikipedia.org/wiki/Java_API_for_RESTful_Web_Services), to create, read, update & delete coffees. The `CafeResource` implements RBAC (role based access control) using [MicroProfile JWT](https://github.com/eclipse/microprofile-jwt-auth) to verify the **groups claim** of the token.

```java
@Path("coffees")
public class CafeResource {

    @Inject
    private CafeRepository cafeRepository;

    @Inject
    @ConfigProperty(name = "admin.group.id")
    private String ADMIN_GROUP_ID;

    @Inject
    private JsonWebToken jwtPrincipal;

    @DELETE
    @Path("{id}")
    public void deleteCoffee(@PathParam("id") Long coffeeId) {
        // Only users in the "admin group" are authorized to delete coffee
        if (!this.jwtPrincipal.getGroups().contains(ADMIN_GROUP_ID)) {
            throw new WebApplicationException(Response.Status.FORBIDDEN);
        }

        try {
            this.cafeRepository.removeCoffeeById(coffeeId);
        } catch (IllegalArgumentException ex) {
            logger.log(Level.SEVERE, "Error calling deleteCoffee() for coffeeId {0}: {1}.",
                    new Object[] { coffeeId, ex });
            throw new WebApplicationException(Response.Status.NOT_FOUND);
        }
    }

    @GET
    @Produces({ MediaType.APPLICATION_XML, MediaType.APPLICATION_JSON })
    public List<Coffee> getAllCoffees() {
        return this.cafeRepository.getAllCoffees();
    }

    @POST
    @Consumes({ MediaType.APPLICATION_XML, MediaType.APPLICATION_JSON })
    @Produces({ MediaType.APPLICATION_XML, MediaType.APPLICATION_JSON })
    public Coffee createCoffee(Coffee coffee) {
        try {
            return this.cafeRepository.persistCoffee(coffee);
        } catch (PersistenceException e) {
            logger.log(Level.SEVERE, "Error creating coffee {0}: {1}.", new Object[] { coffee, e });
            throw new WebApplicationException(e, Response.Status.INTERNAL_SERVER_ERROR);
        }
    }
}
```

The `admin.group.id` is injected into the application using [MicroProfile Config](https://github.com/eclipse/microprofile-config) at the application startup using the `[ConfigProperty](https://javadoc.io/doc/org.eclipse.microprofile.config/microprofile-config-api/latest/org/eclipse/microprofile/config/inject/ConfigProperty.html)` annotation. [MicroProfile JWT](https://github.com/eclipse/microprofile-jwt-auth) enables you to `@Inject` the JWT (Json Web Token).  `CafeResource` REST receives the JWT with the `preferred_username` & `groups` claims from [ID token](https://www.ibm.com/support/knowledgecenter/en/SS7K4U_liberty/com.ibm.websphere.javadoc.liberty.doc/com.ibm.websphere.appserver.api.oauth_1.2-javadoc/com/ibm/websphere/security/openidconnect/token/IdToken.html) issued by Azure AD in the OpenID Connect authorization workflow.

Here is the relevant configuration snippet in `server.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<server description="defaultServer">

    <!-- Enable features -->
    <featureManager>
        <feature>jwt-1.0</feature>
        <feature>mpJwt-1.1</feature>
        <feature>mpConfig-1.3</feature>
    </featureManager>

    <!-- JWT builder -->
    <jwtBuilder id="jwtAuthUserBuilder" keyAlias="default" issuer="https://example.com" expiresInSeconds="600" />

    <!-- JWT consumer -->
    <mpJwt id="jwtUserConsumer" keyName="default" issuer="https://example.com" authFilterRef="mpJwtAuthFilter" />

    <!-- JWT auth filter -->
    <authFilter id="mpJwtAuthFilter">
        <requestUrl id="myRequestUrl" urlPattern="/rest" matchType="contains"/>
    </authFilter>
</server>
```

To add a **groups claim** into the ID token, you will need to create a group with type as **Security** and add one or more members. In the application registration created before, find 'Token configuration' > select 'Add groups claim' > select 'Security groups' as group types to include in ID token > expand 'ID' and select 'Group ID' in 'Customize token properties by type' section. Learn more details from these articles:

- [Create a new group and add members](https://docs.microsoft.com/azure/active-directory/fundamentals/active-directory-groups-create-azure-portal)
- [Configuring groups optional claims](https://docs.microsoft.com/azure/active-directory/develop/active-directory-optional-claims#configuring-groups-optional-claims)

## Other references

- [Configuring an OpenID Connect Client in Liberty](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_config_oidc_rp.html)
- [Configuring the MicroProfile JSON Web Token](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_sec_json.html)
- [Secure your application by using OpenID Connect and Azure AD](https://docs.microsoft.com/learn/modules/secure-app-with-oidc-and-azure-ad/)

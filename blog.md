# Securing Open Liberty Application with Azure Active Directory via OpenID Connect

Long gone are the days when you had to create your own user account management, authentication, and authorization for you web delivered software.  Instead, contemporary applications leverage these functions (Identity and Access Management, IAM for short) from an external provider.  Java EE has powerful standard abstractions for these functions and IBM Open Liberty, being a full Java EE runtime, has great options for externally provided IAM.  Open Liberty also supports IAM mainstays such as [Social Media Login](https://openliberty.io/docs/ref/feature/#socialLogin-1.0.html), [SAML Web Single Sign-on](https://openliberty.io/docs/ref/feature/#samlWeb-2.0.html) and [OpenID Connect Client](https://openliberty.io/docs/ref/feature/#openidConnectClient-1.0.html). In Bruce Tiffany's blog post "[Securing Open Liberty apps and micro-services with MicroProfile JWT and Social Media login](https://openliberty.io/blog/2019/08/29/securing-microservices-social-login-jwt.html)", you have a solid example on how to use Open Liberty Social Media Login feature to authenticate users using their existing social media credentials. In this blog post, let's take a look at another example about how to use Open Liberty OpenID Connect Client feature to secure apps with [Azure Active Directory](https://docs.microsoft.com/azure/active-directory/develop/v2-protocols-oidc) using the existing Java EE IAM APIs.

<!-- IMPORTANT: find a way to capture this activation action to count against our OKRs.  DO NOT PUBLISH without this. -->
The sample code used in this blog is hosted on this [GitHub repo](https://github.com/Azure-Samples/liberty-aad-oidc), feel free to check it out and follow its user guide to run the demo application before or after reading this blog.

## Set up Azure Active Directory

Azure Active Directory (AAD) implements OpenID Connect (OIDC), an authentication protocol built on OAuth 2.0, which lets you securely sign in a user from AAD to an application.  You can't have AAD without Azure.  Before going into the sample code, you must first set up AAD an tenant and create an application registration with redirect URL & client secret. The tenant id, application(client) id & client secret are used by Open Liberty OpenID Connect Client to negotiate with AAD to complete [OAuth 2.0 authorization code flow](https://docs.microsoft.com/azure/active-directory/develop/v2-oauth2-auth-code-flow).

Learn how to set up AAD from these articles:

- [Create a new tenant](https://docs.microsoft.com/azure/active-directory/develop/quickstart-create-new-tenant)
- [Register an application](https://docs.microsoft.com/azure/active-directory/develop/quickstart-register-app)
- [Add a new client secret](https://docs.microsoft.com/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow#request-the-permissions-in-the-app-registration-portal)

## Configure OpenID Connect Client

The following sample code snippets show how a Jakarta EE application running on an Open Liberty server is configured with the OpenID Connect Client (openidConnectClient-1.0) **feature** to authenticate a user from an OpenID Connect Provider, with AAD as the designated security provider.

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

  <!-- add your tenant id, client ID and secret from AAD -->
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

Using AAD allows your application to use a certificate with a root CA signed by Microsoft's public certificate.  This certificate is added to the JVMs' default `cacerts`.  Trusting JVM default `cacerts` ensures a successful SSL handshake between OpenID Connect Client and AAD.

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

<!-- Please provide a diagram here -->

This is just standard Java EE security.  When an unauthenticated user attempt's to access the JSF client, they are redirected to Microsoft to provide their AAD credentials. Upon success, the browser gets redirected back to the client with an authorization code. The client then contacts the Microsoft again with authorization code, client Id & secret to obtain an ID token & access token, and finally create an authenticated user on the client, which then gets access to the JSF client.

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

## Taking it to the Next Level

If you want to go further, you can apply Json Web Token propagated from OpenID Connect Provider to secure downstream internal REST calls with an HTTP Authorization header. Refer to [com.ibm.websphere.security.openidconnect.PropagationHelper.getIdToken()](https://github.com/OpenLiberty/open-liberty/blob/master/dev/com.ibm.ws.security.openidconnect.common/src/com/ibm/websphere/security/openidconnect/PropagationHelper.java#L60-L62) API to get the ID token issued by the OpenID Connect Provider.

## Other references

- [Configuring an OpenID Connect Client in Liberty](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_config_oidc_rp.html)
- [Secure your application by using OpenID Connect and Azure AD](https://docs.microsoft.com/learn/modules/secure-app-with-oidc-and-azure-ad/)

# Securing Open Liberty Applications with Azure Active Directory via OpenID Connect

Nowadays, more and more modern applications are secured by external security provider, which provides the benefit that applications no longer need to own and manage users' credentials. Open Liberty also supports relevant security features, e.g., [Social Media Login](https://openliberty.io/docs/ref/feature/#socialLogin-1.0.html), [SAML Web Single Sign-on](https://openliberty.io/docs/ref/feature/#samlWeb-2.0.html) and [OpenID Connect Client](https://openliberty.io/docs/ref/feature/#openidConnectClient-1.0.html). In blog "[Securing Open Liberty apps and microservices with MicroProfile JWT and Social Media login](https://openliberty.io/blog/2019/08/29/securing-microservices-social-login-jwt.html)", it gave a solid example on how to use Open Liberty Social Media Login feature to authenticate users using their existing social media credentials. In this blog, let's take a look at another example about how to use Open Liberty OpenID Connect Client feature to secure apps with [Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc).

## Set up Azure Active Directory
Azure Active Directory (AAD) implements OpenID Connect (OIDC), an authentication protocol built on OAuth 2.0, which lets you securely sign in a user from AAD to an application. Before going into the sample code, you need to first set up AAD tenant and create an application registration with redirect URL & client secret. The tenant id, application(client) id & client secret are used by Open Liberty OpenID Connect Client to negotiate with AAD to complete [OAuth 2.0 authorization code flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow). Refer to the following articles on how to set it up:
- [Create a new tenant](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [Register an application](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [Add a new client secret](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow#request-the-permissions-in-the-app-registration-portal)

## Configure OpenID Connect Client
The following sample code snippets show how a Jakarta EE application running on an Open Liberty server is configured with OpenID Connect Client (openidConnectClient-1.0) feature to authenticate a user from a OpenID Connect Provider, with AAD as the designated security provider.

The relevant server configuration in `server.xml`:
```
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

  <!-- add your tanent id, client ID and secret from AAD -->
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

The certificate of root CA which signed Microsoft public certificate is added to JVM default cacerts, so trusting JVM default cacerts ensures successful SSL handshake between OpenID Connect Client and AAD.

## Use OpenID Connect to authenticate users
The sample application exposes a [JSF](https://www.oracle.com/java/technologies/javaserverfaces.html) client which defines security constraint that only user with role "users" can access.

The relevant configuration in `web.xml`:
```
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

So when unauthenticated users attempt to access the JSF client, they are redirected to Microsoft to ask their AAD credentials. Upon success, the browser gets redirected back to the client with an authorization code. The client then contacts the Microsoft again with authorization code, client Id & secret to obtain an ID token & access token, and finally create an authenticated user on the client, which then gets access to the JSF client.

To get authenticated user information, inject `javax.security.enterprise.SecurityContext` and call its method `getCallerPrincipal()`:
```
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

The source code is hosted on this [GitHub repo](https://github.com/majguo/liberty-aad-oidc), feel free to check it out and follow the  user guide to run the demo application used in this blog.

## Further considerations
One of further considerations is to apply Json Web Token propagated from OpenID Connect Provider to secure downstream internal REST calls with a HTTP Authorization header. The access token can be accessed using the [com.ibm.websphere.security.openidconnect.PropagationHelper.getAccessToken()](https://github.com/OpenLiberty/open-liberty/blob/master/dev/com.ibm.ws.security.openidconnect.common/src/com/ibm/websphere/security/openidconnect/PropagationHelper.java) API and the ID token can be retrieved by refering to [com.ibm.ws.security.openidconnect.common.impl.PropagationHelperImpl.getSubjectAttributeObject()] API.

## Other references
- [Configuring an OpenID Connect Client in Liberty](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_config_oidc_rp.html)
- [Secure your application by using OpenID Connect and Azure AD](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
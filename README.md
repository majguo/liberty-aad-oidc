# Secure WebSphere Liberty Application with Azure AD OpenID Connect

## Introduction
This demo project provides examples (hello-world & javaee-cafe) on how to secure your application which is running on WebSphere Liberty server by using Azure Active Directory OpenID Connect.

### References
- [Securing Open Liberty apps and microservices with MicroProfile JWT and Social Media login](https://openliberty.io/blog/2019/08/29/securing-microservices-social-login-jwt.html)
- [Configuring an OpenID Connect Client in Liberty](https://www.ibm.com/support/knowledgecenter/SSEQTP_liberty/com.ibm.websphere.wlp.doc/ae/twlp_config_oidc_rp.html)

## Prerequisites
- Register an [Azure subscription](https://azure.microsoft.com/en-us/)
- Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
- Install [Oracle JDK 8](https://www.oracle.com/java/technologies/javase-jdk8-downloads.html)
- Download [Maven](https://maven.apache.org/download.cgi)

## Setup Azure Active Directory
- [Create a new Azure AD tenant](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-create-new-tenant#create-a-new-azure-ad-tenant) if not existing, log down Directory (tenant) ID
- [Create Azure AD users](https://docs.microsoft.com/en-us/azure/openshift/howto-aad-app-configuration#create-a-new-azure-active-directory-user) if not existing, log down their emial addresses & passwords
- [Optional] [Create Azure AD security groups](https://docs.microsoft.com/en-us/azure/openshift/howto-aad-app-configuration#create-an-azure-ad-security-group) "admin" & "users" if not existing, add created users as group members, log down group IDs 
- [Create an Azure AD app registration for authentication](https://docs.microsoft.com/en-us/azure/openshift/configure-azure-ad-ui#create-an-azure-active-directory-application-for-authentication) if not existing, log down Application (client) ID & client secret. Fill in <b>Redirect URI</b> with the redirect URI of applicatoins to be deployed later:
  - https://<span></span>localhost:9543/oidcclient/redirect/liberty-aad-oidc-helloworld
  - https://<span></span>localhost:9643/oidcclient/redirect/liberty-aad-oidc-javaeecafe
- [Configure optional claims](https://docs.microsoft.com/en-us/azure/openshift/configure-azure-ad-ui#configure-optional-claims)
  - Add optional claim > Select ID then check the email and upn claims
  - [Optional] Add groups claim > Select Security groups then select Group ID for each token type

## Build & run application
- [hello-world](https://github.com/majguo/liberty-aad-oidc/tree/master/hello-world)
- [javaee-cafe](https://github.com/majguo/liberty-aad-oidc/tree/master/javaee-cafe)

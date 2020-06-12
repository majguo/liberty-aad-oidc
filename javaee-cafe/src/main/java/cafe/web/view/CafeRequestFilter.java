package cafe.web.view;

import java.lang.invoke.MethodHandles;
import java.util.logging.Logger;

import javax.ws.rs.client.ClientRequestContext;
import javax.ws.rs.client.ClientRequestFilter;
import javax.ws.rs.core.HttpHeaders;

import com.ibm.websphere.security.jwt.Claims;
import com.ibm.websphere.security.jwt.InvalidBuilderException;
import com.ibm.websphere.security.jwt.InvalidClaimException;
import com.ibm.websphere.security.jwt.JwtBuilder;
import com.ibm.websphere.security.jwt.JwtException;
import com.ibm.websphere.security.openidconnect.PropagationHelper;
import com.ibm.websphere.security.openidconnect.token.IdToken;

public class CafeRequestFilter implements ClientRequestFilter {
    private static final Logger logger = Logger.getLogger(MethodHandles.lookup().lookupClass().getName());
    private String jwtTokenString;
    
    public CafeRequestFilter() {
        try {
            IdToken idToken = PropagationHelper.getIdToken();
            jwtTokenString = JwtBuilder.create("jwtAuthUserBuilder").claim(Claims.SUBJECT, "javaee-cafe-rest-endpoints")
                    .claim("upn", idToken.getClaim("preferred_username"))
                    .claim("groups", idToken.getClaim("groups")).buildJwt()
                    .compact();
        } catch (JwtException | InvalidBuilderException | InvalidClaimException e) {
            logger.severe("Creating JWT token failed.");
            e.printStackTrace();
        }
      }

      @Override
      public void filter(ClientRequestContext requestContext) {
          requestContext.getHeaders().putSingle(HttpHeaders.AUTHORIZATION, "Bearer " + jwtTokenString);
      }
}

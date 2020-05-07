package oidc;

import java.io.IOException;
import java.io.PrintWriter;
import java.security.Principal;
import javax.servlet.ServletException;
import javax.servlet.annotation.HttpConstraint;
import javax.servlet.annotation.ServletSecurity;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@WebServlet("/")
@ServletSecurity(value = @HttpConstraint(rolesAllowed= {"users"}))
public class HelloWorldServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private final Logger log = LoggerFactory.getLogger(getClass());
    
    public HelloWorldServlet() {
        super();
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {      
        Principal principal = request.getUserPrincipal();
        log.info("The logged-on user is {}", principal.getName());
        
        PrintWriter pw = response.getWriter();
        pw.append(String.format("Hello, %s!", principal.getName()));
        pw.flush();
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        doGet(request, response);
    }
}

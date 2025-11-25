package com.example.tomcat;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.http.HttpRequest;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public class LoginServlet extends HttpServlet{
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException{
		String username = request.getParameter("username");
		String passwd = request.getParameter("password");
		String sql= "select password from data where username = ?"; 
		
			if(validUser(username,passwd)) {
				response.setContentType("text/html");

				// Get the response writer
				PrintWriter out = response.getWriter();

				// Write simple HTML
				out.println("<html><body>");
				out.println("<h1>Hello, World!</h1>");
				out.println("</body></html>");

			}else {
				response.sendRedirect("index.jsp?error=true");
			}
	}
	
	
	private boolean validUser(String username, String passwd) {
		if("Akash".equalsIgnoreCase(username)&& "akash".equals(passwd)) {
			return true;
		}else {
			return false;
		}
	}
}

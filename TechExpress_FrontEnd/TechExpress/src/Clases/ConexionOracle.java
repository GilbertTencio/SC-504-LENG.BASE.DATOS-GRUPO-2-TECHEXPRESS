
package Clases;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexionOracle {
    private static final String URL = "jdbc:oracle:thin:@192.168.100.82:1521:orcl?connectTimeout=10000&socketTimeout=10000"; 
    private static final String USER = "base_tablas";
    private static final String PASS = "base_tablas";

    public static Connection obtenerConexion() throws SQLException {
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            return DriverManager.getConnection(URL, USER, PASS);
        } catch (ClassNotFoundException e) {
            throw new SQLException("No se pudo cargar el driver JDBC", e);
        }
    }
}


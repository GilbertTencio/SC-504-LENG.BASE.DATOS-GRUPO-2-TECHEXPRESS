
package Clases;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexionOracle {
    private static final String URL = "jdbc:oracle:thin:@//192.168.100.82:1521/orclpdb";
    private static final String USUARIO = "";
    private static final String CLAVE = "";

    public static Connection obtenerConexion() throws SQLException {
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            return DriverManager.getConnection(URL, USUARIO, CLAVE);
        } catch (ClassNotFoundException e) {
            throw new SQLException("No se pudo cargar el driver JDBC", e);
        }
    }
}



package main;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.awt.GridLayout;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JTextField;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.Date;


/* ---------------------------------------------------------------
 * FORMULARIO CLIENTE
 * --------------------------------------------------------------- */
class Formularios extends JDialog {
    private Connection connection;
    private boolean guardado = false;
    private Integer idCliente;
    
    // Componentes del formulario
    private JTextField txtId, txtNombre, txtApellido, txtEmail, txtTelefono, txtDireccion;
    
    public Formularios(Connection connection, Integer idCliente) {
        this.connection = connection;
        this.idCliente = idCliente;
        
        setTitle(idCliente == null ? "Nuevo Cliente" : "Editar Cliente");
        setSize(400, 350);
        setModal(true);
        setLocationRelativeTo(null);
        setLayout(new GridLayout(0, 2, 10, 10));
        
        initComponents();
        if (idCliente != null) {
            cargarDatosCliente();
        }
    }
    
    private void initComponents() {
        txtId = new JTextField();
        txtNombre = new JTextField();
        txtApellido = new JTextField();
        txtEmail = new JTextField();
        txtTelefono = new JTextField();
        txtDireccion = new JTextField();
        
        // Configurar campos
        if (idCliente == null) {
            txtId.setEditable(true);
        } else {
            txtId.setEditable(false);
            txtId.setText(idCliente.toString());
        }
        
        // Botones
        JButton btnGuardar = new JButton("Guardar");
        JButton btnCancelar = new JButton("Cancelar");
        
        // Agregar componentes
        add(new JLabel("ID Cliente:"));
        add(txtId);
        add(new JLabel("Nombre:"));
        add(txtNombre);
        add(new JLabel("Apellido:"));
        add(txtApellido);
        add(new JLabel("Email:"));
        add(txtEmail);
        add(new JLabel("Teléfono:"));
        add(txtTelefono);
        add(new JLabel("Dirección:"));
        add(txtDireccion);
        add(btnGuardar);
        add(btnCancelar);
        
        // Listeners
        btnGuardar.addActionListener(e -> guardarCliente());
        btnCancelar.addActionListener(e -> dispose());
    }
    
    private void cargarDatosCliente() {
        try {
            String sql = "SELECT Nombre, Apellido, Email, Telefono, Direccion " +
                         "FROM Clientes WHERE ID_Cliente = ?";
            
            PreparedStatement pstmt = connection.prepareStatement(sql);
            pstmt.setInt(1, idCliente);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                txtNombre.setText(rs.getString("Nombre"));
                txtApellido.setText(rs.getString("Apellido"));
                txtEmail.setText(rs.getString("Email"));
                txtTelefono.setText(rs.getString("Telefono"));
                txtDireccion.setText(rs.getString("Direccion"));
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar datos del cliente: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void guardarCliente() {
        try {
            // Validaciones
            if (txtNombre.getText().trim().isEmpty() || txtApellido.getText().trim().isEmpty()) {
                JOptionPane.showMessageDialog(this, "Nombre y apellido son obligatorios", 
                        "Error", JOptionPane.ERROR_MESSAGE);
                return;
            }
            
            if (!txtEmail.getText().contains("@") || !txtEmail.getText().contains(".")) {
                JOptionPane.showMessageDialog(this, "Ingrese un email válido", 
                        "Error", JOptionPane.ERROR_MESSAGE);
                return;
            }
            
            if (idCliente == null) {
                // Insertar nuevo cliente
                int id;
                try {
                    id = Integer.parseInt(txtId.getText());
                } catch (NumberFormatException e) {
                    JOptionPane.showMessageDialog(this, "El ID debe ser un número entero", 
                            "Error", JOptionPane.ERROR_MESSAGE);
                    return;
                }
                
                CallableStatement cs = connection.prepareCall(
                        "{call pkg_clientes.Registrar_Cliente(?, ?, ?, ?, ?, ?)}");
                cs.setInt(1, id);
                cs.setString(2, txtNombre.getText());
                cs.setString(3, txtApellido.getText());
                cs.setString(4, txtEmail.getText());
                cs.setString(5, txtTelefono.getText());
                cs.setString(6, txtDireccion.getText());
                cs.execute();
            } else {
                // Actualizar cliente existente
                CallableStatement cs = connection.prepareCall(
                        "{call pkg_clientes.Actualizar_Cliente(?, ?, ?, ?, ?, ?)}");
                cs.setInt(1, idCliente);
                cs.setString(2, txtNombre.getText());
                cs.setString(3, txtApellido.getText());
                cs.setString(4, txtEmail.getText());
                cs.setString(5, txtTelefono.getText());
                cs.setString(6, txtDireccion.getText());
                cs.execute();
            }
            
            guardado = true;
            dispose();
            
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al guardar cliente: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    public boolean isGuardado() {
        return guardado;
    }
}

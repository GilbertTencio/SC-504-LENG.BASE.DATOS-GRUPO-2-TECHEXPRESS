package Clases;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.Date;

public class GUI extends JFrame {
    
    private static final String URL = "jdbc:oracle:thin:@//192.168.100.82:1521/orclpdb"; // Ajusta según tu configuración
    private static final String USER = ""; // Configura el usuario apropiado, e.g., BASE_TABLAS o similar
    private static final String PASS = ""; // Configura la contraseña
    
    private Connection connection;
    private JTabbedPane tabbedPane;
    
    public GUI() {
        super("Sistema TECHXPRESS - Gestión de Datos");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1200, 700);
        setLocationRelativeTo(null);
        
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            connection = DriverManager.getConnection(URL, USER, PASS);
            System.out.println("Conexión exitosa a la base de datos TECHXPRESS");
        } catch (Exception e) {
            JOptionPane.showMessageDialog(this, "Error al conectar a la base de datos: " + e.getMessage(),
                    "Error de conexión", JOptionPane.ERROR_MESSAGE);
            System.exit(1);
        }
        
        initComponents();
    }
    
    private void initComponents() {
        tabbedPane = new JTabbedPane();
        
        // Pestañas para vistas de tablas
        tabbedPane.addTab("Clientes", crearPanelVista("BASE_TABLAS.clientes", new String[]{"idCliente", "nombre", "telefono", "email", "direccion"}));
        tabbedPane.addTab("Técnicos", crearPanelVista("BASE_TABLAS.tecnicos", new String[]{"idTecnico", "nombre", "telefono", "email"}));
        tabbedPane.addTab("Servicios", crearPanelVista("BASE_TABLAS.servicios", new String[]{"idServicio", "descripcion", "costo"}));
        tabbedPane.addTab("Repuestos", crearPanelVista("BASE_TABLAS.repuestos", new String[]{"idRepuesto", "nombre", "descripcion", "stock", "precio_unitario"}));
        tabbedPane.addTab("Usuarios", crearPanelVista("BASE_TABLAS.usuarios", new String[]{"idUsuario", "nombre_usuario", "nombre_completo", "email", "rol", "activo", "fecha_creacion"}));
        tabbedPane.addTab("Equipos", crearPanelVista("OPS_TABLAS.equipos", new String[]{"idEquipo", "idCliente", "tipo_equipo", "marca", "modelo", "numero_serie"}));
        tabbedPane.addTab("Órdenes de Trabajo", crearPanelVista("OPS_TABLAS.ordenestrabajo", new String[]{"idOrden", "idEquipo", "idTecnico", "fecha_ingreso", "fecha_entrega", "estado", "observaciones"}));
        tabbedPane.addTab("Órdenes Servicios", crearPanelVista("OPS_TABLAS.ordenes_servicios", new String[]{"idOrdenServicio", "idOrden", "idServicio", "cantidad"}));
        tabbedPane.addTab("Órdenes Repuestos", crearPanelVista("OPS_TABLAS.ordenes_repuestos", new String[]{"idOrdenRepuesto", "idOrden", "idRepuesto", "cantidad"}));
        tabbedPane.addTab("Facturas", crearPanelVista("FACT_TABLAS.facturas", new String[]{"idFactura", "idOrden", "fecha_factura", "total", "metodo_pago"}));
        
        // Pestañas extra para probar inserciones
        tabbedPane.addTab("Insertar Cliente", crearPanelInsercionCliente());
        tabbedPane.addTab("Insertar Técnico", crearPanelInsercionTecnico());
        
        // Pestaña para plantilla de triggers (auditoría)
        tabbedPane.addTab("Auditoría (Triggers)", crearPanelAuditoria());
        
        add(tabbedPane);
    }
    
    private JPanel crearPanelVista(String tabla, String[] columnas) {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        
        DefaultTableModel modelo = new DefaultTableModel() {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        for (String col : columnas) {
            modelo.addColumn(col);
        }
        
        JTable tablaVista = new JTable(modelo);
        tablaVista.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tablaVista.getTableHeader().setReorderingAllowed(false);
        
        JScrollPane scrollTabla = new JScrollPane(tablaVista);
        
        JPanel panelBotones = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 5));
        JButton btnActualizar = new JButton("Actualizar");
        panelBotones.add(btnActualizar);
        
        panel.add(panelBotones, BorderLayout.NORTH);
        panel.add(scrollTabla, BorderLayout.CENTER);
        
        btnActualizar.addActionListener(e -> actualizarTablaVista(tabla, columnas, modelo));
        
        // Cargar datos iniciales
        actualizarTablaVista(tabla, columnas, modelo);
        
        return panel;
    }
    
    private void actualizarTablaVista(String tabla, String[] columnas, DefaultTableModel modelo) {
        try {
            modelo.setRowCount(0);
            
            String sql = "SELECT " + String.join(", ", columnas) + " FROM " + tabla + " ORDER BY " + columnas[0];
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(sql);
            
            while (rs.next()) {
                Object[] fila = new Object[columnas.length];
                for (int i = 0; i < columnas.length; i++) {
                    fila[i] = rs.getObject(columnas[i]);
                }
                modelo.addRow(fila);
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar datos de " + tabla + ": " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    // Panel para insertar cliente (pestaña extra)
    private JPanel crearPanelInsercionCliente() {
        JPanel panel = new JPanel(new GridLayout(0, 2, 10, 10));
        
        JTextField txtIdCliente = new JTextField();
        JTextField txtNombre = new JTextField();
        JTextField txtTelefono = new JTextField();
        JTextField txtEmail = new JTextField();
        JTextField txtDireccion = new JTextField();
        
        JButton btnInsertar = new JButton("Insertar Cliente");
        
        panel.add(new JLabel("ID Cliente:"));
        panel.add(txtIdCliente);
        panel.add(new JLabel("Nombre:"));
        panel.add(txtNombre);
        panel.add(new JLabel("Teléfono:"));
        panel.add(txtTelefono);
        panel.add(new JLabel("Email:"));
        panel.add(txtEmail);
        panel.add(new JLabel("Dirección:"));
        panel.add(txtDireccion);
        panel.add(btnInsertar);
        
        btnInsertar.addActionListener(e -> {
            try {
                int id = Integer.parseInt(txtIdCliente.getText());
                String nombre = txtNombre.getText();
                String telefono = txtTelefono.getText();
                String email = txtEmail.getText();
                String direccion = txtDireccion.getText();
                
                String sql = "INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (?, ?, ?, ?, ?)";
                PreparedStatement pstmt = connection.prepareStatement(sql);
                pstmt.setInt(1, id);
                pstmt.setString(2, nombre);
                pstmt.setString(3, telefono);
                pstmt.setString(4, email);
                pstmt.setString(5, direccion);
                pstmt.executeUpdate();
                
                JOptionPane.showMessageDialog(this, "Cliente insertado correctamente");
                // Limpiar campos
                txtIdCliente.setText("");
                txtNombre.setText("");
                txtTelefono.setText("");
                txtEmail.setText("");
                txtDireccion.setText("");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, "Error al insertar cliente: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            }
        });
        
        return panel;
    }
    
    // Panel para insertar técnico (pestaña extra)
    private JPanel crearPanelInsercionTecnico() {
        JPanel panel = new JPanel(new GridLayout(0, 2, 10, 10));
        
        JTextField txtIdTecnico = new JTextField();
        JTextField txtNombre = new JTextField();
        JTextField txtTelefono = new JTextField();
        JTextField txtEmail = new JTextField();
        
        JButton btnInsertar = new JButton("Insertar Técnico");
        
        panel.add(new JLabel("ID Técnico:"));
        panel.add(txtIdTecnico);
        panel.add(new JLabel("Nombre:"));
        panel.add(txtNombre);
        panel.add(new JLabel("Teléfono:"));
        panel.add(txtTelefono);
        panel.add(new JLabel("Email:"));
        panel.add(txtEmail);
        panel.add(btnInsertar);
        
        btnInsertar.addActionListener(e -> {
            try {
                int id = Integer.parseInt(txtIdTecnico.getText());
                String nombre = txtNombre.getText();
                String telefono = txtTelefono.getText();
                String email = txtEmail.getText();
                
                String sql = "INSERT INTO BASE_TABLAS.tecnicos (idTecnico, nombre, telefono, email) VALUES (?, ?, ?, ?)";
                PreparedStatement pstmt = connection.prepareStatement(sql);
                pstmt.setInt(1, id);
                pstmt.setString(2, nombre);
                pstmt.setString(3, telefono);
                pstmt.setString(4, email);
                pstmt.executeUpdate();
                
                JOptionPane.showMessageDialog(this, "Técnico insertado correctamente");
                // Limpiar campos
                txtIdTecnico.setText("");
                txtNombre.setText("");
                txtTelefono.setText("");
                txtEmail.setText("");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, "Error al insertar técnico: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            }
        });
        
        return panel;
    }
    
    // Panel para plantilla de auditoría (triggers)
    private JPanel crearPanelAuditoria() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        
        // Modelo para tabla de auditoría (plantilla)
        DefaultTableModel modeloAuditoria = new DefaultTableModel() {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        modeloAuditoria.addColumn("Tabla");
        modeloAuditoria.addColumn("Acción");
        modeloAuditoria.addColumn("ID Registro");
        modeloAuditoria.addColumn("Fecha/Hora");
        modeloAuditoria.addColumn("Usuario");
        
        JTable tablaAuditoria = new JTable(modeloAuditoria);
        JScrollPane scrollTabla = new JScrollPane(tablaAuditoria);
        
        JPanel panelBotones = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 5));
        JButton btnActualizar = new JButton("Actualizar Auditoría");
        panelBotones.add(btnActualizar);
        
        panel.add(panelBotones, BorderLayout.NORTH);
        panel.add(scrollTabla, BorderLayout.CENTER);
        
        // Plantilla para triggers: Aquí se pueden agregar consultas a tablas de auditoría creadas por triggers.
        // Ejemplo: Supongamos una tabla AUDITORIA_CLIENTES con columnas: tabla, accion, id_registro, fecha_hora, usuario
        // Trigger 1: Para inserciones en clientes
        // CREATE OR REPLACE TRIGGER trg_auditoria_clientes_insert
        // AFTER INSERT ON BASE_TABLAS.clientes
        // FOR EACH ROW
        // BEGIN
        //     INSERT INTO AUDITORIA (tabla, accion, id_registro, fecha_hora, usuario)
        //     VALUES ('clientes', 'INSERT', :NEW.idCliente, SYSDATE, USER);
        // END;
        //
        // Trigger 2: Para inserciones en tecnicos
        // CREATE OR REPLACE TRIGGER trg_auditoria_tecnicos_insert
        // AFTER INSERT ON BASE_TABLAS.tecnicos
        // FOR EACH ROW
        // BEGIN
        //     INSERT INTO AUDITORIA (tabla, accion, id_registro, fecha_hora, usuario)
        //     VALUES ('tecnicos', 'INSERT', :NEW.idTecnico, SYSDATE, USER);
        // END;
        
        btnActualizar.addActionListener(e -> {
            // Aquí cargar datos de la tabla AUDITORIA (si existe)
            // Ejemplo: SELECT tabla, accion, id_registro, fecha_hora, usuario FROM AUDITORIA ORDER BY fecha_hora DESC
            modeloAuditoria.setRowCount(0);
            JOptionPane.showMessageDialog(this, "Funcionalidad de auditoría en plantilla. Implementa triggers y tabla AUDITORIA para ver registros.", "Información", JOptionPane.INFORMATION_MESSAGE);
        });
        
        return panel;
    }
 
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            } catch (Exception e) {
                e.printStackTrace();
            }
            
            GUI app = new GUI();
            app.setVisible(true);
        });
    }

}
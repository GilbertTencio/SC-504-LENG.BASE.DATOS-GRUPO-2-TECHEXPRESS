package main;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.Date;

public class TiendaArtesanalGUI extends JFrame {
    
    private static final String URL = "jdbc:oracle:thin:@//localhost:1521/orclpdb";
    private static final String USER = "PROYECTO_DB";
    private static final String PASS = "proyecto_ldb";
    
    private Connection connection;
    private JTabbedPane tabbedPane;
    
    public TiendaArtesanalGUI() {
        super("Sistema de Gestión - Tienda Artesanal");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1000, 650);
        setLocationRelativeTo(null);
        
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            connection = DriverManager.getConnection(URL, USER, PASS);
            System.out.println("Conexion exitosa a la base de datos");
        } catch (Exception e) {
            JOptionPane.showMessageDialog(this, "Error al conectar a la base de datos: " + e.getMessage(),
                    "Error de conexión", JOptionPane.ERROR_MESSAGE);
            System.exit(1);
        }
        
        initComponents();
    }
    
    private void initComponents() {
        tabbedPane = new JTabbedPane();
        
        tabbedPane.addTab("Productos", crearPanelProductos());
        tabbedPane.addTab("Clientes", crearPanelClientes());
        tabbedPane.addTab("Ventas", crearPanelVentas());
        tabbedPane.addTab("Detalles Venta", crearPanelDetallesVenta());
        tabbedPane.addTab("Proveedores", crearPanelProveedores());
        tabbedPane.addTab("Reportes", crearPanelReportes());
        
        add(tabbedPane);
    }

    /* ---------------------------------------------------------------
     * PANEL DE PRODUCTOS
     * --------------------------------------------------------------- */
    private JPanel crearPanelProductos() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        
        // Modelo y tabla para productos
        DefaultTableModel modeloProductos = new DefaultTableModel() {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        modeloProductos.addColumn("ID");
        modeloProductos.addColumn("Nombre");
        modeloProductos.addColumn("Descripción");
        modeloProductos.addColumn("Precio");
        modeloProductos.addColumn("Stock");
        modeloProductos.addColumn("Proveedor");
        modeloProductos.addColumn("Categoría");
        
        JTable tablaProductos = new JTable(modeloProductos);
        tablaProductos.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tablaProductos.getTableHeader().setReorderingAllowed(false);
        
        JScrollPane scrollTabla = new JScrollPane(tablaProductos);
        
        // Panel de botones
        JPanel panelBotones = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 5));
        
        JButton btnAgregar = new JButton("Agregar");
        JButton btnEditar = new JButton("Editar");
        JButton btnEliminar = new JButton("Eliminar");
        JButton btnActualizar = new JButton("Actualizar");
        JButton btnStockBajo = new JButton("Stock Bajo");
        
        panelBotones.add(btnAgregar);
        panelBotones.add(btnEditar);
        panelBotones.add(btnEliminar);
        panelBotones.add(btnActualizar);
        panelBotones.add(btnStockBajo);
        
        // Agregar componentes al panel principal
        panel.add(panelBotones, BorderLayout.NORTH);
        panel.add(scrollTabla, BorderLayout.CENTER);
        
        // Listeners
        btnActualizar.addActionListener(e -> actualizarTablaProductos(modeloProductos));
        
        btnAgregar.addActionListener(e -> {
            FormularioProducto formulario = new FormularioProducto(connection, null);
            formulario.setVisible(true);
            if (formulario.isGuardado()) {
                actualizarTablaProductos(modeloProductos);
            }
        });
        
        btnEditar.addActionListener(e -> {
            int filaSeleccionada = tablaProductos.getSelectedRow();
            if (filaSeleccionada == -1) {
                JOptionPane.showMessageDialog(panel, "Seleccione un producto para editar", 
                        "Error", JOptionPane.WARNING_MESSAGE);
                return;
            }
            
            int idProducto = (int) modeloProductos.getValueAt(filaSeleccionada, 0);
            FormularioProducto formulario = new FormularioProducto(connection, idProducto);
            formulario.setVisible(true);
            if (formulario.isGuardado()) {
                actualizarTablaProductos(modeloProductos);
            }
        });
        
        btnEliminar.addActionListener(e -> {
            int filaSeleccionada = tablaProductos.getSelectedRow();
            if (filaSeleccionada == -1) {
                JOptionPane.showMessageDialog(panel, "Seleccione un producto para eliminar", 
                        "Error", JOptionPane.WARNING_MESSAGE);
                return;
            }
            
            int idProducto = (int) modeloProductos.getValueAt(filaSeleccionada, 0);
            String nombreProducto = (String) modeloProductos.getValueAt(filaSeleccionada, 1);
            
            int confirm = JOptionPane.showConfirmDialog(panel, 
                    "¿Está seguro de eliminar el producto " + nombreProducto + "?",
                    "Confirmar eliminación", JOptionPane.YES_NO_OPTION);
            
            if (confirm == JOptionPane.YES_OPTION) {
                try {
                    CallableStatement cs = connection.prepareCall("{call pkg_productos.Eliminar_Producto(?)}");
                    cs.setInt(1, idProducto);
                    cs.execute();
                    JOptionPane.showMessageDialog(panel, "Producto eliminado correctamente");
                    actualizarTablaProductos(modeloProductos);
                } catch (SQLException ex) {
                    JOptionPane.showMessageDialog(panel, "Error al eliminar producto: " + ex.getMessage(),
                            "Error", JOptionPane.ERROR_MESSAGE);
                }
            }
        });
        
        btnStockBajo.addActionListener(e -> mostrarProductosStockBajo(modeloProductos));
        
        // Cargar datos iniciales
        actualizarTablaProductos(modeloProductos);
        
        return panel;
    }
    
    private void actualizarTablaProductos(DefaultTableModel modelo) {
        try {
            modelo.setRowCount(0); // Limpiar la tabla
            
            String sql = "SELECT p.ID_Producto, p.Nombre, p.Descripcion, p.Precio, p.Stock, " +
                         "pr.Nombre AS NombreProveedor, c.Nombre AS NombreCategoria " +
                         "FROM Productos p " +
                         "JOIN Proveedores pr ON p.ID_Proveedor = pr.ID_Proveedor " +
                         "JOIN Categorias c ON p.ID_Categoria = c.ID_Categoria " +
                         "ORDER BY p.ID_Producto";
            
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(sql);
            
            while (rs.next()) {
                Object[] fila = new Object[]{
                    rs.getInt("ID_Producto"),
                    rs.getString("Nombre"),
                    rs.getString("Descripcion"),
                    rs.getDouble("Precio"),
                    rs.getInt("Stock"),
                    rs.getString("NombreProveedor"),
                    rs.getString("NombreCategoria")
                };
                modelo.addRow(fila);
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar productos: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void mostrarProductosStockBajo(DefaultTableModel modelo) {
        try {
            modelo.setRowCount(0);
            
            String sql = "SELECT p.ID_Producto, p.Nombre, p.Descripcion, p.Precio, p.Stock, " +
                         "pr.Nombre AS NombreProveedor, c.Nombre AS NombreCategoria " +
                         "FROM Productos p " +
                         "JOIN Proveedores pr ON p.ID_Proveedor = pr.ID_Proveedor " +
                         "JOIN Categorias c ON p.ID_Categoria = c.ID_Categoria " +
                         "WHERE p.Stock < 5 " +  // Productos con menos de 5 unidades
                         "ORDER BY p.Stock";
            
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(sql);
            
            while (rs.next()) {
                Object[] fila = new Object[]{
                    rs.getInt("ID_Producto"),
                    rs.getString("Nombre"),
                    rs.getString("Descripcion"),
                    rs.getDouble("Precio"),
                    rs.getInt("Stock"),
                    rs.getString("NombreProveedor"),
                    rs.getString("NombreCategoria")
                };
                modelo.addRow(fila);
            }
            
            if (modelo.getRowCount() == 0) {
                JOptionPane.showMessageDialog(this, "No hay productos con stock bajo", 
                        "Información", JOptionPane.INFORMATION_MESSAGE);
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar productos con stock bajo: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }

    /* ---------------------------------------------------------------
     * PANEL DE CLIENTES
     * --------------------------------------------------------------- */
    private JPanel crearPanelClientes() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        
        // Modelo y tabla para clientes
        DefaultTableModel modeloClientes = new DefaultTableModel() {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        modeloClientes.addColumn("ID");
        modeloClientes.addColumn("Nombre");
        modeloClientes.addColumn("Apellido");
        modeloClientes.addColumn("Email");
        modeloClientes.addColumn("Teléfono");
        modeloClientes.addColumn("Dirección");
        modeloClientes.addColumn("Fecha Registro");
        
        JTable tablaClientes = new JTable(modeloClientes);
        tablaClientes.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tablaClientes.getTableHeader().setReorderingAllowed(false);
        
        JScrollPane scrollTabla = new JScrollPane(tablaClientes);
        
        // Panel de botones
        JPanel panelBotones = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 5));
        
        JButton btnAgregar = new JButton("Agregar");
        JButton btnEditar = new JButton("Editar");
        JButton btnEliminar = new JButton("Eliminar");
        JButton btnActualizar = new JButton("Actualizar");
        
        panelBotones.add(btnAgregar);
        panelBotones.add(btnEditar);
        panelBotones.add(btnEliminar);
        panelBotones.add(btnActualizar);
        
        // Agregar componentes al panel principal
        panel.add(panelBotones, BorderLayout.NORTH);
        panel.add(scrollTabla, BorderLayout.CENTER);
        
        // Listeners
        btnActualizar.addActionListener(e -> actualizarTablaClientes(modeloClientes));
        
        btnAgregar.addActionListener(e -> {
            Formularios formulario = new Formularios(connection, null);
            formulario.setVisible(true);
            if (formulario.isGuardado()) {
                actualizarTablaClientes(modeloClientes);
            }
        });
        
        btnEditar.addActionListener(e -> {
            int filaSeleccionada = tablaClientes.getSelectedRow();
            if (filaSeleccionada == -1) {
                JOptionPane.showMessageDialog(panel, "Seleccione un cliente para editar", 
                        "Error", JOptionPane.WARNING_MESSAGE);
                return;
            }
            
            int idCliente = (int) modeloClientes.getValueAt(filaSeleccionada, 0);
            Formularios formulario = new Formularios(connection, idCliente);
            formulario.setVisible(true);
            if (formulario.isGuardado()) {
                actualizarTablaClientes(modeloClientes);
            }
        });
        
        btnEliminar.addActionListener(e -> {
            int filaSeleccionada = tablaClientes.getSelectedRow();
            if (filaSeleccionada == -1) {
                JOptionPane.showMessageDialog(panel, "Seleccione un cliente para eliminar", 
                        "Error", JOptionPane.WARNING_MESSAGE);
                return;
            }
            
            int idCliente = (int) modeloClientes.getValueAt(filaSeleccionada, 0);
            String nombreCliente = (String) modeloClientes.getValueAt(filaSeleccionada, 1) + " " + 
                                 (String) modeloClientes.getValueAt(filaSeleccionada, 2);
            
            int confirm = JOptionPane.showConfirmDialog(panel, 
                    "¿Está seguro de eliminar el cliente " + nombreCliente + "?",
                    "Confirmar eliminación", JOptionPane.YES_NO_OPTION);
            
            if (confirm == JOptionPane.YES_OPTION) {
                try {
                    CallableStatement cs = connection.prepareCall("{call pkg_clientes.Eliminar_Cliente(?)}");
                    cs.setInt(1, idCliente);
                    cs.execute();
                    JOptionPane.showMessageDialog(panel, "Cliente eliminado correctamente");
                    actualizarTablaClientes(modeloClientes);
                } catch (SQLException ex) {
                    JOptionPane.showMessageDialog(panel, "Error al eliminar cliente: " + ex.getMessage(),
                            "Error", JOptionPane.ERROR_MESSAGE);
                }
            }
        });
        
        // Cargar datos iniciales
        actualizarTablaClientes(modeloClientes);
        
        return panel;
    }
    
    private void actualizarTablaClientes(DefaultTableModel modelo) {
        try {
            modelo.setRowCount(0);
            
            String sql = "SELECT ID_Cliente, Nombre, Apellido, Email, Telefono, Direccion, " +
                         "TO_CHAR(Fecha_Registro, 'DD/MM/YYYY') AS Fecha_Registro " +
                         "FROM Clientes ORDER BY ID_Cliente";
            
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(sql);
            
            while (rs.next()) {
                Object[] fila = new Object[]{
                    rs.getInt("ID_Cliente"),
                    rs.getString("Nombre"),
                    rs.getString("Apellido"),
                    rs.getString("Email"),
                    rs.getString("Telefono"),
                    rs.getString("Direccion"),
                    rs.getString("Fecha_Registro")
                };
                modelo.addRow(fila);
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar clientes: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }

    /* ---------------------------------------------------------------
     * PANEL DE VENTAS
     * --------------------------------------------------------------- */
    private JPanel crearPanelVentas() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        
        // Modelo y tabla para ventas
        DefaultTableModel modeloVentas = new DefaultTableModel() {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        modeloVentas.addColumn("ID Venta");
        modeloVentas.addColumn("Fecha");
        modeloVentas.addColumn("Cliente");
        modeloVentas.addColumn("Empleado");
        modeloVentas.addColumn("Total");
        modeloVentas.addColumn("Estado");
        
        JTable tablaVentas = new JTable(modeloVentas);
        tablaVentas.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tablaVentas.getTableHeader().setReorderingAllowed(false);
        
        JScrollPane scrollTabla = new JScrollPane(tablaVentas);
        
        // Panel de botones
        JPanel panelBotones = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 5));
        
        JButton btnNuevaVenta = new JButton("Nueva Venta");
        JButton btnVerDetalle = new JButton("Ver Detalle");
        JButton btnAnular = new JButton("Anular Venta");
        JButton btnActualizar = new JButton("Actualizar");
        JButton btnPorFecha = new JButton("Filtrar por Fecha");
        
        panelBotones.add(btnNuevaVenta);
        panelBotones.add(btnVerDetalle);
        panelBotones.add(btnAnular);
        panelBotones.add(btnActualizar);
        panelBotones.add(btnPorFecha);
        
        // Agregar componentes al panel principal
        panel.add(panelBotones, BorderLayout.NORTH);
        panel.add(scrollTabla, BorderLayout.CENTER);
        
        // Listeners
        btnActualizar.addActionListener(e -> actualizarTablaVentas(modeloVentas));
        
        btnNuevaVenta.addActionListener(e -> {
            FormularioVenta formulario = new FormularioVenta(connection);
            formulario.setVisible(true);
            if (formulario.isVentaRealizada()) {
                actualizarTablaVentas(modeloVentas);
            }
        });
        
        btnVerDetalle.addActionListener(e -> {
            int filaSeleccionada = tablaVentas.getSelectedRow();
            if (filaSeleccionada == -1) {
                JOptionPane.showMessageDialog(panel, "Seleccione una venta para ver el detalle", 
                        "Error", JOptionPane.WARNING_MESSAGE);
                return;
            }
            
            int idVenta = (int) modeloVentas.getValueAt(filaSeleccionada, 0);
            tabbedPane.setSelectedIndex(3); // Cambiar a pestaña de detalles
            mostrarDetalleVenta(idVenta);
        });
        
        btnAnular.addActionListener(e -> {
            int filaSeleccionada = tablaVentas.getSelectedRow();
            if (filaSeleccionada == -1) {
                JOptionPane.showMessageDialog(panel, "Seleccione una venta para anular", 
                        "Error", JOptionPane.WARNING_MESSAGE);
                return;
            }
            
            int idVenta = (int) modeloVentas.getValueAt(filaSeleccionada, 0);
            String estado = (String) modeloVentas.getValueAt(filaSeleccionada, 5);
            
            if (estado.equals("ANULADA")) {
                JOptionPane.showMessageDialog(panel, "Esta venta ya está anulada", 
                        "Error", JOptionPane.WARNING_MESSAGE);
                return;
            }
            
            int confirm = JOptionPane.showConfirmDialog(panel, 
                    "¿Está seguro de anular la venta #" + idVenta + "?",
                    "Confirmar anulación", JOptionPane.YES_NO_OPTION);
            
            if (confirm == JOptionPane.YES_OPTION) {
                try {
                    CallableStatement cs = connection.prepareCall("{call sp_MarcarVentaComoAnulada(?)}");
                    cs.setInt(1, idVenta);
                    cs.execute();
                    JOptionPane.showMessageDialog(panel, "Venta anulada correctamente");
                    actualizarTablaVentas(modeloVentas);
                } catch (SQLException ex) {
                    JOptionPane.showMessageDialog(panel, "Error al anular venta: " + ex.getMessage(),
                            "Error", JOptionPane.ERROR_MESSAGE);
                }
            }
        });
        
        btnPorFecha.addActionListener(e -> filtrarVentasPorFecha(modeloVentas));
        
        // Cargar datos iniciales
        actualizarTablaVentas(modeloVentas);
        
        return panel;
    }
    
    private void actualizarTablaVentas(DefaultTableModel modelo) {
        try {
            modelo.setRowCount(0);
            
            String sql = "SELECT v.ID_Venta, TO_CHAR(v.Fecha_Venta, 'DD/MM/YYYY HH24:MI') AS Fecha, " +
                         "c.Nombre || ' ' || c.Apellido AS Cliente, " +
                         "e.Nombre || ' ' || e.Apellido AS Empleado, " +
                         "v.Total, v.Estado " +
                         "FROM Ventas v " +
                         "JOIN Clientes c ON v.ID_Cliente = c.ID_Cliente " +
                         "LEFT JOIN Empleados e ON v.ID_Empleado = e.ID_Empleado " +
                         "ORDER BY v.Fecha_Venta DESC";
            
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(sql);
            
            while (rs.next()) {
                Object[] fila = new Object[]{
                    rs.getInt("ID_Venta"),
                    rs.getString("Fecha"),
                    rs.getString("Cliente"),
                    rs.getString("Empleado"),
                    rs.getDouble("Total"),
                    rs.getString("Estado")
                };
                modelo.addRow(fila);
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar ventas: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void filtrarVentasPorFecha(DefaultTableModel modelo) {
        try {
            JDialog dialogo = new JDialog(this, "Filtrar Ventas por Fecha", true);
            dialogo.setLayout(new GridLayout(0, 2, 10, 10));
            
            JTextField txtFechaInicio = new JTextField(new SimpleDateFormat("dd/MM/yyyy").format(new Date()));
            JTextField txtFechaFin = new JTextField(new SimpleDateFormat("dd/MM/yyyy").format(new Date()));
            
            JButton btnFiltrar = new JButton("Filtrar");
            JButton btnCancelar = new JButton("Cancelar");
            
            dialogo.add(new JLabel("Fecha Inicio (dd/MM/yyyy):"));
            dialogo.add(txtFechaInicio);
            dialogo.add(new JLabel("Fecha Fin (dd/MM/yyyy):"));
            dialogo.add(txtFechaFin);
            dialogo.add(btnFiltrar);
            dialogo.add(btnCancelar);
            
            btnFiltrar.addActionListener(e -> {
                try {
                    modelo.setRowCount(0);
                    
                    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
                    Date fechaInicio = sdf.parse(txtFechaInicio.getText());
                    Date fechaFin = sdf.parse(txtFechaFin.getText());
                    
                    String sql = "SELECT v.ID_Venta, TO_CHAR(v.Fecha_Venta, 'DD/MM/YYYY HH24:MI') AS Fecha, " +
                                 "c.Nombre || ' ' || c.Apellido AS Cliente, " +
                                 "e.Nombre || ' ' || e.Apellido AS Empleado, " +
                                 "v.Total, v.Estado " +
                                 "FROM Ventas v " +
                                 "JOIN Clientes c ON v.ID_Cliente = c.ID_Cliente " +
                                 "LEFT JOIN Empleados e ON v.ID_Empleado = e.ID_Empleado " +
                                 "WHERE v.Fecha_Venta BETWEEN TO_DATE(?, 'DD/MM/YYYY') " +
                                 "AND TO_DATE(?, 'DD/MM/YYYY') + 1 " +
                                 "ORDER BY v.Fecha_Venta DESC";
                    
                    PreparedStatement pstmt = connection.prepareStatement(sql);
                    pstmt.setString(1, txtFechaInicio.getText());
                    pstmt.setString(2, txtFechaFin.getText());
                    
                    ResultSet rs = pstmt.executeQuery();
                    
                    while (rs.next()) {
                        Object[] fila = new Object[]{
                            rs.getInt("ID_Venta"),
                            rs.getString("Fecha"),
                            rs.getString("Cliente"),
                            rs.getString("Empleado"),
                            rs.getDouble("Total"),
                            rs.getString("Estado")
                        };
                        modelo.addRow(fila);
                    }
                    
                    dialogo.dispose();
                } catch (Exception ex) {
                    JOptionPane.showMessageDialog(dialogo, "Formato de fecha inválido (usar dd/MM/yyyy)", 
                            "Error", JOptionPane.ERROR_MESSAGE);
                }
            });
            
            btnCancelar.addActionListener(e -> dialogo.dispose());
            
            dialogo.pack();
            dialogo.setLocationRelativeTo(this);
            dialogo.setVisible(true);
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Error al filtrar ventas: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }

    /* ---------------------------------------------------------------
     * PANEL DE DETALLES DE VENTA
     * --------------------------------------------------------------- */
    private DefaultTableModel modeloDetalles;
    private JTable tablaDetalles;
    private JLabel lblInfoVenta;
    
    private JPanel crearPanelDetallesVenta() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        
        // Panel superior con información de la venta
        JPanel panelSuperior = new JPanel(new FlowLayout(FlowLayout.LEFT));
        lblInfoVenta = new JLabel("Seleccione una venta para ver su detalle");
        panelSuperior.add(lblInfoVenta);
        
        // Modelo y tabla para detalles de venta
        modeloDetalles = new DefaultTableModel() {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        modeloDetalles.addColumn("ID Detalle");
        modeloDetalles.addColumn("Producto");
        modeloDetalles.addColumn("Cantidad");
        modeloDetalles.addColumn("Precio Unitario");
        modeloDetalles.addColumn("Descuento (%)");
        modeloDetalles.addColumn("Subtotal");
        
        tablaDetalles = new JTable(modeloDetalles);
        tablaDetalles.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tablaDetalles.getTableHeader().setReorderingAllowed(false);
        
        JScrollPane scrollTabla = new JScrollPane(tablaDetalles);
        
        // Panel de botones
        JPanel panelBotones = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 5));
        JButton btnActualizar = new JButton("Actualizar");
        panelBotones.add(btnActualizar);
        
        // Agregar componentes al panel principal
        panel.add(panelSuperior, BorderLayout.NORTH);
        panel.add(scrollTabla, BorderLayout.CENTER);
        panel.add(panelBotones, BorderLayout.SOUTH);
        
        // Listeners
        btnActualizar.addActionListener(e -> {
            int ventaSeleccionada = tabbedPane.getSelectedIndex();
            if (ventaSeleccionada == 2) { // Si estamos en la pestaña de ventas
                JTable tablaVentas = (JTable) ((JScrollPane) ((JPanel) tabbedPane.getComponent(2)).getComponent(1)).getViewport().getView();
                int filaSeleccionada = tablaVentas.getSelectedRow();
                
                if (filaSeleccionada != -1) {
                    DefaultTableModel model = (DefaultTableModel) tablaVentas.getModel();
                    int idVenta = (int) model.getValueAt(filaSeleccionada, 0);
                    mostrarDetalleVenta(idVenta);
                }
            }
        });
        
        return panel;
    }
    
    private void mostrarDetalleVenta(int idVenta) {
        try {
            modeloDetalles.setRowCount(0);
            
            // Obtener información de la venta
            String sqlVenta = "SELECT v.ID_Venta, TO_CHAR(v.Fecha_Venta, 'DD/MM/YYYY HH24:MI') AS Fecha, " +
                              "c.Nombre || ' ' || c.Apellido AS Cliente, " +
                              "e.Nombre || ' ' || e.Apellido AS Empleado, " +
                              "v.Total, v.Estado " +
                              "FROM Ventas v " +
                              "JOIN Clientes c ON v.ID_Cliente = c.ID_Cliente " +
                              "LEFT JOIN Empleados e ON v.ID_Empleado = e.ID_Empleado " +
                              "WHERE v.ID_Venta = ?";
            
            PreparedStatement pstmtVenta = connection.prepareStatement(sqlVenta);
            pstmtVenta.setInt(1, idVenta);
            ResultSet rsVenta = pstmtVenta.executeQuery();
            
            if (rsVenta.next()) {
                lblInfoVenta.setText(String.format(
                    "Venta #%d - Fecha: %s - Cliente: %s - Empleado: %s - Total: $%,.2f - Estado: %s",
                    rsVenta.getInt("ID_Venta"),
                    rsVenta.getString("Fecha"),
                    rsVenta.getString("Cliente"),
                    rsVenta.getString("Empleado"),
                    rsVenta.getDouble("Total"),
                    rsVenta.getString("Estado")
                ));
            }
            
            // Obtener detalles de la venta
            String sqlDetalles = "SELECT d.ID_Detalle, p.Nombre AS Producto, d.Cantidad, " +
                                 "d.Precio_Unitario, d.Descuento, " +
                                 "(d.Cantidad * d.Precio_Unitario * (1 - NVL(d.Descuento,0)/100)) AS Subtotal " +
                                 "FROM Detalles_Venta d " +
                                 "JOIN Productos p ON d.ID_Producto = p.ID_Producto " +
                                 "WHERE d.ID_Venta = ? " +
                                 "ORDER BY d.ID_Detalle";
            
            PreparedStatement pstmtDetalles = connection.prepareStatement(sqlDetalles);
            pstmtDetalles.setInt(1, idVenta);
            ResultSet rsDetalles = pstmtDetalles.executeQuery();
            
            double total = 0;
            while (rsDetalles.next()) {
                Object[] fila = new Object[]{
                    rsDetalles.getInt("ID_Detalle"),
                    rsDetalles.getString("Producto"),
                    rsDetalles.getInt("Cantidad"),
                    rsDetalles.getDouble("Precio_Unitario"),
                    rsDetalles.getDouble("Descuento"),
                    rsDetalles.getDouble("Subtotal")
                };
                modeloDetalles.addRow(fila);
                total += rsDetalles.getDouble("Subtotal");
            }
            
            // Agregar fila de total
            modeloDetalles.addRow(new Object[]{"", "", "", "", "TOTAL:", total});
            
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar detalle de venta: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }

    /* ---------------------------------------------------------------
     * PANEL DE PROVEEDORES
     * --------------------------------------------------------------- */
    private JPanel crearPanelProveedores() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        
        // Modelo y tabla para proveedores
        DefaultTableModel modeloProveedores = new DefaultTableModel() {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        modeloProveedores.addColumn("ID");
        modeloProveedores.addColumn("Nombre");
        modeloProveedores.addColumn("Contacto");
        modeloProveedores.addColumn("Teléfono");
        modeloProveedores.addColumn("Dirección");
        modeloProveedores.addColumn("Email");
        
        JTable tablaProveedores = new JTable(modeloProveedores);
        tablaProveedores.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tablaProveedores.getTableHeader().setReorderingAllowed(false);
        
        JScrollPane scrollTabla = new JScrollPane(tablaProveedores);
        
        // Panel de botones
        JPanel panelBotones = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 5));
        
        JButton btnAgregar = new JButton("Agregar");
        JButton btnEditar = new JButton("Editar");
        JButton btnEliminar = new JButton("Eliminar");
        JButton btnActualizar = new JButton("Actualizar");
        
        panelBotones.add(btnAgregar);
        panelBotones.add(btnEditar);
        panelBotones.add(btnEliminar);
        panelBotones.add(btnActualizar);
        
        // Agregar componentes al panel principal
        panel.add(panelBotones, BorderLayout.NORTH);
        panel.add(scrollTabla, BorderLayout.CENTER);
        
        // Listeners
        btnActualizar.addActionListener(e -> actualizarTablaProveedores(modeloProveedores));
        
        btnAgregar.addActionListener(e -> {
            FormularioProveedor formulario = new FormularioProveedor(connection, null);
            formulario.setVisible(true);
            if (formulario.isGuardado()) {
                actualizarTablaProveedores(modeloProveedores);
            }
        });
        
        btnEditar.addActionListener(e -> {
            int filaSeleccionada = tablaProveedores.getSelectedRow();
            if (filaSeleccionada == -1) {
                JOptionPane.showMessageDialog(panel, "Seleccione un proveedor para editar", 
                        "Error", JOptionPane.WARNING_MESSAGE);
                return;
            }
            
            int idProveedor = (int) modeloProveedores.getValueAt(filaSeleccionada, 0);
            FormularioProveedor formulario = new FormularioProveedor(connection, idProveedor);
            formulario.setVisible(true);
            if (formulario.isGuardado()) {
                actualizarTablaProveedores(modeloProveedores);
            }
        });
        
        btnEliminar.addActionListener(e -> {
            int filaSeleccionada = tablaProveedores.getSelectedRow();
            if (filaSeleccionada == -1) {
                JOptionPane.showMessageDialog(panel, "Seleccione un proveedor para eliminar", 
                        "Error", JOptionPane.WARNING_MESSAGE);
                return;
            }
            
            int idProveedor = (int) modeloProveedores.getValueAt(filaSeleccionada, 0);
            String nombreProveedor = (String) modeloProveedores.getValueAt(filaSeleccionada, 1);
            
            int confirm = JOptionPane.showConfirmDialog(panel, 
                    "¿Está seguro de eliminar al proveedor " + nombreProveedor + "?",
                    "Confirmar eliminación", JOptionPane.YES_NO_OPTION);
            
            if (confirm == JOptionPane.YES_OPTION) {
                try {
                    CallableStatement cs = connection.prepareCall("{call pkg_proveedores.Eliminar_Proveedor(?)}");
                    cs.setInt(1, idProveedor);
                    cs.execute();
                    JOptionPane.showMessageDialog(panel, "Proveedor eliminado correctamente");
                    actualizarTablaProveedores(modeloProveedores);
                } catch (SQLException ex) {
                    JOptionPane.showMessageDialog(panel, "Error al eliminar proveedor: " + ex.getMessage(),
                            "Error", JOptionPane.ERROR_MESSAGE);
                }
            }
        });
        
        // Cargar datos iniciales
        actualizarTablaProveedores(modeloProveedores);
        
        return panel;
    }
    
    private void actualizarTablaProveedores(DefaultTableModel modelo) {
        try {
            modelo.setRowCount(0);
            
            String sql = "SELECT ID_Proveedor, Nombre, Contacto, Telefono, Direccion, Email " +
                         "FROM Proveedores ORDER BY ID_Proveedor";
            
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(sql);
            
            while (rs.next()) {
                Object[] fila = new Object[]{
                    rs.getInt("ID_Proveedor"),
                    rs.getString("Nombre"),
                    rs.getString("Contacto"),
                    rs.getString("Telefono"),
                    rs.getString("Direccion"),
                    rs.getString("Email")
                };
                modelo.addRow(fila);
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar proveedores: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }

      /* ---------------------------------------------------------------
     * PANEL DE REPORTES (COMPLETO)
     * --------------------------------------------------------------- */
    private JPanel crearPanelReportes() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        
        // Panel de controles
        JPanel panelControles = new JPanel(new GridLayout(1, 4, 5, 5));
        
        // ComboBox para seleccionar reporte
        JComboBox<String> cbReportes = new JComboBox<>(new String[]{
            "Productos más vendidos",
            "Ventas por cliente",
            "Ventas mensuales",
            "Productos con stock crítico",
            "Clientes frecuentes",
            "Inventario valorizado"
        });
        
        JButton btnGenerar = new JButton("Generar Reporte");
        JButton btnExportar = new JButton("Exportar a Excel");
        JButton btnImprimir = new JButton("Imprimir");
        
        panelControles.add(cbReportes);
        panelControles.add(btnGenerar);
        panelControles.add(btnExportar);
        panelControles.add(btnImprimir);
        
        // Modelo y tabla para reportes
        DefaultTableModel modeloReportes = new DefaultTableModel();
        JTable tablaReportes = new JTable(modeloReportes);
        JScrollPane scrollTabla = new JScrollPane(tablaReportes);
        
        // Agregar componentes al panel principal
        panel.add(panelControles, BorderLayout.NORTH);
        panel.add(scrollTabla, BorderLayout.CENTER);
        
        // Listeners
        btnGenerar.addActionListener(e -> {
            String reporteSeleccionado = (String) cbReportes.getSelectedItem();
            generarReporte(reporteSeleccionado, modeloReportes);
        });
        
        btnExportar.addActionListener(e -> exportarAExcel(modeloReportes));
        btnImprimir.addActionListener(e -> imprimirReporte(tablaReportes));
        
        // Cargar reporte inicial
        generarReporte("Productos más vendidos", modeloReportes);
        
        return panel;
    }
    
    private void generarReporte(String reporte, DefaultTableModel modelo) {
        try {
            modelo.setRowCount(0);
            modelo.setColumnCount(0); // Limpiar columnas también
            
            String sql = "";
            String titulo = "";
            
            switch(reporte) {
                case "Productos más vendidos":
                    sql = "SELECT p.Nombre, SUM(dv.Cantidad) AS Unidades_Vendidas, " +
                          "SUM(dv.Cantidad * dv.Precio_Unitario) AS Total_Ventas " +
                          "FROM Detalles_Venta dv " +
                          "JOIN Productos p ON dv.ID_Producto = p.ID_Producto " +
                          "GROUP BY p.Nombre " +
                          "ORDER BY Unidades_Vendidas DESC";
                    titulo = "Productos Más Vendidos";
                    modelo.addColumn("Producto");
                    modelo.addColumn("Unidades Vendidas");
                    modelo.addColumn("Total Ventas");
                    break;
                    
                case "Ventas por cliente":
                    sql = "SELECT c.Nombre || ' ' || c.Apellido AS Cliente, " +
                          "COUNT(v.ID_Venta) AS Numero_Ventas, " +
                          "SUM(v.Total) AS Total_Comprado " +
                          "FROM Clientes c " +
                          "JOIN Ventas v ON c.ID_Cliente = v.ID_Cliente " +
                          "GROUP BY c.Nombre, c.Apellido " +
                          "ORDER BY Total_Comprado DESC";
                    titulo = "Ventas por Cliente";
                    modelo.addColumn("Cliente");
                    modelo.addColumn("N° Ventas");
                    modelo.addColumn("Total Comprado");
                    break;
                    
                case "Ventas mensuales":
                    sql = "SELECT EXTRACT(YEAR FROM Fecha_Venta) AS Anio, " +
                          "EXTRACT(MONTH FROM Fecha_Venta) AS Mes, " +
                          "TO_CHAR(Fecha_Venta, 'Month') AS Nombre_Mes, " +
                          "COUNT(ID_Venta) AS Numero_Ventas, " +
                          "SUM(Total) AS Total_Ventas " +
                          "FROM Ventas " +
                          "GROUP BY EXTRACT(YEAR FROM Fecha_Venta), " +
                          "EXTRACT(MONTH FROM Fecha_Venta), TO_CHAR(Fecha_Venta, 'Month') " +
                          "ORDER BY Anio DESC, Mes DESC";
                    titulo = "Ventas Mensuales";
                    modelo.addColumn("Año");
                    modelo.addColumn("Mes");
                    modelo.addColumn("Nombre Mes");
                    modelo.addColumn("N° Ventas");
                    modelo.addColumn("Total Ventas");
                    break;
                    
                case "Productos con stock crítico":
                    sql = "SELECT p.Nombre, p.Stock, pr.Nombre AS Proveedor " +
                          "FROM Productos p " +
                          "JOIN Proveedores pr ON p.ID_Proveedor = pr.ID_Proveedor " +
                          "WHERE p.Stock < 5 " +
                          "ORDER BY p.Stock";
                    titulo = "Productos con Stock Crítico";
                    modelo.addColumn("Producto");
                    modelo.addColumn("Stock");
                    modelo.addColumn("Proveedor");
                    break;
                    
                case "Clientes frecuentes":
                    sql = "SELECT c.Nombre || ' ' || c.Apellido AS Cliente, " +
                          "COUNT(v.ID_Venta) AS Numero_Ventas, " +
                          "SUM(v.Total) AS Total_Comprado " +
                          "FROM Clientes c " +
                          "JOIN Ventas v ON c.ID_Cliente = v.ID_Cliente " +
                          "GROUP BY c.Nombre, c.Apellido " +
                          "HAVING COUNT(v.ID_Venta) > 3 " +
                          "ORDER BY Numero_Ventas DESC";
                    titulo = "Clientes Frecuentes (más de 3 compras)";
                    modelo.addColumn("Cliente");
                    modelo.addColumn("N° Ventas");
                    modelo.addColumn("Total Comprado");
                    break;
                    
                case "Inventario valorizado":
                    sql = "SELECT p.Nombre, p.Stock, p.Precio, " +
                          "(p.Stock * p.Precio) AS Valor_Total, " +
                          "c.Nombre AS Categoria " +
                          "FROM Productos p " +
                          "JOIN Categorias c ON p.ID_Categoria = c.ID_Categoria " +
                          "ORDER BY Valor_Total DESC";
                    titulo = "Inventario Valorizado";
                    modelo.addColumn("Producto");
                    modelo.addColumn("Stock");
                    modelo.addColumn("Precio Unit.");
                    modelo.addColumn("Valor Total");
                    modelo.addColumn("Categoría");
                    break;
            }
            
            this.setTitle("Sistema de Gestión - Tienda Artesanal - " + titulo);
            
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(sql);
            
            ResultSetMetaData metaData = rs.getMetaData();
            int columnCount = metaData.getColumnCount();
            
            while (rs.next()) {
                Object[] fila = new Object[columnCount];
                for (int i = 0; i < columnCount; i++) {
                    fila[i] = rs.getObject(i + 1);
                }
                modelo.addRow(fila);
            }
            
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al generar reporte: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void exportarAExcel(DefaultTableModel modelo) {
        // Implementación para exportar a Excel
        JOptionPane.showMessageDialog(this, "Función de exportar a Excel no implementada aún",
                "Información", JOptionPane.INFORMATION_MESSAGE);
    }
    
    private void imprimirReporte(JTable tabla) {
        // Implementación para imprimir
        JOptionPane.showMessageDialog(this, "Función de imprimir no implementada aún",
                "Información", JOptionPane.INFORMATION_MESSAGE);
    }

    /* ---------------------------------------------------------------
     * MAIN METHOD
     * --------------------------------------------------------------- */
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            } catch (Exception e) {
                e.printStackTrace();
            }
            
            TiendaArtesanalGUI app = new TiendaArtesanalGUI();
            app.setVisible(true);
        });
    }
}

/* ---------------------------------------------------------------
 * CLASES AUXILIARES - FORMULARIOS
 * --------------------------------------------------------------- */

class FormularioProducto extends JDialog {
    private Connection connection;
    private boolean guardado = false;
    private Integer idProducto;
    
    // Componentes del formulario
    private JTextField txtId, txtNombre, txtDescripcion, txtPrecio, txtStock;
    private JComboBox<String> cbProveedores, cbCategorias;
    
    public FormularioProducto(Connection connection, Integer idProducto) {
        this.connection = connection;
        this.idProducto = idProducto;
        
        setTitle(idProducto == null ? "Nuevo Producto" : "Editar Producto");
        setSize(400, 400);
        setModal(true);
        setLocationRelativeTo(null);
        setLayout(new GridLayout(0, 2, 10, 10));
        
        initComponents();
        if (idProducto != null) {
            cargarDatosProducto();
        }
    }
    
    private void initComponents() {
        txtId = new JTextField();
        txtNombre = new JTextField();
        txtDescripcion = new JTextField();
        txtPrecio = new JTextField();
        txtStock = new JTextField();
        
        cbProveedores = new JComboBox<>();
        cbCategorias = new JComboBox<>();
        
        // Configurar campos
        if (idProducto == null) {
            txtId.setEditable(true);
        } else {
            txtId.setEditable(false);
            txtId.setText(idProducto.toString());
        }
        
        // Cargar combos
        cargarProveedores();
        cargarCategorias();
        
        // Botones
        JButton btnGuardar = new JButton("Guardar");
        JButton btnCancelar = new JButton("Cancelar");
        
        // Agregar componentes
        add(new JLabel("ID Producto:"));
        add(txtId);
        add(new JLabel("Nombre:"));
        add(txtNombre);
        add(new JLabel("Descripción:"));
        add(txtDescripcion);
        add(new JLabel("Precio:"));
        add(txtPrecio);
        add(new JLabel("Stock:"));
        add(txtStock);
        add(new JLabel("Proveedor:"));
        add(cbProveedores);
        add(new JLabel("Categoría:"));
        add(cbCategorias);
        add(btnGuardar);
        add(btnCancelar);
        
        // Listeners
        btnGuardar.addActionListener(e -> guardarProducto());
        btnCancelar.addActionListener(e -> dispose());
    }
    
    private void cargarProveedores() {
        try {
            cbProveedores.removeAllItems();
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT ID_Proveedor, Nombre FROM Proveedores ORDER BY Nombre");
            
            while (rs.next()) {
                cbProveedores.addItem(rs.getInt("ID_Proveedor") + " - " + rs.getString("Nombre"));
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar proveedores: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void cargarCategorias() {
        try {
            cbCategorias.removeAllItems();
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT ID_Categoria, Nombre FROM Categorias ORDER BY Nombre");
            
            while (rs.next()) {
                cbCategorias.addItem(rs.getInt("ID_Categoria") + " - " + rs.getString("Nombre"));
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar categorías: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void cargarDatosProducto() {
        try {
            String sql = "SELECT p.Nombre, p.Descripcion, p.Precio, p.Stock, " +
                         "p.ID_Proveedor, p.ID_Categoria, " +
                         "pr.Nombre AS NombreProveedor, c.Nombre AS NombreCategoria " +
                         "FROM Productos p " +
                         "JOIN Proveedores pr ON p.ID_Proveedor = pr.ID_Proveedor " +
                         "JOIN Categorias c ON p.ID_Categoria = c.ID_Categoria " +
                         "WHERE p.ID_Producto = ?";
            
            PreparedStatement pstmt = connection.prepareStatement(sql);
            pstmt.setInt(1, idProducto);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                txtNombre.setText(rs.getString("Nombre"));
                txtDescripcion.setText(rs.getString("Descripcion"));
                txtPrecio.setText(rs.getDouble("Precio") + "");
                txtStock.setText(rs.getInt("Stock") + "");
                
                // Seleccionar proveedor y categoría correctos
                String proveedor = rs.getInt("ID_Proveedor") + " - " + rs.getString("NombreProveedor");
                String categoria = rs.getInt("ID_Categoria") + " - " + rs.getString("NombreCategoria");
                
                for (int i = 0; i < cbProveedores.getItemCount(); i++) {
                    if (cbProveedores.getItemAt(i).equals(proveedor)) {
                        cbProveedores.setSelectedIndex(i);
                        break;
                    }
                }
                
                for (int i = 0; i < cbCategorias.getItemCount(); i++) {
                    if (cbCategorias.getItemAt(i).equals(categoria)) {
                        cbCategorias.setSelectedIndex(i);
                        break;
                    }
                }
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al cargar datos del producto: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void guardarProducto() {
        try {
            // Validaciones
            if (txtNombre.getText().trim().isEmpty()) {
                JOptionPane.showMessageDialog(this, "El nombre es obligatorio", 
                        "Error", JOptionPane.ERROR_MESSAGE);
                return;
            }
            
            double precio;
            int stock;
            
            try {
                precio = Double.parseDouble(txtPrecio.getText());
                stock = Integer.parseInt(txtStock.getText());
            } catch (NumberFormatException e) {
                JOptionPane.showMessageDialog(this, "Precio y stock deben ser números válidos", 
                        "Error", JOptionPane.ERROR_MESSAGE);
                return;
            }
            
            // Obtener IDs de proveedor y categoría
            int idProveedor = obtenerIdDeCombo((String) cbProveedores.getSelectedItem());
            int idCategoria = obtenerIdDeCombo((String) cbCategorias.getSelectedItem());
            
            if (idProducto == null) {
                // Insertar nuevo producto
                int id;
                try {
                    id = Integer.parseInt(txtId.getText());
                } catch (NumberFormatException e) {
                    JOptionPane.showMessageDialog(this, "El ID debe ser un número entero", 
                            "Error", JOptionPane.ERROR_MESSAGE);
                    return;
                }
                
                CallableStatement cs = connection.prepareCall(
                        "{call pkg_productos.Insertar_Producto(?, ?, ?, ?, ?, ?, ?)}");
                cs.setInt(1, id);
                cs.setString(2, txtNombre.getText());
                cs.setString(3, txtDescripcion.getText());
                cs.setDouble(4, precio);
                cs.setInt(5, stock);
                cs.setInt(6, idProveedor);
                cs.setInt(7, idCategoria);
                cs.execute();
            } else {
                // Actualizar producto existente
                CallableStatement cs = connection.prepareCall(
                        "{call pkg_productos.Actualizar_Producto(?, ?, ?, ?, ?)}");
                cs.setInt(1, idProducto);
                cs.setString(2, txtNombre.getText());
                cs.setString(3, txtDescripcion.getText());
                cs.setDouble(4, precio);
                cs.setInt(5, stock);
                cs.execute();
            }
            
            guardado = true;
            dispose();
            
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Error al guardar producto: " + ex.getMessage(),
                    "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private int obtenerIdDeCombo(String textoCombo) {
        if (textoCombo == null || textoCombo.isEmpty()) return -1;
        return Integer.parseInt(textoCombo.split(" - ")[0]);
    }
    
    public boolean isGuardado() {
        return guardado;
    }
}

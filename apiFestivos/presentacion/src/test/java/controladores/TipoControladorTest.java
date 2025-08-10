package festivos.api.presentacion.controladores;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.util.Arrays;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import com.fasterxml.jackson.databind.ObjectMapper;

import festivos.api.core.servicios.ITipoServicio;
import festivos.api.dominio.entidades.Tipo;

@ExtendWith(MockitoExtension.class)
class TipoControladorTest {

    @Mock
    private ITipoServicio tipoServicio;

    @InjectMocks
    private TipoControlador tipoControlador;

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;
    private Tipo tipo;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(tipoControlador).build();
        objectMapper = new ObjectMapper();

        tipo = new Tipo();
        tipo.setId(1);
        tipo.setNombre("Fijo");
    }

    @Test
    void testListar() throws Exception {
        // Given
        List<Tipo> tipos = Arrays.asList(tipo);
        when(tipoServicio.listar()).thenReturn(tipos);

        // When & Then
        mockMvc.perform(get("/api/tipos/listar"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].nombre").value("Fijo"));

        verify(tipoServicio).listar();
    }

    @Test
    void testObtener() throws Exception {
        // Given
        when(tipoServicio.obtener(1)).thenReturn(tipo);

        // When & Then
        mockMvc.perform(get("/api/tipos/obtener/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Fijo"));

        verify(tipoServicio).obtener(1);
    }

    @Test
    void testBuscar() throws Exception {
        // Given
        List<Tipo> tipos = Arrays.asList(tipo);
        when(tipoServicio.buscar("Fijo")).thenReturn(tipos);

        // When & Then
        mockMvc.perform(get("/api/tipos/buscar/Fijo"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].nombre").value("Fijo"));

        verify(tipoServicio).buscar("Fijo");
    }

    @Test
    void testAgregar() throws Exception {
        // Given
        when(tipoServicio.agregar(any(Tipo.class))).thenReturn(tipo);

        // When & Then
        mockMvc.perform(post("/api/tipos/agregar")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(tipo)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Fijo"));

        verify(tipoServicio).agregar(any(Tipo.class));
    }

    @Test
    void testModificar() throws Exception {
        // Given
        when(tipoServicio.modificar(any(Tipo.class))).thenReturn(tipo);

        // When & Then
        mockMvc.perform(put("/api/tipos/modificar")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(tipo)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Fijo"));

        verify(tipoServicio).modificar(any(Tipo.class));
    }

    @Test
    void testEliminar() throws Exception {
        // Given
        when(tipoServicio.eliminar(1)).thenReturn(true);

        // When & Then
        mockMvc.perform(delete("/api/tipos/eliminar/1"))
                .andExpect(status().isOk())
                .andExpect(content().string("true"));

        verify(tipoServicio).eliminar(1);
    }
}

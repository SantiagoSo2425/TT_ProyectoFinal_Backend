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

import festivos.api.core.servicios.IPaisServicio;
import festivos.api.dominio.entidades.Pais;

@ExtendWith(MockitoExtension.class)
class PaisControladorTest {

    @Mock
    private IPaisServicio paisServicio;

    @InjectMocks
    private PaisControlador paisControlador;

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;
    private Pais pais;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(paisControlador).build();
        objectMapper = new ObjectMapper();

        pais = new Pais();
        pais.setId(1);
        pais.setNombre("Colombia");
    }

    @Test
    void testListar() throws Exception {
        // Given
        List<Pais> paises = Arrays.asList(pais);
        when(paisServicio.listar()).thenReturn(paises);

        // When & Then
        mockMvc.perform(get("/api/paises/listar"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].nombre").value("Colombia"));

        verify(paisServicio).listar();
    }

    @Test
    void testObtener() throws Exception {
        // Given
        when(paisServicio.obtener(1)).thenReturn(pais);

        // When & Then
        mockMvc.perform(get("/api/paises/obtener/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Colombia"));

        verify(paisServicio).obtener(1);
    }

    @Test
    void testBuscar() throws Exception {
        // Given
        List<Pais> paises = Arrays.asList(pais);
        when(paisServicio.buscar("Colombia")).thenReturn(paises);

        // When & Then
        mockMvc.perform(get("/api/paises/buscar/Colombia"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].nombre").value("Colombia"));

        verify(paisServicio).buscar("Colombia");
    }

    @Test
    void testAgregar() throws Exception {
        // Given
        when(paisServicio.agregar(any(Pais.class))).thenReturn(pais);

        // When & Then
        mockMvc.perform(post("/api/paises/agregar")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(pais)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Colombia"));

        verify(paisServicio).agregar(any(Pais.class));
    }

    @Test
    void testModificar() throws Exception {
        // Given
        when(paisServicio.modificar(any(Pais.class))).thenReturn(pais);

        // When & Then
        mockMvc.perform(put("/api/paises/modificar")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(pais)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Colombia"));

        verify(paisServicio).modificar(any(Pais.class));
    }

    @Test
    void testEliminar() throws Exception {
        // Given
        when(paisServicio.eliminar(1)).thenReturn(true);

        // When & Then
        mockMvc.perform(delete("/api/paises/eliminar/1"))
                .andExpect(status().isOk())
                .andExpect(content().string("true"));

        verify(paisServicio).eliminar(1);
    }
}

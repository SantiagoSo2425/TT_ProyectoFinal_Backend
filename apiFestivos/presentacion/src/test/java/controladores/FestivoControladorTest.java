package festivos.api.presentacion.controladores;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import com.fasterxml.jackson.databind.ObjectMapper;

import festivos.api.core.servicios.IFestivoServicio;
import festivos.api.dominio.DTOs.FestivoDto;
import festivos.api.dominio.entidades.Festivo;
import festivos.api.dominio.entidades.Pais;
import festivos.api.dominio.entidades.Tipo;

@ExtendWith(MockitoExtension.class)
class FestivoControladorTest {

    @Mock
    private IFestivoServicio festivoServicio;

    @InjectMocks
    private FestivoControlador festivoControlador;

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;
    private Festivo festivo;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(festivoControlador).build();
        objectMapper = new ObjectMapper();

        Pais pais = new Pais();
        pais.setId(1);
        pais.setNombre("Colombia");

        Tipo tipo = new Tipo();
        tipo.setId(1);
        tipo.setNombre("Fijo");

        festivo = new Festivo();
        festivo.setId(1);
        festivo.setNombre("Año Nuevo");
        festivo.setDia(1);
        festivo.setMes(1);
        festivo.setPais(pais);
        festivo.setTipo(tipo);
    }

    @Test
    void testListar() throws Exception {
        // Given
        List<Festivo> festivos = Arrays.asList(festivo);
        when(festivoServicio.listar()).thenReturn(festivos);

        // When & Then
        mockMvc.perform(get("/api/festivos/listar"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].nombre").value("Año Nuevo"));

        verify(festivoServicio).listar();
    }

    @Test
    void testObtener() throws Exception {
        // Given
        when(festivoServicio.obtener(1)).thenReturn(festivo);

        // When & Then
        mockMvc.perform(get("/api/festivos/obtener/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Año Nuevo"));

        verify(festivoServicio).obtener(1);
    }

    @Test
    void testBuscar() throws Exception {
        // Given
        List<Festivo> festivos = Arrays.asList(festivo);
        when(festivoServicio.buscar("Año")).thenReturn(festivos);

        // When & Then
        mockMvc.perform(get("/api/festivos/buscar/Año"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].nombre").value("Año Nuevo"));

        verify(festivoServicio).buscar("Año");
    }

    @Test
    void testAgregar() throws Exception {
        // Given
        when(festivoServicio.agregar(any(Festivo.class))).thenReturn(festivo);

        // When & Then
        mockMvc.perform(post("/api/festivos/agregar")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(festivo)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Año Nuevo"));

        verify(festivoServicio).agregar(any(Festivo.class));
    }

    @Test
    void testModificar() throws Exception {
        // Given
        when(festivoServicio.modificar(any(Festivo.class))).thenReturn(festivo);

        // When & Then
        mockMvc.perform(put("/api/festivos/modificar")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(festivo)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Año Nuevo"));

        verify(festivoServicio).modificar(any(Festivo.class));
    }

    @Test
    void testEliminar() throws Exception {
        // Given
        when(festivoServicio.eliminar(1)).thenReturn(true);

        // When & Then
        mockMvc.perform(delete("/api/festivos/eliminar/1"))
                .andExpect(status().isOk())
                .andExpect(content().string("true"));

        verify(festivoServicio).eliminar(1);
    }

    @Test
    void testVerificarFechaValida() {
        // Given
        when(festivoServicio.verificar(1, LocalDate.of(2024, 1, 1))).thenReturn(true);

        // When
        ResponseEntity<?> response = festivoControlador.verificar(1, 2024, 1, 1);

        // Then
        assertEquals(200, response.getStatusCodeValue());
        assertEquals(true, response.getBody());
        verify(festivoServicio).verificar(1, LocalDate.of(2024, 1, 1));
    }

    @Test
    void testVerificarFechaInvalida() {
        // When
        ResponseEntity<?> response = festivoControlador.verificar(1, 2024, 13, 1);

        // Then
        assertEquals(400, response.getStatusCodeValue());
        assertTrue(response.getBody().toString().contains("Fecha inválida"));
    }

    @Test
    void testListarPorPaisYAno() throws Exception {
        // Given
        FestivoDto festivoDto = new FestivoDto("Año Nuevo", LocalDate.of(2024, 1, 1));
        List<FestivoDto> festivos = Arrays.asList(festivoDto);
        when(festivoServicio.listar(1, 2024)).thenReturn(festivos);

        // When & Then
        mockMvc.perform(get("/api/festivos/listar/1/2024"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].pais").value("Año Nuevo"));

        verify(festivoServicio).listar(1, 2024);
    }
}

package festivos.api.aplicacion.servicios;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Sort;

import festivos.api.dominio.entidades.Festivo;
import festivos.api.dominio.entidades.Pais;
import festivos.api.dominio.entidades.Tipo;
import festivos.api.infraestructura.repositorios.IFestivoRepositorio;

@ExtendWith(MockitoExtension.class)
class FestivoServicioTest {

    @Mock
    private IFestivoRepositorio repositorio;

    @InjectMocks
    private FestivoServicio festivoServicio;

    private Festivo festivo;
    private Pais pais;
    private Tipo tipo;

    @BeforeEach
    void setUp() {
        pais = new Pais();
        pais.setId(1);
        pais.setNombre("Colombia");

        tipo = new Tipo();
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
    void testListar() {
        // Given
        List<Festivo> festivos = Arrays.asList(festivo);
        when(repositorio.findAll(Sort.by(Sort.Direction.ASC, "nombre"))).thenReturn(festivos);

        // When
        List<Festivo> resultado = festivoServicio.listar();

        // Then
        assertNotNull(resultado);
        assertEquals(1, resultado.size());
        assertEquals("Año Nuevo", resultado.get(0).getNombre());
        verify(repositorio).findAll(Sort.by(Sort.Direction.ASC, "nombre"));
    }

    @Test
    void testObtenerExistente() {
        // Given
        when(repositorio.findById(1)).thenReturn(Optional.of(festivo));

        // When
        Festivo resultado = festivoServicio.obtener(1);

        // Then
        assertNotNull(resultado);
        assertEquals("Año Nuevo", resultado.getNombre());
        verify(repositorio, times(2)).findById(1);
    }

    @Test
    void testObtenerNoExistente() {
        // Given
        when(repositorio.findById(99)).thenReturn(Optional.empty());

        // When
        Festivo resultado = festivoServicio.obtener(99);

        // Then
        assertNull(resultado);
        verify(repositorio).findById(99);
    }

    @Test
    void testBuscar() {
        // Given
        List<Festivo> festivos = Arrays.asList(festivo);
        when(repositorio.buscar("Año")).thenReturn(festivos);

        // When
        List<Festivo> resultado = festivoServicio.buscar("Año");

        // Then
        assertNotNull(resultado);
        assertEquals(1, resultado.size());
        verify(repositorio).buscar("Año");
    }

    @Test
    void testAgregar() {
        // Given
        Festivo nuevoFestivo = new Festivo();
        nuevoFestivo.setNombre("Nuevo Festivo");
        when(repositorio.save(any(Festivo.class))).thenReturn(nuevoFestivo);

        // When
        Festivo resultado = festivoServicio.agregar(nuevoFestivo);

        // Then
        assertNotNull(resultado);
        assertEquals(0, nuevoFestivo.getId()); // Verifica que se estableció el ID en 0
        verify(repositorio).save(nuevoFestivo);
    }

    @Test
    void testModificarExistente() {
        // Given
        when(repositorio.findById(1)).thenReturn(Optional.of(festivo));
        when(repositorio.save(festivo)).thenReturn(festivo);

        // When
        Festivo resultado = festivoServicio.modificar(festivo);

        // Then
        assertNotNull(resultado);
        assertEquals("Año Nuevo", resultado.getNombre());
        verify(repositorio).findById(1);
        verify(repositorio).save(festivo);
    }

    @Test
    void testModificarNoExistente() {
        // Given
        festivo.setId(99);
        when(repositorio.findById(99)).thenReturn(Optional.empty());

        // When
        Festivo resultado = festivoServicio.modificar(festivo);

        // Then
        assertNull(resultado);
        verify(repositorio).findById(99);
        verify(repositorio, never()).save(any());
    }

    @Test
    void testEliminarExitoso() {
        // Given
        doNothing().when(repositorio).deleteById(1);

        // When
        boolean resultado = festivoServicio.eliminar(1);

        // Then
        assertTrue(resultado);
        verify(repositorio).deleteById(1);
    }

    @Test
    void testEliminarConExcepcion() {
        // Given
        doThrow(new RuntimeException("Error")).when(repositorio).deleteById(1);

        // When
        boolean resultado = festivoServicio.eliminar(1);

        // Then
        assertFalse(resultado);
        verify(repositorio).deleteById(1);
    }

    @Test
    void testVerificarFechaEsFestivo() {
        // Given
        LocalDate fecha = LocalDate.of(2024, 1, 1);
        List<Festivo> festivos = Arrays.asList(festivo);
        when(repositorio.listarPorPais(1)).thenReturn(festivos);

        // When
        boolean resultado = festivoServicio.verificar(1, fecha);

        // Then
        assertTrue(resultado);
        verify(repositorio).listarPorPais(1);
    }

    @Test
    void testVerificarFechaNoEsFestivo() {
        // Given
        LocalDate fecha = LocalDate.of(2024, 12, 25);
        List<Festivo> festivos = Arrays.asList(festivo);
        when(repositorio.listarPorPais(1)).thenReturn(festivos);

        // When
        boolean resultado = festivoServicio.verificar(1, fecha);

        // Then
        assertFalse(resultado);
        verify(repositorio).listarPorPais(1);
    }
}

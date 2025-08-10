package festivos.api.aplicacion.servicios;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

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

import festivos.api.dominio.entidades.Tipo;
import festivos.api.infraestructura.repositorios.ITipoRepositorio;

@ExtendWith(MockitoExtension.class)
class TipoServicioTest {

    @Mock
    private ITipoRepositorio repositorio;

    @InjectMocks
    private TipoServicio tipoServicio;

    private Tipo tipo;

    @BeforeEach
    void setUp() {
        tipo = new Tipo();
        tipo.setId(1);
        tipo.setNombre("Fijo");
    }

    @Test
    void testListar() {
        // Given
        List<Tipo> tipos = Arrays.asList(tipo);
        when(repositorio.findAll(Sort.by(Sort.Direction.ASC, "nombre"))).thenReturn(tipos);

        // When
        List<Tipo> resultado = tipoServicio.listar();

        // Then
        assertNotNull(resultado);
        assertEquals(1, resultado.size());
        assertEquals("Fijo", resultado.get(0).getNombre());
        verify(repositorio).findAll(Sort.by(Sort.Direction.ASC, "nombre"));
    }

    @Test
    void testObtenerExistente() {
        // Given
        when(repositorio.findById(1)).thenReturn(Optional.of(tipo));

        // When
        Tipo resultado = tipoServicio.obtener(1);

        // Then
        assertNotNull(resultado);
        assertEquals("Fijo", resultado.getNombre());
        verify(repositorio, times(2)).findById(1);
    }

    @Test
    void testObtenerNoExistente() {
        // Given
        when(repositorio.findById(99)).thenReturn(Optional.empty());

        // When
        Tipo resultado = tipoServicio.obtener(99);

        // Then
        assertNull(resultado);
        verify(repositorio).findById(99);
    }

    @Test
    void testBuscar() {
        // Given
        List<Tipo> tipos = Arrays.asList(tipo);
        when(repositorio.buscar("Fijo")).thenReturn(tipos);

        // When
        List<Tipo> resultado = tipoServicio.buscar("Fijo");

        // Then
        assertNotNull(resultado);
        assertEquals(1, resultado.size());
        verify(repositorio).buscar("Fijo");
    }

    @Test
    void testAgregar() {
        // Given
        Tipo nuevoTipo = new Tipo();
        nuevoTipo.setNombre("Variable");
        when(repositorio.save(any(Tipo.class))).thenReturn(nuevoTipo);

        // When
        Tipo resultado = tipoServicio.agregar(nuevoTipo);

        // Then
        assertNotNull(resultado);
        assertEquals(0, nuevoTipo.getId());
        verify(repositorio).save(nuevoTipo);
    }

    @Test
    void testModificarExistente() {
        // Given
        when(repositorio.findById(1)).thenReturn(Optional.of(tipo));
        when(repositorio.save(tipo)).thenReturn(tipo);

        // When
        Tipo resultado = tipoServicio.modificar(tipo);

        // Then
        assertNotNull(resultado);
        assertEquals("Fijo", resultado.getNombre());
        verify(repositorio).findById(1);
        verify(repositorio).save(tipo);
    }

    @Test
    void testModificarNoExistente() {
        // Given
        tipo.setId(99);
        when(repositorio.findById(99)).thenReturn(Optional.empty());

        // When
        Tipo resultado = tipoServicio.modificar(tipo);

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
        boolean resultado = tipoServicio.eliminar(1);

        // Then
        assertTrue(resultado);
        verify(repositorio).deleteById(1);
    }

    @Test
    void testEliminarConExcepcion() {
        // Given
        doThrow(new RuntimeException("Error")).when(repositorio).deleteById(1);

        // When
        boolean resultado = tipoServicio.eliminar(1);

        // Then
        assertFalse(resultado);
        verify(repositorio).deleteById(1);
    }
}

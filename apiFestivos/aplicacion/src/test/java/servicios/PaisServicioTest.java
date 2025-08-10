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

import festivos.api.dominio.entidades.Pais;
import festivos.api.infraestructura.repositorios.IPaisRepositorio;

@ExtendWith(MockitoExtension.class)
class PaisServicioTest {

    @Mock
    private IPaisRepositorio repositorio;

    @InjectMocks
    private PaisServicio paisServicio;

    private Pais pais;

    @BeforeEach
    void setUp() {
        pais = new Pais();
        pais.setId(1);
        pais.setNombre("Colombia");
    }

    @Test
    void testListar() {
        // Given
        List<Pais> paises = Arrays.asList(pais);
        when(repositorio.findAll(Sort.by(Sort.Direction.ASC, "nombre"))).thenReturn(paises);

        // When
        List<Pais> resultado = paisServicio.listar();

        // Then
        assertNotNull(resultado);
        assertEquals(1, resultado.size());
        assertEquals("Colombia", resultado.get(0).getNombre());
        verify(repositorio).findAll(Sort.by(Sort.Direction.ASC, "nombre"));
    }

    @Test
    void testObtenerExistente() {
        // Given
        when(repositorio.findById(1)).thenReturn(Optional.of(pais));

        // When
        Pais resultado = paisServicio.obtener(1);

        // Then
        assertNotNull(resultado);
        assertEquals("Colombia", resultado.getNombre());
        verify(repositorio, times(2)).findById(1);
    }

    @Test
    void testObtenerNoExistente() {
        // Given
        when(repositorio.findById(99)).thenReturn(Optional.empty());

        // When
        Pais resultado = paisServicio.obtener(99);

        // Then
        assertNull(resultado);
        verify(repositorio).findById(99);
    }

    @Test
    void testBuscar() {
        // Given
        List<Pais> paises = Arrays.asList(pais);
        when(repositorio.buscar("Colombia")).thenReturn(paises);

        // When
        List<Pais> resultado = paisServicio.buscar("Colombia");

        // Then
        assertNotNull(resultado);
        assertEquals(1, resultado.size());
        verify(repositorio).buscar("Colombia");
    }

    @Test
    void testAgregar() {
        // Given
        Pais nuevoPais = new Pais();
        nuevoPais.setNombre("Argentina");
        when(repositorio.save(any(Pais.class))).thenReturn(nuevoPais);

        // When
        Pais resultado = paisServicio.agregar(nuevoPais);

        // Then
        assertNotNull(resultado);
        assertEquals(0, nuevoPais.getId());
        verify(repositorio).save(nuevoPais);
    }

    @Test
    void testModificarExistente() {
        // Given
        when(repositorio.findById(1)).thenReturn(Optional.of(pais));
        when(repositorio.save(pais)).thenReturn(pais);

        // When
        Pais resultado = paisServicio.modificar(pais);

        // Then
        assertNotNull(resultado);
        assertEquals("Colombia", resultado.getNombre());
        verify(repositorio).findById(1);
        verify(repositorio).save(pais);
    }

    @Test
    void testModificarNoExistente() {
        // Given
        pais.setId(99);
        when(repositorio.findById(99)).thenReturn(Optional.empty());

        // When
        Pais resultado = paisServicio.modificar(pais);

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
        boolean resultado = paisServicio.eliminar(1);

        // Then
        assertTrue(resultado);
        verify(repositorio).deleteById(1);
    }

    @Test
    void testEliminarConExcepcion() {
        // Given
        doThrow(new RuntimeException("Error")).when(repositorio).deleteById(1);

        // When
        boolean resultado = paisServicio.eliminar(1);

        // Then
        assertFalse(resultado);
        verify(repositorio).deleteById(1);
    }
}

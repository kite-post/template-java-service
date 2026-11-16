package ua.kite.servicetemplate;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

/**
 * Інтеграційний тест: сервіс піднімається на справжньому порту і відповідає.
 * Клас з суфіксом IT підхоплює Failsafe на фазі verify, тож `make test` швидкий,
 * а `make test-it` і CI проганяють усе.
 *
 * <p>Коли в сервіса з'явиться своя база, сюди додається Testcontainers:
 *
 * <pre>
 * &#64;ServiceConnection
 * static PostgreSQLContainer&lt;?&gt; postgres = new PostgreSQLContainer&lt;&gt;("postgres:16");
 * </pre>
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class InfoEndpointIT {

    @LocalServerPort
    int port;

    @Autowired
    TestRestTemplate rest;

    @Test
    void infoVidpovidae() {
        ResponseEntity<String> response = rest.getForEntity("/api/v1/info", String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).contains("service-template");
    }

    @Test
    void healthKazheUp() {
        ResponseEntity<String> response = rest.getForEntity("/actuator/health", String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).contains("\"status\":\"UP\"");
    }
}

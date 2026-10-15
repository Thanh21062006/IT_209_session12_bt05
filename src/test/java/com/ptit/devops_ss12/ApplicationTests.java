package com.ptit.devops_ss12;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest
class ApplicationTests {

    @Test
    void contextLoads() {
        assertTrue(true);
    }

    @Test
    void testLogic() {
        assertEquals(24, 12 * 2);
    }
}

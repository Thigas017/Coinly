package com.coinly.backend

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
import org.springframework.boot.runApplication

//TODO Desativa a procura automática por uma base de dados no arranque
@SpringBootApplication(exclude = [DataSourceAutoConfiguration::class])
class BackendApplication

fun main(args: Array<String>) {
    runApplication<BackendApplication>(*args)
}
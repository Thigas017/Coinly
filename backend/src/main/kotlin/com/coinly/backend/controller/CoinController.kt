package com.coinly.backend.controller

import com.coinly.backend.model.Coin
import com.coinly.backend.repository.CoinRepository
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/coins")
class CoinController(private val repository: CoinRepository) {

    @GetMapping
    fun getAllCoins(): List<Coin> {
        return repository.findAll()
    }

    @PostMapping
    fun createCoin(@RequestBody coin: Coin): ResponseEntity<Coin> {
        val savedCoin = repository.save(coin)
        return ResponseEntity.status(HttpStatus.CREATED).body(savedCoin)
    }
}
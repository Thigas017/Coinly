package com.coinly.backend.controller

import com.coinly.backend.model.Coin
import com.coinly.backend.repository.CoinRepository
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile
import java.io.File
import java.math.BigDecimal
import java.nio.file.Files
import java.nio.file.Paths

@RestController
@RequestMapping("/api/coins")
class CoinController(private val repository: CoinRepository) {

    //Directory path for storing uploaded coin images on the server
    private val uploadDir = "uploads/coins/"

    init {
        //Ensure upload directory exists during Spring Boot startup
        val directory = File(uploadDir)
        if (!directory.exists()) {
            directory.mkdirs()
        }
    }

    @GetMapping
    fun getAllCoins(): List<Coin> {
        return repository.findAll()
    }

    //Accepts multipart requests (text fields + optional image file)
    @PostMapping(consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    fun createCoin(
        @RequestParam("id") id: String,
        @RequestParam("name") name: String,
        @RequestParam("country") country: String,
        @RequestParam("year") year: Int,
        @RequestParam("faceValue") faceValue: BigDecimal,
        @RequestParam("image", required = false) image: MultipartFile?
    ): ResponseEntity<Coin> {

        var imageUrl: String? = null

        //Persist uploaded image to disk if provided
        if (image != null && !image.isEmpty) {
            //Prefix filename with UUID to prevent naming conflicts
            val fileName = image.originalFilename
            val filePath = Paths.get(uploadDir, fileName)
            Files.write(filePath, image.bytes)
            imageUrl = fileName
        }

        //Instantiate Coin entity using received request data
        val newCoin = Coin(
            id = id,
            name = name,
            country = country,
            faceValue = faceValue,
            year = year,
            imageUrl = imageUrl
        )

        //Persist entity to database
        val savedCoin = repository.save(newCoin)

        return ResponseEntity.status(HttpStatus.CREATED).body(savedCoin)
    }
}
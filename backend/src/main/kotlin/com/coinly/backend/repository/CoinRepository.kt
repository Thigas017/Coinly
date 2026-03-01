package com.coinly.backend.repository

import com.coinly.backend.model.Coin
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface CoinRepository : JpaRepository<Coin, Long>{

}
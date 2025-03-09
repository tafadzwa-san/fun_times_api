# FunTimes API

## 📌 Overview

FunTimes API is a Ruby on Rails application that fetches real-time cryptocurrency market data from multiple sources, including Binance, KuCoin, and CoinGecko. It aggregates data to provide users with a reliable market overview.

## 🚀 Features

- Fetches cryptocurrency prices from multiple sources
- Aggregates data with built-in error handling
- Supports Redis caching for performance optimization
- Uses GraphQL for flexible querying
- Implements JWT authentication (Auth0)

## 🛠️ Setup Instructions

### 1️⃣ Prerequisites

- **Ruby 3.4.2**
- **Rails 8.0.1**
- **PostgreSQL**
- **Redis** (for caching)
- **Bundler** installed (`gem install bundler`)

### 2️⃣ Installation

Clone the repository and install dependencies:

```bash
git clone https://github.com/MrTafadzwaCodes/fun_times_api.git
cd fun_times_api
bundle install
```

### 3️⃣ Configure Environment Variables

Copy `.env.example` to `.env` and set up your API keys:

```bash
cp .env.example .env
```

Fill in required credentials in `.env`:

```ini
BINANCE_API_KEY=your_binance_key
KUCOIN_API_KEY=your_kucoin_key
COINGECKO_API_KEY=your_coingecko_key
REDIS_URL=redis://localhost:6379/1
```

### 4️⃣ Database Setup

Create and migrate the database:

```bash
rails db:create
rails db:migrate
```

### 5️⃣ Running the Server

Start the Rails server:

```bash
rails s
```

### 6️⃣ Running Tests

Execute the test suite:

```bash
rspec
```

## 🔗 API Usage

### Fetch Market Data

#### Request:

```graphql
query {
  marketData(coinSymbol: "BTC") {
    success
    market_data {
      source
      price
    }
    errors {
      source
      error
    }
  }
}
```

#### Response:

```json
{
  "data": {
    "marketData": {
      "success": true,
      "market_data": [
        { "source": "Binance", "price": "50234.56" },
        { "source": "CoinGecko", "price": "50300.00" }
      ],
      "errors": []
    }
  }
}
```

## 🚀 Contribution Guide

1. **Fork** the repository.
2. Create a new **feature branch** (`git checkout -b feature-name`).
3. Implement changes and **write tests**.
4. **Run tests** locally before pushing.
5. Submit a **pull request** for review.

## 📜 License

This project is licensed under the MIT License.

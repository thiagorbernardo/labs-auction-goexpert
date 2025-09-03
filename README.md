# Sistema de Leilões (Go)

Sistema de leilões com fechamento automático usando Go, MongoDB e processamento em lote.

## Como Executar

### 1. Suba os serviços:
```bash
docker-compose up --build
```

### 2. Verifique se está rodando:
```bash
curl http://localhost:8080/auction
# Deve retornar lista de leilões
```

## Como Testar

### Criar um Leilão
```bash
curl -X POST http://localhost:8080/auction \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "iPhone 15 Pro",
    "category": "Eletrônicos", 
    "description": "iPhone novo na caixa",
    "condition": 1
  }'
```

### Fazer Lances
```bash
# Lance 1
curl -X POST http://localhost:8080/bid \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user1",
    "auction_id": "SEU_AUCTION_ID",
    "amount": 1000.00
  }'

# Lance 2 (maior)
curl -X POST http://localhost:8080/bid \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user2", 
    "auction_id": "SEU_AUCTION_ID",
    "amount": 1500.00
  }'
```

### Ver Vencedor
```bash
curl http://localhost:8080/auction/winner/SEU_AUCTION_ID
```

### Teste de Fechamento Automático
```bash
# Execute o script completo
./test-bids.sh
```

**Resultado esperado:**
- Leilão criado
- 4 lances processados em lote
- Vencedor determinado
- Leilão fecha automaticamente após 20s

## Endpoints da API

**Base URL:** `http://localhost:8080`

### Leilões
- `GET /auction` - Listar leilões
- `GET /auction/:id` - Buscar leilão por ID  
- `POST /auction` - Criar leilão
- `GET /auction/winner/:id` - Obter vencedor

### Lances
- `POST /bid` - Fazer lance
- `GET /bid/:auctionId` - Listar lances do leilão

### Usuários  
- `GET /user/:userId` - Buscar usuário

## Configuração

Principais variáveis (arquivo `.env`):
- `AUCTION_INTERVAL=20s` - Tempo para leilão expirar
- `AUCTION_CHECK_INTERVAL=10s` - Frequência de verificação
- `MONGODB_URL=mongodb://mongodb:27017`
- `MONGODB_DB=auctions`

## Troubleshooting

### Erro de conexão?
```bash
# Verifique logs
docker-compose logs app
docker-compose logs mongodb

# Verifique status
docker-compose ps
```

### Leilões não fecham?
Edite `cmd/auction/.env` e reduza os tempos:
```bash
AUCTION_INTERVAL=10s
AUCTION_CHECK_INTERVAL=5s
```

## Estrutura do Projeto

```
labs-auction-goexpert/
├── cmd/auction/         # Servidor HTTP
├── internal/            # Lógica da aplicação  
├── configuration/       # Setup e configuração
├── Dockerfile           # Container da aplicação
└── docker-compose.yml   # Stack completo (app + MongoDB)
```

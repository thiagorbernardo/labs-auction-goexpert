# Sistema de Leilões com Fechamento Automático

Sistema de leilões baseado em Go com funcionalidade de fechamento automático usando goroutines e MongoDB.

## Funcionalidades

- **Gerenciamento de Leilões**: Criar, buscar e gerenciar leilões
- **Sistema de Lances**: Fazer lances em leilões ativos com processamento em lote
- **Fechamento Automático**: Leilões fecham automaticamente após intervalo configurável
- **Segurança de Concorrência**: Operações thread-safe com proteção mutex
- **Monitoramento em Tempo Real**: Goroutine em background monitora e fecha leilões expirados

## Arquitetura

### Componentes Principais

- **Entidade Leilão**: Define estrutura do leilão com status Ativo/Completado
- **Entidade Lance**: Gerencia colocação de lances com validação
- **Camada Repository**: Operações MongoDB com controle de concorrência
- **Camada Use Case**: Implementação da lógica de negócio
- **Camada Controller**: Endpoints da API HTTP

### Sistema de Fechamento Automático

O sistema implementa fechamento automático de leilões através de:

1. **Goroutine em Background**: Executa periodicamente para verificar leilões expirados
2. **Expiração Baseada em Tempo**: Leilões expiram após `AUCTION_INTERVAL` da criação
3. **Atualizações em Lote**: Fecha múltiplos leilões expirados eficientemente em uma operação
4. **Controle de Concorrência**: Proteção mutex previne condições de corrida

## Variáveis de Ambiente

| Variável | Descrição | Padrão | Exemplo |
|----------|-----------|--------|---------|
| `AUCTION_INTERVAL` | Duração antes do leilão expirar | `5m` | `20s`, `2m`, `1h` |
| `AUCTION_CHECK_INTERVAL` | Frequência de verificação de leilões expirados | `30s` | `10s`, `1m` |
| `BATCH_INSERT_INTERVAL` | Intervalo de processamento em lote de lances | `3m` | `20s` |
| `MAX_BATCH_SIZE` | Máximo de lances por lote | `5` | `4` |
| `MONGODB_URL` | String de conexão MongoDB | - | `mongodb://mongodb:27017` |
| `MONGODB_DB` | Nome do banco de dados | - | `auctions` |

## Endpoints da API

### Leilões
- `GET /auction` - Listar leilões com filtros opcionais
- `GET /auction/:auctionId` - Buscar leilão por ID
- `POST /auction` - Criar novo leilão
- `GET /auction/winner/:auctionId` - Obter lance vencedor do leilão

### Lances
- `POST /bid` - Fazer um lance
- `GET /bid/:auctionId` - Obter todos os lances de um leilão

### Usuários
- `GET /user/:userId` - Buscar usuário por ID

## Executando a Aplicação

1. **Iniciar os serviços**:
   ```bash
   docker-compose up -d
   ```

2. **Verificar logs**:
   ```bash
   docker-compose logs -f
   ```

3. **Parar serviços**:
   ```bash
   docker-compose down
   ```

A API estará disponível em `http://localhost:8080`

## Testes

### Executar Testes Unitários
```bash
go test ./...
```

### Teste Completo do Sistema (Recomendado)
Execute o script de teste que demonstra todas as funcionalidades do sistema:

```bash
./test-bids.sh
```

Este script automatiza um teste completo que:
- ✅ Cria um novo leilão
- ✅ Faz múltiplos lances (4 usuários diferentes)
- ✅ Verifica o processamento em lote dos lances
- ✅ Determina o vencedor em tempo real
- ✅ Testa o fechamento automático após expiração (20s)
- ✅ Confirma o vencedor final

**Exemplo de saída:**
```
=== TESTE DE LANCES EM LEILÕES ===
🎯 LEILÃO SELECIONADO: iPhone 15 Pro Max
💰 4 lances processados em lote
🏆 VENCEDOR: R$ 4200
✅ SUCESSO: Leilão fechado automaticamente!
```

## Exemplos de Uso da API

### Criar um Leilão
```bash
curl -X POST http://localhost:8080/auction \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "Guitarra Vintage",
    "category": "Música",
    "description": "Linda guitarra acústica vintage em excelente estado",
    "condition": 1
  }'
```

### Fazer um Lance
```bash
curl -X POST http://localhost:8080/bid \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "auction_id": "auction456",
    "amount": 150.00
  }'
```

### Obter Vencedor do Leilão
```bash
curl http://localhost:8080/auction/winner/auction456
```

## Comportamento do Fechamento Automático

1. **Criação do Leilão**: Quando criado, status do leilão é `Active` (Ativo)
2. **Verificação de Expiração**: Goroutine em background executa a cada `AUCTION_CHECK_INTERVAL`
3. **Cálculo de Tempo**: Leilões expiram após `AUCTION_INTERVAL` do momento da criação
4. **Atualização de Status**: Leilões expirados são atualizados para status `Completed` (Completado)
5. **Validação de Lances**: Novos lances são rejeitados para leilões completados

## Desenvolvimento

### Estrutura do Projeto
```
├── cmd/auction/              # Ponto de entrada da aplicação
├── configuration/            # Configuração e setup
├── internal/
│   ├── entity/              # Entidades de domínio
│   ├── usecase/             # Lógica de negócio
│   └── infra/
│       ├── api/             # Controllers HTTP
│       └── database/        # Implementações de repository
├── docker-compose.yml       # Configuração Docker
└── README.md               # Este arquivo
```

### Arquivos de Implementação Principais

- `internal/infra/database/auction/create_auction.go` - Repository principal de leilões com lógica de fechamento
- `cmd/auction/main.go` - Inicialização da aplicação e goroutine
- `internal/entity/auction_entity/auction_entity.go` - Modelo de domínio do leilão

## Monitoramento e Logs

A aplicação fornece logging estruturado para:
- Operações de fechamento de leilões
- Eventos do ciclo de vida da goroutine
- Operações de banco de dados
- Tratamento de erros

Exemplos de mensagens de log:
```
INFO: Auction close routine started - checkInterval: 10s, auctionInterval: 20s
INFO: Closed 3 expired auctions
ERROR: Error in auction close routine: database connection failed
```

## Solução de Problemas

### Problemas Comuns

1. **Falha na Conexão MongoDB**
   - Verifique se o MongoDB está rodando
   - Verifique `MONGODB_URL` nas variáveis de ambiente
   - Garanta conectividade de rede

2. **Leilões Não Fecham Automaticamente**
   - Verifique valores de `AUCTION_INTERVAL` e `AUCTION_CHECK_INTERVAL`
   - Verifique se a goroutine foi iniciada (check logs)
   - Garanta que o horário do sistema está correto

3. **Alto Uso de Memória**
   - Reduza `MAX_BATCH_SIZE` para processamento de lances
   - Aumente `BATCH_INSERT_INTERVAL` para processar lances menos frequentemente

### Ajuste de Performance

- **Frequência de Verificação**: Menor `AUCTION_CHECK_INTERVAL` para fechamento mais rápido, maior para menos uso de CPU
- **Processamento em Lote**: Ajuste `MAX_BATCH_SIZE` e `BATCH_INSERT_INTERVAL` baseado no volume de lances
- **Indexação de Banco**: Garanta índices nos campos `status` e `timestamp` para consultas eficientes

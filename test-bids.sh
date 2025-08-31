#!/bin/bash

echo "=== TESTE DE LANCES EM LEILÕES ==="
echo ""

# Configurações
API_BASE="http://localhost:8080"
echo "API Base: $API_BASE"
echo ""

# 1. CRIAR NOVO LEILÃO
echo "1. CRIANDO NOVO LEILÃO..."
echo "POST /auction"
curl -X POST $API_BASE/auction \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "iPhone 15 Pro Max",
    "category": "Smartphones",
    "description": "iPhone 15 Pro Max 512GB, cor azul titanium, lacrado",
    "condition": 1
  }'
echo ""
echo ""

# 2. OBTER LEILÃO ATIVO MAIS RECENTE
echo "2. OBTENDO LEILÃO ATIVO..."
AUCTION_RESPONSE=$(curl -s "$API_BASE/auction?status=0")
echo "Leilões ativos:"
echo "$AUCTION_RESPONSE" | jq '.'

# Pegar o último leilão ativo (mais recente)
AUCTION_ID=$(echo "$AUCTION_RESPONSE" | jq -r '.[-1].id')
AUCTION_NAME=$(echo "$AUCTION_RESPONSE" | jq -r '.[-1].product_name')
echo ""
echo "🎯 LEILÃO SELECIONADO:"
echo "ID: $AUCTION_ID"
echo "Produto: $AUCTION_NAME"
echo ""

# 3. FAZER LANCES
echo "3. FAZENDO LANCES NO LEILÃO..."
echo ""

# Lance 1
echo "💰 Lance 1 - Usuário A (R$ 2500):"
curl -X POST $API_BASE/bid \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"550e8400-e29b-41d4-a716-446655440001\",
    \"auction_id\": \"$AUCTION_ID\",
    \"amount\": 2500.00
  }"
echo ""
echo ""

# Lance 2
echo "💰 Lance 2 - Usuário B (R$ 3000):"
curl -X POST $API_BASE/bid \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"550e8400-e29b-41d4-a716-446655440002\",
    \"auction_id\": \"$AUCTION_ID\",
    \"amount\": 3000.00
  }"
echo ""
echo ""

# Lance 3
echo "💰 Lance 3 - Usuário C (R$ 3500):"
curl -X POST $API_BASE/bid \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"550e8400-e29b-41d4-a716-446655440003\",
    \"auction_id\": \"$AUCTION_ID\",
    \"amount\": 3500.00
  }"
echo ""
echo ""

# Lance 4 (maior)
echo "💰 Lance 4 - Usuário D (R$ 4200):"
curl -X POST $API_BASE/bid \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"550e8400-e29b-41d4-a716-446655440004\",
    \"auction_id\": \"$AUCTION_ID\",
    \"amount\": 4200.00
  }"
echo ""
echo ""

# 4. AGUARDAR PROCESSAMENTO
echo "4. AGUARDANDO PROCESSAMENTO DOS LANCES..."
echo "Esperando 25 segundos para processamento em lote..."
echo "MAX_BATCH_SIZE=4 (atingido) ou BATCH_INSERT_INTERVAL=20s..."
sleep 25
echo ""

# 5. VERIFICAR LANCES
echo "5. VERIFICANDO TODOS OS LANCES..."
echo "GET /bid/$AUCTION_ID"
BIDS_RESPONSE=$(curl -s "$API_BASE/bid/$AUCTION_ID")
echo "$BIDS_RESPONSE" | jq '.'
echo ""

# 6. VERIFICAR VENCEDOR
echo "6. VERIFICANDO VENCEDOR..."
echo "GET /auction/winner/$AUCTION_ID"
WINNER_RESPONSE=$(curl -s "$API_BASE/auction/winner/$AUCTION_ID")
echo "$WINNER_RESPONSE" | jq '.'

# Extrair dados do vencedor
WINNER_USER=$(echo "$WINNER_RESPONSE" | jq -r '.bid.user_id // "Nenhum"')
WINNER_AMOUNT=$(echo "$WINNER_RESPONSE" | jq -r '.bid.amount // 0')

echo ""
echo "🏆 RESULTADO FINAL:"
echo "Vencedor: $WINNER_USER"
echo "Lance Vencedor: R$ $WINNER_AMOUNT"
echo ""

# 7. STATUS DO LEILÃO
echo "7. STATUS ATUAL DO LEILÃO..."
AUCTION_STATUS=$(curl -s "$API_BASE/auction/$AUCTION_ID")
STATUS=$(echo "$AUCTION_STATUS" | jq -r '.status')
if [ "$STATUS" = "0" ]; then
    echo "Status: ATIVO ✅"
else
    echo "Status: COMPLETADO ❌"
fi
echo ""

# 8. AGUARDAR EXPIRAÇÃO DO LEILÃO
echo "8. TESTANDO FECHAMENTO AUTOMÁTICO..."
echo "Aguardando 25 segundos para o leilão expirar (AUCTION_INTERVAL=20s)..."
echo "O sistema deve fechar automaticamente o leilão..."
sleep 25

# 9. VERIFICAR SE O LEILÃO FOI FECHADO
echo ""
echo "9. VERIFICANDO SE O LEILÃO FOI FECHADO AUTOMATICAMENTE..."
FINAL_STATUS=$(curl -s "$API_BASE/auction/$AUCTION_ID")
FINAL_STATUS_CODE=$(echo "$FINAL_STATUS" | jq -r '.status')

echo "Status final do leilão:"
echo "$FINAL_STATUS" | jq '.'
echo ""

if [ "$FINAL_STATUS_CODE" = "1" ]; then
    echo "✅ SUCESSO: Leilão foi fechado automaticamente!"
    echo "Status mudou de ATIVO (0) para COMPLETADO (1)"
else
    echo "❌ FALHA: Leilão ainda está ativo (status: $FINAL_STATUS_CODE)"
fi
echo ""

# 10. VERIFICAR VENCEDOR FINAL
echo "10. VENCEDOR FINAL APÓS FECHAMENTO..."
FINAL_WINNER=$(curl -s "$API_BASE/auction/winner/$AUCTION_ID")
echo "$FINAL_WINNER" | jq '.'

FINAL_WINNER_USER=$(echo "$FINAL_WINNER" | jq -r '.bid.user_id // "Nenhum"')
FINAL_WINNER_AMOUNT=$(echo "$FINAL_WINNER" | jq -r '.bid.amount // 0')

echo ""
echo "🏆 VENCEDOR FINAL:"
echo "Usuário: $FINAL_WINNER_USER"
echo "Lance Vencedor: R$ $FINAL_WINNER_AMOUNT"
echo ""

echo "=== TESTE CONCLUÍDO ==="
echo "✅ Funcionalidades testadas:"
echo "  - Criação de leilão"
echo "  - Colocação de lances"
echo "  - Determinação de vencedor"
echo "  - Fechamento automático após expiração"

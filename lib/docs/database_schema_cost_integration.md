-- =====================================================
-- SCHEMA DE BANCO DE DADOS - INTEGRAÇÃO DE CUSTOS
-- FortSmart Agro - Sistema de Gestão Agrícola
-- =====================================================

-- =====================================================
-- 1. MÓDULO TALHÕES
-- =====================================================

CREATE TABLE talhoes (
    id_talhao VARCHAR(36) PRIMARY KEY,
    nome_talhao VARCHAR(100) NOT NULL,
    area_ha DECIMAL(10,2) NOT NULL,
    cultura_atual VARCHAR(50),
    fazenda_id VARCHAR(36),
    coordenadas_geograficas TEXT,
    observacoes TEXT,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_sincronizado BOOLEAN DEFAULT FALSE,
    
    INDEX idx_fazenda (fazenda_id),
    INDEX idx_cultura (cultura_atual)
);

-- =====================================================
-- 2. MÓDULO ESTOQUE
-- =====================================================

CREATE TABLE produtos_estoque (
    id_produto VARCHAR(36) PRIMARY KEY,
    nome_produto VARCHAR(150) NOT NULL,
    tipo_produto ENUM('herbicida', 'inseticida', 'fungicida', 'fertilizante', 'adjuvante', 'semente', 'outro') NOT NULL,
    unidade VARCHAR(20) NOT NULL, -- L, kg, saca, mL, etc.
    preco_unitario DECIMAL(10,2) NOT NULL,
    saldo_atual DECIMAL(10,2) DEFAULT 0,
    valor_total_lote DECIMAL(12,2) GENERATED ALWAYS AS (saldo_atual * preco_unitario) STORED,
    
    -- Campos profissionais
    fornecedor VARCHAR(100),
    numero_lote VARCHAR(50),
    local_armazenagem VARCHAR(100),
    data_validade DATE,
    observacoes TEXT,
    
    -- Controle
    fazenda_id VARCHAR(36),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_sincronizado BOOLEAN DEFAULT FALSE,
    
    INDEX idx_tipo_produto (tipo_produto),
    INDEX idx_fornecedor (fornecedor),
    INDEX idx_fazenda (fazenda_id),
    INDEX idx_validade (data_validade)
);

-- Tabela de movimentações do estoque
CREATE TABLE movimentacoes_estoque (
    id_movimentacao VARCHAR(36) PRIMARY KEY,
    id_produto VARCHAR(36) NOT NULL,
    tipo_movimentacao ENUM('entrada', 'saida', 'ajuste') NOT NULL,
    quantidade DECIMAL(10,2) NOT NULL,
    preco_unitario_momento DECIMAL(10,2) NOT NULL, -- Preço no momento da movimentação
    valor_total DECIMAL(12,2) GENERATED ALWAYS AS (quantidade * preco_unitario_momento) STORED,
    
    -- Referência à aplicação (quando for saída)
    id_aplicacao VARCHAR(36),
    
    -- Controle
    data_movimentacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT,
    operador VARCHAR(100),
    fazenda_id VARCHAR(36),
    is_sincronizado BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (id_produto) REFERENCES produtos_estoque(id_produto) ON DELETE CASCADE,
    FOREIGN KEY (id_aplicacao) REFERENCES aplicacoes(id_aplicacao) ON DELETE SET NULL,
    
    INDEX idx_produto (id_produto),
    INDEX idx_tipo_movimentacao (tipo_movimentacao),
    INDEX idx_data_movimentacao (data_movimentacao),
    INDEX idx_aplicacao (id_aplicacao)
);

-- =====================================================
-- 3. MÓDULO APLICAÇÃO
-- =====================================================

CREATE TABLE aplicacoes (
    id_aplicacao VARCHAR(36) PRIMARY KEY,
    id_talhao VARCHAR(36) NOT NULL,
    id_produto VARCHAR(36) NOT NULL,
    dose_por_ha DECIMAL(8,3) NOT NULL, -- Ex: 2.5 L/ha
    area_aplicada_ha DECIMAL(10,2) NOT NULL,
    quantidade_total DECIMAL(10,2) GENERATED ALWAYS AS (dose_por_ha * area_aplicada_ha) STORED,
    
    -- Custos calculados
    preco_unitario_momento DECIMAL(10,2) NOT NULL, -- Preço do produto no momento da aplicação
    custo_total DECIMAL(12,2) GENERATED ALWAYS AS (quantidade_total * preco_unitario_momento) STORED,
    custo_por_ha DECIMAL(10,2) GENERATED ALWAYS AS (custo_total / area_aplicada_ha) STORED,
    
    -- Dados da aplicação
    data_aplicacao DATE NOT NULL,
    operador VARCHAR(100),
    equipamento VARCHAR(100),
    condicoes_climaticas VARCHAR(200),
    observacoes TEXT,
    
    -- Controle
    fazenda_id VARCHAR(36),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_sincronizado BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (id_talhao) REFERENCES talhoes(id_talhao) ON DELETE CASCADE,
    FOREIGN KEY (id_produto) REFERENCES produtos_estoque(id_produto) ON DELETE CASCADE,
    
    INDEX idx_talhao (id_talhao),
    INDEX idx_produto (id_produto),
    INDEX idx_data_aplicacao (data_aplicacao),
    INDEX idx_fazenda (fazenda_id)
);

-- =====================================================
-- 4. MÓDULO HISTÓRICO & REGISTRO DE TALHÕES
-- =====================================================

CREATE TABLE historico_talhoes (
    id_registro VARCHAR(36) PRIMARY KEY,
    id_talhao VARCHAR(36) NOT NULL,
    tipo_evento ENUM('aplicacao', 'plantio', 'colheita', 'observacao', 'outro') NOT NULL,
    descricao_evento TEXT NOT NULL,
    
    -- Referência à aplicação (quando for aplicação)
    id_aplicacao VARCHAR(36),
    
    -- Dados do evento
    data_evento DATE NOT NULL,
    custo_total_evento DECIMAL(12,2) DEFAULT 0,
    observacoes TEXT,
    
    -- Controle
    fazenda_id VARCHAR(36),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_sincronizado BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (id_talhao) REFERENCES talhoes(id_talhao) ON DELETE CASCADE,
    FOREIGN KEY (id_aplicacao) REFERENCES aplicacoes(id_aplicacao) ON DELETE SET NULL,
    
    INDEX idx_talhao (id_talhao),
    INDEX idx_tipo_evento (tipo_evento),
    INDEX idx_data_evento (data_evento),
    INDEX idx_aplicacao (id_aplicacao)
);

-- =====================================================
-- 5. VIEWS PARA RELATÓRIOS E CONSULTAS
-- =====================================================

-- View: Resumo de Custos por Talhão
CREATE VIEW vw_custos_por_talhao AS
SELECT 
    t.id_talhao,
    t.nome_talhao,
    t.area_ha,
    t.cultura_atual,
    COUNT(a.id_aplicacao) as total_aplicacoes,
    SUM(a.custo_total) as custo_total_aplicacoes,
    AVG(a.custo_por_ha) as custo_medio_por_ha,
    SUM(a.custo_total) / t.area_ha as custo_total_por_ha,
    MAX(a.data_aplicacao) as ultima_aplicacao
FROM talhoes t
LEFT JOIN aplicacoes a ON t.id_talhao = a.id_talhao
GROUP BY t.id_talhao, t.nome_talhao, t.area_ha, t.cultura_atual;

-- View: Detalhamento de Aplicações por Talhão
CREATE VIEW vw_detalhamento_aplicacoes AS
SELECT 
    a.id_aplicacao,
    t.id_talhao,
    t.nome_talhao,
    t.area_ha as area_total_talhao,
    p.nome_produto,
    p.tipo_produto,
    p.unidade,
    a.dose_por_ha,
    a.area_aplicada_ha,
    a.quantidade_total,
    a.preco_unitario_momento,
    a.custo_total,
    a.custo_por_ha,
    a.data_aplicacao,
    a.operador,
    a.equipamento
FROM aplicacoes a
JOIN talhoes t ON a.id_talhao = t.id_talhao
JOIN produtos_estoque p ON a.id_produto = p.id_produto
ORDER BY t.nome_talhao, a.data_aplicacao DESC;

-- View: Resumo de Estoque com Alertas
CREATE VIEW vw_resumo_estoque AS
SELECT 
    p.id_produto,
    p.nome_produto,
    p.tipo_produto,
    p.unidade,
    p.preco_unitario,
    p.saldo_atual,
    p.valor_total_lote,
    p.fornecedor,
    p.data_validade,
    CASE 
        WHEN p.saldo_atual < 10 THEN 'ESTOQUE_BAIXO'
        WHEN p.data_validade IS NOT NULL AND p.data_validade <= DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN 'VENCIMENTO_PROXIMO'
        WHEN p.data_validade IS NOT NULL AND p.data_validade <= CURDATE() THEN 'VENCIDO'
        ELSE 'NORMAL'
    END as status_alerta
FROM produtos_estoque p;

-- =====================================================
-- 6. PROCEDURES PARA OPERAÇÕES AUTOMÁTICAS
-- =====================================================

-- Procedure: Registrar Aplicação com Movimentação Automática
DELIMITER //
CREATE PROCEDURE sp_registrar_aplicacao(
    IN p_id_talhao VARCHAR(36),
    IN p_id_produto VARCHAR(36),
    IN p_dose_por_ha DECIMAL(8,3),
    IN p_area_aplicada_ha DECIMAL(10,2),
    IN p_data_aplicacao DATE,
    IN p_operador VARCHAR(100),
    IN p_equipamento VARCHAR(100),
    IN p_observacoes TEXT,
    IN p_fazenda_id VARCHAR(36)
)
BEGIN
    DECLARE v_id_aplicacao VARCHAR(36);
    DECLARE v_quantidade_total DECIMAL(10,2);
    DECLARE v_preco_unitario DECIMAL(10,2);
    DECLARE v_saldo_atual DECIMAL(10,2);
    DECLARE v_id_movimentacao VARCHAR(36);
    
    -- Gerar IDs únicos
    SET v_id_aplicacao = UUID();
    SET v_id_movimentacao = UUID();
    
    -- Obter preço unitário e saldo atual
    SELECT preco_unitario, saldo_atual INTO v_preco_unitario, v_saldo_atual
    FROM produtos_estoque WHERE id_produto = p_id_produto;
    
    -- Calcular quantidade total
    SET v_quantidade_total = p_dose_por_ha * p_area_aplicada_ha;
    
    -- Verificar se há estoque suficiente
    IF v_saldo_atual < v_quantidade_total THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Estoque insuficiente para esta aplicação';
    END IF;
    
    -- Inserir aplicação
    INSERT INTO aplicacoes (
        id_aplicacao, id_talhao, id_produto, dose_por_ha, area_aplicada_ha,
        preco_unitario_momento, data_aplicacao, operador, equipamento,
        observacoes, fazenda_id
    ) VALUES (
        v_id_aplicacao, p_id_talhao, p_id_produto, p_dose_por_ha, p_area_aplicada_ha,
        v_preco_unitario, p_data_aplicacao, p_operador, p_equipamento,
        p_observacoes, p_fazenda_id
    );
    
    -- Registrar movimentação de saída
    INSERT INTO movimentacoes_estoque (
        id_movimentacao, id_produto, tipo_movimentacao, quantidade,
        preco_unitario_momento, id_aplicacao, observacoes, operador, fazenda_id
    ) VALUES (
        v_id_movimentacao, p_id_produto, 'saida', v_quantidade_total,
        v_preco_unitario, v_id_aplicacao, 
        CONCAT('Saída automática - Aplicação em ', p_id_talhao), 
        p_operador, p_fazenda_id
    );
    
    -- Atualizar saldo do produto
    UPDATE produtos_estoque 
    SET saldo_atual = saldo_atual - v_quantidade_total,
        data_atualizacao = CURRENT_TIMESTAMP
    WHERE id_produto = p_id_produto;
    
    -- Registrar no histórico
    INSERT INTO historico_talhoes (
        id_registro, id_talhao, tipo_evento, descricao_evento,
        id_aplicacao, data_evento, custo_total_evento, fazenda_id
    ) VALUES (
        UUID(), p_id_talhao, 'aplicacao',
        CONCAT('Aplicação de ', (SELECT nome_produto FROM produtos_estoque WHERE id_produto = p_id_produto)),
        v_id_aplicacao, p_data_aplicacao,
        v_quantidade_total * v_preco_unitario, p_fazenda_id
    );
    
    SELECT v_id_aplicacao as id_aplicacao_criada;
END //
DELIMITER ;

-- =====================================================
-- 7. TRIGGERS PARA MANUTENÇÃO AUTOMÁTICA
-- =====================================================

-- Trigger: Atualizar custo_total_evento no histórico quando aplicação for inserida
DELIMITER //
CREATE TRIGGER tr_after_aplicacao_insert
AFTER INSERT ON aplicacoes
FOR EACH ROW
BEGIN
    UPDATE historico_talhoes 
    SET custo_total_evento = NEW.custo_total
    WHERE id_aplicacao = NEW.id_aplicacao;
END //
DELIMITER ;

-- Trigger: Atualizar custo_total_evento no histórico quando aplicação for atualizada
DELIMITER //
CREATE TRIGGER tr_after_aplicacao_update
AFTER UPDATE ON aplicacoes
FOR EACH ROW
BEGIN
    UPDATE historico_talhoes 
    SET custo_total_evento = NEW.custo_total
    WHERE id_aplicacao = NEW.id_aplicacao;
END //
DELIMITER ;

-- =====================================================
-- 8. ÍNDICES ADICIONAIS PARA PERFORMANCE
-- =====================================================

-- Índices compostos para consultas frequentes
CREATE INDEX idx_aplicacoes_talhao_data ON aplicacoes(id_talhao, data_aplicacao);
CREATE INDEX idx_aplicacoes_produto_data ON aplicacoes(id_produto, data_aplicacao);
CREATE INDEX idx_movimentacoes_produto_data ON movimentacoes_estoque(id_produto, data_movimentacao);
CREATE INDEX idx_historico_talhao_data ON historico_talhoes(id_talhao, data_evento);

-- =====================================================
-- 9. EXEMPLOS DE CONSULTAS ÚTEIS
-- =====================================================

-- Consulta: Custo total por talhão no período
/*
SELECT 
    t.nome_talhao,
    t.cultura_atual,
    SUM(a.custo_total) as custo_total_periodo,
    SUM(a.custo_total) / t.area_ha as custo_por_ha_periodo
FROM talhoes t
JOIN aplicacoes a ON t.id_talhao = a.id_talhao
WHERE a.data_aplicacao BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY t.id_talhao, t.nome_talhao, t.cultura_atual, t.area_ha
ORDER BY custo_total_periodo DESC;
*/

-- Consulta: Produtos mais utilizados
/*
SELECT 
    p.nome_produto,
    p.tipo_produto,
    COUNT(a.id_aplicacao) as total_aplicacoes,
    SUM(a.quantidade_total) as quantidade_total_usada,
    SUM(a.custo_total) as custo_total
FROM produtos_estoque p
JOIN aplicacoes a ON p.id_produto = a.id_produto
GROUP BY p.id_produto, p.nome_produto, p.tipo_produto
ORDER BY custo_total DESC;
*/

-- Consulta: Estoque com alertas
/*
SELECT * FROM vw_resumo_estoque 
WHERE status_alerta IN ('ESTOQUE_BAIXO', 'VENCIMENTO_PROXIMO', 'VENCIDO')
ORDER BY status_alerta, nome_produto;
*/

-- =====================================================
-- 10. COMENTÁRIOS FINAIS
-- =====================================================

/*
ESTRUTURA CRIADA:

1. TALHÕES: Armazena informações básicas dos talhões
2. PRODUTOS_ESTOQUE: Catálogo de produtos com preços
3. MOVIMENTACOES_ESTOQUE: Rastreabilidade de entradas/saídas
4. APLICACOES: Registro de aplicações com cálculos automáticos
5. HISTORICO_TALHOES: Histórico consolidado de eventos

VIEWS CRIADAS:
- vw_custos_por_talhao: Resumo de custos por talhão
- vw_detalhamento_aplicacoes: Detalhamento completo de aplicações
- vw_resumo_estoque: Resumo com alertas de estoque

PROCEDURE CRIADA:
- sp_registrar_aplicacao: Registra aplicação com movimentação automática

TRIGGERS CRIADOS:
- Atualização automática do histórico quando aplicação é registrada

FLUXO DE INTEGRAÇÃO:
1. Estoque fornece preço unitário e saldo
2. Aplicação registra dose, área e calcula custos
3. Movimentação automática de saída do estoque
4. Histórico consolida dados para relatórios
*/


Vou detalhar abaixo o que importa de cada módulo, quais rotas/funcionalidades expor e como se conectam:

📊 Integração para Custo por Talhão (Aplicação)
1. Módulo de Estoque

👉 O que importa para o cálculo:

Produtos cadastrados (fertilizantes, defensivos, sementes, adjuvantes).

Preço unitário (R$/L, R$/kg, R$/saco).

Unidade de medida (litro, kg, saca, embalagem).

Lote e validade (para rastreabilidade).

Entrada e saída de produtos (com vínculo à aplicação).

Saldo atualizado.

📌 Rotas necessárias:

GET /estoque/produtos → lista produtos com preço, unidade e saldo.

GET /estoque/produtos/{id} → detalhes de um produto específico.

POST /estoque/saida → registrar saída de produto vinculada a uma aplicação (reduz estoque).

POST /estoque/entrada → registrar entrada de produto.

PUT /estoque/produtos/{id} → atualizar preço e informações.

2. Módulo de Aplicação

👉 O que importa para o cálculo:

Registro da aplicação (ID único, data, operador).

Talhão vinculado.

Produto(s) aplicado(s).

Dose (ex: 1,5 L/ha).

Quantidade total usada (ex: 30 L).

Área do talhão (para multiplicar dose × área).

Equipamento utilizado (opcional, para relatórios de eficiência).

Custo por hectare = soma(dose × preço_unitário).

Custo total do talhão = custo/ha × área.

📌 Rotas necessárias:

GET /aplicacoes → lista todas aplicações (filtros: por talhão, por período).

GET /aplicacoes/{id} → detalhes de uma aplicação.

POST /aplicacoes → registrar aplicação nova (com produtos e doses).

PUT /aplicacoes/{id} → editar aplicação.

DELETE /aplicacoes/{id} → excluir aplicação.

⚡ Integração com estoque:
Ao salvar aplicação → gera saída de produto no estoque.

3. Módulo de Histórico de Talhões

👉 O que importa para o cálculo:

Talhão cadastrado (ID, nome, cultura, área em ha).

Vinculação com aplicações realizadas no talhão.

Linha do tempo: cada evento (plantio, aplicação, colheita).

Custo acumulado do talhão (somatório das aplicações).

Comparação entre talhões (custo/ha, custo total).

📌 Rotas necessárias:

GET /talhoes → lista todos talhões com área e cultura.

GET /talhoes/{id} → detalhes do talhão + histórico.

GET /talhoes/{id}/custos → retorna custo acumulado do talhão.

GET /talhoes/custos?periodo=YYYY-MM → retorna custos de todos os talhões no período.

POST /talhoes → cadastrar talhão.

PUT /talhoes/{id} → atualizar talhão (área, cultura).

DELETE /talhoes/{id} → excluir.

🔗 Fluxo de Geração de Custo por Talhão

Usuário registra aplicação (POST /aplicacoes).

Escolhe talhão + produtos.

Sistema consulta preço unitário do estoque.

Calcula custo/ha e custo total.

Debita estoque automaticamente.

Histórico do talhão é atualizado.

Registra aplicação como evento.

Soma custo acumulado.

Dashboard pode mostrar:

Custo por hectare (aplicação × cultura).

Custo acumulado por talhão.

Comparativo entre talhões.

📌 Resumo dos Campos Necessários para o Cálculo:

Do estoque: produto, preço unitário, unidade, lote.

Da aplicação: dose aplicada, área do talhão, quantidade total usada.

Do talhão: nome, área, cultura.

Do histórico: acumulação de aplicações + custos.
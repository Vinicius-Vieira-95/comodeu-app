-- Criar banco de dados
CREATE DATABASE como_deu;

-- Conectar ao banco
\c como_deu;

-- Criar tabelas (JPA criará automaticamente, mas aqui está o schema esperado)

-- Tabela de Avaliações
CREATE TABLE IF NOT EXISTS evaluations (
    id BIGSERIAL PRIMARY KEY,
    visitor_name VARCHAR(100) NOT NULL,
    cultural_space_name VARCHAR(200) NOT NULL,
    space_type VARCHAR(50),
    visit_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'IN_PROGRESS'
);

-- Tabela de Evidências
CREATE TABLE IF NOT EXISTS evidences (
    id BIGSERIAL PRIMARY KEY,
    evaluation_id BIGINT NOT NULL,
    photo_data BYTEA,
    mark_x INTEGER,
    mark_y INTEGER,
    quick_note VARCHAR(200) NOT NULL,
    capture_time TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'REGISTERED',
    FOREIGN KEY (evaluation_id) REFERENCES evaluations(id) ON DELETE CASCADE
);

-- Tabela de Itens COMO D'EU
CREATE TABLE IF NOT EXISTS como_items (
    id BIGSERIAL PRIMARY KEY,
    item_number INTEGER NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    category VARCHAR(50) NOT NULL,
    keywords TEXT,
    active BOOLEAN DEFAULT true
);

-- Tabela de Classificações
CREATE TABLE IF NOT EXISTS classifications (
    id BIGSERIAL PRIMARY KEY,
    evidence_id BIGINT NOT NULL,
    como_item_id BIGINT NOT NULL,
    personal_analysis VARCHAR(2000),
    classification_time TIMESTAMP NOT NULL,
    FOREIGN KEY (evidence_id) REFERENCES evidences(id) ON DELETE CASCADE,
    FOREIGN KEY (como_item_id) REFERENCES como_items(id)
);

-- Criar índices
CREATE INDEX idx_evaluations_status ON evaluations(status);
CREATE INDEX idx_evidences_evaluation_id ON evidences(evaluation_id);
CREATE INDEX idx_classifications_evidence_id ON classifications(evidence_id);
CREATE INDEX idx_classifications_como_item_id ON classifications(como_item_id);

-- Inserir os 17 itens COMO D'EU
INSERT INTO como_items (item_number, name, description, category, keywords) VALUES
(1, 'Acessibilidade Física', 'Rampas, escadas, portas, circulação, elevadores e acessibilidade geral para pessoas com mobilidade reduzida', 'Acessibilidade', 'rampa,escada,porta,acesso,acessível,elevador,desnível'),
(2, 'Conforto Térmico', 'Temperatura ambiente adequada, ventilação e climatização', 'Conforto', 'temperatura,frio,quente,clima,ventilação'),
(3, 'Conforto Acústico', 'Controle de ruído, reverberação, som ambiente e acústica do espaço', 'Conforto', 'barulho,som,ruído,acústica,silêncio'),
(4, 'Qualidade da Iluminação', 'Brilho adequado, uniformidade, ausência de ofuscamento e permitir visualização clara das obras', 'Conforto', 'luz,iluminação,escuro,brilho,claro,ofuscamento'),
(5, 'Mobiliário Apropriado', 'Bancos, assentos, espaços de descanso em quantidade e qualidade adequada', 'Conforto', 'banco,cadeira,assento,descanso,mobiliário'),
(6, 'Sinalização Clara', 'Indicadores de direção, localização, mapa do espaço e orientação clara para visitantes', 'Informação', 'placa,sinal,indicação,direção,localizar,mapa'),
(7, 'Informações Legíveis', 'Tamanho de fonte, contraste, tipografia e legibilidade adequados', 'Informação', 'letra,fonte,pequena,contraste,legível,ilegível,wcag'),
(8, 'Acesso à Informação', 'Placas informativas, guias, folhetos, audioguias e recursos informativos disponíveis', 'Informação', 'informação,guia,folheto,audioguia,descrição'),
(9, 'Comodidades Gerais', 'Banheiros, fontes de água, café, loja, guarda-volumes e outros serviços essenciais', 'Informação', 'banheiro,água,café,loja,guarda-volumes,serviço'),
(10, 'Clareza Expositiva', 'Explicações claras sobre as obras, contexto histórico, significado e relevância', 'Experiência', 'explicação,contexto,história,significado,interpretação'),
(11, 'Engajamento do Visitante', 'Capacidade de manter interesse, evitar filas excessivas, ritmo apropriado de visita', 'Experiência', 'fila,espera,longa,congestionado,aglomeração,engajamento'),
(12, 'Diversidade de Conteúdo', 'Variedade de perspectivas, temáticas e conteúdo que represente múltiplas visões', 'Experiência', 'conteúdo,diversidade,perspectiva,variedade'),
(13, 'Segurança e Privacidade', 'Medidas de segurança, proteção de dados, bem-estar e proteção do visitante', 'Segurança', 'segurança,risco,privacidade,proteção'),
(14, 'Gestão do Tempo', 'Duração adequada da visita, ritmo apropriado, não muito longa nem muito breve', 'Segurança', 'tempo,pressa,rápido,longo,duração'),
(15, 'Qualidade do Atendimento', 'Profissionalismo do staff, cortesia, conhecimento e disposição em ajudar', 'Segurança', 'atendimento,staff,guia,funcionário,profissional'),
(16, 'Recursos Educacionais', 'Materiais educacionais, atividades, workshops, programação e aprendizado', 'Segurança', 'educação,aprendizado,material,workshop,atividade'),
(17, 'Impressão Geral / Satisfação', 'Avaliação geral da experiência, satisfação do visitante e recomendação', 'Segurança', 'satisfação,impressão,geral,recomendação');

-- Confirmar
SELECT COUNT(*) as total_items FROM como_items;
